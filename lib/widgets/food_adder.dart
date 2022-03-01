import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/api.dart';

class FoodAdderPopup extends StatefulWidget{
  final String? barCode;
  const FoodAdderPopup({Key? key, this.barCode}) : super(key: key);

  @override
  _FoodAdderPopupState createState() => _FoodAdderPopupState();

}

class _FoodAdderPopupState extends State<FoodAdderPopup>{
  Map<String, dynamic> formFields = {};
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController productNameController = TextEditingController();
  TextEditingController expirationDateController = TextEditingController();

  void openDatePicker(BuildContext context) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(3000)
    );

    if (date != null) {
      expirationDateController.text = DateFormat('yyyy-MM-dd').format(date);
      formFields["expirationDate"] = date;
    }
  }

  void onSave() {
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
    List<dynamic> foods = Hive.box('app').get('foods', defaultValue: <Map<dynamic, dynamic>>[]);
    // Add the new one
    foods.add(formFields);
    // Save velues to the db
    Hive.box('app').put('foods', foods);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add food'),
      content: FutureBuilder(
        future: widget.barCode == null ? null: Api.getProductInfo(widget.barCode ?? ""),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: double.infinity,
              height: 30,
              child: Center(
                child: CircularProgressIndicator()
              )
            );
          }

          if (snapshot.hasData && (snapshot.data as Map<String, dynamic>)["status"] == 1) {
            Map<String, dynamic> data = snapshot.data;
            productNameController.text = data["product"]["product_name"];
          }

          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: productNameController,
                    decoration: const InputDecoration(
                      labelText: "Enter food name"
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
                    onSaved: (String? value) => formFields["productName"] = value ?? "",
                  ),
                  TextFormField(
                    controller: expirationDateController,
                    readOnly: true,
                    onTap: () => openDatePicker(context),
                    decoration: const InputDecoration(
                      labelText: "Enter expiration date"
                    ),
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
          child: const Text("Add"),
          onPressed: onSave,
        )
      ],
    );
  }
}
