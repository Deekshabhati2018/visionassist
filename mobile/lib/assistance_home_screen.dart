import 'dart:async';

import 'package:flutter/material.dart';

import 'assistance_widgets.dart';
import 'camera_service.dart';
import 'detection_service.dart';
import 'scene_summary.dart';
import 'speech_service.dart';

enum _SessionState { off, starting, active, error }

enum _AiConnectionState { unknown, checking, connected, unavailable }

enum _ContinuousState { stopped, running, paused }

class AssistanceHomeScreen extends StatefulWidget {
  const AssistanceHomeScreen({
    super.key,
    required this.cameraService,
    required this.detectionService,
    required this.speechService,
  });

  final CameraService cameraService;
  final DetectionClient detectionService;
  final SpeechService speechService;

  @override
  State<AssistanceHomeScreen> createState() => _AssistanceHomeScreenState();
}

class _AssistanceHomeScreenState extends State<AssistanceHomeScreen>
    with WidgetsBindingObserver {
  _SessionState _sessionState = _SessionState.off;
  _AiConnectionState _aiConnectionState = _AiConnectionState.unknown;
  _ContinuousState _continuousState = _ContinuousState.stopped;
  CameraSession? _cameraSession;
  String? _cameraMessage;
  String? _serviceMessage;
  String? _speechMessage;
  DetectionResult? _detectionResult;
  String? _sceneSummary;
  String? _lastAutomaticallySpokenSummary;
  bool _isAnalyzing = false;
  bool _isSpeaking = false;
  bool _isMuted = false;
  bool _modelLoaded = false;
  double _speechRate = 0.45;
  double _speechVolume = 1;
  int _sampleIntervalSeconds = 5;
  Timer? _samplingTimer;
  Completer<void>? _activeAnalysisAbort;
  Completer<void>? _activeHealthAbort;
  int _analysisGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _samplingTimer?.cancel();
    _abortRequests();
    final session = _cameraSession;
    _cameraSession = null;
    if (session != null) {
      unawaited(session.dispose());
    }
    widget.detectionService.close();
    unawaited(widget.speechService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _cameraSession;
    if (_sessionState != _SessionState.active || session == null) {
      return;
    }

    final appIsBackgrounded = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    if (appIsBackgrounded) {
      if (_continuousState == _ContinuousState.running) {
        _pauseContinuousAssistance();
      } else {
        _abortRequests();
        unawaited(_stopSpeech());
      }
      if (mounted) {
        setState(() {
          if (_aiConnectionState == _AiConnectionState.checking) {
            _aiConnectionState = _AiConnectionState.unknown;
          }
          _isAnalyzing = false;
        });
      }
    }
    unawaited(_refreshCameraLifecycle(session, state));
  }

  Future<void> _refreshCameraLifecycle(
    CameraSession session,
    AppLifecycleState state,
  ) async {
    try {
      await session.handleLifecycle(state);
      if (mounted && identical(_cameraSession, session)) {
        setState(() {});
        if (state == AppLifecycleState.resumed) {
          unawaited(_refreshAiServiceHealth(session));
        }
      }
    } catch (_) {
      _samplingTimer?.cancel();
      _samplingTimer = null;
      _abortAnalysis();
      if (identical(_cameraSession, session)) {
        _cameraSession = null;
      }
      unawaited(session.dispose());
      if (mounted) {
        setState(() {
          _sessionState = _SessionState.error;
          _continuousState = _ContinuousState.stopped;
          _cameraMessage =
              'The camera stopped while the app changed state. Try starting assistance again.';
        });
      }
    }
  }

  Future<void> _toggleAssistance() async {
    if (_sessionState == _SessionState.active) {
      await _stopAssistance();
      return;
    }
    if (_sessionState == _SessionState.starting) {
      return;
    }

    setState(() {
      _sessionState = _SessionState.starting;
      _cameraMessage = null;
      _serviceMessage = null;
      _aiConnectionState = _AiConnectionState.unknown;
      _modelLoaded = false;
    });

    try {
      final session = await widget.cameraService.open();
      if (!mounted) {
        await session.dispose();
        return;
      }

      setState(() {
        _cameraSession = session;
        _sessionState = _SessionState.active;
      });
      unawaited(_refreshAiServiceHealth(session));
    } on CameraStartException catch (error) {
      if (mounted) {
        setState(() {
          _sessionState = _SessionState.error;
          _cameraMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessionState = _SessionState.error;
          _cameraMessage =
              'The camera could not be started. Check the device and try again.';
        });
      }
    }
  }

  Future<void> _refreshAiServiceHealth(CameraSession session) async {
    final abort = Completer<void>();
    _activeHealthAbort = abort;
    if (mounted) {
      setState(() {
        _aiConnectionState = _AiConnectionState.checking;
        _serviceMessage = null;
      });
    }

    try {
      final health = await widget.detectionService.checkHealth(
        abortTrigger: abort.future,
      );
      if (!mounted || !identical(_cameraSession, session)) {
        return;
      }
      setState(() {
        _aiConnectionState = _AiConnectionState.connected;
        _modelLoaded = health.modelLoaded;
        _serviceMessage = null;
      });
    } on DetectionRequestCancelled {
      // The session ended while the health request was in flight.
    } on DetectionServiceException catch (error) {
      if (mounted && identical(_cameraSession, session)) {
        setState(() {
          _aiConnectionState = _AiConnectionState.unavailable;
          _serviceMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted && identical(_cameraSession, session)) {
        setState(() {
          _aiConnectionState = _AiConnectionState.unavailable;
          _serviceMessage =
              'Could not check the AI service. Confirm it is running and reachable from this phone.';
        });
      }
    } finally {
      if (identical(_activeHealthAbort, abort)) {
        _activeHealthAbort = null;
      }
    }
  }

  Future<void> _stopAssistance() async {
    _samplingTimer?.cancel();
    _samplingTimer = null;
    _abortRequests();
    final session = _cameraSession;
    _cameraSession = null;
    if (mounted) {
      setState(() {
        _sessionState = _SessionState.off;
        _continuousState = _ContinuousState.stopped;
        _cameraMessage = null;
        _serviceMessage = null;
        _speechMessage = null;
        _detectionResult = null;
        _sceneSummary = null;
        _lastAutomaticallySpokenSummary = null;
        _isAnalyzing = false;
        _isSpeaking = false;
        _aiConnectionState = _AiConnectionState.unknown;
        _modelLoaded = false;
      });
    }
    await _stopSpeech();
    await session?.dispose();
  }

  void _abortRequests() {
    _abortAnalysis();
    final healthAbort = _activeHealthAbort;
    _activeHealthAbort = null;
    if (healthAbort != null && !healthAbort.isCompleted) {
      healthAbort.complete();
    }
  }

  void _abortAnalysis() {
    _analysisGeneration++;
    final abort = _activeAnalysisAbort;
    _activeAnalysisAbort = null;
    if (abort != null && !abort.isCompleted) {
      abort.complete();
    }
    _isAnalyzing = false;
  }

  Future<void> _analyzeCurrentFrame() async {
    await _captureAndAnalyze(announce: true);
  }

  Future<void> _captureAndAnalyze({required bool announce}) async {
    final session = _cameraSession;
    if (session == null || _isAnalyzing || !session.isInitialized) {
      return;
    }

    final generation = ++_analysisGeneration;
    final abort = Completer<void>();
    _activeAnalysisAbort = abort;
    setState(() {
      _isAnalyzing = true;
      _serviceMessage = null;
      _speechMessage = null;
    });

    try {
      final jpegBytes = await session.captureJpeg();
      if (!_isCurrentAnalysis(generation, session)) {
        return;
      }

      final result = await widget.detectionService.analyze(
        jpegBytes,
        abortTrigger: abort.future,
      );
      if (!_isCurrentAnalysis(generation, session)) {
        return;
      }

      final summary = buildSceneSummary(result);
      setState(() {
        _detectionResult = result;
        _sceneSummary = summary;
        _aiConnectionState = _AiConnectionState.connected;
        _modelLoaded = true;
        _serviceMessage = null;
      });
      if (announce) {
        unawaited(_announceAutomatically(summary));
      }
    } on CameraStartException catch (error) {
      if (_isCurrentAnalysis(generation, session)) {
        setState(() {
          _serviceMessage = error.message;
        });
      }
    } on DetectionRequestCancelled {
      // Stop and pause intentionally cancel in-flight inference.
    } on DetectionServiceException catch (error) {
      if (_isCurrentAnalysis(generation, session)) {
        setState(() {
          _aiConnectionState = _AiConnectionState.unavailable;
          _serviceMessage = error.message;
        });
      }
    } catch (_) {
      if (_isCurrentAnalysis(generation, session)) {
        setState(() {
          _aiConnectionState = _AiConnectionState.unavailable;
          _serviceMessage =
              'Could not analyze this frame. Check camera access and the AI service connection.';
        });
      }
    } finally {
      if (_isCurrentAnalysis(generation, session)) {
        setState(() {
          _isAnalyzing = false;
        });
      }
      if (identical(_activeAnalysisAbort, abort)) {
        _activeAnalysisAbort = null;
      }
    }
  }

  bool _isCurrentAnalysis(int generation, CameraSession session) =>
      mounted &&
      generation == _analysisGeneration &&
      identical(_cameraSession, session) &&
      _sessionState == _SessionState.active;

  void _startContinuousAssistance() {
    if (_sessionState != _SessionState.active ||
        _continuousState == _ContinuousState.running) {
      return;
    }
    _samplingTimer?.cancel();
    setState(() {
      _continuousState = _ContinuousState.running;
    });
    unawaited(_runContinuousSample());
    _samplingTimer = Timer.periodic(
      Duration(seconds: _sampleIntervalSeconds),
      (_) => unawaited(_runContinuousSample()),
    );
  }

  Future<void> _runContinuousSample() async {
    if (!mounted ||
        _continuousState != _ContinuousState.running ||
        _isAnalyzing) {
      return;
    }
    await _captureAndAnalyze(announce: true);
  }

  void _pauseContinuousAssistance() {
    if (_continuousState != _ContinuousState.running) {
      return;
    }
    _samplingTimer?.cancel();
    _samplingTimer = null;
    _abortAnalysis();
    setState(() {
      _continuousState = _ContinuousState.paused;
      _isAnalyzing = false;
    });
    unawaited(_stopSpeech());
  }

  void _resumeContinuousAssistance() {
    if (_continuousState != _ContinuousState.paused) {
      return;
    }
    _startContinuousAssistance();
  }

  Future<void> _stopContinuousAssistance() async {
    if (_continuousState == _ContinuousState.stopped) {
      return;
    }
    _samplingTimer?.cancel();
    _samplingTimer = null;
    _abortAnalysis();
    setState(() {
      _continuousState = _ContinuousState.stopped;
      _isAnalyzing = false;
    });
    await _stopSpeech();
  }

  Future<void> _announceAutomatically(String summary) async {
    if (_isMuted || summary == _lastAutomaticallySpokenSummary) {
      return;
    }
    _lastAutomaticallySpokenSummary = summary;
    await _speak(summary);
  }

  Future<void> _speakCurrentSummary() async {
    final summary = _sceneSummary;
    if (summary == null || _isMuted) {
      return;
    }
    await _speak(summary);
  }

  Future<void> _speak(String summary) async {
    if (!mounted || _isMuted) {
      return;
    }
    setState(() {
      _isSpeaking = true;
      _speechMessage = null;
    });
    try {
      await widget.speechService.speak(
        summary,
        speechRate: _speechRate,
        volume: _speechVolume,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _speechMessage =
              'Speech is unavailable. Check that Android has a text-to-speech engine enabled.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await widget.speechService.stop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _speechMessage = 'Could not stop speech. Try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _toggleMute() async {
    final mute = !_isMuted;
    setState(() {
      _isMuted = mute;
      _speechMessage = null;
    });
    if (mute) {
      await _stopSpeech();
    }
  }

  String get _sessionStatusText {
    switch (_sessionState) {
      case _SessionState.off:
        return 'Assistance is off';
      case _SessionState.starting:
        return 'Preparing camera access';
      case _SessionState.active:
        return 'Assistance is active';
      case _SessionState.error:
        return 'Camera access needs attention';
    }
  }

  Color _sessionStatusColor(BuildContext context) {
    switch (_sessionState) {
      case _SessionState.off:
        return const Color(0xFF475467);
      case _SessionState.starting:
        return Theme.of(context).colorScheme.primary;
      case _SessionState.active:
        return const Color(0xFF067647);
      case _SessionState.error:
        return Theme.of(context).colorScheme.error;
    }
  }

  String get _sessionDescription {
    switch (_sessionState) {
      case _SessionState.off:
        return 'Start a camera session when you are ready.';
      case _SessionState.starting:
        return 'Requesting camera permission and preparing the live preview.';
      case _SessionState.active:
        if (_continuousState == _ContinuousState.running) {
          return 'The camera samples frames every $_sampleIntervalSeconds seconds. Object labels are predictions, not distance or hazard measurements.';
        }
        return 'The camera preview is active. Analyze one frame or start continuous assistance.';
      case _SessionState.error:
        return 'Assistance did not start. Read the camera message below and try again.';
    }
  }

  String get _sessionButtonLabel {
    switch (_sessionState) {
      case _SessionState.off:
      case _SessionState.error:
        return 'Start Assistance';
      case _SessionState.starting:
        return 'Starting…';
      case _SessionState.active:
        return 'Stop Assistance';
    }
  }

  String get _cameraStatus {
    if (_cameraSession == null) {
      return _sessionState == _SessionState.starting ? 'Starting' : 'Off';
    }
    return _cameraSession!.isInitialized ? 'Active' : 'Paused';
  }

  String get _aiServiceStatus {
    switch (_aiConnectionState) {
      case _AiConnectionState.unknown:
        return 'Not checked';
      case _AiConnectionState.checking:
        return 'Checking';
      case _AiConnectionState.connected:
        return _modelLoaded ? 'Connected · model ready' : 'Connected · model loads on first scan';
      case _AiConnectionState.unavailable:
        return 'Unavailable';
    }
  }

  String get _analysisStatus {
    if (_isAnalyzing) {
      return 'Analyzing';
    }
    switch (_continuousState) {
      case _ContinuousState.stopped:
        return 'Idle';
      case _ContinuousState.running:
        return 'Sampling every $_sampleIntervalSeconds seconds';
      case _ContinuousState.paused:
        return 'Paused';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _cameraSession;
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
              label: _sessionStatusText,
              child: Text(
                _sessionStatusText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _sessionStatusColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_sessionDescription, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            AssistanceStatusCard(
              cameraStatus: _cameraStatus,
              aiServiceStatus: _aiServiceStatus,
              analysisStatus: _analysisStatus,
            ),
            if (_cameraMessage != null) ...[
              const SizedBox(height: 12),
              AssistanceMessageCard(
                label: 'Camera message',
                message: _cameraMessage!,
              ),
            ],
            if (_serviceMessage != null) ...[
              const SizedBox(height: 12),
              AssistanceMessageCard(
                label: 'AI service message',
                message: _serviceMessage!,
              ),
            ],
            if (session != null) ...[
              const SizedBox(height: 16),
              CameraPreviewCard(session: session),
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
              if (_isAnalyzing) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  label: 'Analyzing the captured frame with the AI service.',
                  child: const Text(
                    'Sending one captured frame to the detector. The first request may take longer while the model loads.',
                  ),
                ),
              ],
              if (_detectionResult != null) ...[
                const SizedBox(height: 12),
                DetectionResultsCard(
                  result: _detectionResult!,
                  summary: _sceneSummary,
                ),
              ],
              const SizedBox(height: 12),
              VoiceAssistanceCard(
                hasSummary: _sceneSummary != null,
                isMuted: _isMuted,
                isSpeaking: _isSpeaking,
                speechRate: _speechRate,
                speechVolume: _speechVolume,
                message: _speechMessage,
                onSpeakAgain: _speakCurrentSummary,
                onToggleMute: _toggleMute,
                onStopSpeech: _stopSpeech,
                onSpeechRateChanged: (value) {
                  setState(() {
                    _speechRate = value;
                  });
                },
                onSpeechVolumeChanged: (value) {
                  setState(() {
                    _speechVolume = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              ContinuousAssistanceCard(
                running: _continuousState == _ContinuousState.running,
                paused: _continuousState == _ContinuousState.paused,
                isAnalyzing: _isAnalyzing,
                sampleIntervalSeconds: _sampleIntervalSeconds,
                onIntervalChanged: (seconds) {
                  setState(() {
                    _sampleIntervalSeconds = seconds;
                  });
                },
                onStart: _startContinuousAssistance,
                onPause: _pauseContinuousAssistance,
                onResume: _resumeContinuousAssistance,
                onStop: _stopContinuousAssistance,
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: _sessionButtonLabel,
              hint: _sessionState == _SessionState.active
                  ? 'Stops continuous analysis, stops speech, and closes the camera'
                  : 'Requests camera access and starts the camera session',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sessionState == _SessionState.starting
                      ? null
                      : _toggleAssistance,
                  icon: Icon(
                    _sessionState == _SessionState.active
                        ? Icons.stop
                        : Icons.play_arrow,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_sessionButtonLabel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


