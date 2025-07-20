import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrdersProvider with ChangeNotifier {
  List<dynamic> _regularOrders = [];
  List<dynamic> _customOrders = [];

  List<dynamic> _selectedOrderItemsList = [];

  var selectedOrderType = "";
  var selectedOrderKey = "";

  List<dynamic> get regularOrders {
    return [..._regularOrders];
  }

  List<dynamic> get customOrders {
    return [..._customOrders];
  }

  List<dynamic> get selectedOrderItemsList {
    return [..._selectedOrderItemsList];
  }

  var workerType = "";

  Future<void> fetchOrders(String month, String year, String date) async {
    print(month);
    print(year);
    print(date);
    _regularOrders = [];
    _customOrders = [];
    var url =
        "https://shastri-nagar-shop-app-default-rtdb.firebaseio.com/activeOrders/$month/$year/$date.json";
    try {
      final response = await http.get(Uri.parse(url));
      final List<dynamic> loadedOrders = [];
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == "null") {
        print("NO orders");
        return;
      }
      print("FETCHED PROPERLY");
      extractedData.forEach((orderId, orderData) {
        if (!(orderData['orderType'] == "regular" &&
            orderData['items'] == null)) {
          loadedOrders.add({
            ...orderData,
            "orderKey": orderId,
            "cakesPrepared": false,
            "snacksPrepared": false,
          });
          modifyDeliveryTime(orderData);
        }
      });
      print("Loaded orders = ");
      print(loadedOrders);
      segregateOrders(loadedOrders);

      print("Segregation completed");
      print(_regularOrders);
      print(_customOrders);
      notifyListeners();
      return;
    } catch (error) {
      print("Error is = $error");
      rethrow;
    }
  }

  void modifyDeliveryTime(dynamic orderData) {
    var time = orderData["deliveryTime"];
    var timeArray = time.toString().trim().split(":");
    var hrs = int.parse(timeArray[0]);
    var modifiedHrs = hrs - 1;
    if (modifiedHrs == 0) {
      modifiedHrs = 12;
    }
    String modHrs = modifiedHrs.toString();
    if (modifiedHrs < 10) {
      modHrs = "0$modHrs";
    }

    var modifiedTime = "$modHrs:${timeArray[1]}";

    orderData["deliveryTime"] = modifiedTime;
  }

  Future<void> updateOrderSeenBy(String month, String year, String date,
      String orderKey, String seenBy) async {
    var url =
        "https://shastri-nagar-shop-app-default-rtdb.firebaseio.com/activeOrders/" +
            month +
            "/" +
            year +
            "/" +
            date +
            "/" +
            orderKey +
            '.json';
    try {
      final body = workerType == "Cake Orders"
          ? {"cakesSeenBy": seenBy}
          : {"snacksSeenBy": seenBy};
      final response =
          await http.patch(Uri.parse(url), body: json.encode(body));
      notifyListeners();
      return;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateOrderItems(String month, String year, String date,
      int index, bool value, String orderKey) async {
    int foundIndex = -1;
    foundIndex = selectedOrderItemsList[index]["indexedAt"];

    var url =
        "https://shastri-nagar-shop-app-default-rtdb.firebaseio.com/activeOrders/" +
            month +
            "/" +
            year +
            "/" +
            date +
            "/" +
            orderKey +
            "/items/" +
            foundIndex.toString() +
            '.json';
    try {
      final body = value ? {'prepared': "YES"} : {'prepared': "NO"};
      final response =
          await http.patch(Uri.parse(url), body: json.encode(body));

      if (value) {
        selectedOrderItemsList[index]["prepared"] = "YES";
      } else {
        selectedOrderItemsList[index]["prepared"] = "NO";
      }

      notifyListeners();
      return;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateOrder(String month, String year, String date,
      String orderType, String orderKey) async {
    var url =
        "https://shastri-nagar-shop-app-default-rtdb.firebaseio.com/activeOrders/" +
            month +
            "/" +
            year +
            "/" +
            date +
            "/" +
            orderKey +
            '.json';
    try {
      final body = {"status": "P"};
      final response =
          await http.patch(Uri.parse(url), body: json.encode(body));

      for (var i = 0; i < _customOrders.length; i++) {
        if (_customOrders[i]["orderKey"] == selectedOrderKey) {
          _customOrders[i]["status"] = "P";
        }
      }

      notifyListeners();
      return;
    } catch (error) {
      rethrow;
    }
  }

  void segregateOrders(List<dynamic> allOrders) {
    allOrders = allOrders
        .where((element) => element['status'] != 'C')
        .toList(); //cancelled orders dikhenge hi nahi!
    _customOrders = [];
    _regularOrders = [];
    var cakesPrepared = false;
    var snacksPrepared = false;
    for (var element in allOrders) {
      if (element["orderType"] == "custom") {
        _customOrders.add(element);
      } else if (element["orderType"] == "regular") {
        var cakeItems = [];
        var snackItems = [];
        var index = 0;
        element["items"].forEach((item) => {
              if (item["itemType"] == "CAKES")
                {
                  cakeItems.add({...item, "indexedAt": index++})
                }
              else if (item['itemType'] == "FACTORY ITEM")
                {print("its a factory item found")}
              else
                {
                  snackItems.add({...item, "indexedAt": index++})
                }
            });
        element["cakeItems"] = cakeItems;
        element["snackItems"] = snackItems;

        var cakeNotPrepared = cakeItems
            .firstWhere((cake) => cake["prepared"] == "NO", orElse: () => null);

        var snackNotPrepared = snackItems.firstWhere(
            (snack) => snack["prepared"] == "NO",
            orElse: () => null);

        if (cakeNotPrepared == null) {
          element["cakesPrepared"] = true;
        }
        if (snackNotPrepared == null) {
          element["snacksPrepared"] = true;
        }
        _regularOrders.add(element);
      }
      // notifyListeners();
    }
  }

  void getSelectedOrderItemsList() {
    _selectedOrderItemsList = [];
    if (workerType == "Cake Orders") {
      _selectedOrderItemsList = (_regularOrders
          .where((element) => element["orderKey"] == selectedOrderKey)
          .toList()[0]["cakeItems"]);
    } else {
      _selectedOrderItemsList = (_regularOrders
          .where((element) => element["orderKey"] == selectedOrderKey)
          .toList()[0]["snackItems"]);
    }
  }

  String getSelectedOrderParticulars(orderType) {
    if (orderType == "regular") {
      return _regularOrders
          .where((element) => element["orderKey"] == selectedOrderKey)
          .toList()[0]["particulars"];
    } else {
      return _customOrders
          .where((element) => element["orderKey"] == selectedOrderKey)
          .toList()[0]["particulars"];
    }
  }

  String getImgUrl() {
    return _customOrders
        .where((element) => element["orderKey"] == selectedOrderKey)
        .toList()[0]["imgUrl"];
  }

  String getPhotoUrl() {
    return _customOrders
        .where((element) => element["orderKey"] == selectedOrderKey)
        .toList()[0]["photoUrl"];
  }

  String getFlavour() {
    return _customOrders
        .where((element) => element["orderKey"] == selectedOrderKey)
        .toList()[0]["flavour"];
  }

  String getMessage() {
    return _customOrders
        .where((element) => element["orderKey"] == selectedOrderKey)
        .toList()[0]["message"];
  }

  bool getCakeStatus() {
    var st = _customOrders
        .where((element) => element["orderKey"] == selectedOrderKey)
        .toList()[0]["status"];
    if (st == "ND") {
      return false;
    }
    return true;
  }

  num getPound() {
    return _customOrders
        .where((element) => element["orderKey"] == selectedOrderKey)
        .toList()[0]["weight"];
  }
}
