import logging
import os

from fastapi import FastAPI, HTTPException, Request
from starlette.concurrency import run_in_threadpool

from .detector import (
    MAX_IMAGE_BYTES,
    InvalidImageError,
    ModelNotReadyError,
    ObjectDetector,
)
from .schemas import DetectionResponse, HealthResponse

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("visionassist.ai")

app = FastAPI(
    title="VisionAssist AI service",
    description="Pretrained object detection for the VisionAssist prototype.",
    version="0.1.0",
)
detector = ObjectDetector()


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    model_loaded = detector.model_loaded
    return HealthResponse(
        status="ok" if model_loaded else "degraded",
        model_loaded=model_loaded,
        model="yolov5n.onnx",
        detail=detector.health_detail(),
    )


@app.post("/inference/detect", response_model=DetectionResponse)
async def detect(request: Request) -> DetectionResponse:
    content_type = request.headers.get("content-type", "").split(";", 1)[0].lower()
    if content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise HTTPException(
            status_code=415,
            detail="Send one JPEG, PNG, or WebP image as the request body.",
        )

    content_length = request.headers.get("content-length")
    if content_length:
        try:
            declared_length = int(content_length)
        except ValueError as error:
            raise HTTPException(status_code=400, detail="Invalid Content-Length header.") from error
        if declared_length < 0:
            raise HTTPException(status_code=400, detail="Invalid Content-Length header.")
        if declared_length > MAX_IMAGE_BYTES:
            raise HTTPException(status_code=413, detail="The image is larger than the 8 MB limit.")

    body_chunks: list[bytes] = []
    body_size = 0
    async for chunk in request.stream():
        body_size += len(chunk)
        if body_size > MAX_IMAGE_BYTES:
            raise HTTPException(status_code=413, detail="The image is larger than the 8 MB limit.")
        body_chunks.append(chunk)
    image_bytes = b"".join(body_chunks)
    try:
        return await run_in_threadpool(detector.detect, image_bytes)
    except InvalidImageError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except ModelNotReadyError as error:
        logger.exception("Detector model is not ready")
        raise HTTPException(status_code=503, detail=str(error)) from error
    except Exception as error:
        logger.exception("Unexpected detection failure")
        raise HTTPException(
            status_code=500,
            detail="The detector failed while processing the image.",
        ) from error