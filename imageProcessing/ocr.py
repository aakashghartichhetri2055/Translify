from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse, JSONResponse, FileResponse, HTMLResponse
from fastapi import HTTPException
import asyncio
from contextlib import asynccontextmanager
import cv2
import uvicorn
import pytesseract
import threading
import time
import numpy as np
import os
import re
import requests

CAPTURE_PATH = "captured_frame.jpg"    # path where snapshot is saved to disk

class Camera:

    def __init__(self):
        self.cap = None
        self._lock = threading.Lock()           # protect access to the lastest jpeg
        self._lastest_jepg = None               # most recent encoded jpeg frame
        self._stop_event = threading.Event()    # siginal both threads to stop
        self._capture_thread = None             # thread 1: read frames from camera

        # Capture State
        self._state_lock = threading.Lock()
        self._mode = "live"
        self._capture_jepg = None
        self._captured_text = ""
        self.translated_text = ""
        self._contents = []     # list of {original_text, translated_text, bbox}

    # This start the camera
    def start(self):
        """
        Opens the default camera device (index 0).
        Change the index to use a different camera (e.g., 1 for an external webcam).
        Raises a RuntimeError if the camera cannot be accessed.
        """
        self.cap = cv2.VideoCapture(0)  # <-- change the 0 for other webcam option
        if not self.cap.isOpened():
            raise RuntimeError("Could not open camera")
        
        self._stop_event.clear()
        self._capture_thread = threading.Thread(target=self.capture_loop, daemon=True)     # this thread will be killed on exit
        self._capture_thread.start()

    # This release camera resource
    def release(self):
        """
        Stops both background threads and releases the camera device.
        Always called on shutdown to avoid leaving the camera locked.
        """
        self._stop_event.set()      # tell both threads to exit their loops

        # check if both thread actually stopped
        if self._capture_thread:
            self._capture_thread.join(timeout=3)

        # Check if camera is open, then release it
        if self.cap and self.cap.isOpened():
            self.cap.release()

    # capture loop (runs in background thread)
    def capture_loop(self):
        while not self._stop_event.is_set():
            if not self.cap or not self.cap.isOpened():
                time.sleep(0.01)
                continue

            ret, frame = self.cap.read()
            if not ret or frame is None:
                time.sleep(0.01)
                continue

            ret, jpeg = cv2.imencode(".jpg", frame)
            if ret:
                with self._lock:
                    self._lastest_jepg = jpeg.tobytes()

    def preprocess_for_ocr(self, gray):
        """
        Normalizes brightness with gamma correction — adjusts exposure without
        amplifying noise like CLAHE + sharpening does.
        """
        # Gamma < 1 brightens a dark image, gamma > 1 darkens a bright image
        avg_brightness = np.mean(gray)
        print(f"[preprocess] avg brightness: {avg_brightness:.1f}")

        # Automatically pick gamma based on how dark or bright the frame is
        if avg_brightness < 85:
            gamma = 0.5   # very dark — brighten aggressively
        elif avg_brightness < 127:
            gamma = 0.75  # moderately dark — brighten gently
        elif avg_brightness > 180:
            gamma = 1.5   # too bright/washed out — darken slightly
        else:
            gamma = 1.0   # already well-lit — no adjustment needed

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
    
    def translate_text(self, text, source_lang="auto", target_lang="en"):
        try:
            response = requests.post("http://172.17.0.1:5000/translate", json={
                "q": text,
                "source": source_lang,
                "target": target_lang,
                "format": "text"
            })
            return response.json()["translatedText"]
        except Exception as e:
            print(f"[translate] failed: {e}")
            return text  # fall back to original text
    
    def capture(self, target_language="es"):
        # grab latest jpeg from self._lastest_jepg
        with self._lock:
            jpeg_bytes = self._lastest_jepg

            if jpeg_bytes is None:
                raise RuntimeError("No Frame Captured")

        # set self._mode = "processing"
        with self._state_lock:
            self._mode = "processing"

        # decode jpeg → numpy array → frame → grayscale
        np_arr = np.frombuffer(jpeg_bytes, dtype=np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        # OCR configuration
        config = "--oem 3 --psm 11 -l eng+spa"  # OEM 3 = default, PSM 11 = sparse text with OSD, lang = english + spanish

        # convert to grayscale for better OCR performance, and upscale if too small
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        orig_h, orig_w = gray.shape
        if orig_w < 1200:
            scale = 1200 / orig_w
            gray_upscaled = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
        else:
            scale = 1.0
            gray_upscaled = gray

        # preprocess to handle light-colored text
        gray_upscaled = self.preprocess_for_ocr(gray_upscaled)

        # run OCR on the upscaled grayscale image, get both text and detailed data for bounding boxes
        data = pytesseract.image_to_data(gray_upscaled, output_type=pytesseract.Output.DICT, config=config)
        text = pytesseract.image_to_string(gray_upscaled, config=config)

        # Print to terminal
        print("\n" + "=" * 50)
        print("[OCR] Detected text:")
        print("-" * 50)
        print(text.strip() if text.strip() else "(no text detected)")
        print("=" * 50 + "\n")

        # Translate the detected text
        translated = self.translate_text(text, source_lang="auto", target_lang=target_language)


        # Group detected words by block number
        from collections import defaultdict
        blocks = defaultdict(list)
        n_boxes = len(data["text"])
        for i in range(n_boxes):
            word = data["text"][i].strip()
            conf = int(data["conf"][i])
 
            # Skip empty words and low-confidence detections
            if not word or conf < 40:
                continue
 
            # Scale bounding box coordinates back down to match the original frame
            x = int(data["left"][i]  / scale)
            y = int(data["top"][i]   / scale)
            w = int(data["width"][i] / scale)
            h = int(data["height"][i]/ scale)
 
            blocks[data["block_num"][i]].append((x, y, w, h, word))

        # Build contents array: one entry per detected block
        contents = []

        # For each block: draw one bounding box around it and overlay translated text
        for block_num, words_in_block in blocks.items():
            if not words_in_block:
                continue
 
            # Compute the union bounding box for the whole block with small padding
            bx  = max(min(b[0]       for b in words_in_block) - 4, 0)
            by  = max(min(b[1]       for b in words_in_block) - 4, 0)
            bx2 = min(max(b[0]+b[2]  for b in words_in_block) + 4, frame.shape[1])
            by2 = min(max(b[1]+b[3]  for b in words_in_block) + 4, frame.shape[0])
 
            # Translate just this block's text
            block_text       = " ".join(b[4] for b in words_in_block)
            block_translated = self.translate_text(block_text, source_lang="auto", target_lang=target_language)

            # Store this block's data: original text, translation, and bounding box.
            # bbox uses top-left corner (x, y) plus width and height — same convention as pytesseract.
            contents.append({
                "original_text":   block_text,
                "translated_text": block_translated,
                "bbox": {
                    "x": bx,
                    "y": by,
                    "w": bx2 - bx,
                    "h": by2 - by,
                },
            })
 
            # Semi-transparent dark fill to cover the original text
            overlay = frame.copy()
            cv2.rectangle(overlay, (bx, by), (bx2, by2), (20, 20, 20), cv2.FILLED)
            cv2.addWeighted(overlay, 0.88, frame, 0.12, 0, frame)
 
            # Green border around the block
            cv2.rectangle(frame, (bx, by), (bx2, by2), (0, 255, 0), 2)
 
            # Fit font size to the box: start at 0.55 and shrink if text won't fit
            font      = cv2.FONT_HERSHEY_SIMPLEX
            thickness = 1
            padding   = 6
            box_w     = bx2 - bx - padding * 2
            box_h     = by2 - by - padding * 2
 
            font_scale = 0.55
            while font_scale > 0.25:
                (_, ch), _ = cv2.getTextSize("A", font, font_scale, thickness)
                line_h     = int(ch * 2.2)
                # Word-wrap at current scale
                lines, current = [], ""
                for w in block_translated.split():
                    test      = (current + " " + w).strip()
                    (tw, _), _ = cv2.getTextSize(test, font, font_scale, thickness)
                    if tw <= box_w:
                        current = test
                    else:
                        if current:
                            lines.append(current)
                        current = w
                if current:
                    lines.append(current)
                # Check if all lines fit vertically
                if len(lines) * line_h <= box_h:
                    break
                font_scale -= 0.05
 
            # Draw each wrapped line of translated text inside the box
            text_y = by + padding + int(cv2.getTextSize("A", font, font_scale, thickness)[0][1])
            for line in lines:
                if text_y > by2 - padding:
                    break
                cv2.putText(frame, line, (bx + padding, text_y),
                            font, font_scale, (0, 255, 0), thickness, cv2.LINE_AA)
                text_y += line_h
        
        # Save raw snapshot after OCR
        cv2.imwrite(CAPTURE_PATH, frame)
        print(f"[snapshot] raw frame saved → {os.path.abspath(CAPTURE_PATH)}")

        # Print contents array to terminal
        print("\n" + "=" * 50)
        print("[CONTENTS] Detected blocks:")
        print("-" * 50)
        for i, entry in enumerate(contents):
            bbox = entry["bbox"]
            print(f"  Block {i + 1}:")
            print(f"    Original   : {entry['original_text']}")
            print(f"    Translated : {entry['translated_text']}")
            print(f"    BBox       : x={bbox['x']}, y={bbox['y']}, w={bbox['w']}, h={bbox['h']}")
        print("=" * 50 + "\n")

        # re-encode to jpeg, store in self._captured_jpeg
        ret, captured_jpeg = cv2.imencode(".jpg", frame)
        
        # store text in self._captured_text
        with self._state_lock:
            self._captured_jpeg = captured_jpeg.tobytes() if ret else jpeg_bytes
            self._captured_text = text
            self._translated_text = translated
            self._contents = contents

            # set self._mode = "captured"
            self._mode = "captured"

    # reset captured state and return to live mode
    def reset(self):
        self._mode = "live"
        self._captured_jpeg = None
        self._captured_text = ""
        self._contents = []

    # generator for streaming video frames as multipart HTTP response
    def generate_frame(self):
        """
        Yields encoded JPEG frames formatted for a multipart HTTP stream.
        Reads from the latest JPEG stored by get_frame — never triggers OCR.
        Use as the src of an <img> tag to display the live feed in a browser.
        """
        while True:
            with self._state_lock:
                mode = self._mode
            
            if mode == "captured":
                with self._state_lock:
                    jpeg_bytes = self._captured_jpeg
                time.sleep(0.1)
            else:
                with self._lock:
                    jpeg_bytes = self._lastest_jepg

            if jpeg_bytes is None:
                time.sleep(0.01)
                continue

            yield (
                b"--frame\r\n"
                b"Content-Type: image/jpeg\r\n\r\n" + jpeg_bytes + b"\r\n"
            )
    
camera = None   # global camera instance

# lifespan manager that handle startup and shutdown
@asynccontextmanager
async def lifespan(app : FastAPI):
    """
    Manages the camera lifecycle tied to the FastAPI app's startup and shutdown.
    - On startup: initializes and opens the camera.
    - On shutdown: releases the camera so the device is not left locked.
    Using a lifespan context ensures cleanup always runs, even if the server crashes.
    """

    global camera

    # startup: attempt to initialize the camera
    try:
        camera = Camera()
        camera.start()

    # if camera fail to open, return the error
    except Exception as e:
        print(f"fail to initialize camera: {e}")
        camera = None
    
    yield

    # shutdown: release the camera device so other processes can access it
    print("shutting down...")
    if camera:
        camera.release()
    print("camera resource released")

app = FastAPI(lifespan=lifespan)

# Simple Html testing for frontend
# HTML Interface with translation support
@app.get("/", response_class=HTMLResponse)
def index():
    return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <title>OCR Camera with Translation</title>
    <style>
        body {
            margin: 0;
            background: #111;
            color: #eee;
            font-family: monospace;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 20px;
            gap: 16px;
        }
        h1 { margin: 0; font-size: 1.5rem; color: #0f0; }
        h2 { margin: 0; font-size: 1.2rem; color: #0f0; }
        img#feed {
            width: 100%;
            max-width: 720px;
            border: 2px solid #333;
            border-radius: 4px;
        }
        .controls {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            justify-content: center;
        }
        button {
            padding: 10px 28px;
            font-size: 1rem;
            font-family: monospace;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        #btn-capture { background: #0f0; color: #000; }
        #btn-capture:disabled { background: #555; color: #888; cursor: not-allowed; }
        #btn-reset { background: #444; color: #eee; }
        select {
            padding: 10px 20px;
            font-size: 1rem;
            font-family: monospace;
            background: #333;
            color: #eee;
            border: 1px solid #0f0;
            border-radius: 4px;
            cursor: pointer;
        }
        .output-panel {
            width: 100%;
            max-width: 720px;
            background: #1a1a1a;
            border: 1px solid #333;
            border-radius: 4px;
            padding: 12px;
        }
        .output-label {
            color: #0f0;
            font-weight: bold;
            margin-bottom: 8px;
        }
        #detected-text {
            background: #222;
            border: 1px solid #444;
            border-radius: 4px;
            padding: 12px;
            margin-bottom: 16px;
            white-space: pre-wrap;
            word-wrap: break-word;
            min-height: 80px;
            font-size: 0.9rem;
        }
        #translated-text {
            background: #222;
            border: 1px solid #0f0;
            border-radius: 4px;
            padding: 12px;
            white-space: pre-wrap;
            word-wrap: break-word;
            min-height: 80px;
            font-size: 1rem;
            color: #0f0;
        }
        #status {
            font-size: 0.85rem;
            color: #aaa;
            min-height: 1.2em;
        }
    </style>
</head>
<body>
    <h1>OCR Camera with Translation</h1>
    <img id="feed" src="/video" alt="camera feed" />
    
    <div class="controls">
        <select id="target-lang">
            <option value="es">Spanish (es)</option>
            <option value="en">English (en)</option>
        </select>
        <button id="btn-capture" onclick="capture()">Capture & Translate</button>
        <button id="btn-reset" onclick="reset()">Reset</button>
    </div>
    
    <div id="status">Live - Ready to capture</div>
    
    <div class="output-panel">
        <div class="output-label">Detected Text (OCR):</div>
        <div id="detected-text">(no text detected yet)</div>
        
        <div class="output-label">Translation:</div>
        <div id="translated-text">(translation will appear here)</div>
    </div>

    <script>
        const feed = document.getElementById("feed");
        const statusDiv = document.getElementById("status");
        const detectedDiv = document.getElementById("detected-text");
        const translatedDiv = document.getElementById("translated-text");
        const btnCapture = document.getElementById("btn-capture");
        const targetLang = document.getElementById("target-lang");

        async function capture() {
            btnCapture.disabled = true;
            statusDiv.textContent = "Processing OCR and translation...";
            detectedDiv.textContent = "(processing...)";
            translatedDiv.textContent = "(translating...)";

            try {
                const lang = targetLang.value;
                const res = await fetch("/capture", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ target_language: lang })
                });
                
                if (!res.ok) throw new Error("Server error: " + res.status);
                
                const data = await res.json();
                
                // Update the feed to show annotated image
                feed.src = "/captured_image?" + Date.now();
                
                // Display results
                detectedDiv.textContent = data.detected_text.trim() || "(no text detected)";
                translatedDiv.textContent = data.translated_text.trim() || "(no translation available)";
                
                statusDiv.textContent = "Capture complete!";
            } catch (err) {
                statusDiv.textContent = "Error: " + err.message;
                detectedDiv.textContent = "(error occurred)";
                translatedDiv.textContent = "(error occurred)";
            } finally {
                btnCapture.disabled = false;
            }
        }

        async function reset() {
            await fetch("/reset", { method: "POST" });
            feed.src = "/video";
            statusDiv.textContent = "Live - Ready to capture";
            detectedDiv.textContent = "(no text detected yet)";
            translatedDiv.textContent = "(translation will appear here)";
        }
    </script>
</body>
</html>
"""

# video routing
@app.get("/video")
def video():
    """
    Streams live camera footage as a multipart JPEG stream.
    Open this endpoint directly in a browser or use it as the src of an <img> tag.
    Returns 503 if the camera failed to initialize on startup.
    """

    if camera is None:
        raise HTTPException(status_code=503, detail="Camera not available")
    return StreamingResponse(
        camera.generate_frame(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )

@app.post("/capture")
async def capture(request: Request):
    if camera is None:
        raise HTTPException(status_code=503, detail="Camera not available")
    try:
        body = await request.json()
        target_language = body.get("target_language", "en")
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, camera.capture, target_language)
        return JSONResponse({
            "detected_text": camera._captured_text,
            "translated_text": camera._translated_text,
            "contents": camera._contents,
        })
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/captured_image")
def captured_image():
    """
    Serves the last saved annotated snapshot from disk.
    Returns 404 if no capture has been taken yet.
    """
    if not os.path.exists(CAPTURE_PATH):
        raise HTTPException(status_code=404, detail="No captured image on disk yet")
    return FileResponse(CAPTURE_PATH, media_type="image/jpeg")

@app.get("/status")
def status():
    """Returns current mode and last detected text."""
    if camera is None:
        raise HTTPException(status_code=503, detail="Camera not available")
    with camera._state_lock:
        return JSONResponse({"mode": camera._mode, "text": camera._captured_text})
    
@app.post("/reset")
def reset():
    """Clears captured state and returns to live mode."""
    if camera is None:
        raise HTTPException(status_code=503, detail="Camera not available")
    camera.reset()
    return JSONResponse({"mode": "live"})

# Automatically run uvicorn server, for running manually see instruction in docker.md
# With this you can run 'python3 ocr.py' in the terminal
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)