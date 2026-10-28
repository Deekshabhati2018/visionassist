import unittest

import cv2
import numpy as np

from ai_service.detector import (
    MODEL_INPUT_SIZE,
    ModelNotReadyError,
    ObjectDetector,
    decode_predictions,
    letterbox,
)


class DetectorMathTests(unittest.TestCase):
    def test_letterbox_preserves_aspect_ratio(self) -> None:
        image = np.zeros((100, 200, 3), dtype=np.uint8)

        result = letterbox(image, 640)

        self.assertEqual(result.image.shape, (640, 640, 3))
        self.assertAlmostEqual(result.scale, 3.2)
        self.assertAlmostEqual(result.pad_y, 160.0)
        self.assertAlmostEqual(result.pad_x, 0.0)
        self.assertAlmostEqual(result.scale_x, 3.2)
        self.assertAlmostEqual(result.scale_y, 3.2)

    def test_preprocessing_converts_bgr_to_normalized_nchw_rgb(self) -> None:
        image = np.full((100, 200, 3), [10, 20, 30], dtype=np.uint8)

        tensor, transform = ObjectDetector._prepare_input(image, np.dtype(np.float32))

        self.assertEqual(tensor.shape, (1, 3, MODEL_INPUT_SIZE, MODEL_INPUT_SIZE))
        self.assertEqual(tensor.dtype, np.float32)
        np.testing.assert_allclose(
            tensor[0, :, 320, 320],
            np.array([30, 20, 10], dtype=np.float32) / 255,
        )
        self.assertEqual(transform.image.shape, (640, 640, 3))

    def test_letterbox_uses_exact_rounded_resize_for_each_axis(self) -> None:
        image = np.zeros((100, 201, 3), dtype=np.uint8)

        result = letterbox(image, MODEL_INPUT_SIZE)

        self.assertAlmostEqual(result.scale_x, 640 / 201)
        self.assertAlmostEqual(result.scale_y, 3.18)
        self.assertEqual(result.pad_y, 161.0)

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

    def test_decoder_uses_preprocessing_transform_for_non_square_images(self) -> None:
        image = np.zeros((100, 201, 3), dtype=np.uint8)
        transform = letterbox(image, MODEL_INPUT_SIZE)
        raw_output = np.zeros((1, 1, 85), dtype=np.float32)
        raw_output[0, 0, :5] = [320, 320, 640, 318, 1]
        raw_output[0, 0, 5] = 0.9

        detections = decode_predictions(
            raw_output,
            image_width=201,
            image_height=100,
            confidence_threshold=0.5,
            iou_threshold=0.45,
            letterbox_result=transform,
        )

        self.assertEqual(len(detections), 1)
        self.assertEqual(detections[0].bounding_box.x_min, 0)
        self.assertEqual(detections[0].bounding_box.x_max, 201)
        self.assertEqual(detections[0].bounding_box.y_min, 0)
        self.assertEqual(detections[0].bounding_box.y_max, 100)

    def test_decoder_ignores_non_finite_prediction_rows(self) -> None:
        raw_output = np.zeros((1, 2, 85), dtype=np.float32)
        raw_output[0, 0, :5] = [np.nan, 320, 160, 160, 0.9]
        raw_output[0, 0, 5] = 0.9
        raw_output[0, 1, :5] = [320, 320, 160, 160, 0.9]
        raw_output[0, 1, 5] = 0.9

        detections = decode_predictions(
            raw_output,
            image_width=640,
            image_height=640,
            confidence_threshold=0.5,
            iou_threshold=0.45,
        )

        self.assertEqual(len(detections), 1)

    def test_decoder_rejects_unexpected_class_output_width(self) -> None:
        with self.assertRaises(ModelNotReadyError):
            decode_predictions(
                np.zeros((1, 1, 86), dtype=np.float32),
                image_width=640,
                image_height=480,
                confidence_threshold=0.35,
                iou_threshold=0.45,
            )

    def test_detector_rejects_invalid_threshold_configuration(self) -> None:
        with self.assertRaises(ValueError):
            ObjectDetector(confidence_threshold=1.1)
        with self.assertRaises(ValueError):
            ObjectDetector(iou_threshold=-0.1)