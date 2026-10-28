import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

const defaultAiServiceUrl = String.fromEnvironment(
  'VISIONASSIST_AI_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class DetectionServiceException implements Exception {
  const DetectionServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DetectionRequestCancelled implements Exception {
  const DetectionRequestCancelled();
}

class AiServiceHealth {
  const AiServiceHealth({
    required this.modelLoaded,
    required this.model,
    this.detail,
  });

  final bool modelLoaded;
  final String model;
  final String? detail;
}

abstract interface class DetectionClient {
  Future<DetectionResult> analyze(
    Uint8List jpegBytes, {
    Future<void>? abortTrigger,
  });

  Future<AiServiceHealth> checkHealth({Future<void>? abortTrigger});

  void close();
}

class DetectionService implements DetectionClient {
  DetectionService({
    this.baseUrl = defaultAiServiceUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 90),
    this.healthTimeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Duration requestTimeout;
  final Duration healthTimeout;
  bool _closed = false;

  @override
  Future<DetectionResult> analyze(Uint8List jpegBytes) async {
    _ensureOpen();
    if (jpegBytes.isEmpty) {
      throw const DetectionServiceException(
        'The camera returned an empty frame. Try again.',
      );
    }
    if (jpegBytes.length > 8 * 1024 * 1024) {
      throw const DetectionServiceException(
        'The captured frame exceeds the AI service 8 MB limit.',
      );
    }

    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

    try {
      final endpoint = Uri.parse('$normalizedBaseUrl/inference/detect');
      final request = http.AbortableRequest(
        'POST',
        endpoint,
        abortTrigger: abortTrigger,
      )
        ..headers['Content-Type'] = 'image/jpeg'
        ..bodyBytes = jpegBytes;
      final response = await _send(request, timeout: requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = _readErrorDetail(response.body);
        throw DetectionServiceException(
          detail ??
              'The AI service returned an error (${response.statusCode}). Check that it is running and try again.',
        );
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('The response must be a JSON object.');
        }
        return DetectionResult.fromJson(decoded);
      } on FormatException catch (error) {
        throw DetectionServiceException(
          'The AI service returned an invalid detection response: ${error.message}',
        );
      }
    } on DetectionServiceException {
      rethrow;
    } on http.RequestAbortedException {
      throw const DetectionRequestCancelled();
    } on TimeoutException {
      throw const DetectionServiceException(
        'The AI request timed out. Check the service connection and try again.',
      );
    } on http.ClientException {
      throw DetectionServiceException(
        'Could not reach the AI service at $baseUrl. Confirm the service is running and the phone can reach that address.',
      );
    } on FormatException {
      throw DetectionServiceException(
        'The AI service address is invalid. Check VISIONASSIST_AI_BASE_URL.',
      );
    } on Exception {
      throw DetectionServiceException(
        'The AI request did not finish. Check the network connection and try again.',
      );
    }
  }

  @override
  Future<AiServiceHealth> checkHealth({Future<void>? abortTrigger}) async {
    _ensureOpen();
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    try {
      final request = http.AbortableRequest(
        'GET',
        Uri.parse('$normalizedBaseUrl/health'),
        abortTrigger: abortTrigger,
      );
      final response = await _send(request, timeout: healthTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = _readErrorDetail(response.body);
        throw DetectionServiceException(
          detail ?? 'The AI service health check failed (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('The health response must be a JSON object.');
      }
      final status = decoded['status'];
      final modelLoaded = decoded['model_loaded'];
      final model = decoded['model'];
      final detail = decoded['detail'];
      if ((status != 'ok' && status != 'degraded') ||
          modelLoaded is! bool ||
          model is! String ||
          model.isEmpty ||
          (detail != null && detail is! String)) {
        throw const FormatException('The health response has an invalid shape.');
      }
      return AiServiceHealth(
        modelLoaded: modelLoaded,
        model: model,
        detail: detail as String?,
      );
    } on DetectionServiceException {
      rethrow;
    } on http.RequestAbortedException {
      throw const DetectionRequestCancelled();
    } on TimeoutException {
      throw const DetectionServiceException(
        'The AI service did not respond to its health check. Confirm it is running and reachable.',
      );
    } on http.ClientException {
      throw DetectionServiceException(
        'Could not reach the AI service at $baseUrl. Confirm the service is running and the phone can reach that address.',
      );
    } on FormatException catch (error) {
      throw DetectionServiceException(
        'The AI service returned an invalid health response: ${error.message}',
      );
    } on Exception {
      throw DetectionServiceException(
        'The AI service health check failed. Check the network connection and try again.',
      );
    }
  }

  Future<http.Response> _send(
    http.AbortableRequest request, {
    required Duration timeout,
  }) {
    return _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
  }

  void _ensureOpen() {
    if (_closed) {
      throw const DetectionServiceException(
        'The AI service client has been closed.',
      );
    }
  }

  String? _readErrorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _client.close();
  }
}

class DetectionResult {
  const DetectionResult({
    required this.schemaVersion,
    required this.model,
    required this.imageWidth,
    required this.imageHeight,
    required this.inferenceMs,
    required this.detections,
  });

  final int schemaVersion;
  final String model;
  final int imageWidth;
  final int imageHeight;
  final double inferenceMs;
  final List<ObjectDetection> detections;

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _requiredInt(json, 'schema_version');
    if (schemaVersion != 1) {
      throw const FormatException('Unsupported schema_version.');
    }

    final model = json['model'];
    final imageWidth = _requiredInt(json, 'image_width');
    final imageHeight = _requiredInt(json, 'image_height');
    final inferenceMs = _requiredNumber(json, 'inference_ms');
    final rawDetections = json['detections'];
    if (model is! String || model.isEmpty) {
      throw const FormatException('model must be a non-empty string.');
    }
    if (imageWidth <= 0 || imageHeight <= 0) {
      throw const FormatException('Image dimensions must be positive.');
    }
    if (inferenceMs < 0) {
      throw const FormatException('inference_ms cannot be negative.');
    }
    if (rawDetections is! List) {
      throw const FormatException('detections must be a list.');
    }

    return DetectionResult(
      schemaVersion: schemaVersion,
      model: model,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      inferenceMs: inferenceMs,
      detections: rawDetections
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Each detection must be an object.');
            }
            return ObjectDetection.fromJson(
              item,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
            );
          })
          .toList(growable: false),
    );
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('$key must be an integer.');
    }
    return value;
  }

  static double _requiredNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num || !value.isFinite) {
      throw FormatException('$key must be a finite number.');
    }
    return value.toDouble();
  }
}

class ObjectDetection {
  const ObjectDetection({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  final int classId;
  final String label;
  final double confidence;
  final DetectionBoundingBox boundingBox;

  factory ObjectDetection.fromJson(
    Map<String, dynamic> json, {
    required int imageWidth,
    required int imageHeight,
  }) {
    final classId = DetectionResult._requiredInt(json, 'class_id');
    final label = json['label'];
    final confidence = DetectionResult._requiredNumber(json, 'confidence');
    final rawBox = json['bounding_box'];
    if (classId < 0 || classId > 79) {
      throw const FormatException('class_id must be a COCO class index.');
    }
    if (label is! String || label.isEmpty) {
      throw const FormatException('label must be a non-empty string.');
    }
    if (confidence < 0 || confidence > 1) {
      throw const FormatException('confidence must be between 0 and 1.');
    }
    if (rawBox is! Map<String, dynamic>) {
      throw const FormatException('bounding_box must be an object.');
    }

    final box = DetectionBoundingBox.fromJson(rawBox);
    if (box.xMin < 0 ||
        box.yMin < 0 ||
        box.xMin >= box.xMax ||
        box.yMin >= box.yMax ||
        box.xMax > imageWidth ||
        box.yMax > imageHeight) {
      throw const FormatException(
        'bounding_box must be ordered and fit within the source image.',
      );
    }

    return ObjectDetection(
      classId: classId,
      label: label,
      confidence: confidence,
      boundingBox: box,
    );
  }
}

class DetectionBoundingBox {
  const DetectionBoundingBox({
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });

  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  factory DetectionBoundingBox.fromJson(Map<String, dynamic> json) {
    return DetectionBoundingBox(
      xMin: DetectionResult._requiredNumber(json, 'x_min'),
      yMin: DetectionResult._requiredNumber(json, 'y_min'),
      xMax: DetectionResult._requiredNumber(json, 'x_max'),
      yMax: DetectionResult._requiredNumber(json, 'y_max'),
    );
  }
}
