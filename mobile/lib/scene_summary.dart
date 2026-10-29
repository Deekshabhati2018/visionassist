import 'detection_service.dart';

String buildSceneSummary(DetectionResult result) {
  if (result.detections.isEmpty) {
    return 'The model detected no objects.';
  }

  final counts = <String, int>{};
  for (final detection in result.detections) {
    counts.update(
      detection.label,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  final orderedCounts = counts.entries.toList()
    ..sort((first, second) {
      final byCount = second.value.compareTo(first.value);
      return byCount != 0 ? byCount : first.key.compareTo(second.key);
    });
  final visibleLabels = orderedCounts.take(4).map((entry) {
    final noun = entry.value == 1 ? 'detection' : 'detections';
    return '${entry.value} $noun labeled ${entry.key}';
  }).join(', ');
  final additionalLabels = orderedCounts.length - 4;
  final additionalNoun = additionalLabels == 1 ? 'other label' : 'other labels';
  final additionalText = additionalLabels > 0
      ? ', and $additionalLabels $additionalNoun'
      : '';
  final objectNoun = result.detections.length == 1 ? 'object' : 'objects';
  return 'The model detected ${result.detections.length} $objectNoun: '
      '$visibleLabels$additionalText.';
}
