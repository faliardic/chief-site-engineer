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

class AgendaPhotoViewerPage extends StatelessWidget {
  const AgendaPhotoViewerPage({
    required this.agenda,
    required this.photo,
    super.key,
  });

  final AgendaApplication agenda;
  final AgendaLogPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajanda fotoğrafı')),
      body: FutureBuilder<StoredAttachmentContent>(
        future: agenda.readAgendaPhoto(photo.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _Diagnostic(photo: photo);
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
                  child: Text(
                    '${photo.originalFileName} • ${photo.mimeType} • '
                    '${photo.byteSize} byte • ${photo.sha256.substring(0, 12)}…',
                    textAlign: TextAlign.center,
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
