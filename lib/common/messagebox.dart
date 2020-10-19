import 'package:flutter/material.dart';

  showMessage(message,BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Message!"),
        content: Text(message.toString()),
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