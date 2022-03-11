import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import '../utils/api.dart';

class FoodAdderPopup extends StatefulWidget{
  final String? barCode;
  final String? id;
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
      expirationDateController.text = DateFormat('yyyy-MM-dd').format(date);
      formFields["expirationDate"] = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  void onSave() async {
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

    // Get stored foods
    StreamingSharedPreferences preferences = await StreamingSharedPreferences.instance;
    List<dynamic> products = jsonDecode(preferences.getString('products', defaultValue: '[]').getValue());


    if (widget.id != null) {
      // Replace the old with the new one
      products[products.indexWhere((product) => product['id'] == widget.id)] = formFields;
    } else {
      formFields['id'] = UniqueKey().toString();
      // Add the new one
      products.add(formFields);
    }

    // Save velues to the db
    await preferences.setString('products', jsonEncode(products));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    String action = 'Add';
    if (widget.id != null) {
      action = 'Edit';
    }
    return AlertDialog(
      title: Text('$action product'),
      content: FutureBuilder(
        future: Future.wait([
          StreamingSharedPreferences.instance,
          widget.barCode == null ? Future.value(null) : Api.getProductInfo(widget.barCode ?? ''),
        ]),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Ops, an error occurred, please retry later'),
            );
          }

          StreamingSharedPreferences preferences = snapshot.data[0];
          var productData = snapshot.data[1];

          if (productData != null && productData['status'] == 1) {
            productNameController.text = productData["product"]["product_name_it"] ?? productData["product"]["product_name"];
          }

          if (widget.id != null) {
            // Get stored foods
            List<dynamic> products = jsonDecode(preferences.getString('products', defaultValue: '[]').getValue());
            Map<String, dynamic> currentProduct = products.firstWhere((product) => product['id'] == widget.id);
            formFields['id'] = currentProduct['id'];
            formFields["productName"] = currentProduct["productName"];
            formFields["expirationDate"] = currentProduct["expirationDate"];
            formFields["quantity"] = currentProduct["quantity"] ?? 1.0;
            productNameController.text = formFields["productName"];
            expirationDateController.text = DateFormat('yyyy-MM-dd').format(Jiffy(formFields["expirationDate"]).dateTime);
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
          onPressed: onSave,
        )
      ],
    );
  }
}
