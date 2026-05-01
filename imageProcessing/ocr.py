from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse, FileResponse
from fastapi import HTTPException
import cv2
import uvicorn
import pytesseract
import numpy as np
import os
from collections import defaultdict

CAPTURE_PATH = "captured_frame.jpg"    # annotated image saved here after each request

app = FastAPI()


def preprocess_for_ocr(gray):
    """
    Normalizes brightness with gamma correction — adjusts exposure without
    amplifying noise like CLAHE + sharpening does.
    """
    avg_brightness = np.mean(gray)
    print(f"[preprocess] avg brightness: {avg_brightness:.1f}")

    if avg_brightness < 85:
        gamma = 0.5       # very dark — brighten aggressively
    elif avg_brightness < 127:
        gamma = 0.75      # moderately dark — brighten gently
    elif avg_brightness > 180:
        gamma = 1.5       # too bright/washed out — darken slightly
    else:
        gamma = 1.0       # already well-lit — no adjustment needed

    if gamma != 1.0:
        print(f"[preprocess] applying gamma: {gamma}")
        table = np.array([
            ((i / 255.0) ** gamma) * 255 for i in range(256)
        ], dtype=np.uint8)
        gray = cv2.LUT(gray, table)

    # Invert only if still dark after gamma correction
    if np.mean(gray) < 100:
        print("[preprocess] inverting for light text on dark background")
        gray = cv2.bitwise_not(gray)

    # Gentle denoise — keep this, it doesn't amplify noise
    gray = cv2.fastNlMeansDenoising(gray, h=10)

    return gray


def run_ocr(jpeg_bytes: bytes):
    """
    Decodes a JPEG image, runs OCR, draws bounding boxes + detected text
    onto the frame, saves it to disk, and returns the text and contents array.
    """
    # Decode jpeg bytes → numpy array → BGR frame
    np_arr = np.frombuffer(jpeg_bytes, dtype=np.uint8)
    frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    # OCR configuration: OEM 3 = default engine, PSM 11 = sparse text, lang = english + spanish
    config = "--oem 3 --psm 11 -l eng+spa"

    # Convert to grayscale and upscale if too small for better OCR accuracy
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    orig_h, orig_w = gray.shape
    if orig_w < 1200:
        scale = 1200 / orig_w
        gray_upscaled = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    else:
        scale = 1.0
        gray_upscaled = gray

    gray_upscaled = preprocess_for_ocr(gray_upscaled)

    # Run OCR — get full text and per-word data for bounding boxes
    data = pytesseract.image_to_data(gray_upscaled, output_type=pytesseract.Output.DICT, config=config)
    text = pytesseract.image_to_string(gray_upscaled, config=config)

    print("\n" + "=" * 50)
    print("[OCR] Detected text:")
    print("-" * 50)
    print(text.strip() if text.strip() else "(no text detected)")
    print("=" * 50 + "\n")

    # Group words by block number
    blocks = defaultdict(list)
    for i in range(len(data["text"])):
        word = data["text"][i].strip()
        conf = int(data["conf"][i])

        if not word or conf < 40:
            continue

        # Scale bbox coordinates back down to match original frame size
        x = int(data["left"][i]   / scale)
        y = int(data["top"][i]    / scale)
        w = int(data["width"][i]  / scale)
        h = int(data["height"][i] / scale)

        blocks[data["block_num"][i]].append((x, y, w, h, word))

    # Build contents array and draw annotations on frame
    contents = []

    for block_num, words_in_block in blocks.items():
        if not words_in_block:
            continue

        # Union bounding box for the whole block with small padding
        bx  = max(min(b[0]       for b in words_in_block) - 4, 0)
        by  = max(min(b[1]       for b in words_in_block) - 4, 0)
        bx2 = min(max(b[0]+b[2]  for b in words_in_block) + 4, frame.shape[1])
        by2 = min(max(b[1]+b[3]  for b in words_in_block) + 4, frame.shape[0])

        block_text = " ".join(b[4] for b in words_in_block)

        contents.append({
            "text": block_text,
            "bbox": {"x": bx, "y": by, "w": bx2 - bx, "h": by2 - by},
        })

        # Draw green bounding box and text label on frame
        cv2.rectangle(frame, (bx, by), (bx2, by2), (0, 255, 0), 2)
        cv2.putText(frame, block_text, (bx, max(by - 6, 12)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1, cv2.LINE_AA)

    # Save annotated image to disk — view at /captured_image
    cv2.imwrite(CAPTURE_PATH, frame)
    print(f"[snapshot] annotated frame saved → {os.path.abspath(CAPTURE_PATH)}")

    print("\n" + "=" * 50)
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
    Receives a JPEG from the backend, runs OCR, saves annotated image to disk,
    and returns extracted text + bounding boxes.
    View the annotated image at GET /captured_image after calling this.
    """
    jpeg_bytes = await image.read()
    if not jpeg_bytes:
        raise HTTPException(status_code=400, detail="Empty image received")

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
    """Serves the last annotated snapshot. Open in browser after a /capture call."""
    if not os.path.exists(CAPTURE_PATH):
        raise HTTPException(status_code=404, detail="No captured image yet")
    return FileResponse(CAPTURE_PATH, media_type="image/jpeg")


if __name__ == "__main__":
   #uvicorn.run(app, host="0.0.0.0", port=8001)
   uvicorn.run(app, host="127.0.0.1", port=8001)