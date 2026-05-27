import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// 1. Modello Dati Essenziale richiesto dalla traccia
class AttivitaStudio {
  String id, titolo, corso, tipo, priorita;
  DateTime data;
  double stimato, effettivo;
  bool completato;

  AttivitaStudio({
    required this.id, required this.titolo, required this.corso, 
    required this.tipo, required this.priorita, required this.data,
    this.stimato = 2.0, this.effettivo = 0.0, this.completato = false,
  });
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _giornoSelezionato = DateTime.now();
  
  // Dati minimi per la demo d'esame
  final List<AttivitaStudio> _attivita = [
    AttivitaStudio(id: '1', titolo: 'Ripasso Teoremi', corso: 'Analisi 1', tipo: 'Ripasso', priorita: 'Alta', data: DateTime.now()),
    AttivitaStudio(id: '2', titolo: 'Esercizi SQL', corso: 'Basi di Dati', tipo: 'Esercitazione', priorita: 'Media', data: DateTime.now()),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listafiltrata = _attivita.where((a) => a.data.day == _giornoSelezionato.day).toList();

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_note, 
                size: 20, 
                color: isDark ? Colors.white : AppColors.planning,
              ),
              const SizedBox(width: 8),
              Text(
                'Pianificazione Studio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.planning,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Selettore Giornaliero Compatto (Oggi / Domani) per la logica di pianificazione
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(label: const Text('Oggi'), selected: _giornoSelezionato.day == DateTime.now().day, onSelected: (_) => setState(() => _giornoSelezionato = DateTime.now())),
              const SizedBox(width: 10),
              ChoiceChip(label: const Text('Domani'), selected: _giornoSelezionato.day == DateTime.now().add(const Duration(days: 1)).day, onSelected: (_) => setState(() => _giornoSelezionato = DateTime.now().add(const Duration(days: 1)))),
            ],
          ),
          const Divider(),
          // Lista delle Attività (Visualizzazione e Gestione Stato)
          Expanded(
            child: listafiltrata.isEmpty 
              ? const Center(child: Text('Nessuna attività pianificata.'))
              : ListView.builder(
                  itemCount: listafiltrata.length,
                  itemBuilder: (context, idx) {
                    final item = listafiltrata[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: Checkbox(value: item.completato, activeColor: AppColors.planning, onChanged: (v) => setState(() => item.completato = v!)),
                        title: Text(item.titolo, style: TextStyle(decoration: item.completato ? TextDecoration.lineThrough : null)),
                        subtitle: Text('${item.corso} • ${item.tipo} • Prio: ${item.priorita} • ${item.effettivo}h/${item.stimato}h'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _apriDialog(item: item)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _attivita.remove(item))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.planning,
        onPressed: () => _apriDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Dialogo unico, leggero e compatto per Aggiungere e Modificare (CRUD)
  void _apriDialog({AttivitaStudio? item}) {
    final isModifica = item != null;
    final tController = TextEditingController(text: isModifica ? item.titolo : '');
    final cController = TextEditingController(text: isModifica ? item.corso : '');
    String tipo = isModifica ? item.tipo : 'Studio';
    String prio = isModifica ? item.priorita : 'Media';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isModifica ? 'Modifica Attività' : 'Nuova Attività'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tController, decoration: const InputDecoration(labelText: 'Titolo')),
            TextField(controller: cController, decoration: const InputDecoration(labelText: 'Corso')),
            DropdownButtonFormField<String>(value: tipo, items: ['Studio', 'Ripasso', 'Esercitazione', 'Lettura'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => tipo = v!),
            DropdownButtonFormField<String>(value: prio, items: ['Bassa', 'Media', 'Alta'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => prio = v!),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              if (tController.text.isEmpty) return;
              setState(() {
                if (isModifica) {
                  item.titolo = tController.text; item.corso = cController.text; item.tipo = tipo; item.priorita = prio;
                } else {
                  _attivita.add(AttivitaStudio(id: DateTime.now().toString(), titolo: tController.text, corso: cController.text, tipo: tipo, priorita: prio, data: _giornoSelezionato));
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}