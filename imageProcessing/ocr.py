from fastapi import FastAPI
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
    
    def capture(self):
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
        config = "--oem 3 --psm 11"  # OEM 3 = default, PSM 11 = sparse text with OSD (good for natural scenes)

        # convert to grayscale for better OCR performance, and upscale if too small
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        orig_h, orig_w = gray.shape
        if orig_w < 1200:
            scale = 1200 / orig_w
            gray_upscaled = cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
        else:
            scale = 1.0
            gray_upscaled = gray
        
        # run OCR on the upscaled grayscale image, get both text and detailed data for bounding boxes
        data = pytesseract.image_to_data(gray_upscaled, output_type=pytesseract.Output.DICT, config=config)
        text = pytesseract.image_to_string(gray_upscaled, config=config)

        # Print to terminal
        print("\n" + "=" * 50)
        print("[OCR] Detected text:")
        print("-" * 50)
        print(text.strip() if text.strip() else "(no text detected)")
        print("=" * 50 + "\n")

        # Draw bounding boxes around each detected word
        n_boxes = len(data["text"])
        for i in range(n_boxes):
            word = data["text"][i].strip()
            conf = int(data["conf"][i])

            # Skip empty words and low-confidence detections (conf == -1 means block/line level)
            if not word or conf < 40:
                continue

            # Scale bounding box coordinates back down to match the original frame
            x = int(data["left"][i]  / scale)
            y = int(data["top"][i]   / scale)
            w = int(data["width"][i] / scale)
            h = int(data["height"][i]/ scale)

            # Draw green bounding box
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

            # Draw label background for readability
            label = f"{word} ({conf}%)"
            (label_w, label_h), baseline = cv2.getTextSize(
                label, cv2.FONT_HERSHEY_PLAIN, 1.2, 1
            )
            label_y = y - 4 if y - label_h - 4 >= 0 else y + h + label_h + 4
            cv2.rectangle(
                frame,
                (x, label_y - label_h - baseline),
                (x + label_w, label_y + baseline),
                (0, 255, 0),
                cv2.FILLED,
            )
            cv2.putText(
                frame, label, (x, label_y),
                cv2.FONT_HERSHEY_PLAIN, 1.2,
                (0, 0, 0), 1, cv2.LINE_AA,
            )
        
        # Save raw snapshot after OCR
        cv2.imwrite(CAPTURE_PATH, frame)
        print(f"[snapshot] raw frame saved → {os.path.abspath(CAPTURE_PATH)}")

        # re-encode to jpeg, store in self._captured_jpeg
        ret, captured_jpeg = cv2.imencode(".jpg", frame)
        
        # store text in self._captured_text
        with self._state_lock:
            self._captured_jpeg = captured_jpeg.tobytes() if ret else jpeg_bytes
            self._captured_text = text

            # set self._mode = "captured"
            self._mode = "captured"

    # reset captured state and return to live mode
    def reset(self):
        self._mode = "live"
        self._captured_jpeg = None
        self._captured_text = ""

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
@app.get("/", response_class=HTMLResponse)

def index():
    """Serves the frontend page with live stream and capture button."""
    return """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>OCR Camera</title>
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
    h1 { margin: 0; font-size: 1.2rem; color: #0f0; }
    img#feed {
      width: 100%;
      max-width: 720px;
      border: 2px solid #333;
      border-radius: 4px;
    }
    .controls { display: flex; gap: 12px; }
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
    #status { font-size: 0.85rem; color: #aaa; min-height: 1.2em; }
    #text-output {
      width: 100%;
      max-width: 720px;
      background: #1a1a1a;
      border: 1px solid #333;
      border-radius: 4px;
      padding: 12px;
      white-space: pre-wrap;
      min-height: 60px;
      font-size: 0.9rem;
      color: #0f0;
    }
  </style>
</head>
<body>
  <h1>OCR Camera</h1>
  <img id="feed" src="/video" alt="camera feed" />
  <div class="controls">
    <button id="btn-capture" onclick="capture()">Capture</button>
    <button id="btn-reset" onclick="reset()">Reset</button>
  </div>
  <div id="status">Live</div>
  <div id="text-output">(detected text will appear here)</div>
 
  <script>
    const feed        = document.getElementById("feed");
    const status      = document.getElementById("status");
    const textOutput  = document.getElementById("text-output");
    const btnCapture  = document.getElementById("btn-capture");
 
    async function capture() {
      btnCapture.disabled = true;
      status.textContent  = "Processing...";
      textOutput.textContent = "";
 
      try {
        const res = await fetch("/capture", { method: "POST" });
        if (!res.ok) throw new Error("Server error: " + res.status);
        const data = await res.json();
 
        // Swap stream to the annotated static image (cache bust with timestamp)
        feed.src = "/captured_image?" + Date.now();
        status.textContent = "Captured";
        textOutput.textContent = data.text.trim() || "(no text detected)";
      } catch (err) {
        status.textContent = "Error: " + err.message;
      } finally {
        btnCapture.disabled = false;
      }
    }
 
    async function reset() {
      await fetch("/reset", { method: "POST" });
      feed.src = "/video";
      status.textContent = "Live";
      textOutput.textContent = "(detected text will appear here)";
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
async def capture():
    """
    Triggers a snapshot:
    - Saves the frame to disk.
    - Runs OCR.
    - Overlays detected text.
    - Returns the detected text as JSON.
    """
    if camera is None:
        raise HTTPException(status_code=503, detail="Camera not available")
    try:
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, camera.capture)
        return JSONResponse({"text": camera._captured_text})
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