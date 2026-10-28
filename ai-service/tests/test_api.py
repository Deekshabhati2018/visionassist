import unittest

from fastapi.testclient import TestClient
from pydantic import ValidationError

from ai_service.main import app
from ai_service.schemas import DetectionResponse


class DetectionApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_health_has_a_stable_response_shape(self) -> None:
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            set(response.json()),
            {"status", "model_loaded", "model", "detail"},
        )
        self.assertIn(response.json()["status"], {"ok", "degraded"})

    def test_detection_rejects_unsupported_media_type(self) -> None:
        response = self.client.post(
            "/inference/detect",
            content=b"not an image",
            headers={"content-type": "text/plain"},
        )

        self.assertEqual(response.status_code, 415)
        self.assertIn("JPEG, PNG, or WebP", response.json()["detail"])

    def test_detection_rejects_invalid_image_bytes(self) -> None:
        response = self.client.post(
            "/inference/detect",
            content=b"not an image",
            headers={"content-type": "image/jpeg"},
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("not a supported image", response.json()["detail"])

    def test_detection_rejects_images_over_the_upload_limit(self) -> None:
        response = self.client.post(
            "/inference/detect",
            content=b"x" * (8 * 1024 * 1024 + 1),
            headers={"content-type": "image/jpeg"},
        )

        self.assertEqual(response.status_code, 413)

    def test_response_schema_accepts_empty_detection_list(self) -> None:
        response = DetectionResponse.model_validate(
            {
                "schema_version": 1,
                "model": "yolov5n.onnx",
                "image_width": 640,
                "image_height": 480,
                "inference_ms": 12.5,
                "detections": [],
            }
        )

        self.assertEqual(response.schema_version, 1)
        self.assertEqual(response.detections, [])

    def test_response_schema_rejects_out_of_bounds_box(self) -> None:
        with self.assertRaises(ValidationError):
            DetectionResponse.model_validate(
                {
                    "schema_version": 1,
                    "model": "yolov5n.onnx",
                    "image_width": 640,
                    "image_height": 480,
                    "inference_ms": 12.5,
                    "detections": [
                        {
                            "class_id": 0,
                            "label": "person",
                            "confidence": 0.8,
                            "bounding_box": {
                                "x_min": 10,
                                "y_min": 20,
                                "x_max": 700,
                                "y_max": 100,
                            },
                        }
                    ],
                }
            )

    def test_openapi_documents_versioned_detection_response(self) -> None:
        schema = self.client.get("/openapi.json").json()
        response_schema = schema["components"]["schemas"]["DetectionResponse"]

        self.assertIn("schema_version", response_schema["properties"])
        self.assertIn("image_width", response_schema["properties"])
        self.assertIn("image_height", response_schema["properties"])
        self.assertIn("inference_ms", response_schema["properties"])
        self.assertIn("detections", response_schema["properties"])


if __name__ == "__main__":
    unittest.main()
