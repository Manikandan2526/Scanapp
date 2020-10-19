import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; //package to save session values
import '../login/loginPages.dart';
import '../common/splash.dart'; //File under lib/splash.dart
// import 'package:http/http.dart' as http; //package to make a http get call
// import '../config.dart';
// import 'dart:convert'; //package to decode json response from api
import '../common/messagebox.dart' as messagebox;
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'distributions.dart';
import '../database/database.dart' as OrderDatabase;
//import '../model/order.dart' as OrderModel;

var listOfColumns;
var orderDatabasedbHelper = OrderDatabase.DbHelper();


class HomePage extends StatefulWidget {
  @override
  _HomePage1 createState() => _HomePage1();
}

class _HomePage1 extends State<HomePage> {
  //final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  //  new GlobalKey<RefreshIndicatorState>();
  logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("LoginId");
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();
  var listOfColumns;
  bool _sortAsc = true;
  //bool _sortAgeAsc = true;
  //bool _sortHightAsc = true;
  bool _sortShipperAsc = true;
  int _sortColumnIndex;
  bool _disablesyncbutton = false;
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
          Text(result.awbno.toString(),
              style: TextStyle(color: Colors.blue)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DistributionPage(),
                // Pass the arguments as part of the RouteSettings. The
                // DetailScreen reads the arguments from these settings.
                settings: RouteSettings(arguments: result.awbno.toString()),
              ),
            );
          },
        ),
        DataCell(Text(result.shippername.toString())),
        DataCell(Text(result.noofboxesinorder.toString())),
        DataCell(Text(result.scannedboxes.toString())),
      ],
    );
  }

  Future<String> getAWBs() async {
    try {
      listOfColumns = await orderDatabasedbHelper.getAWBs();
    } catch (ex) {
      showMessage("Error!" + ex.toString());
      listOfColumns = [];
      //setState(() {listOfColumns = [];});
    }
    return "success";
  }

  
  Future<String> syncOrdersFromApi() async {
    try {
       scaffoldKey.currentState.showSnackBar(new SnackBar(
          backgroundColor: Colors.blue,
          duration: new Duration(seconds: 10),
          content: new Row(
            children: <Widget>[
              new CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              new Text("  Syncing live records! please wait....")
            ],
          ),
        ));
        
      var result = await orderDatabasedbHelper.syncOrdersFromApi();
      if(result == "success"){
         scaffoldKey.currentState.hideCurrentSnackBar();
         _disablesyncbutton =false;
         setState(() {});
      }
      else{
         scaffoldKey.currentState.hideCurrentSnackBar();
         _disablesyncbutton =false;
        messagebox.showMessage(result, context);
      }
    } catch (ex) {
      _disablesyncbutton =false;
      showMessage("Error!" + ex.toString());
      listOfColumns = [];
      //setState(() {listOfColumns = [];});
    }
    return "success";
  }

  var awbcontroller = new MaskedTextController(mask: '@@@-@@@@-@@@@');
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: FutureBuilder<String>(
      //double width = MediaQuery.of(context).size.width;
      future: getAWBs(),
      builder: (buildContext, snapshot) {
        if (snapshot.hasData) {
          //List jsonResponse = listOfColumns as List;
          return new Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
              title: Text('Scan App',
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
              centerTitle: true,
              actions: <Widget>[
                new IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: "Sync live records",
                  onPressed: () {                    
                    if(_disablesyncbutton == false){
                      _disablesyncbutton =true;
                        syncOrdersFromApi();
                    }
                    
                  },
                )
              ],
            ),
            body: Padding(
                padding: EdgeInsets.all(0),
                child: Form(
                    child: ListView(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(40, 15, 40, 5),
                      child: TextFormField(
                        textInputAction: TextInputAction.next,
                        controller: awbcontroller,
                        decoration: InputDecoration(
                            labelText: 'AWB#',
                            border: OutlineInputBorder(),
                            hintText: "Type an AWB#"),
                        onFieldSubmitted: (v) {
                          if (awbcontroller.text.trim().length > 12) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DistributionPage(),
                                // Pass the arguments as part of the RouteSettings. The
                                // DetailScreen reads the arguments from these settings.
                                settings: RouteSettings(
                                  arguments: awbcontroller.text.trim().toUpperCase(),
                                ),
                              ),
                            );
                          } else {
                            messagebox.showMessage(
                                "AWB# should be 11 digits", context);
                          }
                        },
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child:  DataTable(
                            columns: [
                              DataColumn(label: Text('AWB')),
                              DataColumn(
                                label: Text('Shipper'),
                                onSort: (columnIndex, sortAscending) {
                                  setState(() {
                                    if (columnIndex == _sortColumnIndex) {
                                      _sortAsc =
                                          _sortShipperAsc = sortAscending;
                                    } else {
                                      _sortColumnIndex = columnIndex;
                                      _sortAsc = _sortShipperAsc;
                                    }
                                    listOfColumns.sort((a, b) =>
                                        a.Shipper.compareTo(b.Shipper));
                                    if (!_sortAsc) {
                                      listOfColumns =
                                          listOfColumns.reversed.toList();
                                    }
                                  });
                                },
                              ),
                              DataColumn(label: Text('Pieces')),
                              DataColumn(label: Text('Scanned')),
                            ],
                            rows: List.generate(listOfColumns.length,
                                (index) => _getDataRow(listOfColumns[index])),
                          ),                      
                      ),
                    ),
                  ],
                ))),
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
