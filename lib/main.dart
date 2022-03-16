import 'dart:io';
import 'dart:isolate';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:fridge_management/screens/home.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';
/* import 'package:shared_preferences_android/shared_preferences_android.dart'; */
/* import 'package:shared_preferences_ios/shared_preferences_ios.dart'; */
/* import 'package:streaming_shared_preferences/streaming_shared_preferences.dart'; */
import 'data/drift_database.dart';

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'checkingProductExpirations' && inputData != null) {
        final db = AppDb.connectIsolated(inputData['dbPath']);
        
        print(await db.getExpiringProducts());

        await db.close();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cose
  var dir = await getApplicationDocumentsDirectory();
  String path = p.join(dir.path, 'db.sqlite');

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  Workmanager().cancelAll();
  Workmanager().registerPeriodicTask(
    '1',
    'checkingProductExpirations',
    frequency: const Duration(minutes: 15),
    inputData: {
      "dbPath": path,
    }
  );

  // Awesome notification init
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        channelDescription: '',
      ),
    ]
  );

  // App init
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => AppDb(),
      child: MaterialApp(
        title: 'Fridge Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const Home(),
      ),
    );
  }
}

