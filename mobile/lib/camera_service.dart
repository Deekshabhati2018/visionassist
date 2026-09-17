import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';

/// The smallest camera surface the app needs for this milestone.
///
/// Keeping this interface separate from the camera plugin makes the screen
/// testable without a physical camera or platform channel.
abstract interface class CameraService {
  Future<CameraSession> open();
}

abstract interface class CameraSession {
  bool get isInitialized;

  Widget buildPreview();

  Future<void> handleLifecycle(AppLifecycleState state);

  Future<void> dispose();
}

class CameraStartException implements Exception {
  const CameraStartException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FlutterCameraService implements CameraService {
  const FlutterCameraService();

  @override
  Future<CameraSession> open() async {
    final cameras = await camera.availableCameras();
    if (cameras.isEmpty) {
      throw const CameraStartException(
        'No camera was found on this device. Assistance cannot start yet.',
      );
    }

    final description = cameras.firstWhere(
      (item) => item.lensDirection == camera.CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final session = FlutterCameraSession(description);

    try {
      await session.initialize();
      return session;
    } on camera.CameraException catch (error) {
      await session.dispose();
      throw CameraStartException(_cameraErrorMessage(error));
    } catch (_) {
      await session.dispose();
      throw const CameraStartException(
        'The camera could not be started. Check the device and try again.',
      );
    }
  }
}

class FlutterCameraSession implements CameraSession {
  FlutterCameraSession(this.description);

  final camera.CameraDescription description;
  camera.CameraController? _controller;

  Future<void> initialize() async {
    if (_controller?.value.isInitialized ?? false) {
      return;
    }

    final controller = camera.CameraController(
      description,
      camera.ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      _controller = controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Camera is preparing…'));
    }

    return camera.CameraPreview(controller);
  }

  @override
  Future<void> handleLifecycle(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      await _disposeController();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      await initialize();
    }
  }

  @override
  Future<void> dispose() => _disposeController();

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}

String _cameraErrorMessage(camera.CameraException error) {
  switch (error.code) {
    case 'CameraAccessDenied':
      return 'Camera permission was denied. Allow camera access in Android settings, then try again.';
    case 'CameraAccessDeniedWithoutPrompt':
      return 'Camera permission is blocked. Open Android settings, allow camera access for VisionAssist, then try again.';
    case 'CameraAccessRestricted':
      return 'Camera access is restricted on this device. Check device restrictions and try again.';
    default:
      return 'The camera could not be started. Check the device and try again.';
  }
}