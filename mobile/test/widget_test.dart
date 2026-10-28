import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_mobile/camera_service.dart';
import 'package:visionassist_mobile/main.dart';

void main() {
  testWidgets('user can enter assistance and start a session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const VisionAssistApp(cameraService: FakeCameraService()),
    );

    expect(find.text('VisionAssist'), findsOneWidget);
    expect(find.text('Safety notice'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Assistance is off'), findsOneWidget);
    expect(find.text('Start Assistance'), findsOneWidget);

    await tester.tap(find.text('Start Assistance'));
    await tester.pumpAndSettle();

    expect(find.text('Assistance is active'), findsOneWidget);
    expect(find.text('Stop Assistance'), findsOneWidget);
    expect(find.text('Live camera preview'), findsOneWidget);
    expect(find.text('Analyze Current Frame'), findsOneWidget);
  });

  testWidgets('camera denial is explained without activating assistance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const VisionAssistApp(
        cameraService: DeniedCameraService(),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Assistance'));
    await tester.pumpAndSettle();

    expect(find.text('Camera access needs attention'), findsOneWidget);
    expect(
      find.text('Camera permission was denied in this test.'),
      findsOneWidget,
    );
    expect(find.text('Start Assistance'), findsOneWidget);
  });
}

class FakeCameraService implements CameraService {
  const FakeCameraService();

  @override
  Future<CameraSession> open() async => const FakeCameraSession();
}

class DeniedCameraService implements CameraService {
  const DeniedCameraService();

  @override
  Future<CameraSession> open() async {
    throw const CameraStartException(
      'Camera permission was denied in this test.',
    );
  }
}

class FakeCameraSession implements CameraSession {
  const FakeCameraSession();

  @override
  bool get isInitialized => true;

  @override
  Widget buildPreview() => const ColoredBox(color: Color(0xFF1D2939));

  @override
  Future<Uint8List> captureJpeg() async {
    throw UnsupportedError('The camera test does not capture image frames.');
  }

  @override
  Future<void> handleLifecycle(AppLifecycleState state) async {}

  @override
  Future<void> dispose() async {}
}