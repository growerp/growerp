Package designed to select an item from a list, with the option to filter and even search the items online.

Based on [select_dialog V2.0.0](https://pub.dev/packages/select_dialog) with the following changes:
- design of the dialog in the 'GrowERP' design
- A close window button is added.
- modal screen sizes

<img src="https://user-images.githubusercontent.com/16373553/94357714-95d4fc80-0071-11eb-8b99-9cff034a1ece.png" width="49.5%" /> <img src="https://user-images.githubusercontent.com/16373553/94357674-4098eb00-0071-11eb-8985-45edf99b9812.png" width="49.5%" />

## Versions
**Non Null Safety Version**: 1.2.3 or less

**Null Safety Version**: 2.0.0 or more

## pubspec.yaml
```yaml
growerp_select_dialog: <last version>
```

## import
```dart
import 'package:growerp_select_dialog/growerp_select_dialog.dart';
```

## Simple example
```dart
String ex1 = "No value selected";

SelectDialog.showModal<String>(
  context,
  label: "Simple Example",
  selectedValue: ex1,
  items: List.generate(50, (index) => "Item $index"),
  onChange: (String selected) {
    setState(() {
      ex1 = selected;
    });
  },
);
```

## Multiple items select
```dart
List<String> ex5 = [];

SelectDialog.showModal<String>(
  context,
  label: "Multiple Items Example",
  multipleSelectedValues: ex5,
  items: List.generate(50, (index) => "Item $index"),
  onMultipleItemsChange: (List<String> selected) {
    setState(() {
      ex5 = selected;
    });
  },
); 
```

### [MORE EXAMPLES](https://github.com/davidsdearaujo/growerp_select_dialog/tree/master/example)


# Attention
To use a template as an item type, you need to implement **toString**, **equals** and **hashcode**, as shown below:

```dart
class UserModel {
  final String id;
  final DateTime createdAt;
  final String name;
  final String avatar;

  UserModel({this.id, this.createdAt, this.name, this.avatar});

  @override
  String toString() => name;

  @override
  operator ==(o) => o is UserModel && o.id == id;

  @override
  int get hashCode => id.hashCode^name.hashCode^createdAt.hashCode;

}
```


## Getting Started

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
