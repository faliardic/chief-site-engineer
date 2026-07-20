import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

typedef SyntheticAcceptanceRunner = Future<List<String>> Function();

class SyntheticReminderResolution {
  const SyntheticReminderResolution({
    required this.reminder,
    required this.created,
  });

  final MobileReminder reminder;
  final bool created;
}

Future<SyntheticReminderResolution> findOrCreateSyntheticReminder({
  required AgendaApplication agenda,
  required CreateReminderCommand command,
}) async {
  try {
    return SyntheticReminderResolution(
      reminder: await agenda.getReminderDetail(command.id),
      created: false,
    );
  } on AgendaValidationFailure {
    return SyntheticReminderResolution(
      reminder: await agenda.createReminder(command),
      created: true,
    );
  }
}

class SyntheticAcceptanceApp extends StatefulWidget {
  const SyntheticAcceptanceApp({
    required this.title,
    required this.runner,
    super.key,
  });

  final String title;
  final SyntheticAcceptanceRunner runner;

  @override
  State<SyntheticAcceptanceApp> createState() => _SyntheticAcceptanceAppState();
}

class _SyntheticAcceptanceAppState extends State<SyntheticAcceptanceApp> {
  List<String> _lines = const ['acceptance_starting'];

  @override
  void initState() {
    super.initState();
    _runSafely();
  }

  Future<void> _runSafely() async {
    try {
      final lines = await widget.runner();
      if (mounted) {
        setState(
          () => _lines = lines.isEmpty
              ? const ['acceptance_ready']
              : ['acceptance_ready', ...lines],
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _lines = const ['acceptance_failed']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: ListView(
          key: const Key('synthetic-acceptance-status'),
          padding: const EdgeInsets.all(16),
          children: [for (final line in _lines) SelectableText(line)],
        ),
      ),
    );
  }
}
