import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class ConcreteDestinationPage extends StatelessWidget {
  const ConcreteDestinationPage({
    required this.concrete,
    required this.agenda,
    required this.attachments,
    required this.initialProjectId,
    required this.initialIstanbulDay,
    this.projectLocations,
    super.key,
  });

  final ConcreteApplication concrete;
  final AgendaApplication agenda;
  final SafeAttachmentPicker attachments;
  final String initialProjectId;
  final String initialIstanbulDay;
  final ProjectLocationApplication? projectLocations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beton paketleri')),
      body: ConcretePage(
        concrete: concrete,
        agenda: agenda,
        attachments: attachments,
        projectLocations: projectLocations,
        initialProjectId: initialProjectId,
        initialIstanbulDay: initialIstanbulDay,
      ),
    );
  }
}
