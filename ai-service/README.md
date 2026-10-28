# VisionAssist AI service

The first AI milestone is a real pretrained object-detection service. It
accepts one image at a time, runs YOLOv5-nano through ONNX Runtime, and
returns structured detections. It does not store camera frames.

## What is implemented

- `GET /health` — reports service and model readiness
- `POST /inference/detect` — accepts one JPEG, PNG, or WebP body
- 8 MB request limit
- confidence filtering and class-aware non-maximum suppression
- original image dimensions and pixel bounding boxes in the response
- versioned Pydantic response validation and generated OpenAPI schema
- lazy model download into the ignored `models/` directory
- API and unit tests for input validation, response schema, preprocessing, and postprocessing

## Run locally

From the repository root on Windows:

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r ai-service/requirements.txt
$env:PYTHONPATH = "ai-service"
python -m uvicorn ai_service.main:app --host 0.0.0.0 --port 8000
```

On Linux or macOS, activate `.venv/bin/activate` and set `PYTHONPATH=ai-service`
before running the Uvicorn command.

The first detection request downloads the small `yolov5n.onnx` pretrained
weight file. The model is from the Ultralytics YOLOv5 release and is used here
as a baseline detector, not as a safety-certified perception system. Review
the model's AGPL-3.0 licensing terms before redistributing or using it outside
this capstone.

## Check the service

```bash
curl http://localhost:8000/health
curl -X POST http://localhost:8000/inference/detect \
  -H "Content-Type: image/jpeg" \
  --data-binary @path/to/test-image.jpg
```

Run the Python tests (Windows PowerShell):

```powershell
$env:PYTHONPATH = "ai-service"
python -m unittest discover -s ai-service\tests -v
```

On Linux or macOS:

```bash
PYTHONPATH=ai-service python -m unittest discover -s ai-service/tests
```

Run a real image through the live model and validate the returned API schema:

```bash
PYTHONPATH=ai-service python ai-service/scripts/smoke_test.py path/to/test-image.jpg
```

Windows PowerShell:

```powershell
$env:PYTHONPATH = "ai-service"
python ai-service\scripts\smoke_test.py path\to\test-image.jpg
```

The Flutter app can send one camera frame per button press to this service.
See `mobile/README.md` for Android emulator and physical-device setup.
The service has no authentication in this milestone: keep it on a trusted
development network and do not expose it publicly.