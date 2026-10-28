import unittest

import numpy as np

from ai_service.detector import decode_predictions, letterbox


class DetectorMathTests(unittest.TestCase):
    def test_letterbox_preserves_aspect_ratio(self) -> None:
        image = np.zeros((100, 200, 3), dtype=np.uint8)

        result = letterbox(image, 640)

        self.assertEqual(result.image.shape, (640, 640, 3))
        self.assertAlmostEqual(result.scale, 3.2)
        self.assertAlmostEqual(result.pad_y, 160.0)
        self.assertAlmostEqual(result.pad_x, 0.0)

    def test_decode_predictions_maps_boxes_back_to_original_image(self) -> None:
        raw_output = np.zeros((1, 2, 85), dtype=np.float32)
        raw_output[0, 0, :5] = [320, 320, 160, 160, 0.9]
        raw_output[0, 0, 5 + 0] = 0.9
        raw_output[0, 1, :5] = [320, 320, 160, 160, 0.8]
        raw_output[0, 1, 5 + 0] = 0.8

        detections = decode_predictions(
            raw_output,
            image_width=640,
            image_height=640,
            confidence_threshold=0.5,
            iou_threshold=0.45,
        )

        self.assertEqual(len(detections), 1)
        self.assertEqual(detections[0].label, "person")
        self.assertAlmostEqual(detections[0].confidence, 0.81, places=3)
        self.assertEqual(detections[0].bounding_box.x_min, 240.0)
        self.assertEqual(detections[0].bounding_box.y_min, 240.0)

    def test_low_confidence_predictions_are_ignored(self) -> None:
        raw_output = np.zeros((1, 1, 85), dtype=np.float32)
        raw_output[0, 0, :5] = [320, 320, 160, 160, 0.2]
        raw_output[0, 0, 5] = 0.2

        detections = decode_predictions(
            raw_output,
            image_width=640,
            image_height=640,
            confidence_threshold=0.35,
            iou_threshold=0.45,
        )

        self.assertEqual(detections, [])