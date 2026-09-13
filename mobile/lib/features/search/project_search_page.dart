import 'dart:async';

import 'package:chief_site_engineer/application/project_search_application.dart';
import 'package:flutter/material.dart';

typedef ProjectSearchResultOpener =
    Future<bool> Function(ProjectSearchResult result);

class ProjectSearchPage extends StatefulWidget {
  const ProjectSearchPage({
    required this.application,
    required this.activeProjectSession,
    required this.readActiveProjectId,
    required this.openResult,
    super.key,
  });

  final ProjectSearchApplicationPort application;
  final Listenable activeProjectSession;
  final String? Function() readActiveProjectId;
  final ProjectSearchResultOpener openResult;

  @override
  State<ProjectSearchPage> createState() => _ProjectSearchPageState();
}

class _ProjectSearchPageState extends State<ProjectSearchPage> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  String? _projectId;
  List<ProjectSearchResult> _results = const [];
  List<ProjectSearchSourceFailure> _failures = const [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _error;
  String? _openingIdentity;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _projectId = widget.readActiveProjectId();
    widget.activeProjectSession.addListener(_handleActiveProjectChanged);
    _queryController.addListener(_handleQueryChanged);
  }

  @override
  void didUpdateWidget(ProjectSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProjectSession != widget.activeProjectSession) {
      oldWidget.activeProjectSession.removeListener(
        _handleActiveProjectChanged,
      );
      widget.activeProjectSession.addListener(_handleActiveProjectChanged);
      _handleActiveProjectChanged();
    }
  }

  @override
  void dispose() {
    widget.activeProjectSession.removeListener(_handleActiveProjectChanged);
    _queryController
      ..removeListener(_handleQueryChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    if (mounted) setState(() {});
  }

  void _handleActiveProjectChanged() {
    final nextProjectId = widget.readActiveProjectId();
    if (nextProjectId == _projectId) return;
    _generation += 1;
    _queryController.clear();
    if (!mounted) return;
    setState(() {
      _projectId = nextProjectId;
      _results = const [];
      _failures = const [];
      _loading = false;
      _hasSearched = false;
      _error = null;
      _openingIdentity = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final currentProjectId = widget.readActiveProjectId();
    if (currentProjectId != _projectId) {
      _handleActiveProjectChanged();
      return;
    }
    final query = _queryController.text.trim();
    if (currentProjectId == null || query.isEmpty) {
      final generation = ++_generation;
      setState(() {
        _results = const [];
        _failures = const [];
        _loading = false;
        _hasSearched = query.isNotEmpty;
        _error = currentProjectId == null
            ? 'Arama için önce etkin bir proje seçin.'
            : null;
      });
      assert(generation == _generation);
      return;
    }
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _hasSearched = true;
      _error = null;
      _failures = const [];
    });
    try {
      final response = await widget.application.search(
        ProjectSearchQuery(projectId: currentProjectId, query: query),
      );
      if (!mounted ||
          generation != _generation ||
          widget.readActiveProjectId() != currentProjectId) {
        return;
      }
      if (response.results.isEmpty &&
          response.failures.length == ProjectSearchSourceKind.values.length) {
        setState(() {
          _results = const [];
          _failures = response.failures;
          _loading = false;
          _error = 'Arama kaynakları güvenle okunamadı.';
        });
        return;
      }
      setState(() {
        _results = response.results;
        _failures = response.failures;
        _loading = false;
      });
    } on Object {
      if (!mounted ||
          generation != _generation ||
          widget.readActiveProjectId() != currentProjectId) {
        return;
      }
      setState(() {
        _results = const [];
        _failures = const [];
        _loading = false;
        _error = 'Arama sonuçları güvenle okunamadı.';
      });
    }
  }

  Future<void> _open(ProjectSearchResult result) async {
    final currentProjectId = widget.readActiveProjectId();
    if (_openingIdentity != null ||
        currentProjectId == null ||
        currentProjectId != result.projectId) {
      _showUnavailable();
      return;
    }
    setState(() => _openingIdentity = result.identity);
    var opened = false;
    try {
      opened = await widget.openResult(result);
    } on Object {
      opened = false;
    }
    if (!mounted) return;
    setState(() => _openingIdentity = null);
    if (!opened) _showUnavailable();
  }

  void _showUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu kayıt artık bu projede kullanılamıyor.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectAvailable = _projectId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Projede ara')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                key: const Key('project-search-input'),
                controller: _queryController,
                enabled: projectAvailable && !_loading,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => unawaited(_search()),
                decoration: InputDecoration(
                  labelText: 'Ajanda ve Beton içinde ara',
                  hintText: 'Kayıt açıklaması, konum veya beton kodu',
                  border: const OutlineInputBorder(),
                  suffixIcon: Semantics(
                    button: true,
                    label: 'Ara',
                    child: IconButton(
                      key: const Key('project-search-submit'),
                      tooltip: 'Ara',
                      onPressed:
                          projectAvailable &&
                              !_loading &&
                              _queryController.text.trim().isNotEmpty
                          ? () => unawaited(_search())
                          : null,
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_projectId == null) {
      return const _ProjectSearchMessage(
        key: Key('project-search-project-required'),
        icon: Icons.folder_off_outlined,
        message: 'Arama için önce etkin bir proje seçin.',
      );
    }
    if (_loading) {
      return const Center(
        key: Key('project-search-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return _ProjectSearchMessage(
        key: const Key('project-search-error'),
        icon: Icons.search_off_rounded,
        message: _error!,
        action: FilledButton.icon(
          onPressed: _search,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Yeniden dene'),
        ),
      );
    }
    if (!_hasSearched) {
      return const _ProjectSearchMessage(
        key: Key('project-search-idle'),
        icon: Icons.manage_search_rounded,
        message: 'Etkin projedeki Ajanda ve Beton kayıtlarını arayın.',
      );
    }
    return CustomScrollView(
      key: const PageStorageKey<String>('project-search-results-scroll'),
      controller: _scrollController,
      slivers: [
        if (_failures.isNotEmpty)
          SliverToBoxAdapter(
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Container(
                key: const Key('project-search-partial-failure'),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Bazı kaynaklar okunamadı; kullanılabilen sonuçlar gösteriliyor.',
                ),
              ),
            ),
          ),
        if (_results.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _ProjectSearchMessage(
              key: Key('project-search-empty'),
              icon: Icons.find_in_page_outlined,
              message: 'Bu projede eşleşen kayıt bulunamadı.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            sliver: SliverList.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final opening = _openingIdentity == result.identity;
                return Card(
                  key: ValueKey('project-search-result-${result.identity}'),
                  child: Semantics(
                    button: true,
                    label:
                        '${_sourceLabel(result.sourceKind)}, ${result.title}',
                    child: ListTile(
                      minVerticalPadding: 12,
                      leading: Icon(_sourceIcon(result.sourceKind)),
                      title: Text(result.title),
                      subtitle: Text(
                        '${_sourceLabel(result.sourceKind)} • ${result.summary}\n'
                        '${_displayDate(result.sourceDate)} • ${result.statusLabel}',
                      ),
                      isThreeLine: true,
                      trailing: opening
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: opening ? null : () => unawaited(_open(result)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProjectSearchMessage extends StatelessWidget {
  const _ProjectSearchMessage({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

String _sourceLabel(ProjectSearchSourceKind kind) => switch (kind) {
  ProjectSearchSourceKind.agendaObservation => 'Ajanda',
  ProjectSearchSourceKind.concretePour => 'Beton',
};

IconData _sourceIcon(ProjectSearchSourceKind kind) => switch (kind) {
  ProjectSearchSourceKind.agendaObservation => Icons.event_note_outlined,
  ProjectSearchSourceKind.concretePour => Icons.foundation_outlined,
};

String _displayDate(String sourceDate) {
  final date = DateTime.parse(sourceDate).toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
      '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
