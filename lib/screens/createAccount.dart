import 'dart:async';

import 'package:flutter/material.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  String username;
  submit() {
    final form = _formKey.currentState;
    if(form.validate()){
      form.save();
      SnackBar snackbar = SnackBar(content: Text('Welcome $username'),);
      _scaffoldKey.currentState.showSnackBar(snackbar);
      Timer(Duration(seconds: 2), (){Navigator.pop(context, username);});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Create username',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    child: Form(
                      autovalidate: true,
                      key: _formKey,
                      child: TextFormField(
                        validator: (val){
                          if(val.trim().length < 5 || val.isEmpty){
                            return 'Username too short';
                          } else if(val.trim().length > 16){
                            return 'Username too long';
                          } else {
                            return null;
                          }
                        },
                        style: TextStyle(color: Colors.white),
                        onSaved: (val) => username = val,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF121212),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          labelText: 'User Name',
                          labelStyle: TextStyle(color: Colors.white),
                          hintText: 'Must be atleast 5 characters',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 32.0,
                    width: 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Color(0xFF0194F5)),
                    child: Center(
                        child: Text(
                      'Submit',
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    )),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
