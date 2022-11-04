import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fridge_management/screens/home.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'data/drift_database.dart';
import 'package:path/path.dart' as p;

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'checkingProductExpirations' && inputData != null) {
      final db = AppDb.connectIsolated(inputData['dbPath']);
      // Get all expiring products
      List<Product> products = await db.getExpiringProducts();
      // If there are expiring produts then send notification
      if (products.isNotEmpty) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: UniqueKey().hashCode,
            channelKey: 'basic_channel',
            title: 'Food is expiring!',
            body: products.map((Product product) {
              int expirationDays = Jiffy(product.expiration).endOf(Units.DAY).diff(Jiffy(), Units.DAY, false).toInt();
              String expiringDaysMessage = expirationDays == 0 ? 'today' : 'in $expirationDays ${expirationDays > 1 ? "days" : "day"}';
              return '${product.name} is expiring $expiringDaysMessage';
            }).join('\n')
          )
        );
      }
      await db.close();
    }
    return Future.value(true);
  });
}

void initWorkmanager() async {
  var dir = await getApplicationDocumentsDirectory();
  String path = p.join(dir.path, 'db.sqlite');

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kReleaseMode ? false : true,
  );
  Workmanager().registerPeriodicTask(
    '1',
    'checkingProductExpirations',
    frequency: const Duration(hours: 12),
    inputData: {
      "dbPath": path,
    }
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Workmanager init
  initWorkmanager();

  // Awesome notification init
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        defaultColor: Colors.green,
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
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const Home(),
      ),
    );
  }
}
