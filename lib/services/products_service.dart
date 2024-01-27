import 'dart:async';
import 'dart:io';

import 'package:employee_attendance/models/products_models.dart';
import 'package:employee_attendance/services/api_base_helper.dart';
import 'package:employee_attendance/services/app_exceptions.dart';
import 'package:http/http.dart' as http;

//const BASE_URL = 'https://api.npoint.io/7cee1296adbbc89c04db/0';
const BASE_URL = 'https://api.npoint.io/7cee1296adbbc89c04db/0';

class ProductsService {
  Future<List<Product>> getProducts({int code = 200}) async {
    final url = BASE_URL;
    final url2 = Uri.parse(url);
    var responseJson;
    try {
      final resp = await http.get(url2).timeout(const Duration(seconds: 5));
      responseJson = returnResponse(resp);
    } on  TimeoutException catch (_) {
      throw ('Tiempo de espera alcanzado');
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on HttpException {
      throw ("No se encontro esa peticion");
    } catch (e) {
      print(e.toString());
    }

    return productsResponseFromJson(responseJson).products;
  }
}
