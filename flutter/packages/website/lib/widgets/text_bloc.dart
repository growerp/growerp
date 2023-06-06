import 'package:flutter/material.dart';

class Bloc extends StatelessWidget {
  final String? header;
  final String? logo;
  final TextSpan? content;
  const Bloc({this.header, this.content, this.logo});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 550,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(45),
            border: Border.all(color: Colors.grey, width: 1)),
        child: Column(children: [
          SizedBox(
              child: Column(children: <Widget>[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (logo != null) Image.asset(logo!),
              Text(header!,
                  style: TextStyle(
                    fontSize: 20,
                  )),
            ]),
            const Divider(
              color: Colors.grey,
              thickness: 1,
              height: 20,
            ),
            RichText(text: content!)
          ])),
        ]));
  }
}
