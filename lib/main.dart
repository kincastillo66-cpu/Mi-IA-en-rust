import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

// 1. Definimos las firmas de las funciones de Rust
typedef ProcesarTextoNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef ProcesarTextoDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef LiberarMemoriaNative = Void Function(Pointer<Utf8>);
typedef LiberarMemoriaDart = void Function(Pointer<Utf8>);

void main() => runApp(const MiIAApp());

class MiIAApp extends StatelessWidget {
  const MiIAApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi IA en Rust',
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
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'text': '¡Hola! Soy tu interfaz en Flutter. El cerebro en Rust está conectado y listo. Escríbeme algo.'}
  ];
  
  DynamicLibrary? _lib;
  ProcesarTextoDart? _procesarTexto;
  LiberarMemoriaDart? _liberarMemoria;

  @override
  void initState() {
    super.initState();
    _cargarCerebroRust();
  }

  void _cargarCerebroRust() {
    try {
      _lib = DynamicLibrary.open('librust_brain.so');
      _procesarTexto = _lib!.lookupFunction<ProcesarTextoNative, ProcesarTextoDart>('procesar_texto');
      _liberarMemoria = _lib!.lookupFunction<LiberarMemoriaNative, LiberarMemoriaDart>('liberar_memoria');
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Error crítico al cargar Rust: $e'});
      });
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty || _procesarTexto == null) return;

    final userText = _textController.text;
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
    });
    _textController.clear();

    try {
      // 2. Convertimos el texto de Dart a un puntero de C
      final inputPtr = userText.toNativeUtf8();
      
      // 3. Llamamos a Rust
      final resultPtr = _procesarTexto!(inputPtr);
      
      // 4. Convertimos la respuesta de Rust a texto de Dart
      final respuestaRust = resultPtr.toDartString();
      
      // 5. LIMPIEZA: Liberamos la memoria para no colapsar los 2GB de RAM
      malloc.free(inputPtr);
      _liberarMemoria!(resultPtr);

      setState(() {
        _messages.add({'role': 'assistant', 'text': respuestaRust});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Error al comunicarse con Rust: $e'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat con Rust')),
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
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}