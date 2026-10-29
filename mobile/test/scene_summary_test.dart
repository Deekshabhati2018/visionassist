import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_mobile/detection_service.dart';
import 'package:visionassist_mobile/scene_summary.dart';

void main() {
  test('empty detections return a factual no-objects summary', () {
    final result = DetectionResult.fromJson({
      'schema_version': 1,
      'model': 'yolov5n.onnx',
      'image_width': 640,
      'image_height': 480,
      'inference_ms': 8,
      'detections': <Object>[],
    });

    expect(buildSceneSummary(result), 'The model detected no objects.');
  });

  test('summary groups repeated labels without suggesting distance or danger', () {
    final result = DetectionResult.fromJson({
      'schema_version': 1,
      'model': 'yolov5n.onnx',
      'image_width': 640,
      'image_height': 480,
      'inference_ms': 18,
      'detections': [
        _detection('person', 0.9, 10),
        _detection('person', 0.8, 110),
        _detection('chair', 0.7, 210),
      ],
    });

    final summary = buildSceneSummary(result);
    expect(
      summary,
      'The model detected 3 objects: 2 detections labeled person, 1 detection labeled chair.',
    );
    expect(summary, isNot(contains('near')));
    expect(summary, isNot(contains('danger')));
  });
}

Map<String, dynamic> _detection(String label, double confidence, int x) => {
      'class_id': label == 'person' ? 0 : 56,
      'label': label,
      'confidence': confidence,
      'bounding_box': {
        'x_min': x,
        'y_min': 20,
        'x_max': x + 50,
        'y_max': 120,
      },
    };
