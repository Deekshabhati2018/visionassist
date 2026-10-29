import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_mobile/camera_service.dart';
import 'package:visionassist_mobile/detection_service.dart';
import 'package:visionassist_mobile/main.dart';
import 'package:visionassist_mobile/speech_service.dart';

void main() {
  testWidgets('onboarding keeps the safety notice and camera session flow', (
    WidgetTester tester,
  ) async {
    final camera = FakeCameraService();
    final detector = FakeDetectionClient();
    await tester.pumpWidget(
      VisionAssistApp(
        cameraService: camera,
        detectionService: detector,
        speechService: FakeSpeechService(),
      ),
    );

    expect(find.text('VisionAssist'), findsOneWidget);
    expect(find.text('Safety notice'), findsOneWidget);
    await _tapText(tester, 'Continue');
    await tester.pumpAndSettle();
    expect(find.text('Assistance is off'), findsOneWidget);

    await _tapText(tester, 'Start Assistance');
    await tester.pumpAndSettle();
    expect(find.text('Assistance is active'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('AI service'), findsOneWidget);
    expect(find.text('Analysis'), findsOneWidget);
    await _expectVisible(tester, 'Analyze Current Frame');
    expect(find.text('Analyze Current Frame'), findsOneWidget);
  });

  testWidgets('camera denial is explained without activating assistance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      VisionAssistApp(
        cameraService: DeniedCameraService(),
        detectionService: FakeDetectionClient(),
        speechService: FakeSpeechService(),
      ),
    );

    await _tapText(tester, 'Continue');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Start Assistance');
    await tester.pumpAndSettle();

    expect(find.text('Camera access needs attention'), findsOneWidget);
    expect(
      find.text('Camera permission was denied in this test.'),
      findsOneWidget,
    );
    await _expectVisible(tester, 'Start Assistance');
    expect(find.text('Start Assistance'), findsOneWidget);
  });

  testWidgets('analysis shows loading and a clear service error', (
    WidgetTester tester,
  ) async {
    final pendingAnalysis = Completer<DetectionResult>();
    final camera = FakeCameraService();
    final detector = FakeDetectionClient(
      analyzeHandler: (_, {abortTrigger}) => pendingAnalysis.future,
    );
    await _openActiveSession(tester, camera: camera, detector: detector);

    await _tapText(tester, 'Analyze Current Frame');
    await tester.pump();
    await tester.pump();
    expect(find.text('Analyzing frame…'), findsOneWidget);

    pendingAnalysis.completeError(
      const DetectionServiceException('The AI service is offline.'),
    );
    await tester.pumpAndSettle();

    await _expectVisible(tester, 'The AI service is offline.');
    expect(find.text('The AI service is offline.'), findsOneWidget);
    expect(find.text('Analyze Current Frame'), findsOneWidget);
  });

  testWidgets('speaks a concise scene summary with mute and replay controls', (
    WidgetTester tester,
  ) async {
    final speech = FakeSpeechService();
    final detector = FakeDetectionClient(result: sampleResult(people: 2));
    await _openActiveSession(
      tester,
      camera: FakeCameraService(),
      detector: detector,
      speech: speech,
    );

    await _tapText(tester, 'Analyze Current Frame');
    await tester.pumpAndSettle();

    await _expectVisible(
      tester,
      'The model detected 2 objects: 2 detections labeled person.',
    );
    expect(
      find.text('The model detected 2 objects: 2 detections labeled person.'),
      findsOneWidget,
    );
    expect(speech.utterances, [
      'The model detected 2 objects: 2 detections labeled person.',
    ]);

    await _tapText(tester, 'Analyze Current Frame');
    await tester.pumpAndSettle();
    expect(speech.utterances, hasLength(1));

    await _tapText(tester, 'Mute');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Analyze Current Frame');
    await tester.pumpAndSettle();
    expect(speech.utterances, hasLength(1));

    await _tapText(tester, 'Unmute');
    await tester.pumpAndSettle();
    final sliders = find.byType(Slider);
    await tester.scrollUntilVisible(
      sliders.first,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(sliders.first);
    await tester.drag(sliders.first, const Offset(60, 0));
    await tester.pumpAndSettle();
    await tester.drag(sliders.last, const Offset(-60, 0));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Speak Again');
    await tester.pumpAndSettle();
    expect(speech.utterances, hasLength(2));
    expect(speech.rates.last, isNot(0.45));
    expect(speech.volumes.last, lessThan(1));
  });

  testWidgets('continuous sampling never overlaps and supports pause, resume, stop', (
    WidgetTester tester,
  ) async {
    final firstAnalysis = Completer<DetectionResult>();
    final camera = FakeCameraService();
    var analyzeCalls = 0;
    final samplingDetector = FakeDetectionClient(
      analyzeHandler: (_, {abortTrigger}) {
        analyzeCalls++;
        if (analyzeCalls == 1) {
          return firstAnalysis.future;
        }
        return Future.value(sampleResult());
      },
    );
    await _openActiveSession(
      tester,
      camera: camera,
      detector: samplingDetector,
    );

    await _tapText(tester, 'Start Continuous Assistance');
    await tester.pump();
    await tester.pump();
    expect(camera.session.captureCount, 1);
    expect(analyzeCalls, 1);

    await tester.pump(const Duration(seconds: 12));
    expect(camera.session.captureCount, 1);
    expect(analyzeCalls, 1);

    await _tapText(tester, 'Pause');
    await tester.pumpAndSettle();
    firstAnalysis.complete(sampleResult());
    await tester.pumpAndSettle();
    await _expectVisible(tester, 'Paused');
    expect(find.text('Paused'), findsOneWidget);

    await _tapText(tester, 'Resume');
    await tester.pumpAndSettle();
    expect(analyzeCalls, 2);
    expect(camera.session.captureCount, 2);

    await _tapText(tester, 'Stop Continuous');
    await tester.pumpAndSettle();
    final stoppedCaptureCount = camera.session.captureCount;
    await tester.pump(const Duration(seconds: 12));
    expect(camera.session.captureCount, stoppedCaptureCount);
    await _expectVisible(tester, 'Start Continuous Assistance');
    expect(find.text('Start Continuous Assistance'), findsOneWidget);
  });

  testWidgets('Stop Assistance cancels active speech and disposes the camera', (
    WidgetTester tester,
  ) async {
    final speech = FakeSpeechService(pending: Completer<void>());
    final camera = FakeCameraService();
    await _openActiveSession(
      tester,
      camera: camera,
      detector: FakeDetectionClient(result: sampleResult()),
      speech: speech,
    );

    await _tapText(tester, 'Analyze Current Frame');
    await tester.pumpAndSettle();
    expect(speech.isSpeaking, isTrue);

    await _tapText(tester, 'Stop Assistance');
    await tester.pumpAndSettle();

    expect(speech.stopCount, greaterThan(0));
    expect(speech.isSpeaking, isFalse);
    expect(camera.session.isDisposed, isTrue);
  });
}

Future<void> _openActiveSession(
  WidgetTester tester, {
  required FakeCameraService camera,
  required FakeDetectionClient detector,
  FakeSpeechService? speech,
}) async {
  await tester.pumpWidget(
    VisionAssistApp(
      cameraService: camera,
      detectionService: detector,
      speechService: speech ?? FakeSpeechService(),
    ),
  );
  await _tapText(tester, 'Continue');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Start Assistance');
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.scrollUntilVisible(
    finder,
    80,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _expectVisible(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.scrollUntilVisible(
    finder,
    80,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pump();
}

DetectionResult sampleResult({int people = 1}) {
  return DetectionResult.fromJson({
    'schema_version': 1,
    'model': 'yolov5n.onnx',
    'image_width': 640,
    'image_height': 480,
    'inference_ms': 20.5,
    'detections': List.generate(
      people,
      (index) => {
        'class_id': 0,
        'label': 'person',
        'confidence': 0.8 - index * 0.1,
        'bounding_box': {
          'x_min': 10 + index * 100,
          'y_min': 20,
          'x_max': 80 + index * 100,
          'y_max': 120,
        },
      },
    ),
  });
}

class FakeCameraService implements CameraService {
  FakeCameraService() : session = FakeCameraSession();

  final FakeCameraSession session;

  @override
  Future<CameraSession> open() async => session;
}

class DeniedCameraService implements CameraService {
  @override
  Future<CameraSession> open() async {
    throw const CameraStartException(
      'Camera permission was denied in this test.',
    );
  }
}

class FakeCameraSession implements CameraSession {
  int captureCount = 0;
  bool isDisposed = false;

  @override
  bool get isInitialized => !isDisposed;

  @override
  Widget buildPreview() => const ColoredBox(color: Color(0xFF1D2939));

  @override
  Future<Uint8List> captureJpeg() async {
    captureCount++;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> handleLifecycle(AppLifecycleState state) async {}

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}

typedef AnalyzeHandler = Future<DetectionResult> Function(
  Uint8List bytes, {
  Future<void>? abortTrigger,
});

class FakeDetectionClient implements DetectionClient {
  FakeDetectionClient({
    this.result,
    this.analyzeHandler,
  });

  final DetectionResult? result;
  final AnalyzeHandler? analyzeHandler;
  bool isClosed = false;

  @override
  Future<DetectionResult> analyze(
    Uint8List jpegBytes, {
    Future<void>? abortTrigger,
  }) {
    if (analyzeHandler != null) {
      return analyzeHandler!(jpegBytes, abortTrigger: abortTrigger);
    }
    return Future.value(result ?? sampleResult());
  }

  @override
  Future<AiServiceHealth> checkHealth({Future<void>? abortTrigger}) async {
    return const AiServiceHealth(
      modelLoaded: false,
      model: 'yolov5n.onnx',
    );
  }

  @override
  void close() {
    isClosed = true;
  }
}

class FakeSpeechService implements SpeechService {
  FakeSpeechService({this.pending});

  final Completer<void>? pending;
  final List<String> utterances = [];
  final List<double> rates = [];
  final List<double> volumes = [];
  int stopCount = 0;
  bool isSpeaking = false;

  @override
  Future<void> speak(
    String text, {
    required double speechRate,
    required double volume,
  }) {
    utterances.add(text);
    rates.add(speechRate);
    volumes.add(volume);
    isSpeaking = true;
    final completion = pending;
    if (completion == null) {
      isSpeaking = false;
      return Future.value();
    }
    return completion.future.whenComplete(() {
      isSpeaking = false;
    });
  }

  @override
  Future<void> stop() async {
    stopCount++;
    isSpeaking = false;
    if (pending != null && !pending!.isCompleted) {
      pending!.complete();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}


