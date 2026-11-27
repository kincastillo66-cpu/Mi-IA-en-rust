import 'dart:io';
import 'package:flutter/material.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MiIAApp());

class MiIAApp extends StatelessWidget {
  const MiIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi IA Modular',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  LlamaModel? _model;
  bool _isLoading = true;
  String _status = 'Iniciando motor...';

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelPath = '${dir.path}/qwen.gguf';
      final file = File(modelPath);

      if (!await file.exists()) {
        setState(() => _status = 'Descargando cerebro (350MB)...');
        // Descarga el modelo Qwen 0.5B
        final url = Uri.parse('https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf');
        final response = await http.get(url);
        await file.writeAsBytes(response.bodyBytes);
      }

      setState(() => _status = 'Cargando cerebro en RAM...');
      _model = LlamaModel(modelPath, nCtx: 1024, nThreads: 2); // 2 hilos para no colapsar el teléfono
      
      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'text': '¡Hola! Mi cerebro Qwen está listo. ¿De qué hablamos?'});
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty || _model == null) return;

    final userText = _textController.text;
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _messages.add({'role': 'assistant', 'text': 'Pensando...'});
    });
    _textController.clear();

    try {
      // Prompt básico para el modelo
      final prompt = '<|im_start|>user\n$userText<|im_end|>\n<|im_start|>assistant\n';
      final response = await _model!.generate(prompt, maxTokens: 150);
      
      setState(() {
        _messages.removeLast();
        _messages.add({'role': 'assistant', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add({'role': 'assistant', 'text': 'Error al generar: $e'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_status, style: const TextStyle(fontSize: 16)),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aviso: La primera vez tardará unos minutos descargando el modelo. No cierres la app.', textAlign: TextAlign.center),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi IA Modular (Local)')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg['text'] ?? '', style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...', border: OutlineInputBorder()),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}