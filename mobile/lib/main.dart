import 'package:flutter/material.dart';

void main() {
  runApp(const VisionAssistApp());
}

class VisionAssistApp extends StatelessWidget {
  const VisionAssistApp({super.key});

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
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
                          builder: (_) => const AssistanceHomeScreen(),
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
  const AssistanceHomeScreen({super.key});

  @override
  State<AssistanceHomeScreen> createState() => _AssistanceHomeScreenState();
}

class _AssistanceHomeScreenState extends State<AssistanceHomeScreen> {
  bool _isAssistanceActive = false;

  void _toggleAssistance() {
    setState(() {
      _isAssistanceActive = !_isAssistanceActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusText =
        _isAssistanceActive ? 'Assistance is active' : 'Assistance is off';
    final statusColor =
        _isAssistanceActive ? const Color(0xFF067647) : const Color(0xFF475467);

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
              label: statusText,
              child: Text(
                statusText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isAssistanceActive
                  ? 'The assistance session is ready for the camera and AI connection milestone.'
                  : 'Start an assistance session when you are ready.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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
                    const Text(
                      'This shell validates the accessible app flow. Camera permission, live frames, AI detection, and spoken alerts will be connected in the next milestones.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              button: true,
              label: _isAssistanceActive
                  ? 'Stop assistance'
                  : 'Start assistance',
              hint: _isAssistanceActive
                  ? 'Ends the current assistance session'
                  : 'Starts the current assistance session',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _toggleAssistance,
                  icon: Icon(
                    _isAssistanceActive ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _isAssistanceActive
                          ? 'Stop Assistance'
                          : 'Start Assistance',
                    ),
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