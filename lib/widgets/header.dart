import 'package:flutter/material.dart';

AppBar header({bool isAppTitle, String titleText}) {
  return AppBar(
    backgroundColor: Color(0xFF000000),
    title: Text(
      isAppTitle ? 'Pawsome  World' : titleText,
      style:
          TextStyle(fontFamily: isAppTitle? 'Signatra' : '', fontSize: isAppTitle ? 50.0 : 24.0),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
  );
}
