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

import 'dart:convert';
import 'package:growerp_core/growerp_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:from_css_color/from_css_color.dart';
import 'package:growerp_select_dialog/growerp_select_dialog.dart';
import '../../../growerp_website.dart';
import '../website.dart';

class WebsiteForm extends StatelessWidget {
  const WebsiteForm({super.key});

  @override
  Widget build(BuildContext context) => RepositoryProvider(
      create: (context) => WebsiteAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!),
      child: MultiBlocProvider(providers: [
        BlocProvider<WebsiteBloc>(
            create: (BuildContext context) =>
                WebsiteBloc(context.read<WebsiteAPIRepository>())
                  ..add(WebsiteFetch())),
      ], child: const WebsitePage()));
}

class WebsitePage extends StatefulWidget {
  const WebsitePage({super.key});

  @override
  WebsiteFormState createState() => WebsiteFormState();
}

class WebsiteFormState extends State<WebsitePage> {
  late WebsiteBloc _websiteBloc;
  late WebsiteAPIRepository _websiteProvider;
  List<Content> _updatedContent = [];
  List<Category> _selectedCategories = [];
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _obsidianController = TextEditingController();
  final _measurementIdController = TextEditingController();
  final _websiteFormKey1 = GlobalKey<FormState>();
  final _websiteFormKey2 = GlobalKey<FormState>();
  final _websiteFormKey3 = GlobalKey<FormState>();
  ScrollController myScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _websiteBloc = context.read<WebsiteBloc>();
    _websiteProvider = context.read<WebsiteAPIRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebsiteBloc, WebsiteState>(
        listener: (context, websiteState) {
      switch (websiteState.status) {
        case WebsiteStatus.success:
          HelperFunctions.showMessage(
              context, '${websiteState.message}', Colors.green);
          break;
        case WebsiteStatus.failure:
          HelperFunctions.showMessage(
              context, '${websiteState.message}', Colors.red);
          break;
        default:
      }
    }, builder: (context, websiteState) {
      switch (websiteState.status) {
        case WebsiteStatus.success:
          _urlController.text = websiteState.website!.hostName.split('.')[0];
          _titleController.text = websiteState.website!.title;
          _obsidianController.text = websiteState.website!.obsidianName;
          _measurementIdController.text = websiteState.website!.measurementId;
          _updatedContent = List.of(websiteState.website!.websiteContent);
          _selectedCategories =
              List.of(websiteState.website!.productCategories);
          return Scaffold(body: Center(child: _showForm(websiteState)));
        case WebsiteStatus.failure:
          return const Center(child: Text("error happened"));
        default:
          return const LoadingIndicator();
      }
    });
  }

  Widget _showForm(WebsiteState state) {
    // create text content buttons
    List<Widget> textButtons = [];

    // create text content list
    state.website!.websiteContent.asMap().forEach((index, content) {
      if (content.text.isNotEmpty) {
        textButtons.add(InputChip(
          label: Text(
            content.title,
            key: Key(content.title),
          ),
          onPressed: () async {
            var updContent = await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return RepositoryProvider.value(
                      value: _websiteProvider,
                      child: WebsiteContentDialog(state.website!.id, content));
                });
            if (updContent != null) {
              setState(() {
                _websiteBloc.add(WebsiteFetch());
              });
            }
          },
          deleteIcon: const Icon(
            Icons.cancel,
            key: Key("deleteTextChip"),
          ),
          onDeleted: () async {
            bool? result = await confirmDialog(
                context, "delete ${content.title}?", "cannot be undone!");
            if (result == true) {
              _websiteBloc.add(WebsiteUpdate(Website(
                  id: state.website!.id,
                  websiteContent: [
                    _updatedContent[index].copyWith(title: '')
                  ])));
            }
            setState(() {});
          },
        ));
      }
    });
    textButtons.add(IconButton(
        key: const Key('addText'),
        iconSize: 30,
        icon: const Icon(Icons.add_circle),
        color: Colors.deepOrange,
        padding: const EdgeInsets.all(0.0),
        onPressed: () async {
          var updContent = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return RepositoryProvider.value(
                    value: _websiteProvider,
                    child: WebsiteContentDialog(
                        state.website!.id, Content(text: '# ')));
              });

          if (updContent != null) {
            setState(() {
              _websiteBloc.add(WebsiteFetch());
            });
          }
        }));

    // create image buttons
    List<Widget> imageButtons = [];
    state.website!.websiteContent.asMap().forEach((index, content) {
      if (content.text.isEmpty) {
        imageButtons.add(InputChip(
          label: Text(
            content.title,
            key: Key(content.title),
          ),
          onPressed: () async {
            var updContent = await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return RepositoryProvider.value(
                      value: _websiteProvider,
                      child: WebsiteContentDialog(state.website!.id, content));
                });
            if (updContent != null) {
              setState(() {
                _websiteBloc.add(WebsiteFetch());
              });
            }
          },
          deleteIcon: const Icon(
            Icons.cancel,
            key: Key("deleteImageChip"),
          ),
          onDeleted: () async {
            bool? result = await confirmDialog(context,
                "delete ${content.title}?", "This delete cannot be undone!");
            if (result == true) {
              setState(() {
                _websiteBloc.add(WebsiteUpdate(Website(
                    id: state.website!.id,
                    websiteContent: [
                      _updatedContent[index].copyWith(title: '')
                    ])));
              });
            }
          },
        ));
      }
    });
    imageButtons.add(IconButton(
        key: const Key('addImage'),
        iconSize: 30,
        icon: const Icon(Icons.add_circle),
        color: Colors.deepOrange,
        padding: const EdgeInsets.all(0.0),
        onPressed: () async {
          var updContent = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return RepositoryProvider.value(
                    value: _websiteProvider,
                    child: WebsiteContentDialog(state.website!.id, Content()));
              });
          if (updContent != null) {
            setState(() {
              _websiteBloc.add(WebsiteFetch());
            });
          }
        }));

    // create website category buttons
    List<Map<String, dynamic>> catButtons = [];
    state.website!.websiteCategories.asMap().forEach((index, category) {
      List<Widget> productWidgets = [];
      category.products.asMap().forEach((productIndex, product) {
        productWidgets.add(InputChip(
          label: Text(
            product.productName ?? '',
            key: Key(product.productName ?? ''),
          ),
          deleteIcon: const Icon(Icons.cancel, key: Key('deleteProductChip')),
          onDeleted: () async {
            var productList = List.of(
                _websiteBloc.state.website!.websiteCategories[index].products);
            productList.removeAt(productIndex);
            context.read<WebsiteBloc>().add(WebsiteUpdate(Website(
                    id: _websiteBloc.state.website!.id,
                    websiteCategories: [
                      category.copyWith(products: productList)
                    ])));
          },
        ));
      });

      Future<List<Product>> getProduct(String filter) async {
        ApiResult<List<Product>> result =
            await _websiteProvider.lookUpProduct(searchString: filter);
        return result.when(
            success: (data) => data,
            failure: (_) => [Product(productName: 'get data error!')]);
      }

      productWidgets.add(IconButton(
        key: Key("addProduct${category.categoryName}"),
        iconSize: 30,
        icon: const Icon(Icons.add_circle),
        color: Colors.deepOrange,
        padding: const EdgeInsets.all(0.0),
        onPressed: () async {
          SelectDialog.showModal<Product>(
            context,
            searchBoxDecoration: InputDecoration(
                labelText: 'Search text here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                )),
            label: "Find and (un)select products",
            alwaysShowScrollBar: true,
            multipleSelectedValues: category.products,
            onFind: (String filter) async => await getProduct(filter),
            itemBuilder: (context, item, isSelected) {
              return ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                        item.productName != null ? item.productName![0] : '')),
                trailing: isSelected ? const Icon(Icons.check) : null,
                title: Text(item.productName ?? ''),
                subtitle: Text(item.price.toString()),
                selected: isSelected,
              );
            },
            onMultipleItemsChange: (List<Product> selected) {
              _websiteBloc.add(WebsiteUpdate(Website(
                  id: state.website!.id,
                  websiteCategories: [category.copyWith(products: selected)])));
            },
            okButtonBuilder: (context, onPressed) {
              return ElevatedButton(
                  key: const Key('ok'),
                  onPressed: onPressed,
                  child: const Text('ok'));
            },
          );
        },
      ));
      catButtons.add(
          {"categoryName": category.categoryName, "products": productWidgets});
    });

    // create product browse categories
    List<Widget> browseCatButtons = [];
    state.website!.productCategories.asMap().forEach((index, category) {
      browseCatButtons.add(InputChip(
        label: Text(
          category.categoryName,
          key: Key(category.categoryName),
        ),
        deleteIcon: const Icon(
          Icons.cancel,
          key: Key("deleteCategoryChip"),
        ),
        onDeleted: () async {
          bool? result = await confirmDialog(context,
              "Remove ${category.categoryName}?", "can be added again!");
          if (result == true) {
            setState(() {
              _selectedCategories.removeAt(index);
              if (_selectedCategories.isEmpty) {
                _selectedCategories.add(Category(categoryId: 'allDelete'));
              }
              _websiteBloc.add(WebsiteUpdate(Website(
                  id: state.website!.id,
                  productCategories: _selectedCategories)));
            });
          }
        },
      ));
    });

    Future<List<Category>> getCategory(String filter) async {
      ApiResult<List<Category>> result =
          await _websiteProvider.getCategory(searchString: filter);
      return result.when(
          success: (data) => data,
          failure: (_) => [Category(categoryName: 'get data error!')]);
    }

    browseCatButtons.add(IconButton(
      key: const Key('addShopCategory'),
      iconSize: 30,
      icon: const Icon(Icons.add_circle),
      color: Colors.deepOrange,
      padding: const EdgeInsets.all(0.0),
      onPressed: () async {
        SelectDialog.showModal<Category>(
          context,
          searchBoxDecoration: InputDecoration(
              labelText: 'Search text here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              )),
          label: "Find and (un)select categories",
          alwaysShowScrollBar: true,
          multipleSelectedValues: state.website!.productCategories,
          onFind: (String filter) async => await getCategory(filter),
          itemBuilder: (context, item, isSelected) {
            return ListTile(
              leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(item.categoryName.isNotEmpty
                      ? item.categoryName[0]
                      : '')),
              trailing: isSelected ? const Icon(Icons.check) : null,
              title: Text(item.categoryName),
              subtitle: Text(item.description),
              selected: isSelected,
            );
          },
          onMultipleItemsChange: (List<Category> selected) {
            _websiteBloc.add(WebsiteUpdate(
                Website(id: state.website!.id, productCategories: selected)));
          },
          okButtonBuilder: (context, onPressed) {
            return ElevatedButton(
                key: const Key('ok'),
                onPressed: onPressed,
                child: const Text('ok'));
          },
        );
      },
    ));

    // create product browse categories
    List<Widget> colorCatButtons = [];
    Map websiteColor = {};
    if (state.website!.colorJson.isNotEmpty) {
      websiteColor = jsonDecode(state.website!.colorJson);
    }
    websiteColor['HeaderFooterBg'] = websiteColor['HeaderFooterBg'] == ''
        ? '#ffeb3b'
        : websiteColor['HeaderFooterBg'] ?? '#ffeb3b';
    websiteColor['HeaderFooterText'] = websiteColor['HeaderFooterText'] == ''
        ? '#ff5722'
        : websiteColor['HeaderFooterText'] ?? '#ff5722';
    websiteColor.forEach((key, value) => colorCatButtons.add(InputChip(
        backgroundColor: fromCssColor(websiteColor[key]),
        label: Text(key,
            key: Key(key),
            style: TextStyle(
                color: fromCssColor(websiteColor[key]).computeLuminance() < 0.5
                    ? Colors.white
                    : Colors.black)),
        onPressed: () async {
          var result = await showDialog(
              context: context,
              builder: (BuildContext context) {
                String cssColor = '';
                return AlertDialog(
                  title: const Text('Pick a color!'),
                  content: SingleChildScrollView(
                    child: MaterialPicker(
                      pickerColor: fromCssColor(value), //default color
                      onColorChanged: (Color color) {
                        setState(() {
                          cssColor = color.toCssString();
                        });
                      },
                    ),
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop(); //dismiss the color picker
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Save'),
                      onPressed: () {
                        Navigator.of(context)
                            .pop(cssColor); //dismiss the color picker
                      },
                    ),
                  ],
                );
              });
          if (result != null) {
            setState(() {
              websiteColor[key] = result;
              _websiteBloc.add(WebsiteUpdate(Website(
                  id: state.website!.id, colorJson: jsonEncode(websiteColor))));
            });
          }
        })));

    final Uri url = Uri.parse(foundation.kReleaseMode
        ? "https://${state.website?.hostName}"
        : "http://${state.website!.id}.localhost:8080");

    void doLlaunchUrl() async {
      if (!await launchUrl(url)) throw 'Could not launch $url';
    }

    List<Widget> widgets = [
      Container(
          width: 400,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: InkWell(
            onTap: doLlaunchUrl,
            child: Text(
              "${state.website?.hostName}",
              key: const Key('url'),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )),
      Form(
          key: _websiteFormKey1,
          child: Container(
              width: 400,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(
                    color: Colors.black45,
                    style: BorderStyle.solid,
                    width: 0.80),
              ),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('urlInput'),
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: 'url'),
                    validator: (value) {
                      if (value!.isEmpty) return 'A subdomainname is required';
                      return null;
                    },
                  ),
                ),
                Text(
                    state.website!.hostName
                        .substring(state.website!.hostName.indexOf('.')),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                ElevatedButton(
                    key: const Key('updateHost'),
                    child: const Text('update'),
                    onPressed: () async {
                      if (_websiteFormKey1.currentState!.validate()) {
                        _websiteBloc.add(WebsiteUpdate(Website(
                            id: state.website!.id,
                            hostName: _urlController.text)));
                      }
                    }),
              ]))),
      Form(
          key: _websiteFormKey2,
          child: Container(
              width: 400,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(
                    color: Colors.black45,
                    style: BorderStyle.solid,
                    width: 0.80),
              ),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                      key: const Key('title'),
                      controller: _titleController,
                      decoration: const InputDecoration(
                          labelText: 'Title of the website')),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                    key: const Key('updateTitle'),
                    child: const Text('update'),
                    onPressed: () async {
                      if (_websiteFormKey2.currentState!.validate()) {
                        _websiteBloc.add(WebsiteUpdate(Website(
                            id: state.website!.id,
                            title: _titleController.text)));
                      }
                    }),
              ]))),
      Container(
          width: 400,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            const Text(
              'Text sections',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Can change order with long press',
              style: TextStyle(fontSize: 10),
            ),
            PrimaryScrollController(
                controller: myScrollController,
                child: ReorderableWrap(
                    runSpacing: 10,
                    onReorder: (int oldIndex, int newIndex) {
                      List<Content> content = List.of(state
                          .website!.websiteContent
                          .where((el) => el.text.isNotEmpty));
                      if (newIndex == content.length) newIndex--;
                      var save = content[oldIndex];
                      content[oldIndex] = content[newIndex];
                      content[newIndex] = save;
                      int index = 1;
                      for (int i = 0; i < content.length; i++) {
                        content[i] = content[i].copyWith(seqId: index++);
                      }
                      _websiteBloc.add(WebsiteUpdate(Website(
                          id: state.website!.id, websiteContent: content)));
                    },
                    spacing: 10,
                    children: textButtons))
          ])),
      Container(
          width: 400,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            const Text(
              'Images',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(runSpacing: 10, spacing: 10, children: imageButtons)
          ])),
      for (Map cat in catButtons)
        Container(
            width: 400,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(
                  color: Colors.black45, style: BorderStyle.solid, width: 0.80),
            ),
            child: Column(children: [
              Text(
                cat["categoryName"],
                key: Key(cat["categoryName"]),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Wrap(spacing: 10, children: cat["products"])
            ])),
      Container(
          width: 400,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            Text(
              WebsiteLocalizations.of(context)!.shopDropdownCategories,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 10, children: browseCatButtons)
          ])),
      Container(
          width: 400,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            const Text(
              'Website colors',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 10, children: colorCatButtons)
          ])),
      Container(
          width: 400,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Row(children: [
            Expanded(
                child: TextField(
                    key: const Key('obsTitle'),
                    controller: _obsidianController,
                    decoration: const InputDecoration(
                        labelText: 'Title of the vault'))),
            const SizedBox(width: 10),
            ElevatedButton(
                key: const Key('upload'),
                child: const Text('Upload Obsidian Vault'),
                onPressed: () async {
                  FilePickerResult? result;
                  String? path;
                  if (foundation.kIsWeb) {
                    result = await FilePicker.platform.pickFiles(
                        allowedExtensions: ['zip'], type: FileType.custom);
                  } else {
                    path = await FilePicker.platform.getDirectoryPath();
                  }

                  if (path != null || result != null) {
                    _websiteBloc.add(WebsiteObsUpload(
                        Obsidian(
                            title: _obsidianController.text,
                            zip: result?.files.first.bytes!),
                        path));
                  }
                }),
            const SizedBox(width: 10),
            Visibility(
                visible: _obsidianController.text.isNotEmpty,
                child: ElevatedButton(
                    key: const Key('obsidianDelete'),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red)),
                    onPressed: () async {
                      _websiteBloc.add(WebsiteObsUpload(
                          Obsidian(title: _obsidianController.text), null));
                    },
                    child: const Text('Delete')))
          ])),
      Form(
          key: _websiteFormKey3,
          child: Container(
              width: 400,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(
                    color: Colors.black45,
                    style: BorderStyle.solid,
                    width: 0.80),
              ),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                      key: const Key('measurementId'),
                      controller: _measurementIdController,
                      decoration: const InputDecoration(
                          labelText: 'Statistics Id of the website')),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                    key: const Key('measurementId'),
                    child: const Text('update'),
                    onPressed: () async {
                      if (_websiteFormKey3.currentState!.validate()) {
                        _websiteBloc.add(WebsiteUpdate(Website(
                            id: state.website!.id,
                            measurementId: _measurementIdController.text)));
                      }
                    }),
              ]))),
    ];

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10), child: widgets[i++])),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: i < widgets.length ? widgets[i] : Container()))
          ],
        ));
      }
    }

    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(padding: const EdgeInsets.all(10), child: widgets[i]));
    }

    return Center(
        child: SingleChildScrollView(
            key: const Key('listView'),
            padding: const EdgeInsets.all(20),
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(children: [
                  Center(
                      child: Text(
                    'id:#${state.website?.id}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                    key: const Key('header'),
                  )),
                  const SizedBox(height: 10),
                  Column(children: (rows.isEmpty ? column : rows)),
                ]))));
  }
}
