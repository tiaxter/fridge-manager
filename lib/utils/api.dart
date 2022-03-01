import 'package:dio/dio.dart';

class Api {
  static Future<Map<String, dynamic>> getProductInfo(String barcode) async {
      return (await Dio().get("https://world.openfoodfacts.org/api/v0/product/$barcode")).data;
  }
}
