import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

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
  Chat? _chat;
  bool _isLoading = true;
  String _status = 'Iniciando motor...';

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      // 1. Inicializar Flutter Edge AI con el motor LiteRT-LM
      await FlutterEdgeAi.initialize(
        inferenceEngines: [LiteRtLmEngine()],
      );

      setState(() => _status = 'Descargando modelo Gemma 3 270M...');
      
      // 2. Instalar el modelo desde la red (solo la primera vez)
      await FlutterEdgeAi.installModel(
        modelType: ModelType.gemma3n, // Familia Gemma 3
        fileType: ModelFileType.litertlm,
      ).fromNetwork(
        'https://huggingface.co/google/gemma-3-270m-it-litertlm/resolve/main/gemma-3-270m-it.litertlm'
      ).install();

      setState(() => _status = 'Cargando modelo en memoria...');
      
      // 3. Obtener el modelo activo y crear una sesión de chat
      final model = await FlutterEdgeAi.getActiveModel(maxTokens: 512);
      _chat = await model.createChat();

      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'text': '¡Hola! Soy Gemma 3 270M, tu IA local. ¿En qué puedo ayudarte?'});
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty || _chat == null) return;

    final userText = _textController.text;
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _messages.add({'role': 'assistant', 'text': '...'}); // Placeholder
    });
    _textController.clear();

    try {
      // Enviar el mensaje del usuario al chat
      await _chat!.addQueryChunk(Message.text(text: userText, isUser: true));
      // Generar la respuesta
      final response = await _chat!.generateChatResponse();
      
      setState(() {
        _messages.last['text'] = response;
      });
    } catch (e) {
      setState(() {
        _messages.last['text'] = 'Error al generar: $e';
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