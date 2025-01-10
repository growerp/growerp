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
import 'package:dropdown_search/dropdown_search.dart';
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
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_website.dart';

class WebsiteForm extends StatefulWidget {
  const WebsiteForm({super.key});
  @override
  WebsiteFormState createState() => WebsiteFormState();
}

class WebsiteFormState extends State<WebsiteForm> {
  late WebsiteBloc _websiteBloc;
  late DataFetchBloc<Products> _productBloc;
  late DataFetchBloc<Categories> _categoryBloc;
  List<Content> _updatedContent = [];
  List<Category> _selectedCategories = [];
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _obsidianController = TextEditingController();
  final _measurementIdController = TextEditingController();
  final _stripeApiKeyController = TextEditingController();
  final _productSearchBoxController = TextEditingController();
  final _categorySearchBoxController = TextEditingController();
  final _websiteFormKey1 = GlobalKey<FormState>();
  final _websiteFormKey2 = GlobalKey<FormState>();
  final _websiteFormKey3 = GlobalKey<FormState>();
  final _websiteFormKey4 = GlobalKey<FormState>();
  ScrollController myScrollController = ScrollController();
  late String classificationId;
  late RestClient restClient;

  @override
  void initState() {
    super.initState();
    classificationId = context.read<String>();
    restClient = context.read<RestClient>();
    _websiteBloc = context.read<WebsiteBloc>()..add(WebsiteFetch());
    _categoryBloc = context.read<DataFetchBloc<Categories>>()
      ..add(GetDataEvent(
          () => restClient.getCategory(limit: 3, isForDropDown: true)));
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(GetDataEvent(
          () => restClient.getProduct(limit: 3, isForDropDown: true)));
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
          _stripeApiKeyController.text = websiteState.website!.stripeApiKey;
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
                  return WebsiteContentDialog(state.website!.id, content);
                });
            if (updContent != null) {
              _websiteBloc.add(WebsiteFetch());
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
        onPressed: () async {
          var updContent = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return WebsiteContentDialog(
                    state.website!.id, Content(text: '# '));
              });

          if (updContent != null) {
            _websiteBloc.add(WebsiteFetch());
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
                  return WebsiteContentDialog(state.website!.id, content);
                });
            if (updContent != null) {
              _websiteBloc.add(WebsiteFetch());
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
        onPressed: () async {
          var updContent = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return WebsiteContentDialog(state.website!.id, Content());
              });
          if (updContent != null) {
            _websiteBloc.add(WebsiteFetch());
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
            _websiteBloc.add(WebsiteUpdate(Website(
                id: _websiteBloc.state.website!.id,
                websiteCategories: [
                  category.copyWith(products: productList)
                ])));
          },
        ));
      });
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
                    OutlinedButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop(); //dismiss the color picker
                      },
                    ),
                    OutlinedButton(
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
        : "http://${state.website?.hostName}");

    void doLlaunchUrl() async {
      if (!await launchUrl(url)) throw 'Could not launch $url';
    }

    List<Widget> widgets = [
      InputDecorator(
          decoration: InputDecoration(
              labelText: 'Clickable website URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              )),
          child: Column(children: [
            InkWell(
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
            ),
            Form(
                key: _websiteFormKey1,
                child: Row(children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('urlInput'),
                      controller: _urlController,
                      decoration: const InputDecoration(labelText: 'url'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'A subdomainname is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  Text(
                      state.website!.hostName.contains('.')
                          ? state.website!.hostName
                              .substring(state.website!.hostName.indexOf('.'))
                          : '',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  OutlinedButton(
                      key: const Key('updateHost'),
                      child: const Text('update'),
                      onPressed: () async {
                        if (_websiteFormKey1.currentState!.validate()) {
                          _websiteBloc.add(WebsiteUpdate(Website(
                              id: state.website!.id,
                              hostName: _urlController.text)));
                        }
                      }),
                ]))
          ])),
      Form(
          key: _websiteFormKey2,
          child: InputDecorator(
              decoration: InputDecoration(
                  labelText: 'Title of the website',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  )),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                      key: const Key('title'),
                      controller: _titleController,
                      decoration:
                          const InputDecoration(labelText: 'Title text')),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
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
      InputDecorator(
          decoration: InputDecoration(
              labelText: 'Text sections',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              )),
          child: Column(children: [
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
      InputDecorator(
          decoration: InputDecoration(
              labelText: 'Images',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              )),
          child: Wrap(runSpacing: 10, spacing: 10, children: imageButtons)),
      for (Category category in state.website!.websiteCategories)
        BlocBuilder<DataFetchBloc<Products>, DataFetchState>(
            builder: (context, productState) {
          switch (productState.status) {
            case DataFetchStatus.failure:
              return const FatalErrorForm(message: 'server connection problem');
            case DataFetchStatus.loading:
              return const LoadingIndicator();
            case DataFetchStatus.success:
              return DropdownSearch<Product>.multiSelection(
                key: Key("addProduct${category.categoryName}"),
                dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                        labelText: category.categoryName,
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0)))),
                dropdownBuilder: (context, selectedItems) =>
                    selectedItems.isEmpty
                        ? const Text("No item selected")
                        : Wrap(
                            spacing: 10,
                            children: catButtons.firstWhere((element) =>
                                category.categoryName ==
                                element["categoryName"])["products"]),
                popupProps: PopupPropsMultiSelection.menu(
                  showSelectedItems: false,
                  isFilterOnline: true,
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: "Select product"),
                    controller: _productSearchBoxController,
                  ),
                  title: popUp(
                    context: context,
                    title: "Select product",
                    height: 50,
                    width: 500,
                  ),
                ),
                selectedItems: category.products,
                itemAsString: (Product? u) =>
                    " ${u!.productName}[${u.pseudoId}]",
                asyncItems: (String filter) {
                  _productBloc.add(GetDataEvent(() => restClient.getProduct(
                      searchString: filter,
                      limit: 3,
                      isForDropDown: true,
                      assetClassId:
                          classificationId == 'AppHotel' ? 'Hotel Room' : '')));
                  return Future.delayed(const Duration(milliseconds: 250), () {
                    return Future.value(
                        (_productBloc.state.data as Products).products);
                  });
                },
                compareFn: (item, sItem) => item.productId == sItem.productId,
                onChanged: (List<Product>? newValue) {
                  List<Category> newCats =
                      List.of(state.website!.websiteCategories);
                  int index = newCats.indexWhere(
                      (el) => el.categoryName == category.categoryName);
                  newCats[index] =
                      newCats[index].copyWith(products: newValue ?? []);
                  _websiteBloc.add(WebsiteUpdate(Website(
                      id: state.website!.id, websiteCategories: newCats)));
                },
              );
            default:
              return const Center(child: LoadingIndicator());
          }
        }),
      BlocBuilder<DataFetchBloc<Categories>, DataFetchState>(
          builder: (context, categoryState) {
        switch (categoryState.status) {
          case DataFetchStatus.failure:
            return const FatalErrorForm(message: 'server connection problem');
          case DataFetchStatus.loading:
            return const LoadingIndicator();
          case DataFetchStatus.success:
            return DropdownSearch<Category>.multiSelection(
              key: const Key("addShopCategory}"),
              dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                      isDense: true,
                      labelText: 'Shop dropdown categories',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0)))),
              dropdownBuilder: (context, selectedItems) => selectedItems.isEmpty
                  ? const Text("No item selected")
                  : Wrap(spacing: 10, children: browseCatButtons),
              dropdownButtonProps: const DropdownButtonProps(
                  // for autom test
                  icon: Icon(Icons.arrow_drop_down,
                      size: 24, key: Key("addShopCategory"))),
              popupProps: PopupPropsMultiSelection.menu(
                showSelectedItems: false,
                isFilterOnline: true,
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: WebsiteLocalizations.of(context)!
                        .shopDropdownCategories,
                  ),
                  controller: _categorySearchBoxController,
                ),
                title: popUp(
                  context: context,
                  title: "Select/remove category",
                  height: 50,
                  width: 400,
                ),
              ),
              itemAsString: (Category item) => item.categoryName.truncate(15),
              selectedItems: _selectedCategories,
              asyncItems: (String filter) {
                _categoryBloc.add(GetDataEvent(() => restClient.getCategory(
                      searchString: filter,
                      limit: 3,
                      isForDropDown: true,
                    )));
                return Future.delayed(const Duration(milliseconds: 100), () {
                  return Future.value(
                      (_categoryBloc.state.data as Categories).categories);
                });
              },
              compareFn: (item, sItem) => item.categoryId == sItem.categoryId,
              onChanged: (List<Category>? newValue) {
                _websiteBloc.add(WebsiteUpdate(Website(
                    id: state.website!.id, productCategories: newValue ?? [])));
              },
            );
          default:
            return const Center(child: LoadingIndicator());
        }
      }),
      InputDecorator(
          decoration: InputDecoration(
              labelText: 'Website Colors',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              )),
          child:
              Column(children: [Wrap(spacing: 10, children: colorCatButtons)])),
      InputDecorator(
          decoration: InputDecoration(
              labelText: 'Obsidian vault',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              )),
          child: Row(children: [
            Expanded(
                child: TextField(
                    key: const Key('obsTitle'),
                    controller: _obsidianController,
                    decoration: const InputDecoration(
                        labelText: 'Title of the vault'))),
            const SizedBox(width: 10),
            OutlinedButton(
                key: const Key('upload'),
                child: const Text('Upload '),
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
                child: OutlinedButton(
                    key: const Key('obsidianDelete'),
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red)),
                    onPressed: () async {
                      _websiteBloc.add(WebsiteObsUpload(
                          Obsidian(title: _obsidianController.text), null));
                    },
                    child: const Text('Delete')))
          ])),
      Form(
          key: _websiteFormKey3,
          child: InputDecorator(
              decoration: InputDecoration(
                  labelText: 'Google Website statistics ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  )),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                      key: const Key('measurementId'),
                      controller: _measurementIdController,
                      decoration: const InputDecoration(
                          labelText: 'Statistics Id of the website')),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
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
      Form(
          key: _websiteFormKey4,
          child: InputDecorator(
              decoration: InputDecoration(
                  labelText: 'Stripe Api Key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  )),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                      key: const Key('stripeApi'),
                      controller: _stripeApiKeyController,
                      decoration:
                          const InputDecoration(labelText: 'Stripe Api key')),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                    key: const Key('stripeApiButton'),
                    child: const Text('update'),
                    onPressed: () async {
                      if (_websiteFormKey4.currentState!.validate()) {
                        _websiteBloc.add(WebsiteUpdate(Website(
                            id: state.website!.id,
                            stripeApiKey: _stripeApiKeyController.text)));
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
            child: Column(children: [
              Center(
                  child: Text(
                'id:#${state.website?.id}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                key: const Key('header'),
              )),
              const SizedBox(height: 10),
              Column(children: (rows.isEmpty ? column : rows)),
            ])));
  }
}
