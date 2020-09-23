import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pawsome_world/models/user.dart';
import 'package:pawsome_world/widgets/progress.dart';

import 'home.dart';


class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>() ;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _bioValid = true;
  bool _displayNameValid = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column displayProfileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            'Display Name',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: TextField(
            style: TextStyle(color: Colors.white),
            controller: displayNameController,
            decoration: InputDecoration(
              errorText: _displayNameValid ? null : "Display name must be between 3 to 20 characters",
              filled: true,
              fillColor: Color(0xFF121212),
              hintText: 'Update display name',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none),
            ),
          ),
        )
      ],
    );
  }

  Column displayBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            'Bio',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: TextField(
            style: TextStyle(color: Colors.white),
            controller: bioController,
            decoration: InputDecoration(
              errorText: _bioValid ? null : "Bio must be between 3 to 70 characters",
              filled: true,
              fillColor: Color(0xFF121212),
              hintText: 'Update bio',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none),
            ),
          ),
        )
      ],
    );
  }

  updateProfile(){
    setState(() {
      displayNameController.text.trim().length < 3 || displayNameController.text.trim().length > 20  || displayNameController.text.isEmpty ?
          _displayNameValid = false : _displayNameValid = true;
      bioController.text.trim().length < 3 || bioController.text.trim().length > 75 || bioController.text.isEmpty ?
          _bioValid = false : _bioValid = true;
    });
    if( _displayNameValid && _bioValid ) {
      usersRef.document(widget.currentUserId).updateData({
        "displayName": displayNameController.text,
        "bio": bioController.text
      });
      SnackBar snackBar = SnackBar(content: Text('Profile updated ..!!'),);
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 1), (){Navigator.pop(context);});
    }
  }

  logout() async{
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Color(0xFF121212),
        centerTitle: true,
        title: Text('Edit Profile'),
//        actions: <Widget>[
//          IconButton(
//              icon: Icon(Icons.done, color: Color(0xFF34a0fe)),
//              onPressed: () => Navigator.pop(context))
//        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                    child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircleAvatar(
                        radius: 60.0,
                        backgroundImage:
                            CachedNetworkImageProvider(user.photoUrl),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        children: <Widget>[
                          displayProfileField(),
                          displayBioField()
                        ],
                      ),
                    ),
                    FlatButton(
                      onPressed: updateProfile,
                      child: Container(
                        alignment: Alignment.center,
                        height: 28.0,
                        width: 200.0,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(color: Colors.black),
                            color: Color(0xFF0095f6)),
                        child: Text(
                          'Update profile',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14.0),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(5.0),
                      child: FlatButton.icon(
                        onPressed: logout,
                        icon: Icon(
                          Icons.power_settings_new,
                          color: Colors.red,
                        ),
                        label: Text(
                          'Log out',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ))
              ],
            ),
    );
  }
}
