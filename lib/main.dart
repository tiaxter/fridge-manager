import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:fridge_management/screens/home.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:workmanager/workmanager.dart';

/* void callbackDispatcher() { */
  /* Workmanager().executeTask((taskName, inputData) async { */
    /* if (taskName == 'checkingProductExpirations') { */
      /* AwesomeNotifications().createNotification( */
        /* content: NotificationContent( */
          /* id: UniqueKey().hashCode, */
          /* channelKey: 'basic_channel', */
          /* title: 'Food is expiring!!', */
          /* body: 'Dio porco', */
        /* ), */
      /* ); */
    /* } */
    /* return Future.value(true); */
  /* }); */
/* } */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hive init
  await Hive.initFlutter();
  await Hive.openBox('app');

  // Workmanager init
  /* Workmanager().initialize( */
    /* callbackDispatcher, */
    /* isInDebugMode: true, */
  /* ); */
  /* Workmanager().cancelAll(); */
  /* Workmanager().registerPeriodicTask( */
    /* '1', */
    /* 'checkingProductExpirations', */
    /* frequency: const Duration(minutes: 15), */
  /* ); */

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
    return MaterialApp(
      title: 'Fridge Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
