from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from fastapi import HTTPException
from contextlib import asynccontextmanager
import cv2
import uvicorn
import pytesseract

class Camera:
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

    # This release camera resource
    def release(self):
        """
        Safely releases the camera resource.
        Always called on shutdown to avoid leaving the camera device locked.
        """
        # Check if camera is open, then release it
        if self.cap and self.cap.isOpened():
            self.cap.release()

    # capture frame
    def get_frame(self):
        """
        Captures a single frame from the camera and encodes it as a JPEG.
        Returns the raw JPEG bytes, or None if the frame could not be captured.
        """
        # ensure the camera is open before attempting to read
        if not self.cap or not self.cap.isOpened():
            return None
        # read the frame
        ret, frame = self.cap.read()

        # Text detection
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        text = pytesseract.image_to_string(gray)
        print(text)
        cv2.putText(frame, text, (30,30), cv2.FONT_HERSHEY_PLAIN, 2.5, (0,255,0), 2, cv2.LINE_AA)

        # if ret is false or no frame is read, fail to read
        if not ret or frame is None:
            return None
            
        # Compress the raw frame into JPEG format for efficient streaming
        ret, jpeg = cv2.imencode(".jpg", frame)
        if not ret:
            return None
        
        return jpeg.tobytes()
    
    # display the frame
    def generate_frame(self):
        """
        Continuously yields frames formatted as a multipart HTTP stream.
        Each frame is wrapped with the required boundary and Content-Type headers
        so browsers can render it as a live video feed using <img src="/"> tags.
        """
        while True:
            frame_bytes = self.get_frame()

            # retry if frame couldn't be capture
            if frame_bytes is None:
                continue

            # Format each frame according to the multipart/x-mixed-replace protocol
            yield (
                b"--frame\r\n"
                b"Content-Type: image/jpeg\r\n\r\n" + frame_bytes + b"\r\n"
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
# With this you can run python3 ocr.py in the terminal
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)