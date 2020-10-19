import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scanapp/screens/itemsScanDetail.dart';
import 'package:shared_preferences/shared_preferences.dart'; //package to save session values
import '../login/loginPages.dart';
import '../common/splash.dart'; //File under lib/splash.dart
// import 'package:http/http.dart' as http; //package to make a http get call
// import '../config.dart';
// import 'dart:convert'; //package to decode json response from api
import '../common/messagebox.dart' as messagebox;
import 'package:flutter_masked_text/flutter_masked_text.dart';
//import 'package:barcode_keyboard_listener/barcode_keyboard_listener.dart';
import '../database/database.dart' as OrderDatabase;
import '../model/order.dart' as OrderModel;

var listOfColumns;
var orderDatabasedbHelper = OrderDatabase.DbHelper();

class ItemsScanPage extends StatefulWidget {
  @override
  _ItemsScanPage createState() => _ItemsScanPage();
}

// class Manufacturers {
//   const Manufacturers(this.id, this.name, this.defaultUOM, this.barcodeRegex,
//       this.barcodeContainsweight, this.barcodelength);

//   final String name;
//   final int id;
//   final String defaultUOM;
//   final String barcodeRegex;
//   final int barcodeContainsweight;
//   final int barcodelength;
// }

class _ItemsScanPage extends State<ItemsScanPage> {
  logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("LoginId");
  }

  var args,
      orderid,
      customerlocationid,
      warehouseid,
      awb,
      orderitemid,
      itemid,
      customerorwh,
      totalboxes,
      listofcolumns,
      itemdesc,
      barcodeLength,
      barcodeInputLength,
      barcodeRegex,
      barcodeContainsweight;

  int noofboxes;
  int scannedboxes;
  String lastScannedBarcode = "";
  String lastScannedWeight = "";
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentBottomSelectedIndex = 0;
  bool futureCalledAlready = false;
  OrderModel.Manufacturer _selectedManufacturer;
  List<bool> isSelectedUOM;
  var barCodeOrWeight = "Barcode";
  bool _enableBarcodeTextBox = false;
  bool _enableWeightTextBox = false;

  var manufacturer = new List<OrderModel.Manufacturer>();
  // List<Manufacturers> manufacturer = <Manufacturers>[
  //   const Manufacturers(1, "Ibrahim Sea Foods", "KG", r"(.{4})(.{1})$", 1),
  //   const Manufacturers(2, "Sunshine Manufacturers Ibrahim Sea Foods", "LB",
  //       r"(.{4})(.{1})$", 1)
  // ];

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    txtBarcodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    isSelectedUOM = [true, false];
    super.initState();
  }

  final txtBarcodeController = TextEditingController();
  final txtWeightController = TextEditingController();
  final focusbarcode = FocusNode();
  showMessage(message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Message!"),
        content: Text(message),
        actions: [
          new FlatButton(
            child: const Text("Ok"),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop('dialog');
            },
          ),
        ],
      ),
    );
  }

  DataRow _getDataRow(result) {
    return DataRow(
      cells: <DataCell>[
        DataCell(
          Text(itemdesc, style: TextStyle(color: Colors.blue)),
          onTap: () {
               Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemsScanDetailPage(),
                // Pass the arguments as part of the RouteSettings. The
                // DetailScreen reads the arguments from these settings.
                settings: RouteSettings(arguments: {
                  "awbno":awb,
                    "orderid":orderid,                 
                    "customerorwh":customerorwh,                  
                    "orderitemid":orderitemid,                
                    "itemdesc":itemdesc,
                    "noofboxes": noofboxes,
                    "scannedboxes":scannedboxes,
                    "customerorwh":customerorwh,
                    "totalboxes":totalboxes
                }),
              ),
            );
          },
        ),
        DataCell(Text(noofboxes.toString())),
        DataCell(Text(scannedboxes.toString()))
      ],
    );
  }

  void onTabTappedBottomIcon(int index) {
    setState(() {
      if (index == 0) {
        barCodeOrWeight = "Barcode";
      } else {
        barCodeOrWeight = "Weight";
      }
      _currentBottomSelectedIndex = index;
    });
  }

  void onScanned(String value, bool noBarcode) async {
    // txtBarcodeController.clear();
    if (scannedboxes < noofboxes) {
      if (!noBarcode) {
        RegExp regExp = new RegExp(
          barcodeRegex,
          //caseSensitive: false,
          //multiLine: false,
        );
        var weight = regExp.firstMatch(value).group(1).toString();
        // print("allMatches : " +
        //     regExp.allMatches(value).toString());
        // print("firstMatch : " +

        if (weight.length >= 4) {
            lastScannedBarcode = value;
            lastScannedWeight =
                weight.substring(0, 2) + "." + weight.substring(2, 4);
          dynamic resultSaveScanned = await saveOrderScanned();
          if (resultSaveScanned == "success") {
            scannedboxes = scannedboxes + 1;
            listOfColumns = [
              {
                "ItemDesc": itemdesc,
                "NoOfBoxes": noofboxes,
                "Scanned": scannedboxes
              }
            ];

          
            txtBarcodeController.clear();
            setState(() {});
            if (scannedboxes == noofboxes) {
              _scanCompleted();
            }
          } else if (resultSaveScanned == "already scanned") {
            messagebox.showMessage(
                "Same box already scanned. Please verify!", context);
          }
          //FocusScope.of(context).requestFocus(focus);
        } else {
          messagebox.showMessage(
              "Invalid box. Please retry or enter weight manually", context);
        }
        txtBarcodeController.clear();
        // print("hasMatch : " +
        //     regExp.hasMatch(value).toString());
        // print("stringMatch : " +
        //     regExp.stringMatch(value).toString());
        // FocusScope.of(context).requestFocus(focus);
        //messagebox.showMessage("Test11", context);
      } else {
        value = double.parse(value).toStringAsFixed(2);
        if (value.length >= 4) {
              lastScannedBarcode = "";
              lastScannedWeight = value;
          dynamic resultSaveScanned = await saveOrderScanned();
          if (resultSaveScanned == "success") {
            // txtBarcodeController.text = "";
            txtWeightController.text = "";
            setState(() {
              scannedboxes = scannedboxes + 1;
              listOfColumns = [
                {
                  "ItemDesc": itemdesc,
                  "NoOfBoxes": noofboxes,
                  "Scanned": scannedboxes
                }
              ];

          
            });
            FocusScope.of(context).requestFocus(focusbarcode);
          } else if (resultSaveScanned == "already scanned") {
            messagebox.showMessage(
                "Same box already scanned. Please verify!", context);
          }
          
        } else {
          messagebox.showMessage(
              "Invalid weight. Please enter weight again", context);
        }
      }
    } else {
      _scanCompleted();
    }
  }

  Future<String> saveOrderScanned() async {
    try {
     
      var uom ="";
      if(isSelectedUOM.first){
        uom="LB";
      }
      else{
        uom="KG";
      }
      var orderscanned = OrderModel.OrderScanned(
          orderid: orderid,
          awbno: awb,
          orderitemid: orderitemid,
          itemid: itemid,
          customerlocationid: customerlocationid,
          warehouseid: warehouseid,
          barcode: lastScannedBarcode,
          weight: lastScannedWeight,
          uom: uom,
          iscompleted: 0,
          isdeleted: 0);
      return await orderDatabasedbHelper.saveOrderScanned(orderscanned);
    } catch (ex) {
      messagebox.showMessage("Error saving!", context);
      return "error";
    }
  }

  void _scanCompleted() {
    txtBarcodeController.clear();
    txtWeightController.clear();
    _enableBarcodeTextBox = false;
    _enableWeightTextBox = false;
    messagebox.showMessage("Scan completed", context);
  }

  Future<String> getManufacturers() async {
    if (futureCalledAlready == false) {
      args = ModalRoute.of(context).settings.arguments;
      awb = args['awbno'];
      orderid = args['orderid'];
      orderitemid = args['orderitemid'];
      itemid = args['itemid'];
      customerlocationid = args['customerlocationid'];
      warehouseid = args['warehouseid'];
      customerorwh = args['customerorwh'];
      totalboxes = args['totalboxes'];
      itemdesc = args['itemdesc'];
      noofboxes = args['noofboxes'];
      scannedboxes = args['scannedboxes'];
      // if (noofboxes == scannedboxes) {
      //   _scanCompleted();
      // }
      try {
        listOfColumns = [
          {
            "itemdesc": itemdesc,
            "noofboxes": noofboxes,
            "scannedboxes": scannedboxes
          }
        ];
        manufacturer = await orderDatabasedbHelper.getManufacturers();

        futureCalledAlready = true;
      } catch (ex) {
        showMessage("Error!" + ex.toString());
        listOfColumns = [];
        futureCalledAlready = true;
        //setState(() {listOfColumns = [];});
      }
      futureCalledAlready = true;
      return "success";
    } else {
      return "success";
    }
  }

  var controller = new MaskedTextController(mask: '000-0000-0000');
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: FutureBuilder<String>(
      //double width = MediaQuery.of(context).size.width;
      future: getManufacturers(),
      builder: (buildContext, snapshot) {
        if (snapshot.hasData) {
          //List jsonResponse = listOfColumns as List;
          return new Scaffold(
            appBar: AppBar(
              title: Text('Scan App',
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
              centerTitle: true,
            ),
            body: Padding(
                padding: EdgeInsets.all(0),
                child: Form(
                    child: ListView(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(40, 10, 40, 0),
                      height: 50.0,
                      child: Text(awb,
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500)),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(40, 10, 40, 0),
                      height: 50.0,
                      child: Text(
                          customerorwh +
                              "  -  " +
                              totalboxes.toString() +
                              " Box",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500)),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                       
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Item')),
                              DataColumn(label: Text('TotalBoxes')),
                              DataColumn(label: Text('Scanned'))
                            ],
                            rows: List.generate(listOfColumns.length,
                                (index) => _getDataRow(listOfColumns[index])),
                          ),
                      
                      ),
                    ),
                   Offstage(
                      offstage: noofboxes==scannedboxes? true:false,
                    child:Container(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: <Widget>[
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child:
                                    new DropdownButton<OrderModel.Manufacturer>(
                                  hint: new Text("Select a Manufacturer"),
                                  value: _selectedManufacturer,
                                  onChanged:
                                      (OrderModel.Manufacturer newValue) {
                                    // messagebox.showMessage(
                                    //     newValue.id, context);
                                    // messagebox.showMessage(
                                    //     newValue.name, context);
                                    _enableBarcodeTextBox = true;
                                    _enableWeightTextBox = true;
                                    if (scannedboxes <= 0 || _selectedManufacturer ==null) {
                                      barcodeLength = newValue.barcodelength;
                                      barcodeInputLength =
                                          newValue.barcodelength;
                                      barcodeRegex = newValue.barcoderegex;
                                      barcodeContainsweight =
                                          newValue.isbarcodecontainsweight;
                                      setState(() {
                                        _selectedManufacturer = newValue;
                                        if (newValue.defaultuom == "KG") {
                                          isSelectedUOM = [false, true];
                                        } else {
                                          isSelectedUOM = [true, false];
                                        }
                                      });
                                    } else {
                                      messagebox.showMessage(
                                          "Can't choose different manufacturer for same item",
                                          context);
                                    }
                                  },
                                  items: manufacturer.map(
                                      (OrderModel.Manufacturer manufacturers) {
                                    return new DropdownMenuItem<
                                        OrderModel.Manufacturer>(
                                      value: manufacturers,
                                      child: new SizedBox(
                                        width: 240.0,
                                        child: new Text(
                                          manufacturers.manufacturername,
                                          overflow: TextOverflow.clip,
                                          style: new TextStyle(
                                              color: Colors.black),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              Container(
                                width: 100,
                                child: ToggleButtons(
                                  borderColor: Colors.red,
                                  fillColor: Colors.blue,
                                  borderWidth: 1,
                                  selectedBorderColor: Colors.red,
                                  selectedColor: Colors.white,
                                  borderRadius: BorderRadius.circular(0),
                                  children: <Widget>[
                                    Text("LB"),
                                    Text("KG"),
                                  ],
                                  onPressed: (int index) {
                                    setState(() {
                                      for (int i = 0;
                                          i < isSelectedUOM.length;
                                          i++) {
                                        isSelectedUOM[i] = i == index;
                                      }
                                    });
                                  },
                                  isSelected: isSelectedUOM,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                   ),
                     Offstage(
                      offstage: noofboxes==scannedboxes? true:false,
                    child:Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(40, 15, 40, 5),
                      child: TextField(
                        focusNode: focusbarcode,
                        autocorrect: false,
                        enabled: _enableBarcodeTextBox,
                        controller: txtBarcodeController,
                        autofocus: false,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Barcode",
                          border: OutlineInputBorder(),
                          hintText: "Scan Or Enter Barcode",
                        ),
                        // onChanged: (value) {

                        //   if (value.length == barcodeLength && barcodeInputLength !=0) {
                        //     barcodeInputLength =0;
                        //     txtBarcodeController.text = "";
                        //     onScanned(value,false);

                        //   }
                        // },
                        onSubmitted: (value) {
                          onScanned(value, false);
                        },
                      ),
                    ),
                     ),
                     Offstage(
                      offstage: noofboxes==scannedboxes? true:false,
                    child:Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(40, 15, 40, 5),
                      child: TextFormField(
                        enabled: _enableWeightTextBox,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.go,
                        controller: txtWeightController,
                        onFieldSubmitted: (value) {
                          onScanned(value, true);
                        },
                        decoration: InputDecoration(
                          labelText: "Weight",
                          border: OutlineInputBorder(),
                          hintText: "Enter Weight",
                        ),
                      ),
                    ),
                     ),
                    Offstage(
                      offstage: noofboxes==scannedboxes? false:true,
                     child:Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(40, 10, 40, 0),                      
                      child: Text("SCAN COMPLETED",
                          style: TextStyle(
                              fontSize: 30,
                              color: Colors.green,
                              fontWeight: FontWeight.w500)),
                    ),
                    ),                    
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(40, 10, 40, 0),                     
                      child: Text(lastScannedWeight.isEmpty
                                    ? "":"Last Scan",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500)),
                    ),                   
                    Container(
                      alignment: Alignment.center,
                     padding: EdgeInsets.fromLTRB(0, 10, 0, 0),  
                      child: RichText(
                        text: TextSpan(
                          text: '',
                          style: TextStyle(color: Colors.red),
                          /*defining default style is optional */
                          children: <TextSpan>[
                            TextSpan(
                                text: lastScannedBarcode.isEmpty
                                    ? ""
                                    : 'Barcode: ',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 20)),
                            TextSpan(
                                text: lastScannedBarcode,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 20)),
                            TextSpan(
                                text: lastScannedWeight.isEmpty
                                    ? ""
                                    : ' Weight: ',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 20)),
                            TextSpan(
                                text: lastScannedWeight,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ))),
            bottomNavigationBar: BottomNavigationBar(
              onTap: onTabTappedBottomIcon, // new
              currentIndex:
                  _currentBottomSelectedIndex, // this will be set when a new tab is tapped
              items: [
                BottomNavigationBarItem(
                  icon: new Icon(Icons.camera),
                  title: new Text('Upload image'),
                ),
                BottomNavigationBarItem(
                  icon: new Icon(Icons.keyboard),
                  title: new Text('Type Weight'),
                ),
              ],
            ),
            drawer: Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    child: Text(''),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                  ),
                  ListTile(
                    title: Text('Logout'),
                    onTap: () {
                      logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyLoginPage2(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          // Return loading screen while reading preferences
          return Center(child: ClsSplashScreen());
        }
      },
    ));
  }
}
