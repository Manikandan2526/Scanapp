import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';//package to save session values
import 'common/splash.dart'; //File under lib/splash.dart
import 'login/loginPages.dart';
import 'screens/awb.dart';

SharedPreferences prefs;

void main() {     
  runApp(Login());
}


Future<String> checkEmailIdExistInPref() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  try {
  
    if (prefs.getString("LoginId") != null) {     
      return "HomePage";
    } else {
      if (prefs.getStringList("loggedInEmailIds") != null) {
     
        if (prefs.getStringList("loggedInEmailIds").length <= 0) {
          return "LoginPage1";
        } else {       
          return "LoginPage2";
        }
      } else {
        return "LoginPage1";
      }
    }
  } catch (ex) {}
  return null;
}


class Login extends StatelessWidget{
 @override
  Widget build(BuildContext context) {
    return MaterialApp(home: FutureBuilder<String>(
     future: checkEmailIdExistInPref(),
     builder: (buildContext, snapshot) {
       if(snapshot.hasData) {
          if(snapshot.data=="HomePage"){
            // if login id exist then redirect to home screen
          return HomePage();
          }
          else if(snapshot.data=="LoginPage2"){
            //if logged in emailid exist then load login page2
          return MyLoginPage2();
          }
        // Return your home here if pref not exist
          return MyLoginPage1();
    } else {

      // Return loading screen while reading preferences
      return Center(child: ClsSplashScreen());
    }
  },
));
}
}






     