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

import 'dart:async';
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
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_website.dart';

class WebsiteDialog extends StatefulWidget {
  const WebsiteDialog({super.key});
  @override
  WebsiteDialogState createState() => WebsiteDialogState();
}

class WebsiteDialogState extends State<WebsiteDialog> {
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

  final _landingPageIdController = TextEditingController();
  final _checkoutAmountController = TextEditingController();
  final _websiteFormKey1 = GlobalKey<FormState>();
  final _websiteFormKey2 = GlobalKey<FormState>();
  final _websiteFormKey3 = GlobalKey<FormState>();
  final _websiteFormKey4 = GlobalKey<FormState>();
  ScrollController myScrollController = ScrollController();
  late String classificationId;
  late RestClient restClient;
  late WebsiteLocalizations _localizations;
  List<LandingPage> _landingPages = [];
  static const _borderRadius = BorderRadius.all(Radius.circular(25));

  @override
  void initState() {
    super.initState();
    classificationId = context.read<String>();
    restClient = context.read<RestClient>();
    _websiteBloc = context.read<WebsiteBloc>()..add(WebsiteFetch());
    _categoryBloc = context.read<DataFetchBloc<Categories>>()
      ..add(
        GetDataEvent(
          () => restClient.getCategory(limit: 3, isForDropDown: true),
        ),
      );
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
        GetDataEvent(
          () => restClient.getProduct(limit: 3, isForDropDown: true),
        ),
      );
    _fetchLandingPages();
  }

  Future<void> _fetchLandingPages() async {
    try {
      final result = await restClient.getLandingPages(limit: 100);
      setState(() {
        _landingPages = result.landingPages;
      });
    } catch (e) {
      // Silently fail, landing pages will be empty
    }
  }

  @override
  Widget build(BuildContext context) {
    _localizations = WebsiteLocalizations.of(context)!;
    return BlocConsumer<WebsiteBloc, WebsiteState>(
      listener: (context, websiteState) {
        switch (websiteState.status) {
          case WebsiteStatus.success:
            HelperFunctions.showMessage(
              context,
              '${websiteState.message}',
              Colors.green,
            );
            break;
          case WebsiteStatus.failure:
            HelperFunctions.showMessage(
              context,
              '${websiteState.message}',
              Colors.red,
            );
            break;
          default:
        }
      },
      builder: (context, websiteState) {
        switch (websiteState.status) {
          case WebsiteStatus.success:
            _urlController.text = websiteState.website!.hostName.split('.')[0];
            _titleController.text = websiteState.website!.title;
            _obsidianController.text = websiteState.website!.obsidianName;
            _measurementIdController.text = websiteState.website!.measurementId;
            _stripeApiKeyController.text = websiteState.website!.stripeApiKey;
            _updatedContent = List.of(websiteState.website!.websiteContent);
            _selectedCategories = List.of(
              websiteState.website!.productCategories,
            );
            return _showForm(websiteState);
          case WebsiteStatus.failure:
            return Center(child: Text(_localizations.errorTitle));
          default:
            return const LoadingIndicator();
        }
      },
    );
  }

  Widget _showForm(WebsiteState state) {
    // create text content buttons
    List<Widget> textButtons = [];

    // create text content list
    state.website!.websiteContent.asMap().forEach((index, content) {
      if (content.text.isNotEmpty) {
        textButtons.add(
          InputChip(
            label: Text(content.title, key: Key(content.title)),
            onPressed: () async {
              var updContent = await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return WebsiteContentDialog(state.website!.id, content);
                },
              );
              if (updContent != null) {
                _websiteBloc.add(WebsiteFetch());
              }
            },
            deleteIcon: const Icon(Icons.cancel, key: Key("deleteTextChip")),
            onDeleted: () async {
              bool? result = await confirmDialog(
                context,
                _localizations.areYouSure,
                _localizations.websiteContentDelete,
              );
              if (result == true) {
                _websiteBloc.add(
                  WebsiteUpdate(
                    Website(
                      id: state.website!.id,
                      websiteContent: [
                        _updatedContent[index].copyWith(title: ''),
                      ],
                    ),
                  ),
                );
              }
              setState(() {});
            },
          ),
        );
      }
    });
    textButtons.add(
      IconButton(
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
                state.website!.id,
                Content(text: '# '),
              );
            },
          );

          if (updContent != null) {
            _websiteBloc.add(WebsiteFetch());
          }
        },
      ),
    );

    // create image buttons
    List<Widget> imageButtons = [];
    state.website!.websiteContent.asMap().forEach((index, content) {
      if (content.text.isEmpty) {
        imageButtons.add(
          InputChip(
            label: Text(content.title, key: Key(content.title)),
            onPressed: () async {
              var updContent = await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return WebsiteContentDialog(state.website!.id, content);
                },
              );
              if (updContent != null) {
                _websiteBloc.add(WebsiteFetch());
              }
            },
            deleteIcon: const Icon(Icons.cancel, key: Key("deleteImageChip")),
            onDeleted: () async {
              bool? result = await confirmDialog(
                context,
                _localizations.areYouSure,
                _localizations.websiteContentDelete,
              );
              if (result == true) {
                setState(() {
                  _websiteBloc.add(
                    WebsiteUpdate(
                      Website(
                        id: state.website!.id,
                        websiteContent: [
                          _updatedContent[index].copyWith(title: ''),
                        ],
                      ),
                    ),
                  );
                });
              }
            },
          ),
        );
      }
    });
    imageButtons.add(
      IconButton(
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
            },
          );
          if (updContent != null) {
            _websiteBloc.add(WebsiteFetch());
          }
        },
      ),
    );

    // create website category buttons
    List<Map<String, dynamic>> catButtons = [];
    state.website!.websiteCategories.asMap().forEach((index, category) {
      List<Widget> productWidgets = [];
      category.products.asMap().forEach((productIndex, product) {
        productWidgets.add(
          InputChip(
            label: Text(
              product.productName ?? '',
              key: Key(product.productName ?? ''),
            ),
            deleteIcon: const Icon(Icons.cancel, key: Key('deleteProductChip')),
            onDeleted: () async {
              var productList = List.of(
                _websiteBloc.state.website!.websiteCategories[index].products,
              );
              productList.removeAt(productIndex);
              _websiteBloc.add(
                WebsiteUpdate(
                  Website(
                    id: _websiteBloc.state.website!.id,
                    websiteCategories: [
                      category.copyWith(products: productList),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      });
      catButtons.add({
        "categoryName": category.categoryName,
        "products": productWidgets,
      });
    });

    // create product browse categories
    List<Widget> browseCatButtons = [];
    state.website!.productCategories.asMap().forEach((index, category) {
      browseCatButtons.add(
        InputChip(
          label: Text(category.categoryName, key: Key(category.categoryName)),
          deleteIcon: const Icon(Icons.cancel, key: Key("deleteCategoryChip")),
          onDeleted: () async {
            bool? result = await confirmDialog(
              context,
              _localizations.areYouSure,
              _localizations.remove,
            );
            if (result == true) {
              setState(() {
                _selectedCategories.removeAt(index);
                if (_selectedCategories.isEmpty) {
                  _selectedCategories.add(Category(categoryId: 'allDelete'));
                }
                _websiteBloc.add(
                  WebsiteUpdate(
                    Website(
                      id: state.website!.id,
                      productCategories: _selectedCategories,
                    ),
                  ),
                );
              });
            }
          },
        ),
      );
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
    websiteColor.forEach(
      (key, value) => colorCatButtons.add(
        InputChip(
          backgroundColor: fromCssColor(websiteColor[key]),
          label: Text(
            key,
            key: Key(key),
            style: TextStyle(
              color: fromCssColor(websiteColor[key]).computeLuminance() < 0.5
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          onPressed: () async {
            var result = await showDialog(
              context: context,
              builder: (BuildContext context) {
                String cssColor = '';
                return AlertDialog(
                  title: Text(_localizations.websiteColor),
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
                      child: Text(_localizations.cancel),
                      onPressed: () {
                        Navigator.of(context).pop(); //dismiss the color picker
                      },
                    ),
                    OutlinedButton(
                      child: Text(_localizations.save),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(cssColor); //dismiss the color picker
                      },
                    ),
                  ],
                );
              },
            );
            if (result != null) {
              setState(() {
                websiteColor[key] = result;
                _websiteBloc.add(
                  WebsiteUpdate(
                    Website(
                      id: state.website!.id,
                      colorJson: jsonEncode(websiteColor),
                    ),
                  ),
                );
              });
            }
          },
        ),
      ),
    );

    final Uri url = Uri.parse(
      foundation.kReleaseMode
          ? "https://${state.website?.hostName}"
          : "http://${state.website?.hostName}",
    );

    void doLlaunchUrl() async {
      if (!await launchUrl(url)) throw 'Could not launch $url';
    }

    List<Widget> widgets = [
      GroupingDecorator(
        labelText: _localizations.websiteUrl,
        child: Column(
          children: [
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
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('urlInput'),
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: _localizations.websiteUrl,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return '${_localizations.websiteUrl} ${_localizations.errorTitle}';
                        }
                        return null;
                      },
                    ),
                  ),
                  Text(
                    state.website!.hostName.contains('.')
                        ? state.website!.hostName.substring(
                            state.website!.hostName.indexOf('.'),
                          )
                        : '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    key: const Key('updateHost'),
                    child: Text(_localizations.update),
                    onPressed: () async {
                      if (_websiteFormKey1.currentState!.validate()) {
                        _websiteBloc.add(
                          WebsiteUpdate(
                            Website(
                              id: state.website!.id,
                              hostName: _urlController.text,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Form(
        key: _websiteFormKey2,
        child: GroupingDecorator(
          labelText: _localizations.websiteTitle,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('title'),
                  controller: _titleController,
                  decoration: InputDecoration(labelText: _localizations.title),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                key: const Key('updateTitle'),
                child: Text(_localizations.update),
                onPressed: () async {
                  if (_websiteFormKey2.currentState!.validate()) {
                    _websiteBloc.add(
                      WebsiteUpdate(
                        Website(
                          id: state.website!.id,
                          title: _titleController.text,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      GroupingDecorator(
        labelText: 'Quick Links',
        child: Column(
          children: [
            OutlinedButton.icon(
              key: const Key('adminLink'),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('/admin'),
              onPressed: () {
                launchUrl(Uri.parse('http://${state.website!.hostName}/admin'));
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    key: const Key('landingPageLink'),
                    icon: const Icon(Icons.language),
                    label: const Text('/assessmentLanding'),
                    onPressed: () {
                      if (_landingPageIdController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a page first'),
                          ),
                        );
                        return;
                      }
                      launchUrl(
                        Uri.parse(
                          'http://${state.website!.hostName}/assessmentLanding?landingPageId=${_landingPageIdController.text}',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AutocompleteLabel<LandingPage>(
                    key: const Key('landingPageDropdown'),
                    label: 'Select Page',
                    initialValue: _landingPages
                        .where(
                          (p) => p.landingPageId == _landingPageIdController.text,
                        )
                        .firstOrNull,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _landingPages;
                      }
                      return _landingPages.where(
                        (p) => p.title.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },
                    displayStringForOption: (LandingPage p) => p.title,
                    onSelected: (LandingPage? selected) {
                      setState(() {
                        _landingPageIdController.text =
                            selected?.landingPageId ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    key: const Key('checkoutLink'),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('/checkoutOnePage'),
                    onPressed: () {
                      final amount = _checkoutAmountController.text.isNotEmpty
                          ? _checkoutAmountController.text
                          : '0';
                      launchUrl(
                        Uri.parse(
                          'http://${state.website!.hostName}/checkoutOnePage?amount=$amount',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _checkoutAmountController,
                    decoration: const InputDecoration(
                      hintText: 'Amount',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      GroupingDecorator(
        labelText: _localizations.content,
        child: Column(
          children: [
            Text(_localizations.page, style: const TextStyle(fontSize: 10)),
            PrimaryScrollController(
              controller: myScrollController,
              child: ReorderableWrap(
                runSpacing: 10,
                onReorder: (int oldIndex, int newIndex) {
                  List<Content> content = List.of(
                    state.website!.websiteContent.where(
                      (el) => el.text.isNotEmpty,
                    ),
                  );
                  if (newIndex == content.length) newIndex--;
                  var save = content[oldIndex];
                  content[oldIndex] = content[newIndex];
                  content[newIndex] = save;
                  int index = 1;
                  for (int i = 0; i < content.length; i++) {
                    content[i] = content[i].copyWith(seqId: index++);
                  }
                  _websiteBloc.add(
                    WebsiteUpdate(
                      Website(id: state.website!.id, websiteContent: content),
                    ),
                  );
                },
                spacing: 10,
                children: textButtons,
              ),
            ),
          ],
        ),
      ),
      GroupingDecorator(
        labelText: _localizations.images,
        child: Wrap(runSpacing: 10, spacing: 10, children: imageButtons),
      ),
      for (Category category in state.website!.websiteCategories)
        BlocBuilder<DataFetchBloc<Products>, DataFetchState<Products>>(
          builder: (context, productState) {
            switch (productState.status) {
              case DataFetchStatus.failure:
                return FatalErrorForm(message: _localizations.errorTitle);
              case DataFetchStatus.loading:
                return const LoadingIndicator();
              case DataFetchStatus.success:
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: category.categoryName,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category.products.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          children: catButtons.firstWhere(
                            (element) =>
                                category.categoryName ==
                                element["categoryName"],
                          )["products"],
                        ),
                      Autocomplete<Product>(
                        key: Key("addProduct${category.categoryName}"),
                        optionsBuilder:
                            (TextEditingValue textEditingValue) async {
                              _productBloc.add(
                                GetDataEvent(
                                  () => restClient.getProduct(
                                    searchString: textEditingValue.text,
                                    limit: 3,
                                    isForDropDown: true,
                                  ),
                                ),
                              );
                              await Future.delayed(
                                const Duration(milliseconds: 250),
                              );
                              if (!mounted) {
                                return Completer<Iterable<Product>>().future;
                              }
                              return (_productBloc.state.data as Products)
                                  .products;
                            },
                        displayStringForOption: (Product u) =>
                            " ${u.productName}[${u.pseudoId}]",
                        fieldViewBuilder:
                            (
                              context,
                              textController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: _localizations.select,
                                  border: InputBorder.none,
                                ),
                                onFieldSubmitted: (String value) {
                                  onFieldSubmitted();
                                },
                              );
                            },
                        onSelected: (Product newValue) {
                          List<Category> newCats = List.of(
                            state.website!.websiteCategories,
                          );
                          int index = newCats.indexWhere(
                            (el) => el.categoryName == category.categoryName,
                          );
                          List<Product> currentProducts = List.of(
                            newCats[index].products,
                          );
                          if (!currentProducts.any(
                            (p) => p.productId == newValue.productId,
                          )) {
                            currentProducts.add(newValue);
                            newCats[index] = newCats[index].copyWith(
                              products: currentProducts,
                            );
                            _websiteBloc.add(
                              WebsiteUpdate(
                                Website(
                                  id: state.website!.id,
                                  websiteCategories: newCats,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              default:
                return const Center(child: LoadingIndicator());
            }
          },
        ),
      BlocBuilder<DataFetchBloc<Categories>, DataFetchState<Categories>>(
        builder: (context, categoryState) {
          switch (categoryState.status) {
            case DataFetchStatus.failure:
              return FatalErrorForm(message: _localizations.errorTitle);
            case DataFetchStatus.loading:
              return const LoadingIndicator();
            case DataFetchStatus.success:
              return InputDecorator(
                decoration: InputDecoration(
                  isDense: true,
                  labelText: _localizations.websiteProductCategories,
                  border: const OutlineInputBorder(borderRadius: _borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedCategories.isNotEmpty)
                      Wrap(spacing: 10, children: browseCatButtons),
                    Autocomplete<Category>(
                      key: const Key("addShopCategory}"),
                      optionsBuilder:
                          (TextEditingValue textEditingValue) async {
                            _categoryBloc.add(
                              GetDataEvent(
                                () => restClient.getCategory(
                                  searchString: textEditingValue.text,
                                  limit: 3,
                                  isForDropDown: true,
                                ),
                              ),
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                            if (!mounted) {
                              return Completer<Iterable<Category>>().future;
                            }
                            return (_categoryBloc.state.data as Categories)
                                .categories;
                          },
                      displayStringForOption: (Category item) =>
                          item.categoryName.truncate(15),
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: _localizations.select,
                                border: InputBorder.none,
                              ),
                              onFieldSubmitted: (String value) {
                                onFieldSubmitted();
                              },
                            );
                          },
                      onSelected: (Category newValue) {
                        if (!_selectedCategories.any(
                          (c) => c.categoryId == newValue.categoryId,
                        )) {
                          List<Category> newCategories = List.of(
                            _selectedCategories,
                          )..add(newValue);
                          _websiteBloc.add(
                            WebsiteUpdate(
                              Website(
                                id: state.website!.id,
                                productCategories: newCategories,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            default:
              return const Center(child: LoadingIndicator());
          }
        },
      ),
      GroupingDecorator(
        labelText: _localizations.websiteColor,
        child: Column(children: [Wrap(spacing: 10, children: colorCatButtons)]),
      ),
      GroupingDecorator(
        labelText: _localizations.websiteObsidian,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('obsTitle'),
                controller: _obsidianController,
                decoration: InputDecoration(labelText: _localizations.title),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              key: const Key('upload'),
              child: Text(_localizations.upload),
              onPressed: () async {
                FilePickerResult? result;
                String? path;
                // Note: Using FileType.any because file_picker 10.1.2 has a
                // known bug where FileType.custom with allowedExtensions
                // prevents file selection. We validate the extension manually.
                result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  withData: true, // Ensure bytes are available on all platforms
                );

                // Cancelled by user
                if (result == null || result.files.isEmpty) {
                  return;
                }

                // Validate that the selected file is a .zip file
                if (!result.files.first.name.toLowerCase().endsWith('.zip')) {
                  if (mounted) {
                    HelperFunctions.showMessage(
                      context,
                      'Please select a .zip file',
                      Colors.red,
                    );
                  }
                  return;
                }

                // On desktop platforms, get the path from the file
                if (!foundation.kIsWeb) {
                  path = result.files.first.path;
                }

                _websiteBloc.add(
                  WebsiteObsUpload(
                    Obsidian(
                      title: _obsidianController.text,
                      zip: result.files.first.bytes,
                    ),
                    path,
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Visibility(
              visible: _obsidianController.text.isNotEmpty,
              child: OutlinedButton(
                key: const Key('obsidianDelete'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                onPressed: () async {
                  _websiteBloc.add(
                    WebsiteObsUpload(
                      Obsidian(title: _obsidianController.text),
                      null,
                    ),
                  );
                },
                child: Text(_localizations.deleteButton),
              ),
            ),
          ],
        ),
      ),
      Form(
        key: _websiteFormKey3,
        child: GroupingDecorator(
          labelText: _localizations.websiteMeasurementId,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('measurementId'),
                  controller: _measurementIdController,
                  decoration: InputDecoration(labelText: _localizations.id),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                key: const Key('measurementId'),
                child: Text(_localizations.update),
                onPressed: () async {
                  if (_websiteFormKey3.currentState!.validate()) {
                    _websiteBloc.add(
                      WebsiteUpdate(
                        Website(
                          id: state.website!.id,
                          measurementId: _measurementIdController.text,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      Form(
        key: _websiteFormKey4,
        child: GroupingDecorator(
          labelText: _localizations.websiteStripeApiKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('stripeApi'),
                  controller: _stripeApiKeyController,
                  decoration: InputDecoration(labelText: _localizations.key),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                key: const Key('stripeApiButton'),
                child: Text(_localizations.update),
                onPressed: () async {
                  if (_websiteFormKey4.currentState!.validate()) {
                    _websiteBloc.add(
                      WebsiteUpdate(
                        Website(
                          id: state.website!.id,
                          stripeApiKey: _stripeApiKeyController.text,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ];

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: widgets[i++],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: i < widgets.length ? widgets[i] : Container(),
                ),
              ),
            ],
          ),
        );
      }
    }

    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(padding: const EdgeInsets.all(10), child: widgets[i]));
    }

    return Center(
      child: SingleChildScrollView(
        key: const Key('listView'),
        child: Column(
          children: [
            Center(
              child: Text(
                '${_localizations.id}:#${state.website?.id}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                key: const Key('header'),
              ),
            ),
            const SizedBox(height: 10),
            Column(children: (rows.isEmpty ? column : rows)),
          ],
        ),
      ),
    );
  }
}
