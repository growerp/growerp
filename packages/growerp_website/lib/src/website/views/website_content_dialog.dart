import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:growerp_core/growerp_core.dart';
import '../../api_repository.dart';
import '../blocs/blocs.dart';
import '../models/models.dart';

class WebsiteContentDialog extends StatelessWidget {
  final String websiteId;
  final Content content;
  const WebsiteContentDialog(this.websiteId, this.content, {super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (BuildContext context) =>
          ContentBloc(context.read<WebsiteAPIRepository>())
            ..add(ContentFetch(websiteId, content)),
      child: WebsiteContent(websiteId, content));
}

class WebsiteContent extends StatefulWidget {
  final String websiteId;
  final Content content;
  const WebsiteContent(this.websiteId, this.content, {super.key});
  @override
  WebsiteContentState createState() => WebsiteContentState();
}

class WebsiteContentState extends State<WebsiteContent> {
  final TextEditingController _nameController = TextEditingController();
  final _websiteContFormKey = GlobalKey<FormState>();
  dynamic _pickImageError;
  String? _retrieveDataError;
  XFile? _imageFile;
  late Content newContent;
  String data = '';
  String newData = '';

  MethodChannel channel =
      const MethodChannel('plugins.flutter.io/url_launcher');
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    newContent = widget.content;
    _nameController.text = widget.content.title;
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return BlocConsumer<ContentBloc, ContentState>(
        listenWhen: ((previous, current) =>
            (previous.status == ContentStatus.updating &&
                current.status == ContentStatus.success) ||
            current.status == ContentStatus.failure),
        listener: (context, state) {
          switch (state.status) {
            case ContentStatus.success:
              Navigator.of(context).pop(newContent);
              break;
            case ContentStatus.failure:
              HelperFunctions.showMessage(context,
                  'Error getting content: ${state.message}', Colors.red);
              break;
            default:
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case ContentStatus.failure:
              return Center(
                  child: Text('failed to fetch content: ${state.message}'));
            case ContentStatus.success:
              newContent = state.content!;
              data = state.content?.text ?? '';
              if (widget.content.text.isNotEmpty) {
                return Dialog(
                    key: const Key('WebsiteContentText'),
                    insetPadding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: popUp(
                        context: context,
                        width: isPhone ? 400 : 800,
                        height: 600,
                        title: 'Update content ${widget.content.title}',
                        child: _showTextForm(isPhone)));
              } else {
                return Dialog(
                    key: const Key('WebsiteContentImage'),
                    insetPadding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                          width: 400,
                          height: 50,
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColorDark,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              )),
                          child: const Center(
                              child: Text('Image Information',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))),
                      Container(
                          width: 400,
                          height: 400,
                          padding: const EdgeInsets.all(20),
                          child: Scaffold(
                              backgroundColor: Colors.transparent,
                              floatingActionButton:
                                  imageButtons(context, _onImageButtonPressed),
                              body: imageChild(isPhone))),
                      const Positioned(
                          top: 5, right: 5, child: DialogCloseButton())
                    ]));
              }
            default:
              return const Center(child: CircularProgressIndicator());
          }
        });
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

  Widget imageChild(bool isPhone) {
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
                return _showImageForm(isPhone);
              })
          : _showImageForm(isPhone);
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

  Widget _showImageForm(bool isPhone) {
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
    return Form(
        key: _websiteContFormKey,
        child: SingleChildScrollView(
            key: const Key('listView'),
            child: Column(children: <Widget>[
              const SizedBox(height: 40),
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
                        child: Text(
                            widget.content.path.isEmpty ? 'Create' : 'Update'),
                        onPressed: () async {
                          if (_websiteContFormKey.currentState!.validate()) {
                            Uint8List? image =
                                await HelperFunctions.getResizedImage(
                                    _imageFile?.path);
                            if (!mounted) return;
                            if (_imageFile?.path != null && image == null) {
                              HelperFunctions.showMessage(
                                  context, "Image upload error!", Colors.red);
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

  Widget _showTextForm(bool isPhone) {
    Widget input = TextFormField(
        key: const Key('mdInput'),
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Enter text here...'),
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
                        child: MarkdownWidget(
                            data: newData.isNotEmpty ? newData : data))),
              ]),
            )
          : Expanded(
              child: Row(children: [
                Expanded(child: input),
                const SizedBox(width: 20),
                Expanded(child: MarkdownWidget(data: newData)),
              ]),
            ),
      const SizedBox(height: 10),
      ElevatedButton(
          key: const Key('update'),
          child: Text(widget.content.path.isEmpty ? 'Create' : 'Update'),
          onPressed: () async {
            if (newData != data) {
              context.read<ContentBloc>().add(ContentUpdate(
                  widget.websiteId, widget.content.copyWith(text: newData)));
            } else {
              Navigator.of(context).pop();
            }
          })
    ]);
  }
}
