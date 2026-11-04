/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../l10n/generated/pos_localizations.dart';
import '../../checkout/blocs/pos_catalog_bloc.dart';
import '../blocs/pos_modifier_bloc.dart';

/// The choices guests get on products, like the sauce or how it is cooked.
class PosModifierGroupList extends StatefulWidget {
  const PosModifierGroupList({super.key});

  @override
  PosModifierGroupListState createState() => PosModifierGroupListState();
}

class PosModifierGroupListState extends State<PosModifierGroupList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late PosModifierBloc _bloc;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _bloc = context.read<PosModifierBloc>()..add(const PosModifierFetch());
    context.read<PosCatalogBloc>().add(const PosCatalogFetch());
  }

  Future<void> _open(PosModifierGroup? group) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: _bloc,
        child: PosModifierGroupDialog(group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    final isPhone = isAPhone(context);
    return BlocConsumer<PosModifierBloc, PosModifierState>(
      listener: (context, state) {
        if (state.status == PosModifierStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
      },
      builder: (context, state) {
        final groups = state.groups
            .where(
              (group) => (group.groupName ?? '').toLowerCase().contains(
                _search.toLowerCase(),
              ),
            )
            .toList();
        return Column(
          children: [
            ListFilterBar(
              searchHint: localizations.modifiers,
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _search = value),
            ),
            Expanded(
              child: Stack(
                children: [
                  StyledDataTable(
                    key: const Key('PosModifierGroupList'),
                    columns: [
                      StyledColumn(header: localizations.name, flex: 4),
                      StyledColumn(header: localizations.modifiers, flex: 5),
                    ],
                    rows: groups.indexed
                        .map(
                          (entry) => <Widget>[
                            SizedBox(
                              key: Key('item${entry.$1}'),
                              child: Text(
                                entry.$2.groupName ?? '',
                                key: Key('name${entry.$1}'),
                              ),
                            ),
                            Text(
                              entry.$2.modifiers
                                  .map((m) => m.modifierName)
                                  .join(', '),
                            ),
                          ],
                        )
                        .toList(),
                    isLoading:
                        state.status == PosModifierStatus.initial &&
                        groups.isEmpty,
                    scrollController: _scrollController,
                    rowHeight: isPhone ? 64 : 56,
                    onRowTap: (index) => _open(groups[index]),
                  ),
                  Positioned(
                    right: isPhone ? 20 : 50,
                    bottom: 50,
                    child: FloatingActionButton(
                      key: const Key('addNew'),
                      heroTag: 'posModifierAdd',
                      onPressed: () => _open(null),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

/// A group with its modifiers and the products it is on.
class PosModifierGroupDialog extends StatefulWidget {
  const PosModifierGroupDialog(this.group, {super.key});
  final PosModifierGroup? group;

  @override
  PosModifierGroupDialogState createState() => PosModifierGroupDialogState();
}

class PosModifierGroupDialogState extends State<PosModifierGroupDialog> {
  final _nameController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _modifierController = TextEditingController();
  final _priceController = TextEditingController();
  late List<PosModifier> _modifiers;
  late Set<String> _productIds;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.group?.groupName ?? '';
    _minController.text = '${widget.group?.minSelect ?? 0}';
    _maxController.text = '${widget.group?.maxSelect ?? 1}';
    _modifiers = List.of(widget.group?.modifiers ?? []);
    _productIds = Set.of(widget.group?.productIds ?? []);
  }

  void _addModifier() {
    if (_modifierController.text.trim().isEmpty) return;
    setState(() {
      _modifiers.add(
        PosModifier(
          modifierName: _modifierController.text.trim(),
          priceDelta: Decimal.tryParse(_priceController.text) ?? Decimal.zero,
        ),
      );
      _modifierController.clear();
      _priceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    final catalog = context.read<PosCatalogBloc>().state;
    final isNew = widget.group == null;
    return Dialog(
      key: const Key('PosModifierGroupDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PosModifierBloc, PosModifierState>(
        listener: (context, state) {
          if (state.status == PosModifierStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == PosModifierStatus.success &&
              state.message != null) {
            Navigator.of(context).pop();
          }
        },
        child: popUp(
          context: context,
          title: localizations.modifiers,
          height: 600,
          width: 420,
          child: ListView(
            key: const Key('listView'),
            children: [
              TextField(
                key: const Key('posGroupName'),
                controller: _nameController,
                decoration: InputDecoration(labelText: localizations.name),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('posGroupMin'),
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: localizations.minimum,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('posGroupMax'),
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: localizations.maximum,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final (index, modifier) in _modifiers.indexed)
                ListTile(
                  key: Key('posGroupModifier$index'),
                  dense: true,
                  title: Text(modifier.modifierName ?? ''),
                  subtitle: Text('${modifier.priceDelta ?? 0}'),
                  trailing: IconButton(
                    key: Key('posGroupModifierDelete$index'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _modifiers.removeAt(index)),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: const Key('posGroupModifierName'),
                      controller: _modifierController,
                      decoration: InputDecoration(
                        labelText: localizations.modifier,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      key: const Key('posGroupModifierPrice'),
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: localizations.amount,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('posGroupModifierAdd'),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addModifier,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final item in catalog.items)
                    FilterChip(
                      key: Key('posGroupProduct${item.productId}'),
                      label: Text(item.productName ?? ''),
                      selected: _productIds.contains(item.productId),
                      onSelected: (selected) => setState(
                        () => selected
                            ? _productIds.add(item.productId!)
                            : _productIds.remove(item.productId),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!isNew) ...[
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('posGroupDelete'),
                        onPressed: () => context.read<PosModifierBloc>().add(
                          PosModifierDelete(widget.group!.groupId!),
                        ),
                        child: Text(localizations.delete),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('posGroupSave'),
                      onPressed: () {
                        if (_nameController.text.trim().isEmpty) return;
                        context.read<PosModifierBloc>().add(
                          PosModifierSave(
                            PosModifierGroup(
                              groupId: widget.group?.groupId,
                              groupName: _nameController.text.trim(),
                              minSelect: int.tryParse(_minController.text) ?? 0,
                              maxSelect: int.tryParse(_maxController.text) ?? 1,
                              modifiers: _modifiers,
                              productIds: _productIds.toList(),
                            ),
                          ),
                        );
                      },
                      child: Text(localizations.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _modifierController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
