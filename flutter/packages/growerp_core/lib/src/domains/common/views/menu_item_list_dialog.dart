/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// List dialog for menu options - displays all top-level menu options
/// Clicking on an option opens the MenuItemDialog for editing
class MenuItemListDialog extends StatefulWidget {
  final MenuConfiguration menuConfiguration;

  const MenuItemListDialog({Key? key, required this.menuConfiguration})
    : super(key: key);

  @override
  MenuItemListDialogState createState() => MenuItemListDialogState();
}

class MenuItemListDialogState extends State<MenuItemListDialog> {
  late double bottom;
  double? right;
  late bool isPhone;

  @override
  void initState() {
    super.initState();
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 70 : 90);

    return BlocConsumer<MenuConfigBloc, MenuConfigState>(
      listener: (context, state) {
        if (state.status == MenuConfigStatus.failure) {
          HelperFunctions.showMessage(
            context,
            state.message ?? 'Operation failed',
            Colors.red,
          );
        } else if (state.status == MenuConfigStatus.success &&
            state.message != null) {
          HelperFunctions.showMessage(context, state.message!, Colors.green);
        }
      },
      builder: (context, state) {
        // Use bloc state if available, otherwise fall back to widget's initial configuration
        final menuConfig = state.menuConfiguration ?? widget.menuConfiguration;

        // Get menu options sorted by sequence
        final menuItems = menuConfig.menuItems.toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Dialog(
          key: const Key('MenuItemListDialog'),
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: popUp(
            context: context,
            title: 'Menu Options - ${menuConfig.name}',
            width: isPhone ? 380 : 600,
            height: isPhone ? 550 : 500,
            child: Stack(
              children: [
                state.status == MenuConfigStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMenuItemList(menuItems, menuConfig),
                Positioned(
                  right: right,
                  bottom: bottom,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        right = right! - details.delta.dx;
                        bottom -= details.delta.dy;
                      });
                    },
                    child: Column(
                      children: [
                        FloatingActionButton(
                          key: const Key('resetMenuItemsFab'),
                          heroTag: 'menuItemListReset',
                          tooltip: 'Reset to Default',
                          backgroundColor: Colors.orange,
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Reset to Default'),
                                content: const Text(
                                  'Are you sure you want to reset the menu to default?\n\n'
                                  'This will delete all current menu options and restore '
                                  'the original default configuration.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Reset'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              context.read<MenuConfigBloc>().add(
                                MenuConfigReset(
                                  menuConfig.menuConfigurationId ?? '',
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.restore),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton(
                          key: const Key('addMenuItemFab'),
                          heroTag: 'menuItemListAdd',
                          tooltip: 'Add Menu Option',
                          onPressed: () async {
                            await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => BlocProvider.value(
                                value: context.read<MenuConfigBloc>(),
                                child: MenuItemDialog(
                                  menuOption: MenuItem(
                                    title: '',
                                    menuConfigurationId:
                                        menuConfig.menuConfigurationId,
                                    sequenceNum: menuItems.length * 10 + 10,
                                    isActive: true,
                                  ),
                                  menuConfigurationId:
                                      menuConfig.menuConfigurationId ?? '',
                                  isNew: true,
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItemList(
    List<MenuItem> options,
    MenuConfiguration menuConfig,
  ) {
    if (options.isEmpty) {
      return const Center(
        child: Text('No menu options found', style: TextStyle(fontSize: 16)),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      buildDefaultDragHandles: false,
      itemCount: options.length,
      onReorder: (oldIndex, newIndex) {
        _onMenuItemsReorder(options, menuConfig, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final option = options[index];
        // Get children count (MenuItem tabs linked to this option)
        final childrenCount = option.children?.length ?? 0;

        return Card(
          key: Key('menuOption_${option.menuItemId}'),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            onTap: () async {
              await showDialog<bool>(
                context: context,
                builder: (dialogContext) => BlocProvider.value(
                  value: context.read<MenuConfigBloc>(),
                  child: MenuItemDialog(
                    menuOption: option,
                    menuConfigurationId: menuConfig.menuConfigurationId ?? '',
                    isNew: false,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle, size: 20),
                  ),
                  const SizedBox(width: 8),
                  // Icon
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child:
                          getIconFromRegistry(option.iconName) ??
                          (option.image != null
                              ? Image.asset(
                                  option.image!,
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.menu, size: 24),
                                )
                              : const Icon(Icons.menu, size: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title
                  Expanded(
                    flex: 2,
                    child: Text(
                      option.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Tabs Count (hide on phone to save space)
                  if (childrenCount > 0 && !isPhone) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('$childrenCount tabs'),
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(fontSize: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],

                  const Spacer(),

                  // Status
                  // Status
                  InkWell(
                    key: Key('toggleActive_${option.menuItemId}'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.read<MenuConfigBloc>().add(
                        MenuItemToggleActive(option.menuItemId!),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: option.isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        option.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          color: option.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  IconButton(
                    key: Key('deleteMenuItem_${option.menuItemId}'),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete menu option',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete Menu Option'),
                          content: Text(
                            'Are you sure you want to delete "${option.title}"?\n\n'
                            'This will also unlink all associated tab items.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        final bloc = context.read<MenuConfigBloc>();
                        bloc.add(MenuItemDelete(option.menuItemId!));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle reorder of top-level menu items
  void _onMenuItemsReorder(
    List<MenuItem> options,
    MenuConfiguration menuConfig,
    int oldIndex,
    int newIndex,
  ) {
    // Adjust newIndex for ReorderableListView behavior
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Build the new sequence list
    final reorderedOptions = List<MenuItem>.from(options);
    final movedItem = reorderedOptions.removeAt(oldIndex);
    reorderedOptions.insert(newIndex, movedItem);

    // Create sequence updates
    final optionSequences = <Map<String, dynamic>>[];
    for (int i = 0; i < reorderedOptions.length; i++) {
      optionSequences.add({
        'menuItemId': reorderedOptions[i].menuItemId,
        'sequenceNum': (i + 1) * 10,
      });
    }

    // Dispatch reorder event
    context.read<MenuConfigBloc>().add(
      MenuItemsReorder(
        menuConfigurationId: menuConfig.menuConfigurationId ?? '',
        optionSequences: optionSequences,
      ),
    );
  }
}
