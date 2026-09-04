import 'dart:async';

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

class ActiveProjectControl extends StatelessWidget {
  const ActiveProjectControl({
    required this.label,
    required this.projects,
    required this.onSelected,
    super.key,
  });

  final String label;
  final List<MobileProject> projects;
  final ValueChanged<String> onSelected;

  Future<void> _choose(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('active-project-chooser'),
        title: const Text('Proje seç'),
        content: SizedBox(
          width: 360,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.5,
            ),
            child: projects.isEmpty
                ? const Text('Seçilebilir aktif proje yok.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final project in projects)
                        ListTile(
                          key: ValueKey('active-project-option-${project.id}'),
                          title: Text(project.name),
                          onTap: () =>
                              Navigator.of(dialogContext).pop(project.id),
                        ),
                    ],
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
        ],
      ),
    );
    if (context.mounted && selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Tooltip(
          message: 'Aktif proje: $label',
          child: Semantics(
            container: true,
            label: 'Aktif proje: $label',
            child: ActionChip(
              key: const Key('active-project-indicator'),
              onPressed: () => unawaited(_choose(context)),
              avatar: const Icon(Icons.apartment_rounded, size: 18),
              label: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(context).width * 0.35)
                      .clamp(64.0, 132.0)
                      .toDouble(),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              visualDensity: VisualDensity.standard,
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
      ),
    );
  }
}
