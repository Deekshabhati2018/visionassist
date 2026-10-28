from __future__ import annotations

import os
import threading
import time
import urllib.request
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
import onnxruntime as ort

from .labels import COCO_LABELS
from .schemas import BoundingBox, Detection, DetectionResponse


MODEL_NAME = "yolov5n.onnx"
DEFAULT_MODEL_URL = (
    "https://github.com/ultralytics/yolov5/releases/download/v7.0/yolov5n.onnx"
)
MODEL_INPUT_SIZE = 640
MAX_IMAGE_BYTES = 8 * 1024 * 1024
MAX_IMAGE_PIXELS = 20_000_000


class InvalidImageError(ValueError):
    """Raised when a request body is not a decodable image."""


class ModelNotReadyError(RuntimeError):
    """Raised when the detector cannot download or initialize its model."""


@dataclass(frozen=True)
class LetterboxResult:
    image: np.ndarray
    scale: float
    scale_x: float
    scale_y: float
    pad_x: float
    pad_y: float


class ObjectDetector:
    def __init__(
        self,
        model_dir: str | Path | None = None,
        model_url: str | None = None,
        confidence_threshold: float | None = None,
        iou_threshold: float | None = None,
    ) -> None:
        configured_dir = model_dir or os.getenv(
            "VISIONASSIST_MODEL_DIR", "ai-service/models"
        )
        self.model_dir = Path(configured_dir)
        self.model_path = self.model_dir / MODEL_NAME
        self.model_url = model_url or os.getenv(
            "VISIONASSIST_MODEL_URL", DEFAULT_MODEL_URL
        )
        self.confidence_threshold = (
            confidence_threshold
            if confidence_threshold is not None
            else float(os.getenv("VISIONASSIST_CONFIDENCE", "0.35"))
        )
        self.iou_threshold = (
            iou_threshold
            if iou_threshold is not None
            else float(os.getenv("VISIONASSIST_IOU", "0.45"))
        )
        if not 0 <= self.confidence_threshold <= 1:
            raise ValueError("VISIONASSIST_CONFIDENCE must be between 0 and 1.")
        if not 0 <= self.iou_threshold <= 1:
            raise ValueError("VISIONASSIST_IOU must be between 0 and 1.")
        self._session: ort.InferenceSession | None = None
        self._load_error: str | None = None
        self._load_lock = threading.Lock()

    @property
    def model_loaded(self) -> bool:
        return self._session is not None

    @property
    def load_error(self) -> str | None:
        return self._load_error

    def health_detail(self) -> str | None:
        if self.model_loaded:
            return None
        if self._load_error:
            return self._load_error
        return "Model weights will be downloaded on the first detection request."

    def detect(self, image_bytes: bytes) -> DetectionResponse:
        if not image_bytes:
            raise InvalidImageError("The request body is empty.")
        if len(image_bytes) > MAX_IMAGE_BYTES:
            raise InvalidImageError("The image is larger than the 8 MB limit.")

        image = cv2.imdecode(np.frombuffer(image_bytes, dtype=np.uint8), cv2.IMREAD_COLOR)
        if image is None:
            raise InvalidImageError("The request body is not a supported image.")
        if image.shape[0] * image.shape[1] > MAX_IMAGE_PIXELS:
            raise InvalidImageError("The decoded image is larger than the 20 megapixel limit.")

        session = self._ensure_session()
        model_input = session.get_inputs()[0]
        input_tensor, letterboxed = self._prepare_input(
            image,
            dtype=np.float16 if model_input.type == "tensor(float16)" else np.float32,
        )
        input_name = model_input.name

        started_at = time.perf_counter()
        raw_output = session.run(None, {input_name: input_tensor})[0]
        inference_ms = (time.perf_counter() - started_at) * 1000
        detections = decode_predictions(
            raw_output,
            image_width=image.shape[1],
            image_height=image.shape[0],
            confidence_threshold=self.confidence_threshold,
            iou_threshold=self.iou_threshold,
            letterbox_result=letterboxed,
        )

        return DetectionResponse(
            model=MODEL_NAME,
            image_width=image.shape[1],
            image_height=image.shape[0],
            inference_ms=round(inference_ms, 2),
            detections=detections,
        )

    def _ensure_session(self) -> ort.InferenceSession:
        if self._session is not None:
            return self._session

        with self._load_lock:
            if self._session is not None:
                return self._session

            try:
                self._download_model_if_needed()
                self._session = ort.InferenceSession(
                    str(self.model_path),
                    providers=["CPUExecutionProvider"],
                )
                self._load_error = None
            except Exception as error:
                self._load_error = f"Model initialization failed: {error}"
                raise ModelNotReadyError(self._load_error) from error

        return self._session

    def _download_model_if_needed(self) -> None:
        if self.model_path.exists() and self.model_path.stat().st_size > 0:
            return

        self.model_dir.mkdir(parents=True, exist_ok=True)
        temporary_path = self.model_path.with_suffix(".download")
        request = urllib.request.Request(
            self.model_url,
            headers={"User-Agent": "VisionAssist/0.1"},
        )
        with urllib.request.urlopen(request, timeout=60) as response:
            with temporary_path.open("wb") as output:
                while chunk := response.read(1024 * 1024):
                    output.write(chunk)
        temporary_path.replace(self.model_path)

    @staticmethod
    def _prepare_input(
        image: np.ndarray,
        dtype: np.dtype,
    ) -> tuple[np.ndarray, LetterboxResult]:
        letterboxed = letterbox(image, MODEL_INPUT_SIZE)
        rgb = cv2.cvtColor(letterboxed.image, cv2.COLOR_BGR2RGB)
        tensor = rgb.transpose(2, 0, 1).astype(dtype) / 255.0
        return np.expand_dims(tensor, axis=0), letterboxed


def letterbox(image: np.ndarray, size: int) -> LetterboxResult:
    height, width = image.shape[:2]
    scale = min(size / width, size / height)
    resized_width = max(1, round(width * scale))
    resized_height = max(1, round(height * scale))
    resized = cv2.resize(image, (resized_width, resized_height))
    canvas = np.full((size, size, 3), 114, dtype=np.uint8)
    left = int(round((size - resized_width) / 2 - 0.1))
    top = int(round((size - resized_height) / 2 - 0.1))
    canvas[top : top + resized_height, left : left + resized_width] = resized
    return LetterboxResult(
        image=canvas,
        scale=scale,
        scale_x=resized_width / width,
        scale_y=resized_height / height,
        pad_x=float(left),
        pad_y=float(top),
    )


def decode_predictions(
    raw_output: np.ndarray,
    image_width: int,
    image_height: int,
    confidence_threshold: float,
    iou_threshold: float,
    letterbox_result: LetterboxResult | None = None,
) -> list[Detection]:
    predictions = np.asarray(raw_output)
    if predictions.ndim == 3:
        predictions = predictions[0]
    expected_columns = 5 + len(COCO_LABELS)
    if predictions.ndim != 2 or predictions.shape[1] != expected_columns:
        raise ModelNotReadyError("The detector returned an unexpected output shape.")

    finite_rows = np.isfinite(predictions).all(axis=1)
    objectness = predictions[:, 4]
    class_probabilities = predictions[:, 5:]
    class_ids = np.argmax(class_probabilities, axis=1)
    confidences = objectness * class_probabilities[
        np.arange(len(class_probabilities)), class_ids
    ]
    candidate_indexes = np.flatnonzero(
        finite_rows & (confidences >= confidence_threshold)
    )
    if len(candidate_indexes) == 0:
        return []

    if letterbox_result is None:
        scale = min(
            MODEL_INPUT_SIZE / image_width,
            MODEL_INPUT_SIZE / image_height,
        )
        resized_width = max(1, round(image_width * scale))
        resized_height = max(1, round(image_height * scale))
        pad_x = float(round((MODEL_INPUT_SIZE - resized_width) / 2 - 0.1))
        pad_y = float(round((MODEL_INPUT_SIZE - resized_height) / 2 - 0.1))
        scale_x = resized_width / image_width
        scale_y = resized_height / image_height
    else:
        pad_x = letterbox_result.pad_x
        pad_y = letterbox_result.pad_y
        scale_x = letterbox_result.scale_x
        scale_y = letterbox_result.scale_y

    candidates: list[tuple[int, float, BoundingBox]] = []
    for index in candidate_indexes:
        center_x, center_y, width, height = predictions[index, :4]
        x_min = np.clip((center_x - width / 2 - pad_x) / scale_x, 0, image_width)
        y_min = np.clip((center_y - height / 2 - pad_y) / scale_y, 0, image_height)
        x_max = np.clip((center_x + width / 2 - pad_x) / scale_x, 0, image_width)
        y_max = np.clip((center_y + height / 2 - pad_y) / scale_y, 0, image_height)
        if x_max <= x_min or y_max <= y_min:
            continue
        candidates.append(
            (
                int(class_ids[index]),
                float(confidences[index]),
                BoundingBox(
                    x_min=round(float(x_min), 2),
                    y_min=round(float(y_min), 2),
                    x_max=round(float(x_max), 2),
                    y_max=round(float(y_max), 2),
                ),
            )
        )

    selected: list[Detection] = []
    for class_id in sorted({candidate[0] for candidate in candidates}):
        class_candidates = sorted(
            (candidate for candidate in candidates if candidate[0] == class_id),
            key=lambda candidate: candidate[1],
            reverse=True,
        )
        kept: list[tuple[int, float, BoundingBox]] = []
        for candidate in class_candidates:
            if all(
                _intersection_over_union(candidate[2], existing[2]) < iou_threshold
                for existing in kept
            ):
                kept.append(candidate)
        selected.extend(
            Detection(
                class_id=class_id,
                label=COCO_LABELS[class_id],
                confidence=round(confidence, 4),
                bounding_box=box,
            )
            for _, confidence, box in kept
        )

    return sorted(selected, key=lambda detection: detection.confidence, reverse=True)


def _intersection_over_union(first: BoundingBox, second: BoundingBox) -> float:
    intersection_x_min = max(first.x_min, second.x_min)
    intersection_y_min = max(first.y_min, second.y_min)
    intersection_x_max = min(first.x_max, second.x_max)
    intersection_y_max = min(first.y_max, second.y_max)
    intersection_width = max(0.0, intersection_x_max - intersection_x_min)
    intersection_height = max(0.0, intersection_y_max - intersection_y_min)
    intersection_area = intersection_width * intersection_height

    first_area = max(0.0, first.x_max - first.x_min) * max(
        0.0, first.y_max - first.y_min
    )
    second_area = max(0.0, second.x_max - second.x_min) * max(
        0.0, second.y_max - second.y_min
    )
    union_area = first_area + second_area - intersection_area
    return intersection_area / union_area if union_area else 0.0