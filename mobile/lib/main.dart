import 'dart:async';

import 'package:flutter/material.dart';

import 'camera_service.dart';
import 'detection_service.dart';

void main() {
  runApp(const VisionAssistApp());
}

class VisionAssistApp extends StatelessWidget {
  const VisionAssistApp({
    super.key,
    this.cameraService = const FlutterCameraService(),
    this.detectionService = const DetectionService(),
  });

  final CameraService cameraService;
  final DetectionService detectionService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionAssist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF155EEF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        useMaterial3: true,
      ),
      home: OnboardingScreen(
        cameraService: cameraService,
        detectionService: detectionService,
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.cameraService,
    required this.detectionService,
  });

  final CameraService cameraService;
  final DetectionService detectionService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 72,
                    color: Color(0xFF155EEF),
                    semanticLabel: 'VisionAssist',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'VisionAssist',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A voice-first assistant for understanding nearby surroundings.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Semantics(
                        container: true,
                        label:
                            'Safety notice. VisionAssist is an assistive prototype, not a certified safety device.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safety notice',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'VisionAssist is an assistive prototype, not a certified mobility aid. It cannot guarantee collision avoidance. Keep your normal safety practices and use your own judgment.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => AssistanceHomeScreen(
                            cameraService: cameraService,
                            detectionService: detectionService,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AssistanceHomeScreen extends StatefulWidget {
  const AssistanceHomeScreen({
    super.key,
    required this.cameraService,
    required this.detectionService,
  });

  final CameraService cameraService;
  final DetectionService detectionService;

  @override
  State<AssistanceHomeScreen> createState() => _AssistanceHomeScreenState();
}

enum AssistanceState { off, starting, active, error }

class _AssistanceHomeScreenState extends State<AssistanceHomeScreen>
    with WidgetsBindingObserver {
  AssistanceState _assistanceState = AssistanceState.off;
  CameraSession? _cameraSession;
  String? _cameraMessage;
  String? _detectionMessage;
  DetectionResult? _detectionResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final session = _cameraSession;
    _cameraSession = null;
    if (session != null) {
      unawaited(session.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_assistanceState != AssistanceState.active) {
      return;
    }

    final session = _cameraSession;
    if (session == null) {
      return;
    }

    unawaited(_refreshCameraLifecycle(session, state));
  }

  Future<void> _refreshCameraLifecycle(
    CameraSession session,
    AppLifecycleState state,
  ) async {
    try {
      await session.handleLifecycle(state);
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _assistanceState = AssistanceState.error;
          _cameraMessage =
              'The camera stopped while the app changed state. Try starting assistance again.';
        });
      }
    }
  }

  Future<void> _toggleAssistance() async {
    if (_assistanceState == AssistanceState.active) {
      await _stopAssistance();
      return;
    }

    if (_assistanceState == AssistanceState.starting) {
      return;
    }

    setState(() {
      _assistanceState = AssistanceState.starting;
      _cameraMessage = null;
    });

    try {
      final session = await widget.cameraService.open();
      if (!mounted) {
        await session.dispose();
        return;
      }

      setState(() {
        _cameraSession = session;
        _assistanceState = AssistanceState.active;
      });
    } on CameraStartException catch (error) {
      if (mounted) {
        setState(() {
          _assistanceState = AssistanceState.error;
          _cameraMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _assistanceState = AssistanceState.error;
          _cameraMessage =
              'The camera could not be started. Check the device and try again.';
        });
      }
    }
  }

  Future<void> _stopAssistance() async {
    final session = _cameraSession;
    _cameraSession = null;
    setState(() {
      _assistanceState = AssistanceState.off;
      _cameraMessage = null;
      _detectionMessage = null;
      _detectionResult = null;
      _isAnalyzing = false;
    });
    await session?.dispose();
  }

  Future<void> _analyzeCurrentFrame() async {
    final session = _cameraSession;
    if (session == null || _isAnalyzing) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _detectionMessage = null;
      _detectionResult = null;
    });

    try {
      final jpegBytes = await session.captureJpeg();
      if (!mounted || _assistanceState != AssistanceState.active) {
        return;
      }

      final result = await widget.detectionService.analyze(jpegBytes);
      if (!mounted || _assistanceState != AssistanceState.active) {
        return;
      }

      setState(() {
        _detectionResult = result;
      });
    } on CameraStartException catch (error) {
      if (mounted) {
        setState(() {
          _detectionMessage = error.message;
        });
      }
    } on DetectionServiceException catch (error) {
      if (mounted) {
        setState(() {
          _detectionMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _detectionMessage =
              'Could not analyze this frame. Check camera access and the AI service connection.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  String get _statusText {
    switch (_assistanceState) {
      case AssistanceState.off:
        return 'Assistance is off';
      case AssistanceState.starting:
        return 'Preparing camera access';
      case AssistanceState.active:
        return 'Assistance is active';
      case AssistanceState.error:
        return 'Camera access needs attention';
    }
  }

  Color _statusColor(BuildContext context) {
    switch (_assistanceState) {
      case AssistanceState.off:
        return const Color(0xFF475467);
      case AssistanceState.starting:
        return Theme.of(context).colorScheme.primary;
      case AssistanceState.active:
        return const Color(0xFF067647);
      case AssistanceState.error:
        return Theme.of(context).colorScheme.error;
    }
  }

  String get _descriptionText {
    switch (_assistanceState) {
      case AssistanceState.off:
        return 'Start an assistance session when you are ready.';
      case AssistanceState.starting:
        return 'Requesting camera permission and preparing the live preview.';
      case AssistanceState.active:
        return 'The live camera preview is active. Analyze one frame to identify nearby objects.';
      case AssistanceState.error:
        return 'Assistance did not start. Read the camera message below and try again.';
    }
  }

  String get _buttonLabel {
    switch (_assistanceState) {
      case AssistanceState.off:
      case AssistanceState.error:
        return 'Start Assistance';
      case AssistanceState.starting:
        return 'Starting…';
      case AssistanceState.active:
        return 'Stop Assistance';
    }
  }

  Widget _buildPreviewPanel(BuildContext context) {
    final session = _cameraSession;
    if (session == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live camera preview',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Semantics(
              image: true,
              label:
                  'Live camera preview. VisionAssist does not save raw camera video by default.',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: Colors.black,
                    child: session.buildPreview(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Analyze Current Frame sends one temporary JPEG to the pretrained detector. Camera images are not retained.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VisionAssist'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Semantics(
              liveRegion: true,
              label: _statusText,
              child: Text(
                _statusText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _statusColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_descriptionText, style: Theme.of(context).textTheme.bodyLarge),
            if (_cameraMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    liveRegion: true,
                    label: 'Camera message: $_cameraMessage',
                    child: Text(_cameraMessage!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildPreviewPanel(context),
            if (_cameraSession != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeCurrentFrame,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _isAnalyzing
                          ? 'Analyzing frame…'
                          : 'Analyze Current Frame',
                    ),
                  ),
                ),
              ),
              if (_detectionMessage != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Semantics(
                      liveRegion: true,
                      label: 'AI service message: $_detectionMessage',
                      child: Text(_detectionMessage!),
                    ),
                  ),
                ),
              ],
              if (_isAnalyzing) ...[
                const SizedBox(height: 12),
                const Semantics(
                  liveRegion: true,
                  label: 'Analyzing the captured frame with the AI service.',
                  child: Text(
                    'Sending one captured frame to the detector. The first request may take longer while the model loads.',
                  ),
                ),
              ],
              if (_detectionResult != null) ...[
                const SizedBox(height: 12),
                _buildDetectionResults(context, _detectionResult!),
              ],
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current milestone',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _assistanceState == AssistanceState.active
                          ? 'A pretrained detector can analyze one captured frame when you request it. Continuous monitoring, prioritization, and spoken alerts are not enabled yet.'
                          : 'This milestone adds explicit camera access and a live preview without storing raw video.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              button: true,
              label: _buttonLabel,
              hint: _assistanceState == AssistanceState.active
                  ? 'Ends the current assistance session'
                  : 'Requests camera access and starts the current assistance session',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _assistanceState == AssistanceState.starting
                      ? null
                      : _toggleAssistance,
                  icon: Icon(
                    _assistanceState == AssistanceState.active
                        ? Icons.stop
                        : Icons.play_arrow,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_buttonLabel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionResults(
    BuildContext context,
    DetectionResult result,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI frame analysis',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.detections.length} objects found · ${result.inferenceMs.toStringAsFixed(0)} ms · ${result.model}',
            ),
            const SizedBox(height: 12),
            if (result.detections.isEmpty)
              const Text('No objects detected in this frame.')
            else
              ...result.detections.take(8).map(
                    (detection) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.visibility_outlined),
                      title: Text(detection.label),
                      subtitle: Text(
                        '${(detection.confidence * 100).toStringAsFixed(0)}% confidence',
                      ),
                      trailing: Text(
                        'x ${detection.boundingBox.xMin.toStringAsFixed(0)}–${detection.boundingBox.xMax.toStringAsFixed(0)}\n'
                        'y ${detection.boundingBox.yMin.toStringAsFixed(0)}–${detection.boundingBox.yMax.toStringAsFixed(0)}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            const Text(
              'Model predictions can be wrong. Do not use them as a guarantee of safe passage.',
            ),
          ],
        ),
      ),
    );
  }
}