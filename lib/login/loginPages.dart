import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; //package to save session values
import 'package:http/http.dart' as http; //package to make a http get call
import 'dart:async'; //package to make future async call
import 'dart:convert'; //package to decode json response from api
import 'package:scanapp/config.dart';
import 'package:scanapp/screens/awb.dart';
import '../common/splash.dart'; //File under lib/splash.dart
import '../model/order.dart' as OrderModel;
import '../database/database.dart' as OrderDatabase;

List<String> loggedInEmailList = [];

class MyLoginPage1 extends StatefulWidget {
  @override
  _StateLoginPage1 createState() => _StateLoginPage1();
}

class _StateLoginPage1 extends State<MyLoginPage1> {
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController emailController = new TextEditingController();

  _submitCommand(emailId) {
    final form = formKey.currentState;

    if (form.validate()) {
      //Validation success
      form.save();

      validateLoginEmail(emailId);
      // _saveLogginEmailids(emailId);

    } else {
      scaffoldKey.currentState.hideCurrentSnackBar();
    }
  }

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

  Future<void> validateLoginEmail(emailId) async {
    try {
      var params = {
        "LoginEmail": emailId,
        "Source": "App",
      };

      final _baseURL = myApiBaseURL;
      final _methodName = "/ValidateLoginEmail";

      final response = await http
          .post(_baseURL + _methodName, body: params)
          .timeout(Duration(seconds: apiTimeOut));
      if (response.statusCode == 200) {
        var validateEmailResult = json.decode(response.body.toString());
        var status = validateEmailResult["Status"];
        if (status == "valid"){
          var resultData = validateEmailResult["Data"];
          var emailExist = resultData["EmailExist"];
          if (emailExist) {
            _saveLoggedinEmailids(emailId);

            //if emailid exist move to next screen (Password screen)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MyLoginPage2(),
                // Pass the arguments as part of the RouteSettings. The
                // DetailScreen reads the arguments from these settings.
                settings: RouteSettings(
                  arguments: emailId,
                ),
              ),
            );
          } else {
            showMessage("You don't have access to the application.");
          }
        } else {
          showMessage("Error:" + validateEmailResult["Data"]);
        }
      } else {
        showMessage("Connection Error!" + response.statusCode.toString());
      }
      scaffoldKey.currentState.hideCurrentSnackBar();
    } catch (ex) {
      showMessage("Connection Error!" + ex.toString());
      scaffoldKey.currentState.hideCurrentSnackBar();
    }
  }

  _saveLoggedinEmailids(emailid) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList("loggedInEmailIds") == null) {
      loggedInEmailList.add(emailid);
      prefs.setStringList("loggedInEmailIds", loggedInEmailList);
    } else {
      loggedInEmailList = prefs.getStringList("loggedInEmailIds");
      if (!loggedInEmailList.contains(emailid)) {
        loggedInEmailList.add(emailid);
      }

      prefs.setStringList("loggedInEmailIds", loggedInEmailList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Scan App',
              style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
          centerTitle: true,
        ),
        body: Padding(
            padding: EdgeInsets.all(20),
            child: Form(
                key: formKey,
                child: ListView(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      height: 120.0,
                      child: Image.asset(
                        "assets/images/Applogo.png",
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(40),
                      child: Text("Welcome",
                          style: TextStyle(
                              fontSize: 30,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500)),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      child: TextFormField(
                        controller: emailController,
                          autocorrect: false,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.blue,
                          ),
                          labelText: 'Email',
                          hintText: "Enter your email",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == "") {
                            return "Enter an email";
                          }
                          bool emailRule = RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(val);

                          if (!emailRule) {
                            return "Enter a valid email";
                          } else {
                            return null;
                          }
                        },
                        onSaved: (val) {
                          //_saveLoggedinEmailids(val);
                        },
                      ),
                    ),
                    Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(20),
                        child: SizedBox(
                          height: 60,
                          width: 140,
                          child: RaisedButton(
                            color: Colors.blue,
                            onPressed: () {
                              scaffoldKey.currentState
                                  .showSnackBar(new SnackBar(
                                backgroundColor: Colors.blue,
                                duration: new Duration(seconds: 10),
                                content: new Row(
                                  children: <Widget>[
                                    new CircularProgressIndicator(
                                      valueColor:
                                          new AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                    new Text("  Signing-In...")
                                  ],
                                ),
                              ));
                              _submitCommand(emailController.text.trim());
                            },
                            child: Text(
                              "Next",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ))
                  ],
                ))
                )
                );
  }
}

class MyLoginPage2 extends StatefulWidget {
  @override
  _StateLoginPage2 createState() => _StateLoginPage2();
}

class _StateLoginPage2 extends State<MyLoginPage2> {
  var _currentSelectedItem = "";
  var passwordVisible = true;

  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController passwordController = new TextEditingController();


  

  Future<String> getLoggedInEmailIds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
        if (prefs.getStringList("loggedInEmailIds") != null) {
          loggedInEmailList = prefs.getStringList("loggedInEmailIds");  
          return "success";      
        }
    } catch (ex) {}
    return null;
  }
  

  void _submitCommand(emailId) {
    final form = formKey.currentState;

    if (form.validate()) {
      //Validation success
      form.save();
      validateLogin(emailId);
    } else {
      scaffoldKey.currentState.hideCurrentSnackBar();
    }
  }

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

  Future<void> validateLogin(emailId) async {
    try {
      var params = {
        "LoginEmail": _currentSelectedItem,
        "LoginPassword": passwordController.text,
      };

      final _baseURL = myApiBaseURL;
      final _methodName = "/GetLoginDetailScanApp";

      final response = await http
          .post(_baseURL+ _methodName, body: params)
          .timeout(Duration(seconds: apiTimeOut));
      if (response.statusCode == 200) {
        var validateEmailResult = json.decode(response.body.toString());
        var status = validateEmailResult["Status"];
        if (status == "valid") {
          //  _saveLoggedinEmailids(emailId);
          var loginResult = validateEmailResult["Data"];
          _saveLoginIdAndToken(loginResult["Ref"],validateEmailResult["Token"]);

          //if emailid exist move to next screen (Password screen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
              // Pass the arguments as part of the RouteSettings. The
              // DetailScreen reads the arguments from these settings.
            ),
          );
        } else {
          showMessage("Invalid Password!");
        }
      } else {
        showMessage("Connection Error!" + response.statusCode.toString());
      }
      scaffoldKey.currentState.hideCurrentSnackBar();
    } catch (ex) {
      showMessage("Connection Error!" + ex.toString());
      scaffoldKey.currentState.hideCurrentSnackBar();
    }
  }

  _saveLoginIdAndToken(loginId,apiAccessToken) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString("LoginId") == null) {
      prefs.setString("LoginId", loginId);
      prefs.setString("ApiAccessToken", apiAccessToken);
      
      
    }


     var params = {"Ref": loginId};
          Map<String, String> headers = {
            'Content-Type': 'application/json',
            'Authorization': "Bearer " + apiAccessToken.toString(),
          };

          final response = await http
              .post(
                myApiBaseURL + "/GetManufacturersforScan",
                headers: headers,
                body: jsonEncode(params),
              )
              .timeout(Duration(seconds: apiTimeOut));

          if (response.statusCode == 200) {
            var result = json.decode(response.body.toString());
            var status = result["Status"];
            if (status == "valid") {
              //setState(() {listOfColumns = result["Data"].toList();});
              var manufacList = result["Data"].toList();

              //manufacturer = new List<Manufacturers>();
              for (var i = 0; i < manufacList.length; i++) {
                //print(manufacList[i].ManufacturerId);
            
              var manu =   OrderModel.Manufacturer(
                   manufacturerid: manufacList[i]['ManufacturerId'],
                   manufacturername:manufacList[i]['ManufacturerName'],
                   defaultuom: manufacList[i]['DefaultUOM'] ,
                   isbarcodecontainsweight:manufacList[i]['IsBarcodeContainsWeight'] ,
                   barcoderegex: manufacList[i]['BarcodeRegex'] ,
                   barcodelength: 10
                    );
                var orderDatabasedbHelper = OrderDatabase.DbHelper();
                await orderDatabasedbHelper.saveManufacturer(manu);
              }
              //_selectedManufacturer = manufacturer[0];
            } else {
              //setState(() {listOfColumns = [];});
              listOfColumns = [];
             // messagebox.showMessage(result["Data"].toString(), context);
            }
          } else {
            //setState(() {listOfColumns = [];});
            listOfColumns = [];
            showMessage("Connection Error!" + response.statusCode.toString());
          }
  }

  _deleteLoggedInEmailIDFromPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.clear();
    try {
      if (prefs.getStringList("loggedInEmailIds") != null) {
        loggedInEmailList = prefs.getStringList("loggedInEmailIds");
        loggedInEmailList.remove(_currentSelectedItem);
        prefs.setStringList("loggedInEmailIds", loggedInEmailList);
        if (loggedInEmailList.length <= 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyLoginPage1(),
            ),
          );
        } else {
          setState(() {
            loggedInEmailList = loggedInEmailList;
            _currentSelectedItem = loggedInEmailList.last.toString();
          });
        }
        return true;
      } else {
        return false;
      }
    } catch (ex) {}
  }

  @override
 Widget build(BuildContext context) {
    return MaterialApp(home: FutureBuilder<String>(
     future: getLoggedInEmailIds(),
     builder: (buildContext, snapshot) {
     if(snapshot.hasData) {
    var emailId = ModalRoute.of(context).settings.arguments;

    if (_currentSelectedItem == null || _currentSelectedItem == "") {
      if (emailId == "" || emailId == null) {
        _currentSelectedItem = loggedInEmailList.last.toString();
      } else {
        _currentSelectedItem = emailId;
      }
    }

    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Scan App',
              style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
          centerTitle: true,
        ),
        body: Padding(
            padding: EdgeInsets.all(20),
            child: Form(
                key: formKey,
                child: ListView(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      height: 120.0,
                      child: Image.asset(
                        "assets/images/Applogo.png",
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(40),
                      child: Text("Welcome",
                          style: TextStyle(
                              fontSize: 30,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500)),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: <Widget>[
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: MediaQuery.of(context).size.width * 0.72,
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: DropdownButton(
                                  isExpanded: true,
                                  items: loggedInEmailList.map(
                                    (val) {
                                      return DropdownMenuItem(
                                        value: val,
                                        child: Text(val),
                                      );
                                    },
                                  ).toList(),
                                  value: _currentSelectedItem,
                                  onChanged: (value) {
                                    setState(() {
                                      _currentSelectedItem = value;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerRight,
                                child: new IconButton(
                                  icon:
                                      new Icon(Icons.delete, color: Colors.red),
                                  highlightColor: Colors.red,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Message!"),
                                        content: Text(
                                            "Are you sure want to delete account: " +
                                                _currentSelectedItem),
                                        actions: [
                                          new FlatButton(
                                            child: const Text("Yes"),
                                            onPressed: () {
                                              Navigator.of(context,
                                                      rootNavigator: true)
                                                  .pop('dialog');
                                              _deleteLoggedInEmailIDFromPref();
                                            },
                                          ),
                                          new FlatButton(
                                            child: const Text("No"),
                                            onPressed: () {
                                              Navigator.of(context,
                                                      rootNavigator: true)
                                                  .pop('dialog');
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      child: TextFormField(
                        obscureText: passwordVisible,
                        controller: passwordController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Based on passwordVisible state choose the icon
                              passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: () {
                              // Update the state i.e. toogle the state of passwordVisible variable
                              setState(() {
                                passwordVisible = !passwordVisible;
                              });
                            },
                          ),
                          labelText: 'Password',
                          hintText: "Enter your password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == "") {
                            return "Enter a password";
                          } else {
                            return null;
                          }
                        },
                        onSaved: (val) {},
                      ),
                    ),
                    Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(20),
                        child: SizedBox(
                          height: 60,
                          width: 140,
                          child: RaisedButton(
                            color: Colors.blue,
                            onPressed: () {
                              scaffoldKey.currentState
                                  .showSnackBar(new SnackBar(
                                backgroundColor: Colors.blue,
                                duration: new Duration(seconds: 10),
                                content: new Row(
                                  children: <Widget>[
                                    new CircularProgressIndicator(),
                                    new Text("  Signing-In...")
                                  ],
                                ),
                              ));
                              _submitCommand(emailId);
                            },
                            child: Text(
                              "Next",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        )),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(20),
                      child: FlatButton(
                        onPressed: () {
                          //if emailid exist move to next screen (Password screen)
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyLoginPage1(),
                            ),
                          );
                        },
                        child: Text(
                          "Use another account",
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ))));
  }
   else {

      // Return loading screen while reading preferences
        return Center(child: ClsSplashScreen());
    }
  },
));
}
}
 
