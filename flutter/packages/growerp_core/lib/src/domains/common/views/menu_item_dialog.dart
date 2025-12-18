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
  final MenuOption menuOption;
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
        height: isPhone ? 550 : 450,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: _updateButton(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            body: BlocConsumer<MenuConfigBloc, MenuConfigState>(
              listener: (context, state) {
                if (state.status == MenuConfigStatus.failure) {
                  HelperFunctions.showMessage(
                    context,
                    state.message ?? 'Error',
                    Colors.red,
                  );
                }
                if (state.status == MenuConfigStatus.success &&
                    state.message != null) {
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
        padding: const EdgeInsets.all(16),
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

            // Icon and Widget Name Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('menuItemIcon'),
                    initialValue: _selectedIconName,
                    decoration: const InputDecoration(
                      labelText: 'Icon',
                      border: OutlineInputBorder(),
                    ),
                    items: _iconOptions.map((iconName) {
                      return DropdownMenuItem(
                        value: iconName,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            getIconFromRegistry(iconName) ??
                                const Icon(Icons.circle, size: 20),
                            const SizedBox(width: 8),
                            Text(iconName, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _selectedIconName = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Autocomplete<String>(
                    key: const Key('menuItemWidget'),
                    initialValue: TextEditingValue(
                      text: _selectedWidgetName ?? '',
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
                                return ListTile(
                                  dense: true,
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
                        // Auto-fill title and route if widget is selected
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
                ),
              ],
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

            // Children (tabs) info
            if (!widget.isNew && widget.menuOption.children != null) ...[
              const Text(
                'Linked Menu Items (Tabs):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.menuOption.children!.isEmpty)
                const Text('No tabs linked to this menu option.')
              else
                Wrap(
                  spacing: 8,
                  children: widget.menuOption.children!.map((item) {
                    return Chip(
                      label: Text(item.title),
                      avatar:
                          getIconFromRegistry(item.iconName) ??
                          const Icon(Icons.tab, size: 16),
                    );
                  }).toList(),
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
      onPressed: _saveMenuOption,
      icon: const Icon(Icons.save),
      label: Text(widget.isNew ? 'Create' : 'Update'),
    );
  }

  void _saveMenuOption() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final updatedOption = widget.menuOption.copyWith(
      title: _titleController.text,
      route: _routeController.text.isNotEmpty ? _routeController.text : null,
      iconName: _selectedIconName,
      widgetName: _selectedWidgetName,
      sequenceNum: int.tryParse(_sequenceNumController.text) ?? 10,
      isActive: _isActive,
    );

    if (widget.isNew) {
      _menuConfigBloc.add(
        MenuOptionCreate(
          menuConfigurationId: widget.menuConfigurationId,
          menuOption: updatedOption,
        ),
      );
    } else {
      _menuConfigBloc.add(
        MenuOptionUpdate(
          menuOptionId: widget.menuOption.menuOptionId!,
          menuOption: updatedOption,
        ),
      );
    }
  }
}
