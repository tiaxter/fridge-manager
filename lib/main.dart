import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:fridge_management/screens/home.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_ios/shared_preferences_ios.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'checkingProductExpirations') {
      // Shared preferences init
      if (Platform.isAndroid) SharedPreferencesAndroid.registerWith();
      if (Platform.isIOS) SharedPreferencesIOS.registerWith();
      StreamingSharedPreferences prefs = await StreamingSharedPreferences.instance;

      // Get the products
      List<dynamic> products = jsonDecode(prefs.getString('products', defaultValue: '[]').getValue());
      // Filter expiring products 
      products = products.where((product) {
        return Jiffy(product["expirationDate"]).endOf(Units.DAY).diff(Jiffy(), Units.DAY, false).toInt() <= 3;
      }).toList();
      // If there aren't expired products then don't do nothing
      if (products.isEmpty) {
        return Future.value(true);
      }
      // Send notification about expiring food
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: UniqueKey().hashCode,
          channelKey: 'basic_channel',
          title: 'Food is expiring!!',
          body: products.map((product) {
            int expirationDays = Jiffy(product["expirationDate"]).endOf(Units.DAY).diff(Jiffy(), Units.DAY, false).toInt();
            return '${product["productName"]} expiring in $expirationDays ${expirationDays > 1 ? "days" : "day"}';
          }).join('\n'),
        ),
      );
    }
    return Future.value(true);
  });
}

void main() {
  // Workmanager init
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  Workmanager().registerPeriodicTask(
    '1',
    'checkingProductExpirations',
    frequency: const Duration(hours: 1),
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
