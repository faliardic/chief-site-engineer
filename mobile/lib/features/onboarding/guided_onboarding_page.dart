import 'dart:async';

import 'package:flutter/material.dart';

typedef GuidedOnboardingCreateProject = Future<bool> Function();
typedef GuidedOnboardingMarkHandled = Future<void> Function();

class GuidedOnboardingPage extends StatefulWidget {
  const GuidedOnboardingPage({
    required this.hasExistingProject,
    required this.onCreateProject,
    required this.onHandled,
    super.key,
  });

  final bool hasExistingProject;
  final GuidedOnboardingCreateProject onCreateProject;
  final GuidedOnboardingMarkHandled onHandled;

  @override
  State<GuidedOnboardingPage> createState() => _GuidedOnboardingPageState();
}

class _GuidedOnboardingPageState extends State<GuidedOnboardingPage> {
  int _step = 0;
  bool _hasProject = false;
  bool _busy = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _hasProject = widget.hasExistingProject;
  }

  String get _title => switch (_step) {
    0 => 'CSE nedir?',
    1 => 'İlk proje',
    _ => 'Ana günlük akış',
  };

  String get _body => switch (_step) {
    0 =>
      'Şefim; şantiye çalışmalarınızı cihazınızda hatırlamanıza, '
          'kaydetmenize ve gerektiğinde bulmanıza yardımcı olan '
          'yerel-öncelikli kişisel saha asistanınızdır.',
    1 when _hasProject =>
      'Aktif projeniz hazır. Yeni bir proje oluşturmadan mevcut '
          'projenizle devam edebilirsiniz.',
    1 =>
      'Başlamak için yalnızca proje adını girin. Diğer proje '
          'bilgilerini daha sonra tamamlayabilirsiniz.',
    _ =>
      'Ana Sayfa’da projenizin özetini görün. Hatırlatıcı ile açık '
          'işleri takip edin; Ajanda ile gün içindeki saha kayıtlarını '
          'saklayın.',
  };

  IconData get _icon => switch (_step) {
    0 => Icons.engineering_outlined,
    1 => Icons.apartment_rounded,
    _ => Icons.today_outlined,
  };

  String get _primaryLabel => switch (_step) {
    0 => 'Devam',
    1 when !_hasProject => 'Proje oluştur',
    1 => 'Devam',
    _ => 'Bitir',
  };

  Future<void> _handlePrimary() async {
    if (_busy) return;
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_hasProject) {
        setState(() => _step = 2);
        return;
      }
      setState(() => _busy = true);
      bool created = false;
      try {
        created = await widget.onCreateProject();
      } on Object {
        created = false;
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (created) {
          _hasProject = true;
          _step = 2;
        }
      });
      return;
    }
    await _markHandledAndExit();
  }

  Future<void> _markHandledAndExit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onHandled();
    } on Object {
      // Preference persistence is optional UI state and must fail open.
    }
    if (!mounted) return;
    await _exit();
  }

  Future<void> _handleBack() async {
    if (_busy) return;
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    await _exit();
  }

  Future<void> _exit() async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        key: const Key('guided-onboarding-page'),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 600
                  ? 24.0
                  : 40.0;
              return SingleChildScrollView(
                key: const Key('guided-onboarding-scroll'),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      minHeight: (constraints.maxHeight - 40).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: Column(
                        key: ValueKey('guided-onboarding-step-${_step + 1}'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  label: '${_step + 1}. adım, toplam 3 adım',
                                  child: Text(
                                    'Adım ${_step + 1} / 3',
                                    key: const Key(
                                      'guided-onboarding-progress',
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(1),
                                child: Semantics(
                                  container: true,
                                  button: true,
                                  enabled: !_busy,
                                  label: 'Tanıtımı atla',
                                  hint: 'Tanıtımı tamamlandı olarak işaretler',
                                  onTap: _busy
                                      ? null
                                      : () => unawaited(_markHandledAndExit()),
                                  excludeSemantics: true,
                                  child: TextButton(
                                    key: const Key('guided-onboarding-skip'),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : _markHandledAndExit,
                                    child: const Text('Atla'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Icon(
                                  _icon,
                                  size: 40,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Semantics(
                            header: true,
                            child: Text(
                              _title,
                              key: const Key('guided-onboarding-title'),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _body,
                            key: const Key('guided-onboarding-body'),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 32),
                          OverflowBar(
                            alignment: MainAxisAlignment.end,
                            spacing: 8,
                            overflowSpacing: 8,
                            children: [
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: Semantics(
                                  container: true,
                                  button: true,
                                  enabled: !_busy,
                                  label: _step == 0
                                      ? 'Tanıtımdan çık'
                                      : 'Önceki adıma dön',
                                  onTap: _busy
                                      ? null
                                      : () => unawaited(_handleBack()),
                                  excludeSemantics: true,
                                  child: TextButton.icon(
                                    key: const Key('guided-onboarding-back'),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => unawaited(_handleBack()),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    label: const Text('Geri'),
                                  ),
                                ),
                              ),
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: Semantics(
                                  container: true,
                                  button: true,
                                  enabled: !_busy,
                                  label: _primaryLabel,
                                  onTap: _busy
                                      ? null
                                      : () => unawaited(_handlePrimary()),
                                  excludeSemantics: true,
                                  child: FilledButton(
                                    key: const Key('guided-onboarding-primary'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => unawaited(_handlePrimary()),
                                    child: _busy
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(_primaryLabel),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
