import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:visionassist_mobile/detection_service.dart';

void main() {
  Map<String, dynamic> validDetectionResponse() => {
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
              'x_max': 300,
              'y_max': 400,
            },
          },
        ],
      };

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

  test('rejects a detection with confidence outside the valid range', () {
    final payload = validDetectionResponse();
    payload['detections'][0]['confidence'] = 1.01;

    expect(
      () => DetectionResult.fromJson(payload),
      throwsFormatException,
    );
  });

  test('analyzes a frame and validates the real API response contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/inference/detect');
      expect(request.headers['content-type'], 'image/jpeg');
      expect(request.bodyBytes, [1, 2, 3]);
      return http.Response(
        jsonEncode(validDetectionResponse()),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = DetectionService(
      baseUrl: 'http://visionassist.test',
      client: client,
    );
    addTearDown(service.close);

    final result = await service.analyze(Uint8List.fromList([1, 2, 3]));

    expect(result.detections.single.label, 'person');
    expect(result.detections.single.confidence, 0.8);
  });

  test('reports server errors using the API detail message', () async {
    final service = DetectionService(
      baseUrl: 'http://visionassist.test',
      client: MockClient(
        (_) async => http.Response(
          '{"detail":"Model initialization failed."}',
          503,
        ),
      ),
    );
    addTearDown(service.close);

    await expectLater(
      service.analyze(Uint8List.fromList([1])),
      throwsA(
        isA<DetectionServiceException>().having(
          (error) => error.message,
          'message',
          contains('Model initialization failed'),
        ),
      ),
    );
  });

  test('aborts an inference request when the configured timeout expires',
      () async {
    final pendingResponse = Completer<http.Response>();
    final service = DetectionService(
      baseUrl: 'http://visionassist.test',
      requestTimeout: const Duration(milliseconds: 1),
      client: MockClient((_) => pendingResponse.future),
    );
    addTearDown(service.close);

    await expectLater(
      service.analyze(Uint8List.fromList([1])),
      throwsA(
        isA<DetectionServiceException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
    pendingResponse.complete(http.Response('{}', 200));
  });

  test('rejects malformed success responses instead of accepting partial data',
      () async {
    final service = DetectionService(
      baseUrl: 'http://visionassist.test',
      client: MockClient((_) async => http.Response('{"detections":[]}', 200)),
    );
    addTearDown(service.close);

    await expectLater(
      service.analyze(Uint8List.fromList([1])),
      throwsA(isA<DetectionServiceException>()),
    );
  });

  test('health check distinguishes service reachability from model loading',
      () async {
    final service = DetectionService(
      baseUrl: 'http://visionassist.test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'degraded',
            'model_loaded': false,
            'model': 'yolov5n.onnx',
            'detail': 'Model weights will be downloaded on the first request.',
          }),
          200,
        ),
      ),
    );
    addTearDown(service.close);

    final health = await service.checkHealth();

    expect(health.modelLoaded, isFalse);
    expect(health.model, 'yolov5n.onnx');
  });

  test('rejects empty and oversized frames before making a request', () async {
    var requestCount = 0;
    final service = DetectionService(
      baseUrl: 'http://visionassist.test',
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.close);

    await expectLater(
      service.analyze(Uint8List(0)),
      throwsA(isA<DetectionServiceException>()),
    );
    await expectLater(
      service.analyze(Uint8List(8 * 1024 * 1024 + 1)),
      throwsA(isA<DetectionServiceException>()),
    );
    expect(requestCount, 0);
  });
}
