import 'package:flutter/material.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esami e Scadenze'),
      ),
      body: const Center(
        child: Text('Lista Esami - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigare a form aggiungi esame
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
