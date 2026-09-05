import 'package:flutter/material.dart';

/// A secondary screen action; primary capture actions belong in the content.
class ScreenToolAction {
  const ScreenToolAction({
    required this.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final Key key;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

/// Place beside an expanded content area to reserve space without overlapping it.
/// The tools scroll independently when the available screen height is limited.
class ScreenToolRail extends StatelessWidget {
  const ScreenToolRail({required this.actions, super.key});

  final List<ScreenToolAction> actions;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  if (index != 0) const SizedBox(height: 8),
                  Semantics(
                    container: true,
                    label: actions[index].label,
                    button: true,
                    enabled: actions[index].onPressed != null,
                    excludeSemantics: true,
                    onTap: actions[index].onPressed,
                    child: IconButton(
                      key: actions[index].key,
                      tooltip: actions[index].label,
                      style: IconButton.styleFrom(
                        fixedSize: const Size.square(48),
                        minimumSize: const Size.square(48),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.standard,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: actions[index].onPressed,
                      icon: Icon(actions[index].icon, size: 22),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
