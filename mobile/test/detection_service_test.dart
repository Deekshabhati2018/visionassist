import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_mobile/detection_service.dart';

void main() {
  test('parses the versioned empty-detection response', () {
    final result = DetectionResult.fromJson({
      'schema_version': 1,
      'model': 'yolov5n.onnx',
      'image_width': 640,
      'image_height': 480,
      'inference_ms': 14.2,
      'detections': <Object>[],
    });

    expect(result.schemaVersion, 1);
    expect(result.model, 'yolov5n.onnx');
    expect(result.detections, isEmpty);
  });

  test('rejects a detection box outside the source image', () {
    expect(
      () => DetectionResult.fromJson({
        'schema_version': 1,
        'model': 'yolov5n.onnx',
        'image_width': 640,
        'image_height': 480,
        'inference_ms': 14.2,
        'detections': [
          {
            'class_id': 0,
            'label': 'person',
            'confidence': 0.8,
            'bounding_box': {
              'x_min': 10,
              'y_min': 20,
              'x_max': 700,
              'y_max': 100,
            },
          },
        ],
      }),
      throwsFormatException,
    );
  });
}
