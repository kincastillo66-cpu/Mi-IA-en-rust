import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

typedef SaludarFunc = Pointer<Uint8> Function();
typedef Saludar = Pointer<Uint8> Function();

void main() => runApp(const MiIAApp());

class MiIAApp extends StatelessWidget {
  const MiIAApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Rust + Flutter')),
        body: Center(
          child: FutureBuilder<String>(
            future: _cargarSaludo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  snapshot.data ?? 'Error', 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<String> _cargarSaludo() async {
  try {
    final lib = DynamicLibrary.open('librust_brain.so');
    final saludar = lib.lookupFunction<SaludarFunc, Saludar>('saludar_desde_rust');
    final puntero = saludar();
    return puntero.cast<Utf8>().toDartString();
  } catch (e) {
    return 'Aún no conectado: $e';
  }
}