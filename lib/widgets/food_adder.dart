import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:fridge_management/data/drift_database.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../utils/api.dart';

class FoodAdderPopup extends StatefulWidget{
  final String? barCode;
  final int? id;
  const FoodAdderPopup({
    Key? key, this.barCode, this.id
  }) : super(key: key);

  @override
  _FoodAdderPopupState createState() => _FoodAdderPopupState();

}

class _FoodAdderPopupState extends State<FoodAdderPopup>{
  Map<String, dynamic> formFields = {
    'quantity': 1.0,
  };

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController productNameController = TextEditingController();
  TextEditingController expirationDateController = TextEditingController();

  void openDatePicker(BuildContext context) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: (formFields.containsKey("expirationDate") && formFields["expirationDate"] != null) ? Jiffy(formFields["expirationDate"]).dateTime : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(3000)
    );

    if (date != null) {
      expirationDateController.text = Jiffy(date).format('yyyy-MM-dd');
      formFields["expirationDate"] = Jiffy(date).dateTime;
    }
  }

  void onSave(AppDb db) async {
    // If name field is not valid
    if (!formKey.currentState!.validate()) {
      return;
    }
    // Save productName inside the form values
    formKey.currentState!.save();
    // If date field is not valid
    if (!formFields.containsKey("expirationDate") || formFields["expirationDate"] == null) {
      return;
    }

    if (widget.id != null) {
      // Replace the old with the new one
      db.updateProduct(
        Product(
          id: widget.id ?? 0,
          name: formFields['productName'],
          quantity: formFields['quantity'].toInt(),
          expiration: formFields['expirationDate'],
          deletedAt: null,
        )
      );
    } else {
      // Add the new one
      db.addProduct(
        ProductsCompanion(
          name: Value(formFields['productName']),
          quantity: Value(formFields['quantity'].toInt()),
          expiration: Value(formFields['expirationDate']),
          deletedAt: const Value.absent(),
        )
      );
    }

    // Save velues to the db
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    AppDb db = Provider.of<AppDb>(context);

    String action = widget.id != null ? 'Edit' : 'Add';

    if (widget.id != null) {
      // Get stored foods
      db.getProductById(widget.id ?? 0).then((Product product) {
        formFields['id'] = product.id;
        formFields["productName"] = product.name;
        formFields["expirationDate"] = product.expiration;
        formFields["quantity"] = product.quantity.toDouble();
        productNameController.text = formFields["productName"];
        expirationDateController.text = Jiffy(formFields["expirationDate"]).format('yyyy-MM-dd');
      });
    }

    return AlertDialog(
      title: Text('$action product'),
      content: FutureBuilder(
        future: widget.barCode == null ? Future.value(null) : Api.getProductInfo(widget.barCode ?? ''),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            );
          }

          var productData = snapshot.data;

          if (productData != null && productData['status'] == 1) {
            productNameController.text = productData["product"]["product_name_it"] ?? productData["product"]["product_name"];
          }

          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: productNameController,
                    decoration: const InputDecoration(
                      labelText: "Product name"
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
                    onSaved: (String? value) => formFields["productName"] = value ?? "",
                  ),
                  TextFormField(
                    controller: expirationDateController,
                    readOnly: true,
                    onTap: () => openDatePicker(context),
                    decoration: const InputDecoration(
                      labelText: "Expiration date"
                    ),
                  ),
                  SpinBox(
                    min: 1,
                    max: 1000,
                    decoration: const InputDecoration(
                      labelText: "Quantity"
                    ),
                    value: formFields["quantity"],
                    onChanged: (double value) => formFields["quantity"] = value,
                  )
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(action),
          onPressed: () => onSave(db),
        )
      ],
    );
  }
}
