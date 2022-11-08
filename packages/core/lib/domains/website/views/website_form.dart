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
import 'dart:io';
import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/domains/domains.dart';
import 'package:reorderables/reorderables.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:from_css_color/from_css_color.dart';
import '../../../api_repository.dart';

class WebsiteForm extends StatelessWidget {
  final Key? key;
  final UserGroup userGroup;
  const WebsiteForm({
    this.key,
    required this.userGroup,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) =>
            WebsiteBloc(context.read<APIRepository>())..add(WebsiteFetch()),
        child: BlocProvider(
          create: (BuildContext context) =>
              CategoryBloc(context.read<APIRepository>())..add(CategoryFetch()),
          child: WebsitePage(),
        ));
  }
}

class WebsitePage extends StatefulWidget {
  @override
  _WebsiteState createState() => _WebsiteState();
}

class _WebsiteState extends State<WebsitePage> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  late WebsiteBloc _websiteBloc;
  List<Content> _updatedContent = [];
  List<Category> _selectedCategories = [];
  List<Category> _availableCategories = [];
  TextEditingController _urlController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _obsidianController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _websiteBloc = context.read<WebsiteBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) async {
      switch (state.status) {
        case CategoryStatus.failure:
          HelperFunctions.showMessage(context,
              'Error getting categories: ${state.message}', Colors.red);
          break;
        default:
      }
    }, builder: (context, state) {
      if (state.status == CategoryStatus.success) {
        _availableCategories = state.categories;
        return BlocConsumer<WebsiteBloc, WebsiteState>(
            listener: (context, state) {
          switch (state.status) {
            case WebsiteStatus.success:
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.green);
              break;
            case WebsiteStatus.failure:
              HelperFunctions.showMessage(
                  context, '${state.message}', Colors.red);
              break;
            default:
          }
        }, builder: (context, state) {
          switch (state.status) {
            case WebsiteStatus.success:
              _urlController.text = state.website!.hostName.split('.')[0];
              _titleController.text = state.website!.title;
              _obsidianController.text = state.website!.obsidianName;
              _updatedContent = List.of(state.website!.websiteContent);
              _selectedCategories = List.of(state.website!.productCategories);
              return Scaffold(body: Center(child: _showForm(state)));
            case WebsiteStatus.failure:
              return Center(child: Text("error happened"));
            default:
              return LoadingIndicator();
          }
        });
      }
      return LoadingIndicator();
    });
  }

  Widget _showForm(WebsiteState state) {
    // create text content buttons
    List<Widget> _textButtons = [];

    // create text content list
    state.website!.websiteContent.asMap().forEach((index, content) {
      if (content.text.isNotEmpty)
        _textButtons.add(InputChip(
          label: Text(
            content.title,
            key: Key(content.title),
          ),
          onPressed: () async {
            var updContent = await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return BlocProvider.value(
                      value: _websiteBloc,
                      child: WebsiteContentDialog(state.website!.id, content));
                });
            if (updContent != null)
              setState(() {
                context.read<WebsiteBloc>().add(WebsiteFetch());
              });
          },
          deleteIcon: const Icon(
            Icons.cancel,
            key: Key("deleteTextChip"),
          ),
          onDeleted: () async {
            bool result = await confirmDialog(
                context, "delete ${content.title}?", "cannot be undone!");
            if (result == true)
              context.read<WebsiteBloc>().add(WebsiteUpdate(Website(
                      id: state.website!.id,
                      websiteContent: [
                        _updatedContent[index].copyWith(title: '')
                      ])));
            setState(() {});
          },
        ));
    });
    _textButtons.add(IconButton(
        key: Key('addText'),
        iconSize: 30,
        icon: Icon(Icons.add_circle),
        color: Colors.deepOrange,
        padding: const EdgeInsets.all(0.0),
        onPressed: () async {
          var updContent = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return BlocProvider.value(
                    value: _websiteBloc,
                    child: WebsiteContentDialog(
                        state.website!.id, Content(text: '# ')));
              });

          if (updContent != null)
            setState(() {
              context.read<WebsiteBloc>().add(WebsiteFetch());
            });
        }));

    // create image buttons
    List<Widget> _imageButtons = [];
    state.website!.websiteContent.asMap().forEach((index, content) {
      if (content.text.isEmpty)
        _imageButtons.add(InputChip(
          label: Text(
            content.title,
            key: Key(content.title),
          ),
          onPressed: () async {
            var updContent = await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return BlocProvider.value(
                      value: _websiteBloc,
                      child: WebsiteContentDialog(state.website!.id, content));
                });
            if (updContent != null)
              setState(() {
                context.read<WebsiteBloc>().add(WebsiteFetch());
              });
          },
          deleteIcon: const Icon(
            Icons.cancel,
            key: Key("deleteImageChip"),
          ),
          onDeleted: () async {
            bool result = await confirmDialog(
                context, "delete ${content.title}?", "cannot be undone!");
            if (result == true)
              setState(() {
                context.read<WebsiteBloc>().add(WebsiteUpdate(Website(
                        id: state.website!.id,
                        websiteContent: [
                          _updatedContent[index].copyWith(title: '')
                        ])));
              });
          },
        ));
    });
    _imageButtons.add(IconButton(
        key: Key('addImage'),
        iconSize: 30,
        icon: Icon(Icons.add_circle),
        color: Colors.deepOrange,
        padding: const EdgeInsets.all(0.0),
        onPressed: () async {
          var updContent = await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) {
                return WebsiteContentDialog(state.website!.id, Content());
              });
          if (updContent != null)
            setState(() {
              context.read<WebsiteBloc>().add(WebsiteFetch());
            });
        }));

    // create website category buttons
    List<Widget> catButtons = [];
    state.website!.websiteCategories.asMap().forEach((index, category) {
      catButtons.add(ElevatedButton(
          key: Key(category.categoryName),
          child: Text(
            category.categoryName,
          ),
          onPressed: () async {
            await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return BlocProvider.value(
                      value: _websiteBloc,
                      child:
                          WebsiteCategoryDialog(state.website!.id, category));
                });
          }));
    });

    // create product browse categories
    List<Widget> browseCatButtons = [];
    state.website!.productCategories.asMap().forEach((index, category) {
      browseCatButtons.add(InputChip(
        label: Text(
          category.categoryName,
          key: Key(category.categoryName),
        ),
        deleteIcon: Icon(
          Icons.cancel,
          key: Key("delete${category.categoryName}"),
        ),
        onDeleted: () async {
          bool result = await confirmDialog(context,
              "Remove ${category.categoryName}?", "can be added again!");
          if (result == true) {
            setState(() {
              _selectedCategories.removeAt(index);
              if (_selectedCategories.isEmpty)
                _selectedCategories.add(Category(categoryId: 'allDelete'));
              context.read<WebsiteBloc>().add(WebsiteUpdate(Website(
                  id: state.website!.id,
                  productCategories: _selectedCategories)));
            });
          }
        },
      ));
    });

    browseCatButtons.add(IconButton(
      key: Key('addShopCategory'),
      iconSize: 30,
      icon: Icon(Icons.add_circle),
      color: Colors.deepOrange,
      padding: const EdgeInsets.all(0.0),
      onPressed: () async {
        var result = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return MultiSelect<Category>(
                title: 'Select one or more categories',
                items: _availableCategories,
                selectedItems: _selectedCategories,
              );
            });
        if (result != null) {
          setState(() {
            _selectedCategories = result;
          });
          context.read<WebsiteBloc>().add(WebsiteUpdate(Website(
              id: state.website!.id, productCategories: _selectedCategories)));
        }
      },
    ));

    // create product browse categories
    List<Widget> colorCatButtons = [];
    Map websiteColor = {};
    if (state.website!.colorJson.isNotEmpty)
      websiteColor = jsonDecode(state.website!.colorJson);
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
                  title: Text('Pick a color!'),
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
              context.read<WebsiteBloc>().add(WebsiteUpdate(Website(
                  id: state.website!.id, colorJson: jsonEncode(websiteColor))));
            });
          }
        })));

    final Uri _url = Uri.parse(foundation.kReleaseMode
        ? "https://${state.website?.hostName}"
        : "http://${state.website!.id}.localhost:8080");

    void _launchUrl() async {
      if (!await launchUrl(_url)) throw 'Could not launch $_url';
    }

    List<Widget> _widgets = [
      Container(
          width: 400,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: InkWell(
            onTap: _launchUrl,
            child: Text(
              "${state.website?.hostName}",
              key: Key('url'),
              style: TextStyle(
                fontSize: 20,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )),
      Form(
          key: _formKey1,
          child: Container(
              width: 400,
              padding: EdgeInsets.all(10),
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
                    key: Key('urlInput'),
                    controller: _urlController,
                    decoration: new InputDecoration(labelText: 'url'),
                    validator: (value) {
                      if (value!.isEmpty) return 'A subdomainname is required';
                      return null;
                    },
                  ),
                ),
                Text(
                    state.website!.hostName
                        .substring(state.website!.hostName.indexOf('.')),
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                ElevatedButton(
                    key: Key('updateHost'),
                    child: Text('update'),
                    onPressed: () async {
                      if (_formKey1.currentState!.validate()) {
                        _websiteBloc.add(WebsiteUpdate(Website(
                            id: state.website!.id,
                            hostName: _urlController.text)));
                      }
                    }),
              ]))),
      Form(
          key: _formKey2,
          child: Container(
              width: 400,
              padding: EdgeInsets.all(10),
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
                      key: Key('title'),
                      controller: _titleController,
                      decoration: new InputDecoration(
                          labelText: 'Title of the website')),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                    key: Key('updateTitle'),
                    child: Text('update'),
                    onPressed: () async {
                      if (_formKey2.currentState!.validate()) {
                        _websiteBloc.add(WebsiteUpdate(Website(
                            id: state.website!.id,
                            title: _titleController.text)));
                      }
                    }),
              ]))),
      Container(
          width: 400,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            Text(
              'Text sections',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Can change order with long press',
              style: TextStyle(fontSize: 10),
            ),
            ReorderableWrap(
                runSpacing: 10,
                onReorder: (int oldIndex, int newIndex) {
                  var content = List.of(state.website!.websiteContent
                      .where((el) => el.text.isNotEmpty));
                  if (newIndex == content.length) newIndex--;
                  var save = content[oldIndex];
                  content[oldIndex] = content[newIndex];
                  content[newIndex] = save;
                  int index = 1;
                  for (int i = 0; i < content.length; i++)
                    content[i] = content[i].copyWith(seqId: index++);
                  context.read<WebsiteBloc>().add(WebsiteUpdate(
                      Website(id: state.website!.id, websiteContent: content)));
                },
                spacing: 10,
                children: _textButtons)
          ])),
      Container(
          width: 400,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            Text(
              'Images',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(runSpacing: 10, spacing: 10, children: _imageButtons)
          ])),
      Container(
          width: 400,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            Text(
              'Home Page Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(children: catButtons, spacing: 10)
          ])),
      Container(
          width: 400,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            Text(
              'Shop dropdown Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(children: browseCatButtons, spacing: 10)
          ])),
      Container(
          width: 400,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Column(children: [
            Text(
              'Website colors',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(children: colorCatButtons, spacing: 10)
          ])),
      Container(
          width: 400,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
                color: Colors.black45, style: BorderStyle.solid, width: 0.80),
          ),
          child: Row(children: [
            Expanded(
                child: TextField(
                    key: Key('obsTitle'),
                    controller: _obsidianController,
                    decoration:
                        new InputDecoration(labelText: 'Title of the vault'))),
            SizedBox(width: 10),
            ElevatedButton(
                key: Key('upload'),
                child: Text('Upload Obsidian Vault'),
                onPressed: () async {
                  FilePickerResult? result;
                  String? path;
                  if (foundation.kIsWeb)
                    result = await FilePicker.platform.pickFiles(
                        allowedExtensions: ['zip'], type: FileType.custom);
                  else
                    path = await FilePicker.platform.getDirectoryPath();

                  if (path != null || result != null)
                    context.read<WebsiteBloc>().add(WebsiteObsUpload(
                        Obsidian(
                            title: _obsidianController.text,
                            zip: result?.files.first.bytes!),
                        path));
                }),
            SizedBox(width: 10),
            Visibility(
                visible: _obsidianController.text.isNotEmpty,
                child: ElevatedButton(
                    key: Key('obsidianDelete'),
                    child: Text('Delete'),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red)),
                    onPressed: () async {
                      context.read<WebsiteBloc>().add(WebsiteObsUpload(
                          Obsidian(title: _obsidianController.text), null));
                    }))
          ])),
    ];

    List<Widget> rows = [];
    if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET)) {
      // change list in two columns
      for (var i = 0; i < _widgets.length; i++)
        rows.add(Row(
          children: [
            Expanded(
                child:
                    Padding(padding: EdgeInsets.all(10), child: _widgets[i++])),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: i < _widgets.length ? _widgets[i] : Container()))
          ],
        ));
    }

    List<Widget> column = [];
    for (var i = 0; i < _widgets.length; i++)
      column.add(Padding(padding: EdgeInsets.all(10), child: _widgets[i]));

    return Center(
        child: Container(
            child: SingleChildScrollView(
                key: Key('listView'),
                padding: EdgeInsets.all(20),
                child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(children: [
                      Center(
                          child: Text(
                        'id:#${state.website?.id}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                        key: Key('header'),
                      )),
                      SizedBox(height: 10),
                      Column(children: (rows.isEmpty ? column : rows)),
                    ])))));
  }
}
