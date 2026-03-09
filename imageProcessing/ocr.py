from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from fastapi import HTTPException
from contextlib import asynccontextmanager
import cv2
import uvicorn
import pytesseract
import threading
import time

class Camera:

    def __init__(self):
        self.cap = None
        self._lock = threading.Lock()           # protect access to the lastest jpeg
        self._lastest_jepg = None               # most recent encoded jpeg frame
        self._ocr_text = ""                     # last OCR result from _ocr_loop
        self._stop_event = threading.Event()    # siginal both threads to stop
        self._capture_thread = None             # thread 1: read frames from camera
        self._ocr_thread = None                 # thread 2: runs tesseract ocr
        self._ocr_frame = None                  # lastest frame shared with ocr thread
        self._ocr_frame_lock = threading.Lock() # protect access to _ocr-frame
        self._ocr_ready = threading.Event()     # siginals ocr thread a new frame is ready

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
        self._capture_thread = threading.Thread(target=self.get_frame, daemon=True)     # this thread will be killed on exit
        self._ocr_thread = threading.Thread(target=self._ocr_loop, daemon=True)
        self._capture_thread.start()
        self._ocr_thread.start()

    # This release camera resource
    def release(self):
        """
        Stops both background threads and releases the camera device.
        Always called on shutdown to avoid leaving the camera locked.
        """
        self._stop_event.set()      # tell both threads to exit their loops
        self._ocr_ready.set()       # Unblock OCR thread if it's waiting

        # check if both thread actually stopped
        if self._capture_thread:
            self._capture_thread.join(timeout=3)
        if self._ocr_thread:
            self._ocr_thread.join(timeout=3)

        # Check if camera is open, then release it
        if self.cap and self.cap.isOpened():
            self.cap.release()

    # capture loop (runs in background thread)
    def get_frame(self):
        """
        Capture thread. Reads frames from the camera at full speed and stores
        the latest encoded JPEG for streaming. Overlays the last known OCR text
        without waiting for Tesseract.
        Never waits for OCR — uses whatever text was last produced by _ocr_loop.
        """
        while not self._stop_event.is_set():
            if not self.cap or not self.cap.isOpened():
                time.sleep(0.01)
                continue

            ret, frame = self.cap.read()
            if not ret or frame is None:
                time.sleep(0.01)
                continue

            # share the latest frame with the OCR thread
            with self._ocr_frame_lock:
                self._ocr_frame = frame.copy()
            self._ocr_ready.set()

            # draw the last known OCR result onto the frame before encoding
            display_frame = frame.copy()
            if self._ocr_text:
                y_offset = 30
                for line in self._ocr_text.strip().splitlines():
                    if line.strip():
                        cv2.putText(display_frame, line.strip(), (10, y_offset), cv2.FONT_HERSHEY_PLAIN, 2.5, (0, 255, 0), 2, cv2.LINE_AA)
                        y_offset += 35

            ret, jpeg = cv2.imencode(".jpg", display_frame)
            if ret:
                with self._lock:
                    self._lastest_jepg = jpeg.tobytes()

    def _ocr_loop(self):
        """
        Runs Tesseract in a background thread. Waits for a frame signal from
        get_frame, processes it, then stores the result in self._ocr_text.
        Slow OCR calls never block frame capture or streaming.
        """
        while not self._stop_event.is_set():
            self._ocr_ready.wait()      # block until get_frame siginals a new frame
            self._ocr_ready.clear()

            if self._stop_event.is_set():
                break

            with self._ocr_frame_lock:
                if self._ocr_frame is None:
                    continue
                frame_to_process = self._ocr_frame.copy()

            gray = cv2.cvtColor(frame_to_process, cv2.COLOR_BGR2GRAY)
            text = pytesseract.image_to_string(gray)

            # update shared text; fall back to a placeholder if nothing was detected
            if text:
                self._ocr_text = text
            else:
                self._ocr_text = "No Text Detected"
            
            print(self._ocr_text)

    def generate_frame(self):
        """
        Yields encoded JPEG frames formatted for a multipart HTTP stream.
        Reads from the latest JPEG stored by get_frame — never triggers OCR.
        Use as the src of an <img> tag to display the live feed in a browser.
        """
        while True:
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

# video routing
@app.get("/")
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

# Automatically run uvicorn server, for running manually see instruction in docker.md
# With this you can run 'python3 ocr.py' in the terminal
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)