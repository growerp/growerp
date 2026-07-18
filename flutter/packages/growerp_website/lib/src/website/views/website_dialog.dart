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
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:from_css_color/from_css_color.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _substackController = TextEditingController();
  final _websiteFormKey1 = GlobalKey<FormState>();
  ScrollController myScrollController = ScrollController();
  late String applicationId;
  late RestClient restClient;
  late WebsiteLocalizations _localizations;
  List<LandingPage> _landingPages = [];
  String? _templateId;
  bool? _websiteThemeDark;

  @override
  void initState() {
    super.initState();
    applicationId = context.read<String>();
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

  /// Lumina design tokens used by the 'modern' website template set;
  /// names must match luminaDefaults in PopRestStore screen/store.xml.
  static String _toCssHex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static Map<String, String> _luminaFromScheme(ColorScheme cs) => {
    'surface': _toCssHex(cs.surface),
    'surfaceContainerLowest': _toCssHex(cs.surfaceContainerLowest),
    'surfaceContainerLow': _toCssHex(cs.surfaceContainerLow),
    'surfaceContainer': _toCssHex(cs.surfaceContainer),
    'surfaceContainerHigh': _toCssHex(cs.surfaceContainerHigh),
    'surfaceContainerHighest': _toCssHex(cs.surfaceContainerHighest),
    'onSurface': _toCssHex(cs.onSurface),
    'onSurfaceVariant': _toCssHex(cs.onSurfaceVariant),
    'primary': _toCssHex(cs.primary),
    'onPrimary': _toCssHex(cs.onPrimary),
    'primaryContainer': _toCssHex(cs.primaryContainer),
    'secondary': _toCssHex(cs.secondary),
    'tertiary': _toCssHex(cs.tertiary),
    'error': _toCssHex(cs.error),
    'outline': _toCssHex(cs.outline),
    'outlineVariant': _toCssHex(cs.outlineVariant),
  };

  Future<String?> _pickCssColor(String currentCss) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String cssColor = '';
        return AlertDialog(
          title: Text(_localizations.websiteColor),
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: fromCssColor(currentCss), //default color
              onColorChanged: (Color color) {
                cssColor = _toCssHex(color);
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
            if (websiteState.website!.colorJson.isNotEmpty) {
              final socialJson =
                  jsonDecode(websiteState.website!.colorJson) as Map;
              _twitterController.text =
                  (socialJson['TwitterUrl'] ?? '') as String;
              _facebookController.text =
                  (socialJson['FacebookUrl'] ?? '') as String;
              _instagramController.text =
                  (socialJson['InstagramUrl'] ?? '') as String;
              _youtubeController.text =
                  (socialJson['YouTubeUrl'] ?? '') as String;
              _linkedinController.text =
                  (socialJson['LinkedInUrl'] ?? '') as String;
              _substackController.text =
                  (socialJson['SubstackUrl'] ?? '') as String;
            }
            return _showForm(websiteState);
          case WebsiteStatus.failure:
            return Center(child: Text(_localizations.errorTitle));
          default:
            return const LoadingIndicator();
        }
      },
    );
  }

  /// Flutter color-theme picker for the website: writes the selected
  /// scheme's Material 3 colors as the 'lumina' object in colorJson,
  /// consumed by the modern website template CSS.
  Widget _websiteThemePicker(WebsiteState state, Map websiteColor) {
    final bool dark =
        _websiteThemeDark ?? websiteColor['luminaBrightness'] != 'light';
    final String? selectedScheme = websiteColor['luminaScheme'] as String?;

    void saveTheme(FlexScheme scheme, {bool? asDark}) {
      final bool useDark = asDark ?? dark;
      final colors = useDark
          ? FlexThemeData.dark(scheme: scheme).colorScheme
          : FlexThemeData.light(scheme: scheme).colorScheme;
      final updated = Map.of(websiteColor);
      updated['lumina'] = _luminaFromScheme(colors);
      updated['luminaScheme'] = scheme.name;
      updated['luminaBrightness'] = useDark ? 'dark' : 'light';
      _websiteBloc.add(
        WebsiteUpdate(
          Website(id: state.website!.id, colorJson: jsonEncode(updated)),
        ),
      );
    }

    List<Widget> tiles = [];
    for (final scheme in curatedSchemes) {
      final colors = dark
          ? FlexThemeData.dark(scheme: scheme).colorScheme
          : FlexThemeData.light(scheme: scheme).colorScheme;
      final isSelected = scheme.name == selectedScheme;
      tiles.add(
        Tooltip(
          message: scheme.name,
          child: InkWell(
            key: Key('websiteTheme${scheme.name}'),
            onTap: () => saveTheme(scheme),
            child: Container(
              width: 56,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: Container(color: colors.primary)),
                          Expanded(child: Container(color: colors.secondary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: Container(color: colors.tertiary)),
                          Expanded(child: Container(color: colors.surface)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // individual fine-tune chips for the theme (Lumina) tokens
    List<Widget> luminaChips = [];
    final luminaColors = websiteColor['lumina'];
    if (luminaColors is Map) {
      luminaColors.forEach((key, value) {
        if (value is! String) return;
        luminaChips.add(
          InputChip(
            backgroundColor: fromCssColor(value),
            label: Text(
              key,
              key: Key('lumina$key'),
              style: TextStyle(
                color: fromCssColor(value).computeLuminance() < 0.5
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            onPressed: () async {
              var result = await _pickCssColor(value);
              if (result != null) {
                setState(() {
                  luminaColors[key] = result;
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
        );
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SegmentedButton<bool>(
              key: const Key('websiteThemeBrightness'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Light')),
                ButtonSegment(value: true, label: Text('Dark')),
              ],
              selected: {dark},
              onSelectionChanged: (selection) {
                final bool newDark = selection.first;
                setState(() => _websiteThemeDark = newDark);
                // re-apply the currently selected scheme in the new
                // brightness so the website theme changes immediately
                if (selectedScheme != null) {
                  for (final scheme in curatedSchemes) {
                    if (scheme.name == selectedScheme) {
                      saveTheme(scheme, asDark: newDark);
                      break;
                    }
                  }
                }
              },
            ),
            const Spacer(),
            OutlinedButton(
              key: const Key('resetWebsiteColors'),
              onPressed: () {
                final updated = Map.of(websiteColor)
                  ..remove('lumina')
                  ..remove('luminaScheme')
                  ..remove('luminaBrightness');
                setState(() => _websiteThemeDark = null);
                _websiteBloc.add(
                  WebsiteUpdate(
                    Website(
                      id: state.website!.id,
                      colorJson: jsonEncode(updated),
                    ),
                  ),
                );
              },
              child: const Text('Reset to defaults'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: tiles),
        if (luminaChips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 5, children: luminaChips),
        ],
      ],
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
    // full FreeMarker/HTML page (ftl content type)
    textButtons.add(
      IconButton(
        key: const Key('addFtl'),
        iconSize: 30,
        tooltip: 'Add FreeMarker/HTML page',
        icon: const Icon(Icons.code),
        color: Colors.deepOrange,
        onPressed: () async {
          var updContent = await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return WebsiteContentDialog(
                state.website!.id,
                Content(contentType: 'ftl', text: '<#-- title: New Page -->\n'),
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

    // website theme colors (lumina tokens, applied to both template sets)
    Map websiteColor = {};
    if (state.website!.colorJson.isNotEmpty) {
      websiteColor = jsonDecode(state.website!.colorJson);
    }

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
        useCardStyle: false,
        labelText: 'Website Info',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _websiteFormKey1,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        key: const Key('launchUrl'),
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open website',
                        onPressed: doLlaunchUrl,
                      ),
                    ],
                  ),
                  TextFormField(
                    key: const Key('title'),
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: _localizations.title,
                    ),
                  ),
                  TextFormField(
                    key: const Key('measurementId'),
                    controller: _measurementIdController,
                    decoration: InputDecoration(
                      labelText: _localizations.websiteMeasurementId,
                    ),
                  ),
                  TextFormField(
                    key: const Key('stripeApi'),
                    controller: _stripeApiKeyController,
                    decoration: InputDecoration(
                      labelText: _localizations.websiteStripeApiKey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('templateId'),
                    decoration: const InputDecoration(
                      labelText: 'Website Template',
                    ),
                    initialValue: _templateId ?? state.website!.templateId,
                    items: const [
                      DropdownMenuItem(value: 'legacy', child: Text('Legacy')),
                      DropdownMenuItem(
                        value: 'modern',
                        child: Text('Modern Tailwind'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _templateId = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('twitterUrl'),
                    controller: _twitterController,
                    decoration: const InputDecoration(
                      labelText: 'Twitter / X URL',
                      hintText: 'https://twitter.com/yourhandle',
                    ),
                  ),
                  TextFormField(
                    key: const Key('facebookUrl'),
                    controller: _facebookController,
                    decoration: const InputDecoration(
                      labelText: 'Facebook URL',
                      hintText: 'https://facebook.com/yourpage',
                    ),
                  ),
                  TextFormField(
                    key: const Key('instagramUrl'),
                    controller: _instagramController,
                    decoration: const InputDecoration(
                      labelText: 'Instagram URL',
                      hintText: 'https://instagram.com/yourhandle',
                    ),
                  ),
                  TextFormField(
                    key: const Key('youtubeUrl'),
                    controller: _youtubeController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube URL',
                      hintText: 'https://youtube.com/yourchannel',
                    ),
                  ),
                  TextFormField(
                    key: const Key('linkedinUrl'),
                    controller: _linkedinController,
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn URL',
                      hintText: 'https://linkedin.com/company/yourcompany',
                    ),
                  ),
                  TextFormField(
                    key: const Key('substackUrl'),
                    controller: _substackController,
                    decoration: const InputDecoration(
                      labelText: 'Substack URL',
                      hintText: 'https://yourname.substack.com',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Website theme (applies to both Legacy and Modern templates)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _websiteThemePicker(state, websiteColor),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                key: const Key('modifyWebsiteInfo'),
                child: Text(_localizations.update),
                onPressed: () {
                  if (_websiteFormKey1.currentState!.validate()) {
                    Map updatedColor = {};
                    if (state.website!.colorJson.isNotEmpty) {
                      updatedColor = Map.from(
                        jsonDecode(state.website!.colorJson) as Map,
                      );
                    }
                    updatedColor['TwitterUrl'] = _twitterController.text;
                    updatedColor['FacebookUrl'] = _facebookController.text;
                    updatedColor['InstagramUrl'] = _instagramController.text;
                    updatedColor['YouTubeUrl'] = _youtubeController.text;
                    updatedColor['LinkedInUrl'] = _linkedinController.text;
                    updatedColor['SubstackUrl'] = _substackController.text;
                    _websiteBloc.add(
                      WebsiteUpdate(
                        Website(
                          id: state.website!.id,
                          hostName: _urlController.text,
                          title: _titleController.text,
                          measurementId: _measurementIdController.text,
                          stripeApiKey: _stripeApiKeyController.text,
                          templateId: _templateId ?? state.website!.templateId,
                          colorJson: jsonEncode(updatedColor),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      GroupingDecorator(
        useCardStyle: false,
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
      GroupingDecorator(
        useCardStyle: false,
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
                          (p) =>
                              p.landingPageId == _landingPageIdController.text,
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
        useCardStyle: false,
        labelText: _localizations.content,
        child: Column(
          children: [
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
        useCardStyle: false,
        labelText:
            '${_localizations.images} (can be included in content text with: ![](/getimage/imagename))',
        child: Wrap(runSpacing: 10, spacing: 10, children: imageButtons),
      ),
      for (Category category in state.website!.websiteCategories)
        BlocBuilder<DataFetchBloc<Products>, DataFetchState<Products>>(
          builder: (context, productState) {
            switch (productState.status) {
              case DataFetchStatus.failure:
                return FatalErrorForm(message: _localizations.errorTitle);
              case DataFetchStatus.loading:
              case DataFetchStatus.success:
                // During a reload, DataFetchBloc preserves data via copyWith,
                // so keep the Autocomplete mounted. Replacing with
                // LoadingIndicator disposes _RawAutocompleteState and causes
                // it to access a defunct context in _announceSemantics.
                return GroupingDecorator(
                  useCardStyle: false,
                  labelText:
                      '${category.categoryName} (remove all to remove section from website)',
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
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                  maxWidth: 400,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      key: Key(option.productName ?? ''),
                                      dense: true,
                                      title: Text(
                                        " ${option.productName}[${option.pseudoId}]",
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
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
            case DataFetchStatus.success:
              // During a reload, DataFetchBloc preserves data via copyWith,
              // so keep the Autocomplete mounted (see Products BlocBuilder above).
              return GroupingDecorator(
                useCardStyle: false,
                labelText:
                    '${_localizations.websiteProductCategories} (remove all to remove the category dropdown)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedCategories.isNotEmpty)
                      Wrap(spacing: 10, children: browseCatButtons),
                    Autocomplete<Category>(
                      key: const Key("addShopCategory"),
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
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 400,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    key: Key(option.categoryName),
                                    dense: true,
                                    title: Text(
                                      option.categoryName.truncate(15),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
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
    ];

    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return SingleChildScrollView(
      key: const Key('listView'),
      padding: const EdgeInsets.all(10),
      child: MasonryGridView.count(
        crossAxisCount: isMobile ? 1 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widgets.length,
        itemBuilder: (context, index) => widgets[index],
      ),
    );
  }
}
