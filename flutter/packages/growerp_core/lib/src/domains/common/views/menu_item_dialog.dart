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

/// Dialog for creating/editing menu options
class MenuItemDialog extends StatefulWidget {
  final MenuItem menuOption;
  final String menuConfigurationId;
  final bool isNew;

  const MenuItemDialog({
    Key? key,
    required this.menuOption,
    required this.menuConfigurationId,
    required this.isNew,
  }) : super(key: key);

  @override
  MenuItemDialogState createState() => MenuItemDialogState();
}

class MenuItemDialogState extends State<MenuItemDialog> {
  late final GlobalKey<FormState> _formKey;
  final _titleController = TextEditingController();
  final _routeController = TextEditingController();
  final _sequenceNumController = TextEditingController();

  late String? _selectedIconName;
  late String? _selectedWidgetName;
  late bool _isActive;
  late MenuConfigBloc _menuConfigBloc;
  late bool isPhone;

  /// Track when the user explicitly saves the menu item.
  /// This prevents the dialog from closing when a child tab is added/modified.
  bool _pendingClose = false;

  // Available icon names
  final List<String> _iconOptions = [
    'dashboard',
    'home',
    'business',
    'people',
    'inventory',
    'shopping_cart',
    'warehouse',
    'account_balance',
    'info',
    'settings',
    'task',
    'money',
    'send',
    'call_received',
    'location_pin',
    'question_answer',
    'web',
    'quiz',
    'subscriptions',
    'webhook',
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();

    // Initialize form fields from existing menu option
    _titleController.text = widget.menuOption.title;
    _routeController.text = widget.menuOption.route ?? '';
    _sequenceNumController.text = widget.menuOption.sequenceNum.toString();

    _selectedIconName = widget.menuOption.iconName;
    _selectedWidgetName = widget.menuOption.widgetName;
    _isActive = widget.menuOption.isActive;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuConfigBloc = context.read<MenuConfigBloc>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _routeController.dispose();
    _sequenceNumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;

    final String title = !widget.isNew
        ? 'Edit: ${widget.menuOption.title}'
        : 'New Menu Option';

    return Dialog(
      key: const Key('MenuItemDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: title,
        width: isPhone ? 400 : 600,
        height: isPhone ? 650 : 550,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: _updateButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            body: BlocConsumer<MenuConfigBloc, MenuConfigState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status,
              listener: (context, state) {
                if (state.status == MenuConfigStatus.failure) {
                  HelperFunctions.showMessage(
                    context,
                    state.message ?? 'Error',
                    Colors.red,
                  );
                }
                // Only close the dialog when the user explicitly saved the menu item
                if (state.status == MenuConfigStatus.success &&
                    state.message != null &&
                    _pendingClose) {
                  Navigator.of(context).pop(true);
                }
              },
              builder: (context, state) {
                if (state.status == MenuConfigStatus.loading) {
                  return const LoadingIndicator();
                }
                return _showForm();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _showForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextFormField(
              key: const Key('menuItemTitle'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Route
            TextFormField(
              key: const Key('menuItemRoute'),
              controller: _routeController,
              decoration: const InputDecoration(
                labelText: 'Route (e.g., /users)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Icon - Searchable Autocomplete
            Autocomplete<String>(
              key: const Key('menuItemIcon'),
              initialValue: TextEditingValue(text: _selectedIconName ?? ''),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                if (query.isEmpty) {
                  return _iconOptions;
                }
                return _iconOptions.where(
                  (iconName) => iconName.toLowerCase().contains(query),
                );
              },
              fieldViewBuilder:
                  (context, textController, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Icon',
                        border: const OutlineInputBorder(),
                        prefixIcon: _selectedIconName != null
                            ? getIconFromRegistry(_selectedIconName!) ??
                                  const Icon(Icons.circle, size: 20)
                            : null,
                        suffixIcon: textController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  textController.clear();
                                  setState(() {
                                    _selectedIconName = null;
                                  });
                                },
                              )
                            : const Icon(Icons.search, size: 18),
                      ),
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 300,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading:
                                getIconFromRegistry(option) ??
                                const Icon(Icons.circle, size: 20),
                            title: Text(option),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (String selection) {
                setState(() {
                  _selectedIconName = selection;
                });
              },
            ),
            const SizedBox(height: 16),

            // Widget Name - Searchable Autocomplete
            Autocomplete<String>(
              key: const Key('menuItemWidget'),
              initialValue: TextEditingValue(text: _selectedWidgetName ?? ''),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                if (query.isEmpty) {
                  return WidgetRegistry.registeredWidgets;
                }
                return WidgetRegistry.registeredWidgets.where(
                  (widget) => widget.toLowerCase().contains(query),
                );
              },
              fieldViewBuilder:
                  (context, textController, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Widget Name',
                        border: const OutlineInputBorder(),
                        suffixIcon: textController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  textController.clear();
                                  setState(() {
                                    _selectedWidgetName = null;
                                  });
                                },
                              )
                            : const Icon(Icons.search, size: 18),
                      ),
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 300,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final iconName = WidgetRegistry.getIconName(option);
                          return ListTile(
                            dense: true,
                            leading:
                                getIconFromRegistry(iconName) ??
                                const Icon(Icons.widgets, size: 20),
                            title: Text(
                              option,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (value) {
                setState(() {
                  _selectedWidgetName = value;
                  if (_titleController.text.isEmpty) {
                    // Convert CamelCase to Title Case
                    _titleController.text = value
                        .replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (m) => ' ${m.group(1)}',
                        )
                        .trim();
                  }
                  if (_routeController.text.isEmpty) {
                    // Convert to route format
                    _routeController.text =
                        '/${value[0].toLowerCase()}${value.substring(1)}';
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Sequence and Active Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('menuItemSequence'),
                    controller: _sequenceNumController,
                    decoration: const InputDecoration(
                      labelText: 'Sequence',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    key: const Key('menuItemActive'),
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Children (tabs) management - only show for existing (not new) menu options
            if (!widget.isNew) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Linked Menu Items (Tabs):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Add Tab button
                  IconButton(
                    key: const Key('addTabButton'),
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Tab',
                    onPressed: () => _showAddTabDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<MenuConfigBloc, MenuConfigState>(
                builder: (context, state) {
                  // Get current children from bloc state if available
                  final currentOption = state.menuConfiguration?.menuItems
                      .where(
                        (o) => o.menuItemId == widget.menuOption.menuItemId,
                      )
                      .firstOrNull;
                  final children =
                      currentOption?.children ??
                      widget.menuOption.children ??
                      [];

                  if (children.isEmpty) {
                    return const Text(
                      'No tabs linked. Click + to add a tab.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  // Use ReorderableListView for drag-drop reordering
                  return SizedBox(
                    height: (children.length * 56.0).clamp(56.0, 200.0),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: children.length,
                      onReorder: (oldIndex, newIndex) {
                        _onChildTabsReorder(children, oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = children[index];
                        return Card(
                          key: Key('tab_${item.menuItemId}'),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            dense: true,
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle, size: 20),
                            ),
                            title: Row(
                              children: [
                                getIconFromRegistry(item.iconName) ??
                                    const Icon(Icons.tab, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  tooltip: 'Edit tab',
                                  onPressed: () => _showEditTabDialog(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Remove tab',
                                  onPressed: () => _unlinkTab(item),
                                ),
                              ],
                            ),
                            onTap: () => _showEditTabDialog(item),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _updateButton() {
    return FloatingActionButton.extended(
      key: const Key('menuItemUpdate'),
      heroTag: 'menuItemSave',
      onPressed: _saveMenuItem,
      icon: const Icon(Icons.save),
      label: Text(widget.isNew ? 'Create' : 'Update'),
    );
  }

  void _saveMenuItem() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Mark that we're explicitly saving, so the dialog should close on success
    _pendingClose = true;

    // Auto-generate route from title if not provided
    String? route = _routeController.text.isNotEmpty
        ? _routeController.text
        : null;
    if (route == null && _titleController.text.isNotEmpty) {
      // Convert title to route: lowercase, replace spaces with hyphens
      route =
          '/${_titleController.text.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';
    }

    final updatedOption = widget.menuOption.copyWith(
      title: _titleController.text,
      route: route,
      iconName: _selectedIconName,
      widgetName: _selectedWidgetName,
      sequenceNum: int.tryParse(_sequenceNumController.text) ?? 10,
      isActive: _isActive,
    );

    if (widget.isNew) {
      _menuConfigBloc.add(
        MenuItemCreate(
          menuConfigurationId: widget.menuConfigurationId,
          menuOption: updatedOption,
        ),
      );
    } else {
      _menuConfigBloc.add(
        MenuItemUpdate(
          menuItemId: widget.menuOption.menuItemId!,
          menuOption: updatedOption,
        ),
      );
    }
  }

  /// Show dialog to add a new tab (link a widget as MenuItem)
  void _showAddTabDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selectedWidget;
        final titleController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              key: const Key('addTabDialog'),
              title: const Text('Add Tab'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Widget selector
                    Autocomplete<String>(
                      key: const Key('tabWidgetSelector'),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase();
                        if (query.isEmpty) {
                          return WidgetRegistry.registeredWidgets;
                        }
                        return WidgetRegistry.registeredWidgets.where(
                          (widget) => widget.toLowerCase().contains(query),
                        );
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmit) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Widget Name *',
                                border: OutlineInputBorder(),
                                hintText: 'Search widgets...',
                              ),
                            );
                          },
                      onSelected: (value) {
                        setDialogState(() {
                          selectedWidget = value;
                          // Auto-fill title from widget name
                          if (titleController.text.isEmpty) {
                            titleController.text = value
                                .replaceAllMapped(
                                  RegExp(r'([A-Z])'),
                                  (m) => ' ${m.group(1)}',
                                )
                                .trim();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Title field
                    TextFormField(
                      key: const Key('tabTitle'),
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tab Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const Key('addTabConfirm'),
                  onPressed: () {
                    if (selectedWidget != null &&
                        titleController.text.isNotEmpty) {
                      // Create a new MenuItem and link it
                      _linkNewTab(selectedWidget!, titleController.text);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Link a new tab (widget) to this MenuItem
  void _linkNewTab(String widgetName, String title) {
    // Get current children count for sequence
    final currentChildren = widget.menuOption.children ?? [];
    final newSequence = (currentChildren.length + 1) * 10;

    _menuConfigBloc.add(
      MenuItemLink(
        parentMenuItemId: widget.menuOption.menuItemId!,
        sequenceNum: newSequence,
        title: title,
        widgetName: widgetName,
      ),
    );
  }

  /// Unlink a tab from this MenuItem
  void _unlinkTab(MenuItem item) {
    _menuConfigBloc.add(MenuItemUnlink(childMenuItemId: item.menuItemId!));
  }

  /// Handle reorder of child tabs
  void _onChildTabsReorder(
    List<MenuItem> children,
    int oldIndex,
    int newIndex,
  ) {
    // Adjust newIndex for ReorderableListView behavior
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Build the new sequence list
    final reorderedChildren = List<MenuItem>.from(children);
    final movedItem = reorderedChildren.removeAt(oldIndex);
    reorderedChildren.insert(newIndex, movedItem);

    // Create sequence updates
    final optionSequences = <Map<String, dynamic>>[];
    for (int i = 0; i < reorderedChildren.length; i++) {
      optionSequences.add({
        'menuItemId': reorderedChildren[i].menuItemId,
        'sequenceNum': (i + 1) * 10,
      });
    }

    // Dispatch reorder event
    _menuConfigBloc.add(
      MenuItemsReorder(
        menuConfigurationId: widget.menuConfigurationId,
        optionSequences: optionSequences,
      ),
    );
  }

  /// Show dialog to edit an existing tab
  void _showEditTabDialog(MenuItem tab) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selectedWidget = tab.widgetName;
        final titleController = TextEditingController(text: tab.title);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              key: const Key('editTabDialog'),
              title: const Text('Edit Tab'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Widget selector
                    Autocomplete<String>(
                      key: const Key('editTabWidgetSelector'),
                      initialValue: TextEditingValue(
                        text: selectedWidget ?? '',
                      ),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase();
                        if (query.isEmpty) {
                          return WidgetRegistry.registeredWidgets;
                        }
                        return WidgetRegistry.registeredWidgets.where(
                          (widget) => widget.toLowerCase().contains(query),
                        );
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmit) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Widget Name *',
                                border: OutlineInputBorder(),
                                hintText: 'Search widgets...',
                              ),
                            );
                          },
                      onSelected: (value) {
                        setDialogState(() {
                          selectedWidget = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Title field
                    TextFormField(
                      key: const Key('editTabTitle'),
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tab Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const Key('editTabConfirm'),
                  onPressed: () {
                    if (selectedWidget != null &&
                        titleController.text.isNotEmpty) {
                      // Update the existing tab
                      _updateTab(tab, selectedWidget!, titleController.text);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Update an existing tab's properties
  void _updateTab(MenuItem tab, String widgetName, String title) {
    final updatedTab = tab.copyWith(title: title, widgetName: widgetName);

    _menuConfigBloc.add(
      MenuItemUpdate(menuItemId: tab.menuItemId!, menuOption: updatedTab),
    );
  }
}
