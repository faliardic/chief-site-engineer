import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:flutter/material.dart';

typedef InventoryFloorAction = void Function(String blockId, String floorId);

class InventoryFloorLevelModel {
  const InventoryFloorLevelModel({
    required this.floor,
    required this.assetCount,
  });

  final InventoryFloorRecord floor;
  final int assetCount;
}

class InventoryFloorStackModel {
  const InventoryFloorStackModel({
    required this.block,
    required this.floors,
    required this.assetCount,
  });

  final InventoryBlockRecord block;
  final List<InventoryFloorLevelModel> floors;
  final int assetCount;
}

class InventoryFloorViewModel {
  const InventoryFloorViewModel({
    required this.blocks,
    required this.projectAssetCount,
  });

  factory InventoryFloorViewModel.fromCanonical({
    required Iterable<InventoryBlockRecord> activeBlocks,
    required Iterable<InventoryFloorRecord> activeFloors,
    required Iterable<InventoryAssetProjection> assets,
  }) {
    final blocks = activeBlocks.toList(growable: false)
      ..sort((left, right) {
        final ordinal = left.ordinal.compareTo(right.ordinal);
        return ordinal != 0 ? ordinal : left.id.compareTo(right.id);
      });
    final blockIds = blocks.map((block) => block.id).toSet();
    final floors = activeFloors
        .where((floor) => blockIds.contains(floor.blockId))
        .toList(growable: false);
    final floorById = <String, InventoryFloorRecord>{
      for (final floor in floors) floor.id: floor,
    };
    final assetIdsByFloor = <String, Set<String>>{
      for (final floor in floors) floor.id: <String>{},
    };
    for (final projection in assets) {
      final asset = projection.asset;
      final placement = projection.activePlacement;
      final floor = placement == null ? null : floorById[placement.floorId];
      if (asset.archivedAt != null ||
          placement == null ||
          !placement.isActive ||
          placement.assetId != asset.id ||
          placement.projectId != asset.projectId ||
          placement.quantity != asset.totalQuantity ||
          floor == null ||
          floor.projectId != asset.projectId) {
        continue;
      }
      assetIdsByFloor[floor.id]!.add(asset.id);
    }
    final projectAssetIds = <String>{};
    final stacks = <InventoryFloorStackModel>[];
    for (final block in blocks) {
      final blockFloors =
          floors
              .where((floor) => floor.blockId == block.id)
              .toList(growable: false)
            ..sort((left, right) {
              final ordinal = right.ordinal.compareTo(left.ordinal);
              return ordinal != 0 ? ordinal : left.id.compareTo(right.id);
            });
      final blockAssetIds = <String>{};
      final levels = <InventoryFloorLevelModel>[];
      for (final floor in blockFloors) {
        final floorAssetIds = assetIdsByFloor[floor.id]!;
        blockAssetIds.addAll(floorAssetIds);
        projectAssetIds.addAll(floorAssetIds);
        levels.add(
          InventoryFloorLevelModel(
            floor: floor,
            assetCount: floorAssetIds.length,
          ),
        );
      }
      stacks.add(
        InventoryFloorStackModel(
          block: block,
          floors: List<InventoryFloorLevelModel>.unmodifiable(levels),
          assetCount: blockAssetIds.length,
        ),
      );
    }
    return InventoryFloorViewModel(
      blocks: List<InventoryFloorStackModel>.unmodifiable(stacks),
      projectAssetCount: projectAssetIds.length,
    );
  }

  final List<InventoryFloorStackModel> blocks;
  final int projectAssetCount;
}

class InventoryFloorView extends StatelessWidget {
  const InventoryFloorView({
    required this.model,
    required this.onOpenMap,
    required this.onOpenList,
    required this.onCreate,
    super.key,
  });

  final InventoryFloorViewModel model;
  final InventoryFloorAction onOpenMap;
  final InventoryFloorAction onOpenList;
  final InventoryFloorAction onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('inventory-floor-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Proje toplamı: ${model.projectAssetCount} kayıt',
            key: const Key('inventory-floor-project-total'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (model.blocks.isEmpty)
          const Expanded(
            child: Center(
              key: Key('inventory-floor-empty'),
              child: Text('Kat görünümü için aktif alan bulunmuyor.'),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < model.blocks.length; index += 1)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == model.blocks.length - 1 ? 0 : 12,
                        ),
                        child: _InventoryBlockStack(
                          model: model.blocks[index],
                          onOpenMap: onOpenMap,
                          onOpenList: onOpenList,
                          onCreate: onCreate,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InventoryBlockStack extends StatelessWidget {
  const _InventoryBlockStack({
    required this.model,
    required this.onOpenMap,
    required this.onOpenList,
    required this.onCreate,
  });

  final InventoryFloorStackModel model;
  final InventoryFloorAction onOpenMap;
  final InventoryFloorAction onOpenList;
  final InventoryFloorAction onCreate;

  @override
  Widget build(BuildContext context) {
    final block = model.block;
    return SizedBox(
      key: Key('inventory-floor-block-${block.id}'),
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                block.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${model.assetCount} kayıt',
                key: Key('inventory-floor-block-total-${block.id}'),
              ),
              const SizedBox(height: 8),
              for (final level in model.floors)
                _InventoryFloorLevel(
                  block: block,
                  model: level,
                  onOpenMap: onOpenMap,
                  onOpenList: onOpenList,
                  onCreate: onCreate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryFloorLevel extends StatelessWidget {
  const _InventoryFloorLevel({
    required this.block,
    required this.model,
    required this.onOpenMap,
    required this.onOpenList,
    required this.onCreate,
  });

  final InventoryBlockRecord block;
  final InventoryFloorLevelModel model;
  final InventoryFloorAction onOpenMap;
  final InventoryFloorAction onOpenList;
  final InventoryFloorAction onCreate;

  @override
  Widget build(BuildContext context) {
    final floor = model.floor;
    return Card.outlined(
      key: Key('inventory-floor-row-${floor.id}'),
      child: Column(
        children: [
          ListTile(
            key: Key('inventory-floor-map-${floor.id}'),
            onTap: () => onOpenMap(block.id, floor.id),
            title: Text(floor.displayName),
            subtitle: Text(
              '${model.assetCount} kayıt',
              key: Key('inventory-floor-count-${floor.id}'),
            ),
            trailing: IconButton(
              key: Key('inventory-floor-create-${floor.id}'),
              tooltip: '${floor.displayName} katına envanter ekle',
              onPressed: () => onCreate(block.id, floor.id),
              icon: const Icon(Icons.add_location_alt_outlined),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key('inventory-floor-list-${floor.id}'),
              onPressed: () => onOpenList(block.id, floor.id),
              icon: const Icon(Icons.view_list_outlined),
              label: const Text('Liste'),
            ),
          ),
        ],
      ),
    );
  }
}
