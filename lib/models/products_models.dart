// To parse this JSON data, do
//
//     final productsResponse = productsResponseFromJson(jsonString);

import 'dart:convert';

ProductsResponse productsResponseFromJson(String str) =>
    ProductsResponse.fromJson(json.decode(str));

String productsResponseToJson(ProductsResponse data) =>
    json.encode(data.toJson());

class ProductsResponse {
  ProductsResponse({
    required this.ok,
    required this.products,
  });

  bool ok;
  List<Product> products;

  factory ProductsResponse.fromJson(Map<String, dynamic> json) =>
      ProductsResponse(
        ok: json["ok"],
        products: List<Product>.from(
            json["products"].map((x) => Product.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "ok": ok,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
      };
}

class Product {
  Product({
    required this.available,
    required this.state,
    required this.id,
    required this.title,
    required this.desc,
    required this.price,
    required this.img,
    required this.detailImg,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  bool available;
  bool state;
  String id;
  String title;
  String desc;
  double price;
  String img;
  String detailImg;

  DateTime createdAt;
  DateTime updatedAt;
  int v;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        available: json["available"],
        state: json["state"],
        id: json["_id"],
        title: json["title"],
        desc: json["desc"],
        price: json["price"].toDouble(),
        img: json["img"],
        detailImg: json["detailImg"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "available": available,
        "state": state,
        "_id": id,
        "title": title,
        "desc": desc,
        "price": price,
        "img": img,
        "detailImg": detailImg,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
      };
}
