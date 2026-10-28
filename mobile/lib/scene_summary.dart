import 'detection_service.dart';

String buildSceneSummary(DetectionResult result) {
  if (result.detections.isEmpty) {
    return 'No objects detected.';
  }

  final counts = <String, int>{};
  for (final detection in result.detections) {
    counts.update(
      detection.label,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  final visibleLabels = counts.entries.take(4).map((entry) {
    final noun = entry.value == 1 ? 'detection' : 'detections';
    return '${entry.value} $noun labeled ${entry.key}';
  }).join(', ');
  final additionalLabels = counts.length - 4;
  final additionalText = additionalLabels > 0
      ? ', and $additionalLabels other labels'
      : '';
  final objectNoun = result.detections.length == 1 ? 'object' : 'objects';
  return 'Detected ${result.detections.length} $objectNoun: '
      '$visibleLabels$additionalText.';
}
