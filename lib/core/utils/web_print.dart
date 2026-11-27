import 'dart:typed_data';

import 'web_print_stub.dart'
    if (dart.library.js_interop) 'web_print_web.dart'
    as impl;

bool triggerBrowserPrint() => impl.triggerBrowserPrint();

Future<bool> triggerWebBytesDownload(Uint8List bytes, String filename) =>
    impl.triggerWebBytesDownload(bytes, filename);
