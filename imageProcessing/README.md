## Running the Server
 
```bash
python3 ocr.py
```
 
The server starts on `http://localhost:8001`.
 
---
 
## Endpoints
 
### `POST /capture`
Accepts a JPEG image, runs OCR, and returns extracted text and bounding boxes.
Also saves the annotated image (with boxes and labels drawn) to `captured_frame.jpg`.
 
### `GET /captured_image`
Serves the last annotated image saved to disk. Open in a browser after a `/capture` call to visually verify the bounding boxes.
 
---

## Testing with curl
 
**Run OCR on an image:**
```bash
curl -X POST http://localhost:8001/capture \
  -F "image=@test.jpg"
```
 
Replace `test.jpg` with the path to your image file name.

**View the annotated image:**
 
After running the curl command, open this URL in your browser:
```
http://localhost:8001/captured_image
```
 