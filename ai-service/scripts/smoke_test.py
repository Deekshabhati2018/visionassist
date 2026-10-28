from __future__ import annotations

import argparse
from pathlib import Path

import httpx
from pydantic import ValidationError

from ai_service.schemas import DetectionResponse


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Send a real image to the running VisionAssist detector."
    )
    parser.add_argument("image", type=Path, help="Path to a JPEG, PNG, or WebP image")
    parser.add_argument(
        "--url",
        default="http://127.0.0.1:8000",
        help="AI service base URL (default: http://127.0.0.1:8000)",
    )
    args = parser.parse_args()

    if not args.image.is_file():
        parser.error(f"Image file does not exist: {args.image}")

    content_type = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(args.image.suffix.lower())
    if content_type is None:
        parser.error("Image must have a .jpg, .jpeg, .png, or .webp extension.")

    response = httpx.post(
        f"{args.url.rstrip('/')}/inference/detect",
        content=args.image.read_bytes(),
        headers={"Content-Type": content_type},
        timeout=90,
    )
    response.raise_for_status()

    try:
        result = DetectionResponse.model_validate(response.json())
    except (ValueError, ValidationError) as error:
        raise SystemExit(f"AI service response did not match its schema: {error}") from error

    print(
        f"Valid response: schema v{result.schema_version}, {result.model}, "
        f"{result.image_width}x{result.image_height}, {result.inference_ms:.1f} ms"
    )
    if not result.detections:
        print("No objects detected in this image.")
    for detection in result.detections:
        print(
            f"- {detection.label}: {detection.confidence:.1%} "
            f"box={detection.bounding_box.model_dump()}"
        )


if __name__ == "__main__":
    main()
