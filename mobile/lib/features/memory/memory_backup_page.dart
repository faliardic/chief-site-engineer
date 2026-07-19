import 'package:chief_site_engineer/application/mobile_backup_application.dart';
import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
import 'package:flutter/material.dart';

class MemoryBackupPage extends StatefulWidget {
  const MemoryBackupPage({required this.backup, super.key});

  final MobileBackupApplication backup;

  @override
  State<MemoryBackupPage> createState() => _MemoryBackupPageState();
}

class _MemoryBackupPageState extends State<MemoryBackupPage> {
  final _backupPassword = TextEditingController();
  final _backupPasswordConfirmation = TextEditingController();
  final _restorePassword = TextEditingController();

  MobileBackupCreationResult? _created;
  MobileBackupSummary? _lastBackup;
  MobileBackupPreflight? _preflight;
  String? _selectedPackage;
  String? _backupMessage;
  String? _restoreMessage;
  bool _backupBusy = false;
  bool _restoreBusy = false;
  bool _replacementAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  @override
  void dispose() {
    _backupPassword.dispose();
    _backupPasswordConfirmation.dispose();
    _restorePassword.dispose();
    super.dispose();
  }

  Future<void> _loadLastBackup() async {
    try {
      final summary = await widget.backup.lastSuccessfulBackup();
      if (mounted) setState(() => _lastBackup = summary);
    } on Object {
      // A malformed optional summary never prevents a fresh backup.
    }
  }

  Future<void> _createBackup() async {
    if (_backupBusy || _restoreBusy) return;
    setState(() {
      _backupBusy = true;
      _backupMessage = null;
    });
    try {
      final result = await widget.backup.createBackup(
        CreateMobileBackupCommand(
          password: _backupPassword.text,
          passwordConfirmation: _backupPasswordConfirmation.text,
        ),
      );
      if (!mounted) return;
      _backupPassword.clear();
      _backupPasswordConfirmation.clear();
      setState(() {
        _created = result;
        _lastBackup = result.summary;
        _backupMessage = 'Yedek güvenle oluşturuldu.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _backupMessage = _safeMessage(error));
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _shareBackup() async {
    final created = _created;
    if (created == null || _backupBusy || _restoreBusy) return;
    setState(() {
      _backupBusy = true;
      _backupMessage = null;
    });
    try {
      await widget.backup.shareBackup(created.absolutePath);
      if (mounted) setState(() => _backupMessage = 'Paylaşım ekranı açıldı.');
    } on Object catch (error) {
      if (mounted) setState(() => _backupMessage = _safeMessage(error));
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _pickPackage() async {
    if (_backupBusy || _restoreBusy) return;
    setState(() {
      _restoreBusy = true;
      _restoreMessage = null;
    });
    try {
      final selected = await widget.backup.pickBackupPackage();
      if (!mounted || selected == null) return;
      setState(() {
        _selectedPackage = selected;
        _preflight = null;
        _replacementAcknowledged = false;
        _restoreMessage = 'Yedek seçildi. Ön kontrolü başlatın.';
      });
    } on Object catch (error) {
      if (mounted) setState(() => _restoreMessage = _safeMessage(error));
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  Future<void> _preflightPackage() async {
    final selected = _selectedPackage;
    if (selected == null || _backupBusy || _restoreBusy) return;
    setState(() {
      _restoreBusy = true;
      _restoreMessage = null;
      _preflight = null;
      _replacementAcknowledged = false;
    });
    try {
      final preflight = await widget.backup.preflightBackup(
        selected,
        _restorePassword.text,
      );
      if (!mounted) return;
      setState(() {
        _preflight = preflight;
        _restoreMessage = 'Ön kontrol başarılı. Yedek geri yüklenebilir.';
      });
    } on Object catch (error) {
      if (mounted) setState(() => _restoreMessage = _safeMessage(error));
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  Future<void> _askFinalRestoreConfirmation() async {
    final preflight = _preflight;
    if (preflight == null ||
        !_replacementAcknowledged ||
        _backupBusy ||
        _restoreBusy) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tam geri yükleme'),
        content: const Text(
          'Mevcut mobil hafıza tamamen değiştirilecek. İşlemden önce otomatik '
          'bir güvenlik yedeği alınır; kayıtlar birleştirilmez.',
        ),
        actions: [
          TextButton(
            key: const Key('restore-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('restore-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tamamen değiştir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _restorePackage(preflight);
  }

  Future<void> _restorePackage(MobileBackupPreflight preflight) async {
    setState(() {
      _restoreBusy = true;
      _restoreMessage = null;
    });
    try {
      final result = await widget.backup.restoreBackup(
        RestoreMobileBackupCommand(
          packagePath: preflight.packagePath,
          password: _restorePassword.text,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );
      if (!mounted) return;
      _restorePassword.clear();
      setState(() {
        _preflight = null;
        _replacementAcknowledged = false;
        _restoreMessage =
            'Geri yükleme tamamlandı. Şema ${result.activeSchemaVersion} etkin.';
      });
    } on Object catch (error) {
      if (mounted) setState(() => _restoreMessage = _safeMessage(error));
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  String _safeMessage(Object error) => switch (error) {
    MobileBackupFailure() => error.userMessage,
    _ => 'İşlem güvenle tamamlanamadı. Veriler değiştirilmedi.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hafıza ve Yedekleme')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tam mobil yedek', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'SQLite kayıtları ve etkin Beton eki dosyaları, parola korumalı '
              '.csebackup paketi olarak hazırlanır. Parola saklanmaz.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('backup-password'),
              controller: _backupPassword,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Yedek parolası',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('backup-password-confirmation'),
              controller: _backupPasswordConfirmation,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Parolayı doğrula',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const Key('create-backup'),
                onPressed: _backupBusy || _restoreBusy ? null : _createBackup,
                icon: _backupBusy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.archive_outlined),
                label: const Text('Yedek oluştur'),
              ),
            ),
            if (_created != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const Key('share-backup'),
                  onPressed: _backupBusy || _restoreBusy ? null : _shareBackup,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Yedeği paylaş / kaydet'),
                ),
              ),
            ],
            if (_backupMessage != null) ...[
              const SizedBox(height: 8),
              Text(_backupMessage!, key: const Key('backup-message')),
            ],
            if (_lastBackup case final last?) ...[
              const SizedBox(height: 12),
              _SummaryCard(title: 'Son başarılı yedek', summary: last),
            ],
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),
            Text('Tam geri yükleme', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Geri yükleme mevcut mobil hafızayı birleştirmeden tamamen '
              'değiştirir. Ön kontrol aktif veriye dokunmaz.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('pick-backup'),
                onPressed: _backupBusy || _restoreBusy ? null : _pickPackage,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(
                  _selectedPackage == null ? 'Yedek seç' : 'Başka yedek seç',
                ),
              ),
            ),
            if (_selectedPackage != null) ...[
              const SizedBox(height: 8),
              const Text('Bir .csebackup dosyası seçildi.'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('restore-password'),
                controller: _restorePassword,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Yedek parolası',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton.tonalIcon(
                  key: const Key('preflight-backup'),
                  onPressed: _backupBusy || _restoreBusy
                      ? null
                      : _preflightPackage,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Ön kontrolü çalıştır'),
                ),
              ),
            ],
            if (_preflight case final preflight?) ...[
              const SizedBox(height: 12),
              _PreflightCard(preflight: preflight),
              CheckboxListTile(
                key: const Key('replacement-acknowledgement'),
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                value: _replacementAcknowledged,
                onChanged: _restoreBusy
                    ? null
                    : (value) => setState(
                        () => _replacementAcknowledged = value ?? false,
                      ),
                title: const Text(
                  'Mevcut mobil hafızanın tamamen değişeceğini anlıyorum.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const Key('restore-backup'),
                  onPressed:
                      _replacementAcknowledged && !_restoreBusy && !_backupBusy
                      ? _askFinalRestoreConfirmation
                      : null,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Tam geri yüklemeyi başlat'),
                ),
              ),
            ],
            if (_restoreMessage != null) ...[
              const SizedBox(height: 8),
              Text(_restoreMessage!, key: const Key('restore-message')),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.summary});

  final String title;
  final MobileBackupSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Oluşturma (UTC): ${summary.createdAtUtc}'),
            Text('Ek dosyası: ${summary.attachmentCount}'),
            Text('Paket boyutu: ${_formatBytes(summary.packageByteSize)}'),
            Text('Mobil şema: ${summary.mobileSchemaVersion}'),
          ],
        ),
      ),
    );
  }
}

class _PreflightCard extends StatelessWidget {
  const _PreflightCard({required this.preflight});

  final MobileBackupPreflight preflight;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ön kontrol özeti',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Oluşturma (UTC): ${preflight.manifest.createdAtUtc}'),
            Text('Ek dosyası: ${preflight.manifest.attachments.length}'),
            Text('Paket boyutu: ${_formatBytes(preflight.packageByteSize)}'),
            Text('Etkinleşecek şema: ${preflight.migratedSchemaVersion}'),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
