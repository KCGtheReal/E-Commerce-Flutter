import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/firebase/firestore_storefront_service.dart';
import 'core/storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
