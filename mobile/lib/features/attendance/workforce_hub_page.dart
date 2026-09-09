import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:flutter/material.dart';

class WorkforceHubPage extends StatefulWidget {
  const WorkforceHubPage({
    required this.attendance,
    required this.agenda,
    required this.activeProjectId,
    required this.isActive,
    this.onProjectSelected,
    super.key,
  });

  final AttendanceApplication attendance;
  final AgendaApplication agenda;
  final String? activeProjectId;
  final bool isActive;
  final ValueChanged<String>? onProjectSelected;

  @override
  State<WorkforceHubPage> createState() => _WorkforceHubPageState();
}

class _WorkforceHubPageState extends State<WorkforceHubPage> {
  _WorkforceSubview _selectedSubview = _WorkforceSubview.attendance;
  final Set<_WorkforceSubview> _visitedSubviews = {
    _WorkforceSubview.attendance,
  };

  void _selectSubview(_WorkforceSubview subview) {
    if (_selectedSubview == subview) return;
    setState(() {
      _selectedSubview = subview;
      _visitedSubviews.add(subview);
    });
  }

  Widget _subviewButton({
    required _WorkforceSubview subview,
    required String label,
    required IconData icon,
    required Key key,
  }) {
    final selected = _selectedSubview == subview;
    final child = selected
        ? FilledButton.tonalIcon(
            key: key,
            onPressed: () => _selectSubview(subview),
            icon: Icon(icon),
            label: Text(label, textAlign: TextAlign.center),
          )
        : OutlinedButton.icon(
            key: key,
            onPressed: () => _selectSubview(subview),
            icon: Icon(icon),
            label: Text(label, textAlign: TextAlign.center),
          );
    return Semantics(selected: selected, button: true, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      key: const Key('workforce-hub'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackControls =
                  constraints.maxWidth < 360 || textScale > 1.3;
              final attendanceButton = _subviewButton(
                subview: _WorkforceSubview.attendance,
                label: 'Günlük Puantaj',
                icon: Icons.fact_check_outlined,
                key: const Key('workforce-hub-attendance-tab'),
              );
              final directoryButton = _subviewButton(
                subview: _WorkforceSubview.directory,
                label: 'Sicil',
                icon: Icons.badge_outlined,
                key: const Key('workforce-hub-directory-tab'),
              );
              return Semantics(
                container: true,
                label: 'İş Gücü bölümleri',
                child: stackControls
                    ? Column(
                        key: const Key('workforce-hub-stacked-selector'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          attendanceButton,
                          const SizedBox(height: 8),
                          directoryButton,
                        ],
                      )
                    : Row(
                        key: const Key('workforce-hub-inline-selector'),
                        children: [
                          Expanded(child: attendanceButton),
                          const SizedBox(width: 8),
                          Expanded(child: directoryButton),
                        ],
                      ),
              );
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            key: const Key('workforce-hub-content'),
            index: _selectedSubview.index,
            children: [
              AttendancePage(
                attendance: widget.attendance,
                agenda: widget.agenda,
                activeProjectId: widget.activeProjectId,
                isActive:
                    widget.isActive &&
                    _selectedSubview == _WorkforceSubview.attendance,
                showProjectSelector: false,
                reloadOnReactivation: false,
                onProjectSelected: widget.onProjectSelected,
              ),
              _visitedSubviews.contains(_WorkforceSubview.directory)
                  ? WorkforceDirectoryPage(
                      attendance: widget.attendance,
                      agenda: widget.agenda,
                      activeProjectId: widget.activeProjectId,
                      usesSharedProjectContext: true,
                      isActive:
                          widget.isActive &&
                          _selectedSubview == _WorkforceSubview.directory,
                      onProjectSelected: widget.onProjectSelected,
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

enum _WorkforceSubview { attendance, directory }
