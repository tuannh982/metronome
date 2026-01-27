import 'package:highlight/highlight.dart';

final livesetLanguage = Mode(
  refs: {},
  aliases: ['liveset'],
  keywords: {'keyword': 'tempo time bars bar delay'},
  contains: [
    Mode(className: 'comment', begin: '//', end: r'$'),
    Mode(className: 'comment', begin: r'/\*', end: r'\*/'),
    Mode(className: 'number', begin: r'\b\d+(\.\d+)?\b'),
    Mode(className: 'operator', begin: r'[/,]'),
  ],
);
