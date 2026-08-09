import 'dart:typed_data';

import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:flutter/material.dart';

class ConcreteAttachmentViewerPage extends StatelessWidget {
  const ConcreteAttachmentViewerPage({
    required this.concrete,
    required this.attachment,
    super.key,
  });

  final ConcreteApplication concrete;
  final ConcreteAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(attachment.evidenceType.label)),
      body:
          attachment.mimeType == 'image/jpeg' ||
              attachment.mimeType == 'image/png'
          ? _ImageDocument(concrete: concrete, attachment: attachment)
          : _ExternalDocument(concrete: concrete, attachment: attachment),
    );
  }
}

class _ImageDocument extends StatelessWidget {
  const _ImageDocument({required this.concrete, required this.attachment});

  final ConcreteApplication concrete;
  final ConcreteAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoredAttachmentContent>(
      future: concrete.readAttachment(attachment.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _Diagnostic(attachment: attachment);
        }
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
                      Uint8List.fromList(snapshot.requireData.bytes),
                      key: const Key('concrete-full-image'),
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
            _Metadata(attachment: attachment),
          ],
        );
      },
    );
  }
}

class _ExternalDocument extends StatefulWidget {
  const _ExternalDocument({required this.concrete, required this.attachment});

  final ConcreteApplication concrete;
  final ConcreteAttachment attachment;

  @override
  State<_ExternalDocument> createState() => _ExternalDocumentState();
}

class _ExternalDocumentState extends State<_ExternalDocument> {
  bool _opening = false;
  String? _error;

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await widget.concrete.openAttachment(widget.attachment.id);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Dosya güvenli cihaz uygulamasında açılamadı.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachment.integrity != ConcreteAttachmentIntegrity.ok) {
      return _Diagnostic(attachment: widget.attachment);
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_externalIcon(widget.attachment.mimeType), size: 72),
            const SizedBox(height: 12),
            Text(
              widget.attachment.originalFileName,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: widget.attachment.mimeType == 'application/pdf'
                  ? const Key('open-concrete-pdf')
                  : const Key('open-concrete-media'),
              onPressed: _opening ? null : _open,
              icon: const Icon(Icons.open_in_new),
              label: Text(
                _opening ? 'Açılıyor…' : 'Güvenli cihaz uygulamasında aç',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            _Metadata(attachment: widget.attachment),
          ],
        ),
      ),
    );
  }
}

IconData _externalIcon(String mimeType) {
  if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (mimeType.startsWith('video/')) return Icons.video_file_outlined;
  if (mimeType.startsWith('audio/')) return Icons.audio_file_outlined;
  return Icons.insert_drive_file_outlined;
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.attachment});

  final ConcreteAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${attachment.mimeType} • ${attachment.byteSize} byte • '
          '${attachment.sha256.substring(0, 12)}… • '
          '${attachment.integrity.label}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Diagnostic extends StatelessWidget {
  const _Diagnostic({required this.attachment});

  final ConcreteAttachment attachment;

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
              'Dosya eksik, bozuk veya MIME/hash doğrulaması başarısız. '
              'Kayıt değiştirilmedi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tanı: ${attachment.integrity.name} • ${attachment.mimeType} • '
              '${attachment.sha256.substring(0, 12)}…',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
