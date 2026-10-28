import 'package:flutter/material.dart';

import 'assistance_home_screen.dart';
import 'camera_service.dart';
import 'detection_service.dart';
import 'speech_service.dart';

void main() {
  runApp(VisionAssistApp());
}

class VisionAssistApp extends StatelessWidget {
  VisionAssistApp({
    super.key,
    CameraService? cameraService,
    DetectionClient? detectionService,
    SpeechService? speechService,
  })  : cameraService = cameraService ?? const FlutterCameraService(),
        detectionService = detectionService ?? DetectionService(),
        speechService = speechService ?? FlutterSpeechService();

  final CameraService cameraService;
  final DetectionClient detectionService;
  final SpeechService speechService;

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
        speechService: speechService,
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.cameraService,
    required this.detectionService,
    required this.speechService,
  });

  final CameraService cameraService;
  final DetectionClient detectionService;
  final SpeechService speechService;

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
                    'A voice-first assistant that describes objects recognized in a camera frame.',
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
                            speechService: speechService,
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
