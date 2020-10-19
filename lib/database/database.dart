import 'dart:async';
import 'dart:io' as io;
//import 'dart:js';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../model/order.dart';
import 'package:http/http.dart' as http; //package to make a http get call
import '../config.dart';
import 'dart:convert'; //package to decode json response from api
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import '../common/messagebox.dart' as messagebox;

class DbHelper {
  static Database myDb;

  Future<Database> get db async {
    if (myDb != null) return myDb;
    myDb = await initDb();
    return myDb;
  }

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "Scanapp.db");
    var theDb = await openDatabase(path, version: 1, onCreate: onCreate);
    return theDb;
  }

  Future<void> onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE tblOrderItem(orderid INTEGER, awbno TEXT," +
        "shippername TEXT, noofboxesinorder INTEGER,orderitemid INTEGER,itemid INTEGER," +
        "itemdesc TEXT, noofboxesinorderitem INTEGER,customerlocationid INTEGER,warehouseid INTEGER," +
        "warehousename TEXT, customerorwh TEXT,distributionboxes INTEGER," +
        "scannedboxes INTEGER,iscompleted INTEGER,isdeleted INTEGER )");

    await db.execute(
        "CREATE TABLE tblOrderItemScanned(orderid INTEGER, awbno TEXT," +
            "orderitemid INTEGER,itemid INTEGER," +
            "customerlocationid INTEGER,warehouseid INTEGER," +
            "uom TEXT,barcode TEXT," +
            "weight NUMERIC,iscompleted INTEGER,isdeleted INTEGER )");

    print("Created tables");
    await db.execute(
        "CREATE TABLE tblmanufactures(manufacturerId INTEGER  PRIMARY KEY, manufacturerName TEXT," +
            "defaultuom TEXT,barcoderegex TEXT,isbarcodecontainsweight INTEGER,barcodelength INTEGER)");
    print("Created tables1");
  }

  Future<void> reset() async {
    var dbClient = await db;
    // await dbClient.rawQuery(
    //     'Update tblOrder set Isdeleted=1');
    await dbClient.rawQuery('delete from tblOrderItem');
    await dbClient.rawQuery('delete from tblOrderItemScanned');
  }

  Future<void> saveOrder(Order order) async {
    var dbClient = await db;

    await dbClient.transaction((txn) async {
      return await txn.insert(
        'tblOrderItem',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> saveManufacturer(Manufacturer manufacturer) async {
    var dbClient = await db;

    await dbClient.transaction((txn) async {
      return await txn.insert(
        'tblmanufactures',
        manufacturer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<String> saveOrderScanned(OrderScanned order) async {
    var dbClient = await db;

    var query =
        'SELECT count(orderid) FROM tblOrderItemScanned where orderid=${order.orderid} and orderitemid=${order.orderitemid} ' +
            'and itemid=${order.itemid} and customerlocationid=${order.customerlocationid} and warehouseid=${order.warehouseid} ' +
            'and barcode="${order.barcode}"';
    var x = await dbClient.rawQuery(query);
    int cnt = Sqflite.firstIntValue(x);
    if (cnt <= 0) {
      await dbClient.transaction((txn) async {
        return await txn.insert(
          'tblOrderItemScanned',
          order.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      return "success";
    } else {
      return "already scanned";
    }
  }

  Future<List<Order>> getAWBs() async {
    var dbClient = await db;

    List<Map> li = await dbClient.rawQuery(
        'SELECT awbno,orderid,MAX(shippername) shippername,max(noofboxesinorder) noofboxesinorder,sum(scannedboxes) scannedboxes FROM tblOrderItem where isdeleted=0 group by awbno,orderid');
    List<Order> orders = new List();
    for (int i = 0; i < li.length; i++) {
      int scannedboxes = 0;
      var x = await dbClient.rawQuery(
          'SELECT count(*) FROM tblOrderItemScanned where orderid=${li[i]['orderid']}');

      if (x.length > 0) {
        scannedboxes = Sqflite.firstIntValue(x);
      }

      var order = Order(
          orderid: li[i]['orderid'],
          awbno: li[i]['awbno'],
          shippername: li[i]['shippername'],
          noofboxesinorder: li[i]['noofboxesinorder'],
          orderitemid: 0,
          itemid: 0,
          itemdesc: '',
          noofboxesinorderitem: 0,
          customerlocationid: 0,
          warehouseid: 0,
          warehousename: '',
          customerorwh: '',
          distributionboxes: 0,
          scannedboxes: scannedboxes,
          iscompleted: 0,
          isdeleted: 0);
      orders.add(order);
    }
    print(orders.length);
    return orders;
  }

  Future<List<Manufacturer>> getManufacturers() async {
    var dbClient = await db;

    List<Map> list = await dbClient.rawQuery('SELECT * FROM tblmanufactures');
    List<Manufacturer> manufacturers = new List();
    for (int i = 0; i < list.length; i++) {
      var manufacturer = Manufacturer(
          manufacturerid: list[i]['manufacturerId'],
          manufacturername: list[i]['manufacturerName'],
          defaultuom: list[i]['defaultuom'],
          isbarcodecontainsweight: list[i]['isbarcodecontainsweight'],
          barcoderegex: list[i]['barcoderegex'],
          barcodelength: list[i]['barcodelength']);
      manufacturers.add(manufacturer);
    }

    return manufacturers;
  }

  Future<List<OrderScanned>> getOrderItemScannedDetail(int orderItemId) async {
    var dbClient = await db;

    List<Map> list = await dbClient.rawQuery(
        'SELECT * FROM tblOrderItemScanned where orderitemid=$orderItemId');
    List<OrderScanned> orderItemsScanned = new List();
    for (int i = 0; i < list.length; i++) {
      var orderitemscanned = OrderScanned(
          orderid: list[i]['orderid'],
          awbno: list[i]['awbno'],
          orderitemid: list[i]['orderitemid'],
          customerlocationid: list[i]['customerlocationid'],
          warehouseid: list[i]['warehouseid'],
          uom:  list[i]['uom'],
          barcode: list[i]['barcode'],
          weight: list[i]['weight'],
          iscompleted: 0,
          isdeleted: 0);

      orderItemsScanned.add(orderitemscanned);
    }

    return orderItemsScanned;
  }

  Future<List<Order>> getCustomerorWhListByAWB(String awbno) async {
    var dbClient = await db;
    var query = '';
    var customerlocationid = 0;
    var x = await dbClient.rawQuery(
        'SELECT customerlocationid FROM tblOrderItem where awbno="' +
            awbno +
            '" LIMIT 1');

    if (x.length > 0) {
      customerlocationid = Sqflite.firstIntValue(x);
    }

    if (customerlocationid > 0) {
      query =
          'SELECT max(orderid) orderid,max(awbno) awbno,customerlocationid,warehouseid,max(customerorwh) customerorwh,sum(distributionboxes) distributionboxes,' +
              'sum(scannedboxes) scannedboxes FROM tblOrderItem where awbno="' +
              awbno +
              '" group by customerlocationid';
    } else {
      query =
          'SELECT max(orderid) orderid,max(awbno) awbno,0 customerlocationid,warehouseid,max(customerorwh) customerorwh,max(noofboxesinorder) distributionboxes,' +
              'sum(scannedboxes) scannedboxes FROM tblOrderItem where awbno="' +
              awbno +
              '" group by warehouseid';
    }

    List<Map> li = await dbClient.rawQuery(query);
    List<Order> orders = new List();
    for (int i = 0; i < li.length; i++) {
      int scannedboxes = 0;
      var x = await dbClient.rawQuery(
          'SELECT count(*) FROM tblOrderItemScanned where orderid=${li[i]['orderid']} ' +
              'and customerlocationid=${li[i]['customerlocationid']} and warehouseid=${li[i]['warehouseid']}');

      if (x.length > 0) {
        scannedboxes = Sqflite.firstIntValue(x);
      }

      var order = Order(
          orderid: li[i]['orderid'],
          awbno: li[i]['awbno'],
          shippername: '',
          noofboxesinorder: 0,
          orderitemid: 0,
          itemid: 0,
          itemdesc: '',
          noofboxesinorderitem: 0,
          customerlocationid: li[i]['customerlocationid'],
          warehouseid: li[i]['warehouseid'],
          warehousename: '',
          customerorwh: li[i]['customerorwh'],
          distributionboxes: li[i]['distributionboxes'],
          scannedboxes: scannedboxes,
          iscompleted: 0,
          isdeleted: 0);
      orders.add(order);
    }
    print(orders.length);
    return orders;
  }

  Future<List<Order>> getItemlistByCustomerOrWarehouse(
      String awbno, int customerlocationid, int warehouseid) async {
    var dbClient = await db;
    var query = '';

    if (customerlocationid > 0) {
      query =
          'SELECT awbno,orderid,customerlocationid,warehouseid,orderitemid,customerorwh,itemid,itemdesc,distributionboxes,' +
              'scannedboxes scannedboxes FROM tblOrderItem where awbno="' +
              awbno +
              '" and customerlocationid=' +
              customerlocationid.toString() +
              '';
    } else {
      query =
          'SELECT awbno,orderid,customerlocationid,warehouseid,orderitemid,customerorwh,itemid,itemdesc,noofboxesinorderitem distributionboxes,' +
              'scannedboxes scannedboxes FROM tblOrderItem where awbno="' +
              awbno +
              '" and warehouseid=' +
              warehouseid.toString() +
              '';
    }

    List<Map> li = await dbClient.rawQuery(query);
    List<Order> orders = new List();
    for (int i = 0; i < li.length; i++) {
      int scannedboxes = 0;
      var x = await dbClient.rawQuery(
          'SELECT count(orderid) FROM tblOrderItemScanned where orderid=${li[i]['orderid']} and orderitemid=${li[i]['orderitemid']} ' +
              'and customerlocationid=${li[i]['customerlocationid']} and warehouseid=${li[i]['warehouseid']}');

      if (x.length > 0) {
        scannedboxes = Sqflite.firstIntValue(x);
      }

      var order = Order(
          orderid: li[i]['orderid'],
          awbno: li[i]['awbno'],
          shippername: '',
          noofboxesinorder: 0,
          orderitemid: li[i]['orderitemid'],
          itemid: li[i]['itemid'],
          itemdesc: li[i]['itemdesc'],
          noofboxesinorderitem: 0,
          customerlocationid: li[i]['customerlocationid'],
          warehouseid: li[i]['warehouseid'],
          warehousename: '',
          customerorwh: li[i]['customerorwh'],
          distributionboxes: li[i]['distributionboxes'],
          scannedboxes: scannedboxes,
          iscompleted: 0,
          isdeleted: 0);
      orders.add(order);
    }
    print(orders.length);
    return orders;
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> toJson() {
    return {"name": "", "imagePath": "", "totalGames": "", "points": ""};
  }

  Future<String> syncOrdersFromApi() async {
    try {
      
      var dbClient = await db;
      
      
      List<Map> list = await dbClient.rawQuery(
          'SELECT orderitemid OrderItemId,customerlocationid CustomerLocationId, ' +
              'warehouseid	WarehouseId,CASE WHEN uom="LB" then 1 Else 2 END AS UOMId,barcode Barcode,weight Weight '+
              'FROM tblOrderItemScanned where iscompleted=0');
      String orderItemsScanned = jsonEncode(list);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (prefs.getString("LoginId") != null) {
        var token = prefs.getString("ApiAccessToken");
        var ref = prefs.getString("LoginId");

        var params = {"Ref": ref, "OrderItemsScanned": orderItemsScanned};
        Map<String, String> headers = {
          'Content-Type': 'application/json',
          'Authorization': "Bearer " + token.toString(),
        };

        final response = await http
            .post(
              myApiBaseURL + "/AddOrderItemScannedforScan",
              headers: headers,
              body: jsonEncode(params),
            )
            .timeout(Duration(seconds: apiTimeOut));

        if (response.statusCode == 200) {
          var result = json.decode(response.body.toString());
          var status = result["Status"];
          if (status == "valid") {
            var params = {"Ref": ref};
            Map<String, String> headers = {
              'Content-Type': 'application/json',
              'Authorization': "Bearer " + token.toString(),
            };

            final response1 = await http
                .post(
                  myApiBaseURL + "/GetOrdersforPickupScan",
                  headers: headers,
                  body: jsonEncode(params),
                )
                .timeout(Duration(seconds: apiTimeOut));

            if (response1.statusCode == 200) {
              var result1 = json.decode(response1.body.toString());
              var status1 = result1["Status"];
              if (status1 == "valid") {
                await reset();

                var orderItemdata = result1["Data"][0].toList();
                var orderItemScanneddata = result1["Data"][1].toList();

                for (int i = 0; i < orderItemdata.length; i++) {
                  var order = Order(
                      orderid: orderItemdata[i]['OrderId'],
                      awbno: orderItemdata[i]['AWBNO'],
                      shippername: orderItemdata[i]['ShipperName'],
                      noofboxesinorder: orderItemdata[i]['NoofBoxesInOrder'],
                      orderitemid: orderItemdata[i]['OrderItemId'],
                      itemid: orderItemdata[i]['ItemId'],
                      itemdesc: orderItemdata[i]['ItemDesc'],
                      noofboxesinorderitem: orderItemdata[i]
                          ['NoOfBoxesinOrderItem'],
                      customerlocationid: orderItemdata[i]
                          ['CustomerLocationId'],
                      warehouseid: orderItemdata[i]['WarehouseId'],
                      warehousename: orderItemdata[i]['WarehouseName'],
                      customerorwh: orderItemdata[i]['Customer/WH'],
                      distributionboxes: orderItemdata[i]['DistributionBoxes'],
                      scannedboxes: orderItemdata[i]['Scanned'],
                      iscompleted: 0,
                      isdeleted: 0);

                  await saveOrder(order);
                }

                for (int i = 0; i < orderItemScanneddata.length; i++) {
                  var orderScanned = OrderScanned(
                      orderid: orderItemScanneddata[i]['OrderId'],
                      awbno: orderItemScanneddata[i]['AWBNO'],
                      orderitemid: orderItemScanneddata[i]['OrderItemId'],
                      customerlocationid: orderItemScanneddata[i]
                          ['CustomerLocationId'],
                      warehouseid: orderItemScanneddata[i]['WarehouseId'],
                      barcode: orderItemScanneddata[i]['BarCode'],
                      weight: orderItemScanneddata[i]['Weight'],
                      uom:  orderItemScanneddata[i]['Weight'] ==1?"LB":"KG",
                      iscompleted: 1,
                      isdeleted: 0);

                  await saveOrderScanned(orderScanned);
                }
                return "success";
              } else {
                return result1["Data"].toString();
              }
            } else {
              return "Connection Error!" + response1.statusCode.toString();
            }
          } else {
            return result["Data"].toString();
          }
        } else {
          return "Connection Error!" + response.statusCode.toString();
        }
      } else {
        return "Please login again";
      }
    } catch (ex) {
      return "Error!" + ex.toString();
    }
  }

  // Future<String> syncOrdersFromApi() async {
  //     //var dbClient = await db;
  //     // List<Map> list = await dbClient.rawQuery(
  //     //       'SELECT orderid OrderId,awbno AWBNo,orderitemid OrderItemId,0 ItemSizeId,itemid ItemId,customerlocationid CustomerLocationId, '+
  //     //        'warehouseid	WarehouseId,1 UOMId,barcode Barcode,weight Weight FROM tblOrderItemScanned');
  //     //String orderItemsScanned = jsonEncode(list);

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   try {
  //     if (prefs.getString("LoginId") != null) {
  //       var token = prefs.getString("ApiAccessToken");
  //       var ref = prefs.getString("LoginId");

  //       var params = {"Ref": ref};
  //       Map<String, String> headers = {
  //         'Content-Type': 'application/json',
  //         'Authorization': "Bearer " + token.toString(),
  //       };

  //       final response = await http
  //           .post(
  //             myApiBaseURL + "/GetOrdersforPickupScan",
  //             headers: headers,
  //             body: jsonEncode(params),
  //           )
  //           .timeout(Duration(seconds: apiTimeOut));

  //       if (response.statusCode == 200) {
  //         var result = json.decode(response.body.toString());
  //         var status = result["Status"];
  //         if (status == "valid") {
  //           //setState(() {listOfColumns = result["Data"].toList();});
  //           await setAllOrdersAsDeleted();
  //           var data = result["Data"].toList();
  //           for (int i = 0; i < data.length; i++) {
  //             var order = Order(
  //                 orderid: data[i]['OrderId'],
  //                 awbno: data[i]['AWBNO'],
  //                 shippername: data[i]['ShipperName'],
  //                 noofboxesinorder: data[i]['NoofBoxesInOrder'],
  //                 orderitemid: data[i]['OrderItemId'],
  //                 itemid: data[i]['ItemId'],
  //                 itemdesc: data[i]['ItemDesc'],
  //                 noofboxesinorderitem: data[i]['NoOfBoxesinOrderItem'],
  //                 customerlocationid: data[i]['CustomerLocationId'],
  //                 warehouseid: data[i]['WarehouseId'],
  //                 warehousename: data[i]['WarehouseName'],
  //                 customerorwh: data[i]['Customer/WH'],
  //                 distributionboxes: data[i]['DistributionBoxes'],
  //                 scannedboxes: data[i]['Scanned'],
  //                 iscompleted: 0,
  //                 isdeleted: 0);
  //             await saveOrder(order);
  //           }

  //           return "success";
  //         } else {
  //           return result["Data"].toString();
  //         }
  //       } else {
  //         return "Connection Error!" + response.statusCode.toString();
  //       }
  //     } else {
  //       return "Please login again";
  //     }
  //   } catch (ex) {
  //     return "Error!" + ex.toString();
  //   }
  // }
}
