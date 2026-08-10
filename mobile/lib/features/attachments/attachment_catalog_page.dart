import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:flutter/material.dart';

class AttachmentCatalogPage extends StatefulWidget {
  const AttachmentCatalogPage({
    required this.catalog,
    this.initialProjectId,
    this.selectionSourceType,
    this.selectionSourceId,
    this.allowedMimeTypes,
    this.title = 'Dosya Kataloğu',
    super.key,
  });

  final AttachmentCatalogApplication catalog;
  final String? initialProjectId;
  final AttachmentCatalogSourceType? selectionSourceType;
  final String? selectionSourceId;
  final Set<String>? allowedMimeTypes;
  final String title;

  bool get isSelection =>
      selectionSourceType != null && selectionSourceId != null;

  @override
  State<AttachmentCatalogPage> createState() => _AttachmentCatalogPageState();
}

class _AttachmentCatalogPageState extends State<AttachmentCatalogPage> {
  late Future<_CatalogView> _view;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;
    _reload();
  }

  void _reload() {
    _view = _load();
  }

  Future<_CatalogView> _load() async {
    final projects = await widget.catalog.listProjects();
    var selected = _selectedProjectId;
    if (selected == null && projects.isNotEmpty) selected = projects.first.id;
    final items = selected == null
        ? const <ProjectAttachmentCatalogItem>[]
        : await widget.catalog.listProjectAttachments(selected);
    return _CatalogView(
      projects: projects,
      selectedProjectId: selected,
      items: items,
    );
  }

  void _selectProject(String? projectId) {
    if (projectId == null || projectId == _selectedProjectId) return;
    setState(() {
      _selectedProjectId = projectId;
      _reload();
    });
  }

  bool _eligible(ProjectAttachmentCatalogItem item) {
    if (!widget.isSelection ||
        item.integrity != ManagedAttachmentIntegrity.healthy) {
      return false;
    }
    final allowed = widget.allowedMimeTypes;
    if (allowed != null && !allowed.contains(item.mimeType)) return false;
    return !item.isActivelyLinkedTo(
      widget.selectionSourceType!,
      widget.selectionSourceId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            key: const Key('refresh-attachment-catalog'),
            tooltip: 'Kataloğu yenile',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_CatalogView>(
        future: _view,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _CatalogMessage(
              key: Key('attachment-catalog-error'),
              icon: Icons.warning_amber_rounded,
              message: 'Dosya kataloğu güvenli biçimde açılamadı.',
            );
          }
          final view = snapshot.requireData;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: DropdownButtonFormField<String>(
                  key: const Key('attachment-catalog-project-selector'),
                  initialValue: view.selectedProjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Proje',
                    border: OutlineInputBorder(),
                  ),
                  items: view.projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.initialProjectId == null
                      ? _selectProject
                      : null,
                ),
              ),
              Expanded(
                child: view.projects.isEmpty
                    ? const _CatalogMessage(
                        icon: Icons.folder_off_outlined,
                        message: 'Aktif proje bulunamadı.',
                      )
                    : view.items.isEmpty
                    ? const _CatalogMessage(
                        key: Key('attachment-catalog-empty'),
                        icon: Icons.attach_file_outlined,
                        message: 'Bu projede kayıtlı dosya yok.',
                      )
                    : ListView.builder(
                        key: const Key('attachment-catalog-list'),
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: view.items.length,
                        itemBuilder: (context, index) {
                          final item = view.items[index];
                          final eligible = _eligible(item);
                          return Card(
                            child: ListTile(
                              key: Key(
                                'attachment-catalog-item-${item.physicalAttachmentId}',
                              ),
                              minVerticalPadding: 12,
                              leading: Icon(
                                item.integrity ==
                                        ManagedAttachmentIntegrity.healthy
                                    ? Icons.verified_outlined
                                    : Icons.warning_amber_rounded,
                              ),
                              title: Text(item.displayFileName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.mimeType} • ${item.byteSize} byte • '
                                    '${_integrityLabel(item.integrity)}',
                                  ),
                                  const SizedBox(height: 4),
                                  for (final link in item.links)
                                    Text(
                                      '${link.sourceLabel} • ${link.role}'
                                      '${link.isActive ? '' : ' • Arşivli'}',
                                      key: Key(
                                        'attachment-catalog-link-${link.id}',
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: widget.isSelection
                                  ? Icon(
                                      eligible
                                          ? Icons.add_link_rounded
                                          : Icons.block_outlined,
                                    )
                                  : Text('${item.links.length} bağ'),
                              onTap: widget.isSelection && eligible
                                  ? () => Navigator.pop(context, item)
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogView {
  const _CatalogView({
    required this.projects,
    required this.selectedProjectId,
    required this.items,
  });

  final List<AttachmentCatalogProject> projects;
  final String? selectedProjectId;
  final List<ProjectAttachmentCatalogItem> items;
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _integrityLabel(ManagedAttachmentIntegrity value) => switch (value) {
  ManagedAttachmentIntegrity.healthy => 'Sağlıklı',
  ManagedAttachmentIntegrity.missingFile => 'Dosya eksik',
  ManagedAttachmentIntegrity.sizeMismatch => 'Boyut uyuşmuyor',
  ManagedAttachmentIntegrity.hashMismatch => 'Hash uyuşmuyor',
  ManagedAttachmentIntegrity.mimeMismatch => 'Dosya türü uyuşmuyor',
  ManagedAttachmentIntegrity.unsafePath => 'Güvensiz yol',
};
