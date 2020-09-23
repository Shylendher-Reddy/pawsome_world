import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pawsome_world/models/user.dart';
import 'package:pawsome_world/screens/profile.dart';
import 'package:pawsome_world/screens/search.dart';
import 'package:pawsome_world/screens/timeline.dart';
import 'package:pawsome_world/screens/upload.dart';
import 'createAccount.dart';
import 'notifications.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection("posts");
final notificationsRef = Firestore.instance.collection("notifications");
final commentsRef = Firestore.instance.collection("comments");
final followersRef = Firestore.instance.collection("followers");
final followingRef = Firestore.instance.collection("following");
final timelineRef = Firestore.instance.collection("timeline");
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();

    pageController = PageController();

    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account){
      handleSignIn(account);
    });
  }

  handleSignIn(GoogleSignInAccount account)async{
    if (account != null) {
      await createUserInFireStore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications(){
    final GoogleSignInAccount user = googleSignIn.currentUser;

    if(Platform.isIOS) getIOSPermission();

    _firebaseMessaging.getToken().then((token) => usersRef.document(user.id).updateData({"androidNotificationToken" : token}) );
    _firebaseMessaging.configure(onMessage: (Map<String , dynamic> message) async{
      final String recipientId = message['data']['recipient'];
      final String body = message['notification']['body'];
      if(recipientId == user.id) {
        SnackBar snackBar = SnackBar(content: Text(body , overflow: TextOverflow.ellipsis,));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    });
  }

  getIOSPermission(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true , badge: true , sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {  });
  }

  createUserInFireStore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      usersRef.document(user.id).setData({
        "id": user.id,
        "email": user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        "username": username,
        'bio': '',
        'timestamp': timestamp
      });

      await followersRef.document(user.id).collection("followers").document(user.id).setData({});

      doc = await usersRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  handleLogIn() {
    googleSignIn.signIn();
  }

  pageChange(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTapPageChange(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        controller: pageController,
        children: <Widget>[
          Timeline(currentUser: currentUser,),
          Search(),
          Upload(currentUser: currentUser),
          Notifications(),
          Profile(profileId : currentUser?.id)
        ],
        onPageChanged: pageChange,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: Color(0xFF000000),
        activeColor: Color(0xFF0194F5),
        inactiveColor: Color(0xFFF9FAF9),
        currentIndex: pageIndex,
        onTap: onTapPageChange,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle))
        ],
      ),
    );
  }

  Scaffold unAuthScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to the world of PETS..!!',
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 34.0,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: handleLogIn,
              child: Container(
                height: 60,
                width: 260,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.0),
                    image: DecorationImage(
                        image: AssetImage(
                            'assets/images/google_signin_button.png'),
                        fit: BoxFit.cover)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : unAuthScreen();
  }
}
