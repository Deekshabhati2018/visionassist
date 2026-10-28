import 'package:flutter_tts/flutter_tts.dart';

abstract interface class SpeechService {
  Future<void> speak(
    String text, {
    required double speechRate,
    required double volume,
  });

  Future<void> stop();

  Future<void> dispose();
}

class FlutterSpeechService implements SpeechService {
  FlutterSpeechService({FlutterTts? engine}) : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;
  Future<void>? _ready;
  bool _disposed = false;

  Future<void> _initialize() async {
    _ready ??= _engine.awaitSpeakCompletion(true).then<void>((_) {});
    await _ready;
  }

  @override
  Future<void> speak(
    String text, {
    required double speechRate,
    required double volume,
  }) async {
    if (_disposed || text.trim().isEmpty) {
      return;
    }
    await _initialize();
    await _engine.setSpeechRate(speechRate);
    await _engine.setVolume(volume);
    await _engine.speak(text);
  }

  @override
  Future<void> stop() async {
    await _engine.stop();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    await stop();
    _disposed = true;
  }
}
