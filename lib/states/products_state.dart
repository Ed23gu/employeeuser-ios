import 'package:employee_attendance/models/products_models.dart';
import 'package:employee_attendance/services/app_exceptions.dart';
import 'package:employee_attendance/services/products_service.dart';
import 'package:flutter/material.dart';

enum ProductState { INITIAL, LOADING, LOADED, EMPTY, ERROR }

class ProductsChangeNotifier with ChangeNotifier {
  // Servicio que nos permite obtener los productos por medio de un REST API
  final _productsService = ProductsService();
  // Estado de la logica de negocios para el manejo de productos
  ProductState _productState = ProductState.INITIAL;
  // Nuestra lista de productos para mostrar en pantalla
  List<Product> _products = [];
  // Si ocurre algun error con las peticiones, la guardaremos aca.
  late AppException _appException;

  ProductsChangeNotifier() {
    getProducts(code: 200);
  }

  // GET & SET de los Productos
  getProducts({int code = 200}) async {
    _setState(ProductState.LOADING);
    try {
      _products = await _productsService.getProducts(code: code);
      _setState(ProductState.LOADED);
    } on AppException catch (appException) {
      _setFailure(appException);
    }
  }

  // GET de los productos
  List<Product> get products => _products;

  // GET & SET del estado
  ProductState get state => _productState;

  _setState(ProductState value) {
    _productState = value;
    notifyListeners();
  }

  // GET & SET de los errores
  AppException get failure => _appException;
  _setFailure(AppException value) {
    _appException = value;
    _setState(ProductState.ERROR);
  }
}
