import 'dart:async';

import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.backupPageBuilder,
    required this.fileDataHealthPageBuilder,
    super.key,
  });

  final WidgetBuilder? backupPageBuilder;
  final WidgetBuilder? fileDataHealthPageBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        child: ListView(
          key: const Key('settings-destinations'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SettingsDestinationTile(
              key: const Key('settings-memory-backup'),
              icon: Icons.settings_backup_restore_rounded,
              label: 'Hafıza ve Yedekleme',
              description: 'Yedekleme ve kurtarma seçenekleri',
              destinationBuilder: backupPageBuilder,
            ),
            _SettingsDestinationTile(
              key: const Key('settings-file-data-health'),
              icon: Icons.health_and_safety_outlined,
              label: 'Dosya ve Veri Sağlığı',
              description: 'Dosya bütünlüğü ve veri sağlığı denetimi',
              destinationBuilder: fileDataHealthPageBuilder,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDestinationTile extends StatelessWidget {
  const _SettingsDestinationTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.destinationBuilder,
    super.key,
  });

  final IconData icon;
  final String label;
  final String description;
  final WidgetBuilder? destinationBuilder;

  void _open(BuildContext context) {
    final builder = destinationBuilder;
    if (builder == null) return;
    unawaited(
      Navigator.of(
        context,
      ).push<void>(MaterialPageRoute<void>(builder: builder)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = destinationBuilder != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      hint: description,
      onTap: enabled ? () => _open(context) : null,
      child: ExcludeSemantics(
        child: ListTile(
          minTileHeight: 64,
          leading: Icon(icon),
          title: Text(label),
          subtitle: Text(description),
          enabled: enabled,
          onTap: enabled ? () => _open(context) : null,
        ),
      ),
    );
  }
}
