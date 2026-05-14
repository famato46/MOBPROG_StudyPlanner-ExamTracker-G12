import 'package:flutter/material.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corsi'),
      ),
      body: const Center(
        child: Text('Lista Corsi - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigare a form aggiungi corso
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
