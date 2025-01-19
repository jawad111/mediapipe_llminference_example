import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediapipe_llminference_example/mediapipe_genai_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter LLM Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LlmExamplePage(),
    );
  }
}


// UI class
class LlmExamplePage extends StatefulWidget {
  const LlmExamplePage({Key? key}) : super(key: key);

  @override
  State<LlmExamplePage> createState() => _LlmExamplePageState();
}

class _LlmExamplePageState extends State<LlmExamplePage> {
  final LlmService _llmService = LlmService();
  final TextEditingController _promptController = TextEditingController();

  String _response = '';
  bool _isProcessing = false;
  Stream<String>? _responseStream;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _initializeModel() async {
    setState(() {
      _isProcessing = true;
      _response = 'Loading . . .';
    });
    final result = await _llmService.initializeModel();
    setState(() {
      _response = result;
      _isProcessing = false;
    });
  }

  void _generateResponse() async {
    if (_promptController.text.isEmpty) {
      setState(() {
        _response = 'Prompt cannot be empty';
      });
      return;
    }
    setState(() {
      _isProcessing = true;
      _response = 'Loading . . .';
    });
    final result = await _llmService.generateResponse(_promptController.text);
    setState(() {
      _response = result;
      _isProcessing = false;
    });
  }

  void _generateResponseAsync() {
    if (_promptController.text.isEmpty) {
      setState(() {
        _response = 'Prompt cannot be empty';
      });
      return;
    }
    setState(() {
      _responseStream = _llmService.generateResponseAsync(_promptController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Inference Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your prompt',
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _initializeModel,
                    child: const Text('Initialize Model'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _generateResponse,
                    child: const Text('Sync Response'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _generateResponseAsync,
                    child: const Text('Async Response'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Response:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _responseStream != null
                  ? StreamBuilder<String>(
                      stream: _responseStream,
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? _response,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _response,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
