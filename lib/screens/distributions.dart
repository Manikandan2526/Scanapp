import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; //package to save session values
import '../login/loginPages.dart';
import '../screens/items.dart';
import '../common/splash.dart'; //File under lib/splash.dart
//import '../common/messagebox.dart' as messagebox;
import 'package:flutter_masked_text/flutter_masked_text.dart';
import '../database/database.dart' as OrderDatabase;
//import '../model/order.dart' as OrderModel;

var listOfColumns;

var orderDatabasedbHelper = OrderDatabase.DbHelper();

class DistributionPage extends StatefulWidget {
  @override
  _DistributionPage createState() => _DistributionPage();
}

class _DistributionPage extends State<DistributionPage> {
  logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("LoginId");
  }
  var args;
  var awbno = '';

  final scaffoldKey = GlobalKey<ScaffoldState>();
  var listOfColumns;
 
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

  Future<String> getCustomerorWhListByAWB() async {   
    try{
      awbno = ModalRoute.of(context).settings.arguments;      
      listOfColumns  = await orderDatabasedbHelper.getCustomerorWhListByAWB(awbno); 
        
    }
    catch (ex) {
      showMessage("Error!" + ex.toString());
      listOfColumns = [];
      //setState(() {listOfColumns = [];});
    }
      return "success";
  }

  DataRow _getDataRow(result) {
    return DataRow(
      cells: <DataCell>[
        DataCell(
          Text(result.customerorwh.toString(),
              style: TextStyle(color: Colors.blue)),
          onTap: () {
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemsPage(),
                // Pass the arguments as part of the RouteSettings. The
                // DetailScreen reads the arguments from these settings.
                settings: RouteSettings(
                  arguments: {
                    "awbno":result.awbno,
                    "orderid":result.orderid,
                    "customerlocationid":result.customerlocationid,
                    "warehouseid":result.warehouseid,
                    "customerorwh":result.customerorwh.toString(),
                    "totalboxes":result.distributionboxes,
                  }
                  
                   
                ),
              ),
            );            
            
          },
        ),        
        DataCell(Text(result.distributionboxes.toString())),
        DataCell(Text(result.scannedboxes.toString())),
      ],
    );
  }
var controller = new MaskedTextController(mask: '000-0000-0000');
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: FutureBuilder<String>(
      //double width = MediaQuery.of(context).size.width;
      future: getCustomerorWhListByAWB(),
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
                      padding: EdgeInsets.fromLTRB(40, 10,40,0),
                       height: 50.0,
                      child: Text(awbno,style:TextStyle(
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
                              DataColumn(label: Text('Customer/WH')),
                              DataColumn(label: Text('TotalBoxes')),
                              DataColumn(label: Text('Scanned')),
                            ],
                            rows: List.generate(listOfColumns.length,
                                (index) => _getDataRow(listOfColumns[index])),
                          ),
                       
                      ),
                    ),
                  ],
                ))
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
