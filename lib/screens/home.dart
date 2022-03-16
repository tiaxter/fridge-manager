import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fridge_management/screens/settings.dart';
import 'package:fridge_management/widgets/dismissable_tile.dart';
import 'package:fridge_management/widgets/food_adder.dart';
import 'package:fridge_management/widgets/food_card.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';

import '../data/drift_database.dart';
/* import 'package:streaming_shared_preferences/streaming_shared_preferences.dart'; */

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

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

    // Get db
    AppDb db = Provider.of<AppDb>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fridge Management"),
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
      body: StreamBuilder(
        stream: db.watchProducts(),
        builder: (BuildContext context, AsyncSnapshot<List<Product>> snapshot) {
          List<Product> products = snapshot.data ?? [];

          return ListView.builder(
           shrinkWrap: true,
           itemCount: products.length,
           itemBuilder: (context, index) {
             return DismissableTile(
              key: UniqueKey(),
              child: FoodCard(
                id: products[index].id,
                title: products[index].name,
                expiration: products[index].expiration,
                quantity: products[index].quantity.toDouble(),
              ),
              onDismissed: () async {
                await db.deleteProduct(products[index].id);
              },
              cancelDismiss: () async {
                await db.undoDeleteProduct(products[index].id);
              },
             );
           },
          );
        },
      ),
    );
  }

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
}
