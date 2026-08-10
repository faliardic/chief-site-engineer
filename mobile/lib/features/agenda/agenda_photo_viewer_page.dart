import 'dart:typed_data';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

class AgendaPhotoThumbnail extends StatefulWidget {
  const AgendaPhotoThumbnail({
    required this.agenda,
    required this.photo,
    super.key,
  });

  final AgendaApplication agenda;
  final AgendaLogPhoto photo;

  @override
  State<AgendaPhotoThumbnail> createState() => _AgendaPhotoThumbnailState();
}

class _AgendaPhotoThumbnailState extends State<AgendaPhotoThumbnail> {
  late Future<StoredAttachmentContent> _content;

  @override
  void initState() {
    super.initState();
    _content = widget.agenda.readAgendaPhoto(widget.photo.id);
  }

  @override
  void didUpdateWidget(covariant AgendaPhotoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agenda != widget.agenda ||
        oldWidget.photo.id != widget.photo.id) {
      _content = widget.agenda.readAgendaPhoto(widget.photo.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoredAttachmentContent>(
      future: _content,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(
            color: Colors.black12,
            child: Icon(Icons.photo_outlined),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            Uint8List.fromList(snapshot.requireData.bytes),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }
}

class AgendaPhotoViewerPage extends StatefulWidget {
  const AgendaPhotoViewerPage({
    required this.agenda,
    required this.photo,
    super.key,
  });

  final AgendaApplication agenda;
  final AgendaLogPhoto photo;

  @override
  State<AgendaPhotoViewerPage> createState() => _AgendaPhotoViewerPageState();
}

class _AgendaPhotoViewerPageState extends State<AgendaPhotoViewerPage> {
  late Future<StoredAttachmentContent> _content;
  bool _exporting = false;
  bool _operationFailed = false;
  String? _operationMessage;

  AgendaPhotoExportApplication? get _exporter {
    final agenda = widget.agenda;
    return agenda is AgendaPhotoExportApplication
        ? agenda as AgendaPhotoExportApplication
        : null;
  }

  @override
  void initState() {
    super.initState();
    _content = widget.agenda.readAgendaPhoto(widget.photo.id);
  }

  @override
  void didUpdateWidget(covariant AgendaPhotoViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agenda != widget.agenda ||
        oldWidget.photo.id != widget.photo.id) {
      _content = widget.agenda.readAgendaPhoto(widget.photo.id);
      _operationMessage = null;
      _operationFailed = false;
    }
  }

  Future<void> _save() async {
    final exporter = _exporter;
    if (exporter == null || _exporting) return;
    setState(() {
      _exporting = true;
      _operationMessage = null;
      _operationFailed = false;
    });
    try {
      final saved = await exporter.saveAgendaPhoto(widget.photo.id);
      if (!mounted) return;
      setState(() {
        _operationMessage = saved
            ? 'Fotoğraf cihaza kaydedildi.'
            : 'Kaydetme iptal edildi.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _operationFailed = true;
        _operationMessage =
            'Fotoğraf güvenli biçimde kaydedilemedi. Kayıt değişmedi.';
      });
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share() async {
    final exporter = _exporter;
    if (exporter == null || _exporting) return;
    setState(() {
      _exporting = true;
      _operationMessage = null;
      _operationFailed = false;
    });
    try {
      await exporter.shareAgendaPhoto(widget.photo.id);
      if (!mounted) return;
      setState(() => _operationMessage = 'Paylaşım ekranı açıldı.');
    } on Object {
      if (!mounted) return;
      setState(() {
        _operationFailed = true;
        _operationMessage =
            'Fotoğraf güvenli biçimde paylaşılamadı. Kayıt değişmedi.';
      });
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajanda fotoğrafı')),
      body: FutureBuilder<StoredAttachmentContent>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _Diagnostic(photo: widget.photo);
          }
          final value = snapshot.requireData;
          return Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 6,
                    child: Center(
                      child: Image.memory(
                        Uint8List.fromList(value.bytes),
                        key: const Key('agenda-full-photo'),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_exporter != null) ...[
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('agenda-photo-save'),
                              onPressed: _exporting ? null : _save,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Cihaza kaydet'),
                            ),
                            FilledButton.icon(
                              key: const Key('agenda-photo-share'),
                              onPressed: _exporting ? null : _share,
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Paylaş'),
                            ),
                          ],
                        ),
                        if (_exporting) ...[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(
                            key: Key('agenda-photo-export-progress'),
                          ),
                        ],
                        if (_operationMessage case final message?) ...[
                          const SizedBox(height: 8),
                          Text(
                            message,
                            key: const Key('agenda-photo-export-message'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _operationFailed
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                      Text(
                        '${widget.photo.originalFileName} • '
                        '${widget.photo.mimeType} • '
                        '${widget.photo.byteSize} byte • '
                        '${widget.photo.sha256.substring(0, 12)}…',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Diagnostic extends StatelessWidget {
  const _Diagnostic({required this.photo});

  final AgendaLogPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Fotoğraf güvenli biçimde açılamadı. Kayıt silinmedi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tanı: ${photo.integrity.name} • ${photo.mimeType} • '
              '${photo.sha256.substring(0, 12)}…',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
