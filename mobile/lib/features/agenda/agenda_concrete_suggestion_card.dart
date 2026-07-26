import 'package:flutter/material.dart';

class AgendaConcreteSuggestionCard extends StatelessWidget {
  const AgendaConcreteSuggestionCard({
    required this.message,
    this.onSelectConcreteCategory,
    this.onOpenConcrete,
    this.selectCategoryKey,
    this.openConcreteKey,
    super.key,
  });

  final String message;
  final VoidCallback? onSelectConcreteCategory;
  final VoidCallback? onOpenConcrete;
  final Key? selectCategoryKey;
  final Key? openConcreteKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.foundation_outlined),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            if (onSelectConcreteCategory != null) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: OutlinedButton(
                  key: selectCategoryKey,
                  onPressed: onSelectConcreteCategory,
                  child: const Text('Kayıt türünü Beton yap'),
                ),
              ),
            ],
            if (onOpenConcrete != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: FilledButton.tonalIcon(
                  key: openConcreteKey,
                  onPressed: onOpenConcrete,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Beton paketine git'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
