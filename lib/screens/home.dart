import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fridge_management/widgets/dismissable_tile.dart';
import 'package:fridge_management/widgets/food_adder.dart';
import 'package:fridge_management/widgets/food_card.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quick_actions/quick_actions.dart';

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
              child: Image.asset('assets/png/with_barcode.png'),
            ),
            label: 'With Bar Code',
            onTap: () async {
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
          ),
          SpeedDialChild(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/png/without_barcode.png'),
            ),
            label: 'Without Bar Code',
            onTap: () => openFoodAdderPopup(context, null),
          ),
        ],
      ),
      // Get value from Hive.box and re-render if key "foods" is updated
      body: ValueListenableBuilder<Box>(
        valueListenable: Hive.box('app').listenable(keys: ["foods"]),
        // Return the List of Foods' cards
        builder: (context, box, widget) {
          /* box.delete("foods"); */
          // Get foods data
          List<dynamic> foods = box.get("foods", defaultValue: <Map<String, dynamic>>[]);

          // If there's no food then show "No food"
          if (foods.isEmpty) {
            return const Center(
              child: Text("Add some food pressing the + button"),
            );
          }

          // If there are many foods
          return ListView.builder(
            shrinkWrap: true,
            itemCount: foods.length,
            itemBuilder: (context, index) {
              // Get the current food in case it will be deleteed
              Map<dynamic, dynamic> currentFood = foods[index];
              return DismissableTile(
                child: FoodCard(
                  title: foods[index]["productName"],
                  expiration: foods[index]["expirationDate"],
                  quantity: foods[index]["quantity"] ?? 1.0,
                  index: index,
                ),
                key: UniqueKey(),
                onDismissed: () async {
                  foods.removeAt(index);
                  await box.put("foods", foods);
                },
                cancelDismiss: () async {
                  foods.insert(index, currentFood);
                  await box.put("foods", foods);
                },
              );
            },
          );
        },
      ),
    );
  }
}
