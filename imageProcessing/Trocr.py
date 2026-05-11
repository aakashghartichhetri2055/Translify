from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse, FileResponse
from fastapi import HTTPException
import cv2
import uvicorn
import numpy as np
import os
from PIL import Image
import torch
from transformers import TrOCRProcessor, VisionEncoderDecoderModel

import config

CAPTURE_PATH = "captured_frame.jpg"

# Load once at startup
print(f"[init] Loading TrOCR model: {config.MODEL_ID}")
device    = "cuda" if torch.cuda.is_available() else "cpu"
processor = TrOCRProcessor.from_pretrained(config.MODEL_ID)
model     = VisionEncoderDecoderModel.from_pretrained(config.MODEL_ID).to(device)
model.eval()
print(f"[init] Model loaded on {device}")

app = FastAPI()


def select_best_channel(bgr: np.ndarray) -> np.ndarray:
    """Pick the B/G/R channel (or its inverse) with the cleanest Otsu split,
    then make sure background is the bright side."""
    best_gray  = None
    best_score = -1

    for ch in cv2.split(bgr):
        for img in [ch, cv2.bitwise_not(ch)]:
            _, binary = cv2.threshold(
                img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
            )
            fg = img[binary == 255]
            bg = img[binary == 0]

            if len(fg) == 0 or len(bg) == 0:
                continue

            score = abs(float(np.mean(fg)) - float(np.mean(bg)))
            print(f"[channel] score={score:.1f}")

            if score > best_score:
                best_score = score
                best_gray  = img.copy()

    print(f"[channel] best contrast score: {best_score:.1f}")

    # Background should be the bright side; downstream BINARY_INV depends on it
    _, otsu = cv2.threshold(best_gray, 0, 255,
                            cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    bright_fraction = (otsu == 255).sum() / otsu.size
    if bright_fraction < 0.5:
        print(f"[channel] inverting polarity (bright fraction {bright_fraction:.2f})")
        best_gray = cv2.bitwise_not(best_gray)

    return best_gray


def preprocess_for_ocr(gray: np.ndarray, bgr: np.ndarray = None) -> np.ndarray:
    """Best-channel swap (if bgr given) -> gamma -> optional invert -> denoise."""
    polarity_already_normalized = bgr is not None
    if bgr is not None:
        gray = select_best_channel(bgr)

    avg = np.mean(gray)
    print(f"[preprocess] avg brightness: {avg:.1f}")

    if avg < config.GAMMA_VERY_DARK:
        gamma = 0.5
    elif avg < config.GAMMA_DARK:
        gamma = 0.75
    elif avg > config.GAMMA_BRIGHT:
        gamma = 1.5
    else:
        gamma = 1.0

    if gamma != 1.0:
        print(f"[preprocess] applying gamma: {gamma}")
        table = np.array([
            ((i / 255.0) ** gamma) * 255 for i in range(256)
        ], dtype=np.uint8)
        gray = cv2.LUT(gray, table)

    # Skip when bgr was given; select_best_channel already handled polarity
    if not polarity_already_normalized:
        if np.mean(gray) < config.INVERT_THRESHOLD:
            print("[preprocess] inverting (light text on dark background)")
            gray = cv2.bitwise_not(gray)

    gray = cv2.fastNlMeansDenoising(gray, h=config.DENOISE_H)
    return gray


def detect_text_regions(gray: np.ndarray):
    """Adaptive threshold + horizontal dilate -> contours -> filter."""
    binary = cv2.adaptiveThreshold(
        gray, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        blockSize=config.ADAPTIVE_BLOCK_SIZE,
        C=config.ADAPTIVE_C
    )

    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (config.H_KERNEL_WIDTH, 1))
    dilated  = cv2.dilate(binary, h_kernel, iterations=1)

    # RETR_LIST so an outer contour can't hide nested text
    contours, _ = cv2.findContours(dilated, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)

    regions = []
    img_h, img_w = gray.shape
    max_h = img_h * config.MAX_LINE_HEIGHT_RATIO

    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)

        if w < config.MIN_REGION_W or h < config.MIN_REGION_H:
            continue  # noise

        if h > max_h:
            print(f"[detect] dropping oversized blob {w}x{h}")
            continue

        if w > img_w * 0.95 and h > img_h * 0.95:
            print(f"[detect] dropping page-spanning blob {w}x{h}")
            continue

        regions.append((x, y, w, h))

    regions.sort(key=lambda r: (r[1], r[0]))
    return regions


def merge_regions_into_lines(regions):
    """Merge boxes onto the same line by vertical overlap."""
    if not regions:
        return []

    def vertical_overlap_ratio(a, b):
        a_y, a_y2 = a[1], a[1] + a[3]
        b_y, b_y2 = b[1], b[1] + b[3]
        overlap = max(0, min(a_y2, b_y2) - max(a_y, b_y))
        min_h   = min(a[3], b[3])
        return overlap / min_h if min_h > 0 else 0.0

    lines = []
    used  = [False] * len(regions)

    for i, r in enumerate(regions):
        if used[i]:
            continue
        group = [r]
        used[i] = True
        for j in range(i + 1, len(regions)):
            if used[j]:
                continue
            if any(vertical_overlap_ratio(g, regions[j]) >= config.VERTICAL_OVERLAP_THRESH
                   for g in group):
                group.append(regions[j])
                used[j] = True
        lines.append(group)

    merged = []
    for group in lines:
        x1 = min(r[0] for r in group)
        y1 = min(r[1] for r in group)
        x2 = max(r[0] + r[2] for r in group)
        y2 = max(r[1] + r[3] for r in group)
        merged.append((x1, y1, x2 - x1, y2 - y1))

    merged.sort(key=lambda r: (r[1], r[0]))
    return merged


def recognize_crop(crop_bgr: np.ndarray) -> str:
    """Run TrOCR on one crop. Skips tiny or low-confidence results."""
    h, w = crop_bgr.shape[:2]
    if w < config.MIN_CROP_PX or h < config.MIN_CROP_PX:
        print(f"[recognize] skipping crop {w}x{h} (too small)")
        return ""

    pil_img = Image.fromarray(cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB))
    pixel_values = processor(images=pil_img, return_tensors="pt").pixel_values.to(device)

    with torch.no_grad():
        outputs = model.generate(
            pixel_values,
            num_beams=config.NUM_BEAMS,
            max_new_tokens=config.MAX_NEW_TOKENS,
            output_scores=True,
            return_dict_in_generate=True,
        )

    confidence = outputs.sequences_scores[0].item()
    text = processor.batch_decode(outputs.sequences, skip_special_tokens=True)[0].strip()

    print(f"[recognize] '{text}'  confidence={confidence:.3f}")

    if confidence < config.MIN_CONFIDENCE:
        print(f"[recognize] rejected (confidence {confidence:.3f} < {config.MIN_CONFIDENCE})")
        return ""

    return text


def run_ocr(jpeg_bytes: bytes):
    """End-to-end pipeline. Returns (text, contents) and saves an annotated frame."""
    np_arr = np.frombuffer(jpeg_bytes, dtype=np.uint8)
    frame  = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    # Upscale small inputs; TrOCR reads them better at higher res
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    orig_h, orig_w = gray.shape
    if orig_w < config.UPSCALE_MIN_WIDTH:
        scale         = config.UPSCALE_MIN_WIDTH / orig_w
        gray_upscaled = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
        frame_scaled  = cv2.resize(frame, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    else:
        scale         = 1.0
        gray_upscaled = gray
        frame_scaled  = frame

    gray_upscaled = preprocess_for_ocr(gray_upscaled, bgr=frame_scaled)

    regions_scaled = detect_text_regions(gray_upscaled)
    regions_scaled = merge_regions_into_lines(regions_scaled)
    print(f"[ocr] {len(regions_scaled)} line(s) after merging")

    all_lines = []
    contents  = []

    for (sx, sy, sw, sh) in regions_scaled:
        crop = frame_scaled[sy:sy + sh, sx:sx + sw]
        if crop.size == 0:
            continue

        line_text = recognize_crop(crop)
        if not line_text:
            continue

        # Map back to original coords
        ox = int(sx / scale)
        oy = int(sy / scale)
        ow = int(sw / scale)
        oh = int(sh / scale)

        # Small padding around the box
        bx  = max(ox - 4, 0)
        by  = max(oy - 4, 0)
        bx2 = min(ox + ow + 4, frame.shape[1])
        by2 = min(oy + oh + 4, frame.shape[0])

        all_lines.append(line_text)
        contents.append({
            "text": line_text,
            "bbox": {"x": bx, "y": by, "w": bx2 - bx, "h": by2 - by},
        })

        cv2.rectangle(frame, (bx, by), (bx2, by2), (0, 255, 0), 2)
        cv2.putText(frame, line_text, (bx, max(by - 6, 12)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1, cv2.LINE_AA)

    text = "\n".join(all_lines)

    cv2.imwrite(CAPTURE_PATH, frame)
    print(f"[snapshot] annotated frame saved -> {os.path.abspath(CAPTURE_PATH)}")

    print("\n" + "=" * 50)
    print("[OCR] Detected text:")
    print("-" * 50)
    print(text.strip() if text.strip() else "(no text detected)")
    print("=" * 50 + "\n")

    print("[CONTENTS] Detected blocks:")
    print("-" * 50)
    for i, entry in enumerate(contents):
        bbox = entry["bbox"]
        print(f"  Block {i + 1}:")
        print(f"    Text : {entry['text']}")
        print(f"    BBox : x={bbox['x']}, y={bbox['y']}, w={bbox['w']}, h={bbox['h']}")
    print("=" * 50 + "\n")

    return text, contents


@app.post("/capture")
async def capture(image: UploadFile = File(...)):
    """OCR a JPEG. Annotated image available at GET /captured_image."""
    jpeg_bytes = await image.read()
    if not jpeg_bytes:
        raise HTTPException(status_code=400, detail="No image received")

    try:
        text, contents = run_ocr(jpeg_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    return JSONResponse({
        "text":     text,
        "contents": contents,
    })


@app.get("/captured_image")
def captured_image():
    """Last annotated snapshot."""
    if not os.path.exists(CAPTURE_PATH):
        raise HTTPException(status_code=404, detail="No captured image yet")
    return FileResponse(CAPTURE_PATH, media_type="image/jpeg")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)