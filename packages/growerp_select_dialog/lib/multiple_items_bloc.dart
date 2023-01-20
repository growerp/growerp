class MultipleItemsBloc<T> {
  final void Function(List<T>)? onMultipleItemsChange;
  MultipleItemsBloc(
    List<T>? initialSelectedItems,
    this.onMultipleItemsChange,
  ) {
    selectedItems = initialSelectedItems ?? <T>[];
  }

  late List<T> selectedItems;

  void selectItem(T item) {
    if (!selectedItems.contains(item)) selectedItems.add(item);
  }

  void unselectItem(T item) {
    if (selectedItems.contains(item)) selectedItems.remove(item);
  }

  void onSelectButtonPressed() {
    onMultipleItemsChange?.call(selectedItems);
  }
}
