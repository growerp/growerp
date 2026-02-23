import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:growerp_core/growerp_core.dart';

import '../../../growerp_website.dart';

class WebsiteContentDialog extends StatelessWidget {
  final String websiteId;
  final Content content;
  const WebsiteContentDialog(this.websiteId, this.content, {super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (BuildContext context) => ContentBloc(context.read<RestClient>()),
    child: WebsiteContent(websiteId, content),
  );
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
  XFile? _imageFile;
  late Content newContent;
  String data = '';
  String newData = '';
  late bool isMarkDown;
  late ContentBloc _contentBloc;
  late ThemeBloc _themeBloc;
  late WebsiteLocalizations _localizations;

  MethodChannel channel = const MethodChannel(
    'plugins.flutter.io/url_launcher',
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    newContent = widget.content;
    _nameController.text = widget.content.title;
    if (newContent.text.contains("<html")) {
      isMarkDown = false;
    } else {
      isMarkDown = true;
    }
    _contentBloc = context.read<ContentBloc>();
    _contentBloc.add(ContentFetch(widget.websiteId, widget.content));
    _themeBloc = context.read<ThemeBloc>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = WebsiteLocalizations.of(context)!;
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<ContentBloc, ContentState>(
      listenWhen: ((previous, current) =>
          (previous.status == ContentStatus.updating &&
              current.status == ContentStatus.success) ||
          current.status == ContentStatus.failure),
      listener: (context, state) {
        switch (state.status) {
          case ContentStatus.success:
            //      HelperFunctions.showMessage(
            //          context, "${state.message}", Colors.green);
            // Pop with locally-known content (including the new name the user
            // typed) rather than state.content!, which may reflect stale cached
            // backend data for the title field after a rename.
            Navigator.of(
              context,
            ).pop(newContent.copyWith(title: _nameController.text));
            break;
          case ContentStatus.failure:
            HelperFunctions.showMessage(
              context,
              '${_localizations.errorTitle}: ${state.message}',
              Colors.red,
            );
            break;
          default:
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case ContentStatus.failure:
            return Center(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(newContent),
                child: Text(_localizations.continueButton),
              ),
            );
          case ContentStatus.success:
            newContent = state.content!;
            data = state.content!.text;
            if (newData.isEmpty) newData = data;
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
                  title:
                      '${_localizations.update} ${_localizations.content} ${widget.content.title}',
                  child: _showMdTextForm(isPhone),
                ),
              );
              //                        isMarkDown
              //                            ? _showMdTextForm(isPhone)
              //                            : _showHtmlTextForm(isPhone)));
            } else {
              return Dialog(
                key: const Key('WebsiteContentImage'),
                insetPadding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                  context: context,
                  width: isPhone ? 350 : 800,
                  height: 500,
                  title: _localizations.imageInformation(widget.content.title),
                  child: imageChild(isPhone),
                ),
              );
            }
          default:
            return const Center(child: LoadingIndicator());
        }
      },
    );
  }

  Widget imageChild(bool isPhone) {
    return _showImageForm(isPhone);
  }

  Widget _showImageForm(bool isPhone) {
    return Form(
      key: _websiteContFormKey,
      child: SingleChildScrollView(
        key: const Key('listView'),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            StyledImageUpload(
              label: 'Content Image',
              subtitle: 'Click to upload. JPG, PNG up to 2MB',
              image: _imageFile != null
                  ? (foundation.kIsWeb
                        ? NetworkImage(_imageFile!.path)
                        : FileImage(File(_imageFile!.path)))
                  : null,
              imageBytes: _imageFile == null ? newContent.image : null,
              fallbackText: newContent.title.isEmpty
                  ? '?'
                  : newContent.title[0],
              onUploadTap: () async {
                final pickedFile = await HelperFunctions.pickImage();
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = pickedFile;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('imageName'),
              decoration: InputDecoration(labelText: _localizations.name),
              controller: _nameController,
              validator: (value) {
                return value!.isEmpty
                    ? '${_localizations.name} ${_localizations.errorTitle}'
                    : null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(
                      widget.content.path.isEmpty
                          ? _localizations.create
                          : _localizations.update,
                    ),
                    onPressed: () async {
                      if (_websiteContFormKey.currentState!.validate()) {
                        Uint8List? image =
                            await HelperFunctions.getResizedImage(
                              _imageFile?.path,
                            );
                        if (!mounted) return;
                        if (_imageFile?.path != null && image == null) {
                          HelperFunctions.showMessage(
                            context,
                            _localizations.errorTitle,
                            Colors.red,
                          );
                        } else {
                          _contentBloc.add(
                            ContentUpdate(
                              widget.websiteId,
                              widget.content.copyWith(
                                title: _nameController.text,
                                image: image,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _showMdTextForm(bool isPhone) {
    Widget input = TextFormField(
      key: const Key('mdInput'),
      autofocus: true,
      decoration: InputDecoration(labelText: _localizations.description),
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      textInputAction: TextInputAction.newline,
      initialValue: data,
      onChanged: (text) {
        setState(() {
          newData = text;
        });
      },
    );
    return Column(
      children: [
        isPhone
            ? Expanded(
                child: Column(
                  children: [
                    Expanded(child: input),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                          border: Border.all(
                            style: BorderStyle.solid,
                            width: 0.80,
                          ),
                        ),
                        child: MarkdownWidget(
                          data: newData,
                          config: _themeBloc.state.themeMode == ThemeMode.dark
                              ? MarkdownConfig.darkConfig
                              : MarkdownConfig.defaultConfig,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Expanded(
                child: Row(
                  children: [
                    Expanded(child: input),
                    const SizedBox(width: 20),
                    Expanded(
                      child: MarkdownWidget(
                        data: newData,
                        config: _themeBloc.state.themeMode == ThemeMode.dark
                            ? MarkdownConfig.darkConfig
                            : MarkdownConfig.defaultConfig,
                      ),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('update'),
          child: Text(
            widget.content.path.isEmpty
                ? _localizations.create
                : _localizations.update,
          ),
          onPressed: () async {
            if (newData != '') {
              _contentBloc.add(
                ContentUpdate(
                  widget.websiteId,
                  widget.content.copyWith(text: newData),
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  /*
  Widget _showHtmlTextForm(bool isPhone) {
     Widget input = TextFormField(
        key: const Key('htmlInput'),
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

    HtmlEditorController controller = HtmlEditorController();

    return HtmlEditor(
      controller: controller, //required
      htmlEditorOptions: const HtmlEditorOptions(
        hint: "Your text here...",
        //initalText: "text content initial, if any",
      ),
      otherOptions: const OtherOptions(
        height: 400,
      ),
    );
  }
*/
}
