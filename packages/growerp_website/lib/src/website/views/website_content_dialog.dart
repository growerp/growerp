import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:growerp_core/templates/imageButtons.dart';
import 'package:growerp_core/domains/common/functions/helper_functions.dart';
import 'package:growerp_core/domains/domains.dart';
import '../../../growerp_website.dart';
import '../website.dart';

class WebsiteContentDialog extends StatelessWidget {
  final String websiteId;
  final Content content;
  const WebsiteContentDialog(this.websiteId, this.content, {super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) =>
            ContentBloc(context.read<WebsiteAPIRepository>()),
        child: WebsiteContent(websiteId, content));
  }
}

class WebsiteContent extends StatefulWidget {
  final String websiteId;
  final Content content;
  const WebsiteContent(this.websiteId, this.content, {super.key});
  @override
  State<WebsiteContent> createState() => _WebsiteContentState();
}

class _WebsiteContentState extends State<WebsiteContent> {
  final TextEditingController _nameController = TextEditingController();
  final _websiteContFormKey = GlobalKey<FormState>();
  dynamic _pickImageError;
  String? _retrieveDataError;
  XFile? _imageFile;
  late Content newContent;
  String? data;
  String? newData;

  MethodChannel channel =
      const MethodChannel('plugins.flutter.io/url_launcher');
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    if (widget.content.path.isNotEmpty) {
      context
          .read<ContentBloc>()
          .add(ContentFetch(widget.websiteId, widget.content));
    } else {
      context.read<ContentBloc>().add(ContentInit());
    }
    newContent = widget.content;
    _nameController.text = widget.content.title;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    if (widget.content.text.isNotEmpty) {
      return BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) async {
        switch (state.status) {
          case ContentStatus.failure:
            HelperFunctions.showMessage(
                context, 'Error getting content: ${state.message}', Colors.red);
            break;
          default:
        }
      }, builder: (context, state) {
        if (state.status == ContentStatus.success) {
          data = state.content?.text != ""
              ? state.content?.text
              : widget.content.text;
          return Dialog(
              key: const Key('WebsiteContentText'),
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                  width: isPhone ? 400 : 800,
                  height: 600,
                  padding: const EdgeInsets.all(20),
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Stack(clipBehavior: Clip.none, children: [
                        _showTextForm(isPhone, state),
                        Positioned(
                            top: 5, right: 5, child: DialogCloseButton()),
                      ]))));
        }
        return LoadingIndicator();
      });
    } else {
      return BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) async {
        switch (state.status) {
          case ContentStatus.failure:
            HelperFunctions.showMessage(
                context, 'Error getting content: ${state.message}', Colors.red);
            break;
          default:
        }
      }, builder: (context, state) {
        newContent = state.content ?? widget.content;
        if (state.status == ContentStatus.success) {
          return Dialog(
              key: const Key('WebsiteContentImage'),
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                    width: 400,
                    height: 400,
                    padding: const EdgeInsets.all(20),
                    child: Scaffold(
                        backgroundColor: Colors.transparent,
                        floatingActionButton:
                            imageButtons(context, _onImageButtonPressed),
                        body: listChild(isPhone, state))),
                Positioned(top: 5, right: 5, child: DialogCloseButton())
              ]));
        }
        return LoadingIndicator();
      });
    }
  }

  void _onImageButtonPressed(ImageSource source,
      {BuildContext? context}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
      );
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _imageFile = response.file;
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  Widget listChild(bool isPhone, state) {
    return Builder(builder: (BuildContext context) {
      return !foundation.kIsWeb &&
              foundation.defaultTargetPlatform == TargetPlatform.android
          ? FutureBuilder<void>(
              future: retrieveLostData(),
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Pick image error: ${snapshot.error}}',
                    textAlign: TextAlign.center,
                  );
                }
                return _showImageForm(isPhone, state);
              })
          : _showImageForm(isPhone, state);
    });
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showImageForm(bool isPhone, ContentState state) {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    }
    return BlocConsumer<ContentBloc, ContentState>(
        listener: (context, state) async {
      switch (state.status) {
        case ContentStatus.success:
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(state.content);
          break;
        case ContentStatus.failure:
          HelperFunctions.showMessage(
              context, 'Error getting content: ${state.message}', Colors.red);
          break;
        default:
      }
    }, builder: (context, state) {
      if (state.status == ContentStatus.success) {
        return Form(
            key: _websiteContFormKey,
            child: SingleChildScrollView(
                key: const Key('listView'),
                child: Column(children: <Widget>[
                  CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 80,
                      child: _imageFile != null
                          ? foundation.kIsWeb
                              ? Image.network(_imageFile!.path, scale: 0.3)
                              : Image.file(File(_imageFile!.path), scale: 0.3)
                          : newContent.image != null
                              ? Image.memory(newContent.image!, scale: 0.3)
                              : Text(
                                  newContent.title.isEmpty
                                      ? '?'
                                      : newContent.title[0],
                                  style: const TextStyle(
                                      fontSize: 30, color: Colors.black))),
                  const SizedBox(height: 30),
                  TextFormField(
                    key: const Key('imageName'),
                    decoration: const InputDecoration(labelText: 'Image Name'),
                    controller: _nameController,
                    validator: (value) {
                      return value!.isEmpty ? 'Please enter a name?' : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: ElevatedButton(
                            key: const Key('update'),
                            child: Text(widget.content.path.isEmpty
                                ? 'Create'
                                : 'Update'),
                            onPressed: () async {
                              if (_websiteContFormKey.currentState!
                                  .validate()) {
                                Uint8List? image =
                                    await HelperFunctions.getResizedImage(
                                        _imageFile?.path);
                                if (_imageFile?.path != null && image == null) {
                                  HelperFunctions.showMessage(context,
                                      "Image upload error!", Colors.red);
                                } else {
                                  context.read<ContentBloc>().add(ContentUpdate(
                                      widget.websiteId,
                                      widget.content.copyWith(
                                          title: _nameController.text,
                                          image: image)));
                                }
                              }
                            }))
                  ])
                ])));
      }
      return LoadingIndicator();
    });
  }

  Widget _showTextForm(bool isPhone, ContentState state) {
    Widget input = TextFormField(
        key: const Key('mdInput'),
        autofocus: true,
        decoration: InputDecoration(labelText: '${widget.content.title} text'),
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        textInputAction: TextInputAction.newline,
        initialValue: data,
        onChanged: (text) {
          setState(() {
            newData = text;
          });
        });
    return BlocConsumer<ContentBloc, ContentState>(
        listener: (context, state) async {
      switch (state.status) {
        case ContentStatus.success:
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(state.content);
          break;
        case ContentStatus.failure:
          HelperFunctions.showMessage(
              context, 'Error getting content: ${state.message}', Colors.red);
          break;
        default:
      }
      ;
    }, builder: (context, state) {
      if (state.status == ContentStatus.success) {
        return Column(children: [
          isPhone
              ? Expanded(
                  child: Column(children: [
                    Expanded(child: input),
                    const SizedBox(height: 10),
                    Expanded(
                        child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.0),
                              border: Border.all(
                                  color: Colors.black45,
                                  style: BorderStyle.solid,
                                  width: 0.80),
                            ),
                            child: MarkdownWidget(data: newData ?? data!))),
                  ]),
                )
              : Expanded(
                  child: Row(children: [
                    Expanded(child: input),
                    const SizedBox(width: 20),
                    Expanded(child: MarkdownWidget(data: newData ?? data!)),
                  ]),
                ),
          const SizedBox(height: 10),
          ElevatedButton(
              key: const Key('update'),
              child: Text(widget.content.path.isEmpty ? 'Create' : 'Update'),
              onPressed: () async {
                if (newData != data) {
                  context.read<ContentBloc>().add(ContentUpdate(
                      widget.websiteId,
                      widget.content.copyWith(text: newData!)));
                } else {
                  Navigator.of(context).pop();
                }
              })
        ]);
      }
      return LoadingIndicator();
    });
  }
}
