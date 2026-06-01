![Logo](https://github.com/user-attachments/assets/f7bc6087-620d-4b8e-884c-0d16f75921e6) ![Titolo](https://github.com/user-attachments/assets/fba94301-2675-4c23-aa42-552907530e38)

# UniPath — Study Planner & Exam Tracker
### Gruppo 12 · Mobile Programming A.A. 2025/2026 · Università degli Studi di Salerno

UniPath è un'applicazione mobile sviluppata in Flutter per aiutare lo studente universitario a organizzare lo studio, pianificare le attività, monitorare gli esami e tenere traccia dei propri progressi accademici.

---

## Funzionalità principali

- **Gestione Corsi** — CRUD completo per i corsi universitari con nome, docente, CFU, semestre, stato di avanzamento e voto desiderato.
- **Esami e Scadenze** — Inserimento e monitoraggio di appelli, consegne e scadenze con badge di urgenza, filtri per tipologia e priorità.
- **Pianificazione Studio** — Calendario mensile interattivo con vista giornaliera e settimanale per organizzare le sessioni di studio.
- **Attività e Obiettivi** — To-do list con priorità, scadenze, tempo stimato e tempo effettivo impiegato.
- **Timer Pomodoro** — Sessioni di studio focalizzato da 25 minuti con salvataggio automatico del tempo nel database al completamento.
- **Statistiche** — Grafici a torta e a barre sul tempo di studio, KPI della carriera e simulatore interattivo del voto di laurea.
- **Suggerimenti Automatici** — La Dashboard genera consigli di studio basati sugli esami programmati nei 14 giorni successivi.
- **Dark Mode** — Tema scuro persistente, attivabile dalla Dashboard e salvato tra le sessioni.

---

## Installazione ed esecuzione

```bash
# Clona il repository
git clone https://github.com/famato46/UniPath_MOBPOG_G12

# Installa le dipendenze
flutter pub get

# Avvia l'app
flutter run
```

Requisiti: Flutter >= 3.38.4, Dart >= 3.11. Supporta Android (API 21+) e iOS (14.0+).

---

## Stack tecnologico

| Tecnologia | Utilizzo |
|---|---|
| **Flutter 3.38.4 / Dart 3.11** | Framework principale |
| **SQLite (sqflite)** | Persistenza locale strutturata |
| **Provider** | State management globale |
| **SharedPreferences** | Persistenza preferenze utente |
| **fl_chart** | Grafici interattivi |
| **intl** | Formattazione date in italiano |
| **uuid** | Generazione ID univoci |

---

## Struttura del progetto

```text
lib/
├── database/
│   └── database_helper.dart
├── models/
│   ├── course.dart
│   ├── exam.dart
│   ├── study_session.dart
│   └── task.dart
├── providers/
│   ├── planner_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── main_screen.dart
│   ├── home_screen.dart
│   ├── courses_screen.dart
│   ├── course_detail_screen.dart
│   ├── course_form_screen.dart
│   ├── exams_screen.dart
│   ├── exam_detail_screen.dart
│   ├── exam_form_screen.dart
│   ├── planning_screen.dart
│   ├── session_form_screen.dart
│   ├── task_form_screen.dart
│   └── stats_screen.dart
├── utils/
│   └── app_colors.dart
├── widgets/
│   ├── form.dart
│   ├── planning_calendar.dart
│   ├── planning_filter_section.dart
│   ├── planning_task_picker.dart
└── main.dart
```

---

## Componenti del Gruppo 12

| Nome | Matricola |
|---|---|
| Amato Francesca Gaia | 0612708845 |
| Di Vito Andrea | 0612709214 |
| Iasevoli Lucia | 0612709030 |
| Monetta Lucia | 0612709620 |
| Muccio Matteo | 0612709614 |

---

*Docente: prof. Francesco Cauteruccio*
