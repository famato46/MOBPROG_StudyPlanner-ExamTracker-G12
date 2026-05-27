import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// Modelli distinti per rispettare la traccia alla lettera
class SessioneStudio {
  String id, titolo, corso, tipo;
  DateTime data;
  bool completato;
  SessioneStudio({required this.id, required this.titolo, required this.corso, required this.tipo, required this.data, this.completato = false});
}

class ObiettivoStudio {
  String id, titolo, descrizione, corso, priorita, note;
  double stimato, effettivo;
  bool completato;
  ObiettivoStudio({required this.id, required this.titolo, this.descrizione = '', required this.corso, required this.priorita, this.stimato = 0.0, this.effettivo = 0.0, this.note = '', this.completato = false});
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});
  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _giorno = DateTime.now();

  final List<SessioneStudio> _sessioni = [
    SessioneStudio(id: '1', titolo: 'Ripasso Funzioni', corso: 'Analisi 1', tipo: 'Ripasso', data: DateTime.now()),
  ];
  final List<ObiettivoStudio> _obiettivi = [
    ObiettivoStudio(id: '1', titolo: 'Finire Lab SQL', descrizione: 'Tutte le query', corso: 'Basi di Dati', priorita: 'Alta', stimato: 6.0),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessioniFiltrate = _sessioni.where((s) => s.data.day == _giorno.day).toList();

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
              Icon(Icons.event_note, size: 20, color: isDark ? Colors.white : AppColors.planning),
              const SizedBox(width: 8),
              Text(
                'Pianificazione & Obiettivi', // Modificato qui
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.planning),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.planning,
          labelColor: isDark ? Colors.white : AppColors.planning,
          tabs: const [Tab(text: 'Pianificazione'), Tab(text: 'Obiettivi')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // VISTA 1: PIANIFICAZIONE
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(label: const Text('Oggi'), selected: _giorno.day == DateTime.now().day, onSelected: (_) => setState(() => _giorno = DateTime.now())),
                    const SizedBox(width: 10),
                    ChoiceChip(label: const Text('Domani'), selected: _giorno.day == DateTime.now().add(const Duration(days: 1)).day, onSelected: (_) => setState(() => _giorno = DateTime.now().add(const Duration(days: 1)))),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: sessioniFiltrate.isEmpty
                    ? const Center(child: Text('Nessuna sessione pianificata.'))
                    : ListView.builder(
                        itemCount: sessioniFiltrate.length,
                        itemBuilder: (ctx, i) {
                          final item = sessioniFiltrate[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: Checkbox(value: item.completato, activeColor: AppColors.planning, onChanged: (v) => setState(() => item.completato = v!)),
                              title: Text(item.titolo, style: TextStyle(decoration: item.completato ? TextDecoration.lineThrough : null)),
                              subtitle: Text('${item.corso} • Tipo: ${item.tipo}'),
                              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _sessioni.remove(item))),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // VISTA 2: OBIETTIVI
          _obiettivi.isEmpty
              ? const Center(child: Text('Nessun obiettivo inserito.'))
              : ListView.builder(
                  itemCount: _obiettivi.length,
                  itemBuilder: (ctx, i) {
                    final item = _obiettivi[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: Checkbox(value: item.completato, activeColor: AppColors.planning, onChanged: (v) => setState(() => item.completato = v!)),
                        title: Text(item.titolo, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.corso} • Prio: ${item.priorita}\nOre: ${item.effettivo}h / ${item.stimato}h\nNote: ${item.note}'),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => _obiettivi.remove(item))),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.planning,
        onPressed: _aggiungiElemento,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _aggiungiElemento() {
    final tC = TextEditingController();
    final cC = TextEditingController();
    String extra = _tabController.index == 0 ? 'Studio' : 'Media';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tabController.index == 0 ? 'Pianifica Sessione' : 'Nuovo Obiettivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tC, decoration: const InputDecoration(labelText: 'Titolo *')),
            TextField(controller: cC, decoration: const InputDecoration(labelText: 'Corso *')),
            DropdownButtonFormField<String>(
              value: extra,
              decoration: InputDecoration(labelText: _tabController.index == 0 ? 'Tipo' : 'Priorità'),
              items: (_tabController.index == 0 
                      ? ['Studio', 'Ripasso', 'Esercitazioni', 'Preparazione esame', 'Lettura di materiale', 'Completamento consegne']
                      : ['Bassa', 'Media', 'Alta'])
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => extra = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () {
              if (tC.text.isEmpty || cC.text.isEmpty) return;
              setState(() {
                if (_tabController.index == 0) {
                  _sessioni.add(SessioneStudio(id: DateTime.now().toString(), titolo: tC.text, corso: cC.text, tipo: extra, data: _giorno));
                } else {
                  _obiettivi.add(ObiettivoStudio(id: DateTime.now().toString(), titolo: tC.text, corso: cC.text, priorita: extra));
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