import 'package:splashscreen/splashscreen.dart'; //Starting loading page
import 'package:flutter/material.dart';


class ClsSplashScreen extends StatefulWidget {
  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<ClsSplashScreen> {
  @override
  Widget build(BuildContext context) {    
    return new Scaffold(
      body: new Center(            
      child:new SplashScreen(      
      seconds: 25,            
      title: new Text('Scan App',
      style: new TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 30.0,
        color: Colors.blue,
      ),),
      image: new Image.asset("assets/images/Applogo.png"),
      backgroundColor: Colors.white,
      styleTextUnderTheLoader: new TextStyle(),
      loaderColor: Colors.blue,
      photoSize: 50.0,           
    )));
  }
}