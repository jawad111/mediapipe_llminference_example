import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Logic class
class LlmService {
  static const MethodChannel _channel =
      MethodChannel('com.example.mediapipe_llminference_example/inference');
  static const EventChannel _eventChannel = EventChannel('flutter_gemma_stream');

  Future<String> initializeModel() async {
    try {
      final result = await _channel.invokeMethod('initialize', {
        'modelPath': '/data/local/tmp/llm/model.bin',
        'maxTokens': 50,
        'temperature': 0.7,
        'randomSeed': 42,
        'topK': 40,
      });
      return 'Initialization result: $result';
    } catch (e) {
      return 'Error initializing model: $e';
    }
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final result = await _channel.invokeMethod('generateResponse', {
        'prompt': prompt,
      });
      return result ?? 'No response received';
    } catch (e) {
      return 'Error generating response: $e';
    }
  }

  Stream<String> generateResponseAsync(String prompt) {
    _channel.invokeMethod('generateResponseAsync', {
      'prompt': prompt,
    });
    return _eventChannel.receiveBroadcastStream().map((event) => event.toString());
  }
}