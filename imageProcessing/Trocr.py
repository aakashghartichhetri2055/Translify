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

# The annotated image gets overwritten here after every request
CAPTURE_PATH = "captured_frame.jpg"

# Load the model once at startup so every request is fast
print(f"[init] Loading TrOCR model: {config.MODEL_ID}")
device    = "cuda" if torch.cuda.is_available() else "cpu"
processor = TrOCRProcessor.from_pretrained(config.MODEL_ID)
model     = VisionEncoderDecoderModel.from_pretrained(config.MODEL_ID).to(device)
model.eval()
print(f"[init] Model loaded on {device}")

app = FastAPI()


def preprocess_for_ocr(gray: np.ndarray) -> np.ndarray:
    """
    Cleans up the image before we try to read text from it.

    We use gamma correction to fix over/under-exposed images — it's gentler
    than CLAHE and doesn't amplify noise. If the image is still very dark after
    that, we invert it (handles white text on dark backgrounds). Finally, we
    run a quick denoise pass to get rid of speckles.
    """
    avg_brightness = np.mean(gray)
    print(f"[preprocess] avg brightness: {avg_brightness:.1f}")

    if avg_brightness < config.GAMMA_VERY_DARK:
        gamma = 0.5
    elif avg_brightness < config.GAMMA_DARK:
        gamma = 0.75
    elif avg_brightness > config.GAMMA_BRIGHT:
        gamma = 1.5
    else:
        gamma = 1.0

    if gamma != 1.0:
        print(f"[preprocess] applying gamma: {gamma}")
        table = np.array([
            ((i / 255.0) ** gamma) * 255 for i in range(256)
        ], dtype=np.uint8)
        gray = cv2.LUT(gray, table)

    if np.mean(gray) < config.INVERT_THRESHOLD:
        print("[preprocess] inverting for light text on dark background")
        gray = cv2.bitwise_not(gray)

    gray = cv2.fastNlMeansDenoising(gray, h=config.DENOISE_H)

    return gray


def detect_text_regions(gray: np.ndarray):
    """
    Finds where the text is on the page and returns bounding boxes for each chunk.

    Steps:
      1. Threshold the image to get a clean black-and-white mask of the ink
      2. Dilate horizontally to glue nearby characters into word-sized blobs
      3. Find contours — each one becomes a candidate text region

    We skip vertical dilation on purpose: it tends to merge everything into one
    giant blob on dark-background images. Line grouping happens separately in
    merge_regions_into_lines().

    Returns a list of (x, y, w, h) tuples in the original image's coordinate space.
    """
    _, binary = cv2.threshold(
        gray, 0, 255,
        cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
    )

    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (config.H_KERNEL_WIDTH, 1))
    dilated  = cv2.dilate(binary, h_kernel, iterations=1)

    contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    regions = []
    img_h, img_w = gray.shape
    max_h   = img_h * config.MAX_LINE_HEIGHT_RATIO

    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)

        # Drop tiny blobs — they're almost always noise
        if w < config.MIN_REGION_W or h < config.MIN_REGION_H:
            continue

        # Drop blobs that are suspiciously tall — probably a background artifact
        if h > max_h:
            print(f"[detect] dropping oversized blob {w}x{h} "
                  f"(>{config.MAX_LINE_HEIGHT_RATIO*100:.0f}% of image height {img_h})")
            continue

        regions.append((x, y, w, h))

    regions.sort(key=lambda r: (r[1], r[0]))
    return regions


def merge_regions_into_lines(regions):
    """
    Groups nearby regions into single per-line bounding boxes.

    Two regions are treated as the same line if they overlap vertically by more
    than config.VERTICAL_OVERLAP_THRESH (as a fraction of the shorter region's height).
    """
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
            if any(vertical_overlap_ratio(r, regions[j]) >= config.VERTICAL_OVERLAP_THRESH
                   for r in group):
                group.append(regions[j])
                used[j] = True
        lines.append(group)

    # Combine each group into one big bounding box
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
    """
    Runs TrOCR on a single cropped region and returns the text it found.

    Skips crops that are too small (likely noise) or whose confidence score
    falls below the threshold (likely gibberish).
    """
    h, w = crop_bgr.shape[:2]
    if w < config.MIN_CROP_PX or h < config.MIN_CROP_PX:
        print(f"[recognize] skipping crop {w}x{h} — too small")
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
        print(f"[recognize] rejected — confidence {confidence:.3f} < threshold {config.MIN_CONFIDENCE}")
        return ""

    return text


def run_ocr(jpeg_bytes: bytes):
    """
    The main pipeline. Takes raw JPEG bytes and returns all the text we found
    along with bounding boxes for each line.

    Also saves an annotated copy of the image to disk so you can visually
    check what the model detected.
    """
    np_arr = np.frombuffer(jpeg_bytes, dtype=np.uint8)
    frame  = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    # Upscale small images — TrOCR reads them much more reliably at higher res
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

    gray_upscaled = preprocess_for_ocr(gray_upscaled)

    regions_scaled = detect_text_regions(gray_upscaled)
    regions_scaled = merge_regions_into_lines(regions_scaled)
    print(f"[ocr] {len(regions_scaled)} line(s) detected after merging")

    all_lines = []
    contents  = []

    for (sx, sy, sw, sh) in regions_scaled:
        crop = frame_scaled[sy:sy + sh, sx:sx + sw]
        if crop.size == 0:
            continue

        line_text = recognize_crop(crop)
        if not line_text:
            continue

        # Map the upscaled coordinates back to the original image
        ox = int(sx / scale)
        oy = int(sy / scale)
        ow = int(sw / scale)
        oh = int(sh / scale)

        # Add a small padding around the box so it doesn't hug the text too tightly
        bx  = max(ox - 4, 0)
        by  = max(oy - 4, 0)
        bx2 = min(ox + ow + 4, frame.shape[1])
        by2 = min(oy + oh + 4, frame.shape[0])

        all_lines.append(line_text)
        contents.append({
            "text": line_text,
            "bbox": {"x": bx, "y": by, "w": bx2 - bx, "h": by2 - by},
        })

        # Draw the box and label on the frame for visual debugging
        cv2.rectangle(frame, (bx, by), (bx2, by2), (0, 255, 0), 2)
        cv2.putText(frame, line_text, (bx, max(by - 6, 12)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1, cv2.LINE_AA)

    text = "\n".join(all_lines)

    cv2.imwrite(CAPTURE_PATH, frame)
    print(f"[snapshot] annotated frame saved → {os.path.abspath(CAPTURE_PATH)}")

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
    """
    Accepts a JPEG, runs OCR on it, and returns the detected text with bounding boxes.
    The annotated image is saved to disk — view it at GET /captured_image.
    """
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
    """Returns the last annotated snapshot. Open in your browser after a /capture call."""
    if not os.path.exists(CAPTURE_PATH):
        raise HTTPException(status_code=404, detail="No captured image yet")
    return FileResponse(CAPTURE_PATH, media_type="image/jpeg")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)