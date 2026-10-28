from typing import Literal

from pydantic import BaseModel, Field, model_validator


class BoundingBox(BaseModel):
    x_min: float = Field(ge=0)
    y_min: float = Field(ge=0)
    x_max: float = Field(ge=0)
    y_max: float = Field(ge=0)


class Detection(BaseModel):
    class_id: int = Field(ge=0, le=79)
    label: str = Field(min_length=1)
    confidence: float = Field(ge=0, le=1)
    bounding_box: BoundingBox


class DetectionResponse(BaseModel):
    schema_version: Literal[1] = 1
    model: str
    image_width: int = Field(gt=0)
    image_height: int = Field(gt=0)
    inference_ms: float = Field(ge=0)
    detections: list[Detection]

    @model_validator(mode="after")
    def validate_bounding_boxes(self) -> "DetectionResponse":
        for detection in self.detections:
            box = detection.bounding_box
            if box.x_min >= box.x_max or box.y_min >= box.y_max:
                raise ValueError("Bounding boxes must have positive width and height.")
            if box.x_max > self.image_width or box.y_max > self.image_height:
                raise ValueError("Bounding boxes must fit within the source image.")
        return self


class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"]
    model_loaded: bool
    model: str
    detail: str | None = None