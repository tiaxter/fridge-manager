import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fridge_management/screens/settings.dart';
import 'package:fridge_management/widgets/dismissable_tile.dart';
import 'package:fridge_management/widgets/food_adder.dart';
import 'package:fridge_management/widgets/food_card.dart';
import 'package:jiffy/jiffy.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  void openFoodAdderPopup(BuildContext context, String? barCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FoodAdderPopup(barCode: barCode);
      }
    );
  }

  void scanProductWithBarcode(BuildContext context) async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
      "#00000000",
      "Cancel",
      false,
      ScanMode.BARCODE
    );
    // If there's no recorded barcode
    if (barcode == "-1") {
      return;
    }
    openFoodAdderPopup(context, barcode);
  }


  @override
  Widget build(BuildContext context) {
    // Quick actions init
    QuickActions quickActions = const QuickActions();
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'add_product_barcode',
        localizedTitle: 'Add product with barcode',
        icon: 'with_barcode',
      ),
      const ShortcutItem(
        type: 'add_product_without_barcode',
        localizedTitle: 'Add product without barcode',
        icon: 'without_barcode',
      ),
    ]);
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'add_product_barcode') {
        scanProductWithBarcode(context);
      }

      if (shortcutType == 'add_product_without_barcode') {
        openFoodAdderPopup(context, null);
      }
    });
    // Allow notification permissions
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (isAllowed) {
        return;
      }

      await AwesomeNotifications().requestPermissionToSendNotifications();
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text("Fridge Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showAboutDialog(
                context: context,
                children: const [
                  Text("Developed by Gerardo Palmiotto"),
                  Text("From an idea of Juri Donvito"),
                  Text("Using Open Food Facts API"),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          )
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 3,
        spaceBetweenChildren: 4,
        children: [
          SpeedDialChild(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/png/without_barcode.png'),
            ),
            label: 'Without Bar Code',
            onTap: () => openFoodAdderPopup(context, null),
          ),
          SpeedDialChild(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/png/with_barcode.png'),
            ),
            label: 'With Bar Code',
            onTap: () => scanProductWithBarcode(context)
          ),
        ],
      ),
      body: FutureBuilder(
        future: StreamingSharedPreferences.instance,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator()
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Ops... an error occurred, please retry later!"),
            );
          }

          StreamingSharedPreferences preferences = snapshot.data;
          return PreferenceBuilder(
            preference: preferences.getString('products', defaultValue: '[]'),
            builder: (BuildContext context, String productsString) {
              // Decode from stringed json to json
              List<dynamic> products = jsonDecode(productsString);

              // If there's no food then show "No food"
              if (products.isEmpty) {
                return const Center(
                  child: Text("Add some food pressing the + button"),
                );
              }

              // Sort by expiration date
              products.sort((a, b) {
                DateTime firstDate = Jiffy(a["expirationDate"]).dateTime;
                DateTime secondDate = Jiffy(b["expirationDate"]).dateTime;

                return firstDate.compareTo(secondDate);
              });

              return ListView.builder(
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  // Get the current food in case it will be deleteed
                  Map<dynamic, dynamic> currentFood = products[index];
                  return DismissableTile(
                    child: FoodCard(
                      title: products[index]["productName"],
                      expiration: Jiffy(products[index]["expirationDate"]).dateTime,
                      quantity: products[index]["quantity"] ?? 1.0,
                      id: products[index]['id'],
                    ),
                    key: UniqueKey(),
                    onDismissed: () async {
                      products.removeAt(index);
                      preferences.setString('products', jsonEncode(products));
                    },
                    cancelDismiss: () async {
                      products.insert(index, currentFood);
                      preferences.setString('products', jsonEncode(products));
                    },
                  );
                },
              );
            },
          );
        })
    );
  }
}
