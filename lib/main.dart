import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/firebase/firestore_storefront_service.dart';
import 'core/storage/app_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    AppTheme.systemOverlayStyle(brightness: Brightness.light),
  );
  await initializeResetFirebase();
  final storage = await AppStorage.create();
  final apiClient = ApiClient(storage: storage);

  runApp(
    ResetStoreApp(
      storage: storage,
      apiClient: apiClient,
      autoInitialize: true,
    ),
  );
}
