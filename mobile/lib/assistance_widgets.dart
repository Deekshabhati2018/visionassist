import 'package:flutter/material.dart';

import 'camera_service.dart';
import 'detection_service.dart';

class AssistanceStatusCard extends StatelessWidget {
  const AssistanceStatusCard({
    super.key,
    required this.cameraStatus,
    required this.aiServiceStatus,
    required this.analysisStatus,
  });

  final String cameraStatus;
  final String aiServiceStatus;
  final String analysisStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _StatusRow(label: 'Camera', value: cameraStatus),
            const Divider(height: 1),
            _StatusRow(label: 'AI service', value: aiServiceStatus),
            const Divider(height: 1),
            _StatusRow(label: 'Analysis', value: analysisStatus),
          ],
        ),
      ),
    );
  }
}

class CameraPreviewCard extends StatelessWidget {
  const CameraPreviewCard({super.key, required this.session});

  final CameraSession session;

  @override
  Widget build(BuildContext context) {
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
              'Frames are captured only for analysis, then the temporary image is deleted. The AI service does not retain camera images.',
            ),
          ],
        ),
      ),
    );
  }
}

class ContinuousAssistanceCard extends StatelessWidget {
  const ContinuousAssistanceCard({
    super.key,
    required this.running,
    required this.paused,
    required this.isAnalyzing,
    required this.sampleIntervalSeconds,
    required this.onIntervalChanged,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final bool running;
  final bool paused;
  final bool isAnalyzing;
  final int sampleIntervalSeconds;
  final ValueChanged<int> onIntervalChanged;
  final VoidCallback? onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continuous assistance',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Samples one camera frame at a time. It does not measure distance, movement, or danger.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Sample interval')),
                DropdownButton<int>(
                  value: sampleIntervalSeconds,
                  onChanged: running
                      ? null
                      : (value) {
                          if (value != null) {
                            onIntervalChanged(value);
                          }
                        },
                  items: const [3, 5, 10]
                      .map(
                        (seconds) => DropdownMenuItem<int>(
                          value: seconds,
                          child: Text('$seconds seconds'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!running && !paused)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isAnalyzing ? null : onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Continuous Assistance'),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (running)
                    OutlinedButton.icon(
                      onPressed: onPause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),
                  if (paused)
                    FilledButton.icon(
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                    ),
                  OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Continuous'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class VoiceAssistanceCard extends StatelessWidget {
  const VoiceAssistanceCard({
    super.key,
    required this.hasSummary,
    required this.isMuted,
    required this.isSpeaking,
    required this.speechRate,
    required this.speechVolume,
    required this.message,
    required this.onSpeakAgain,
    required this.onToggleMute,
    required this.onStopSpeech,
    required this.onSpeechRateChanged,
    required this.onSpeechVolumeChanged,
  });

  final bool hasSummary;
  final bool isMuted;
  final bool isSpeaking;
  final double speechRate;
  final double speechVolume;
  final String? message;
  final VoidCallback onSpeakAgain;
  final VoidCallback onToggleMute;
  final VoidCallback onStopSpeech;
  final ValueChanged<double> onSpeechRateChanged;
  final ValueChanged<double> onSpeechVolumeChanged;

  @override
  Widget build(BuildContext context) {
    final ratePercent = (speechRate * 100).round();
    final volumePercent = (speechVolume * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice assistance',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: !hasSummary || isMuted ? null : onSpeakAgain,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Speak Again'),
                ),
                OutlinedButton.icon(
                  onPressed: onToggleMute,
                  icon: Icon(isMuted ? Icons.volume_off : Icons.volume_mute),
                  label: Text(isMuted ? 'Unmute' : 'Mute'),
                ),
                if (isSpeaking)
                  TextButton.icon(
                    onPressed: onStopSpeech,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Speech'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Speech rate',
              value: '$ratePercent percent',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Speech rate · $ratePercent%'),
                  Slider(
                    min: 0.25,
                    max: 0.75,
                    divisions: 10,
                    value: speechRate,
                    onChanged: onSpeechRateChanged,
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Speech volume',
              value: '$volumePercent percent',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Speech volume · $volumePercent%'),
                  Slider(
                    min: 0,
                    max: 1,
                    divisions: 10,
                    value: speechVolume,
                    onChanged: onSpeechVolumeChanged,
                  ),
                ],
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                label: 'Speech message: $message',
                child: Text(
                  message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DetectionResultsCard extends StatelessWidget {
  const DetectionResultsCard({
    super.key,
    required this.result,
    required this.summary,
  });

  final DetectionResult result;
  final String? summary;

  @override
  Widget build(BuildContext context) {
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
              '${result.detections.length} detections · ${result.inferenceMs.toStringAsFixed(0)} ms · ${result.model}',
            ),
            if (summary != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                label: 'Scene summary: $summary',
                child: Text(
                  summary!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (result.detections.isEmpty)
              const Text('The model detected no objects in this frame.')
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
              'Predictions may be wrong. Bounding boxes do not measure distance or danger. VisionAssist is not a certified mobility or safety device.',
            ),
          ],
        ),
      ),
    );
  }
}

class AssistanceMessageCard extends StatelessWidget {
  const AssistanceMessageCard({
    super.key,
    required this.label,
    required this.message,
  });

  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          liveRegion: true,
          label: '$label: $message',
          child: Text(message),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label status: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
