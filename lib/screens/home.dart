import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fridge_management/widgets/dismissable_tile.dart';
import 'package:fridge_management/widgets/food_adder.dart';
import 'package:fridge_management/widgets/food_card.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
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
            child: const FaIcon(FontAwesomeIcons.barcode),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                FaIcon(FontAwesomeIcons.barcode, color: Colors.grey.shade400),
                const Icon(Icons.close, size: 28),
              ]
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
