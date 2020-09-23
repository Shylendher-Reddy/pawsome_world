import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pawsome_world/models/user.dart';
import 'package:pawsome_world/widgets/header.dart';
import 'package:pawsome_world/widgets/post.dart';
import 'package:pawsome_world/widgets/post_tile.dart';
import 'package:pawsome_world/widgets/progress.dart';

import 'editProfile.dart';
import 'home.dart';


class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserName = currentUser?.username;
  final String currentUserId = currentUser?.id;
  bool isFollowing = false;
  bool isLoading = false;
  String viewType = "grid";
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    getIsFollowing();
  }

  getIsFollowing() async{
    DocumentSnapshot documentSnapshot = await followersRef.document(widget.profileId).collection("followers").document(currentUserId).get();
    setState(() {
      isFollowing = documentSnapshot.exists;
    });
  }

  getFollowers() async{
    QuerySnapshot snapshot = await followersRef.document(widget.profileId).collection("followers").getDocuments();
    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  getFollowing() async{
    QuerySnapshot snapshot = await followingRef.document(widget.profileId).collection("following").getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection("userPosts")
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 10.0 , bottom: 5.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          alignment: Alignment.center,
          height: 30.0,
          width: 300.0,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: isFollowing ? Colors.grey : Color(0xFF0194F5)),
              color: isFollowing ? Colors.black : Color(0xFF0194F5)),
          child: Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditProfile(currentUserId: currentUserId))).then((value) {
      setState(() {});
    });
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;

    if (isProfileOwner) {
      return buildButton(text: 'Edit Profile', function: editProfile);
    } else if(isFollowing) {
      return buildButton(text: 'Unfollow' , function: handleUnfollow);
    } else if(!isFollowing) {
      return buildButton(text: "Follow" , function: handleFollow);
    }
  }

  handleUnfollow(){
    setState(() {isFollowing = false;});
    followersRef.document(widget.profileId).collection("followers").document(currentUserId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    followingRef.document(currentUserId).collection("following").document(widget.profileId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    notificationsRef.document(widget.profileId).collection("notificationItem").document(currentUserId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
  }

  handleFollow(){
    setState(() {isFollowing = true;});
      followersRef.document(widget.profileId).collection("followers").document(currentUserId).setData({});
      followingRef.document(currentUserId).collection("following").document(widget.profileId).setData({});
      notificationsRef.document(widget.profileId).collection("notificationItem").document(currentUserId).setData({
        "type": "follow",
        "ownerId": widget.profileId,
        "userId": currentUserId,
        "timestamp": timestamp,
        "username": currentUserName,
        "userProfileImage": currentUser.photoUrl
      });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
          ),
        )
      ],
    );
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Container(
          color: Color(0xFF121212),
          child: Padding(
            padding: EdgeInsets.only(left: 10.0, right: 10.0 , top: 10.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    Expanded(
                        child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("Posts", postCount),
                            buildCountColumn("Followers", followersCount),
                            buildCountColumn("Following", followingCount)
                          ],
                        )
                      ],
                    ))
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 12.0),
                  alignment: Alignment.topLeft,
                  child: Text(
                    user.displayName,
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4.0),
                  alignment: Alignment.topLeft,
                  child: Text(
                    user.username,
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 13.0),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 6.0),
                  alignment: Alignment.topLeft,
                  child: Text(
                    user.bio,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[buildProfileButton()],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.pets , color: Colors.grey,size: 150.0,),
            Text("No posts yet" , style: TextStyle(color: Colors.grey , fontStyle: FontStyle.italic , fontSize: 24.0),)
          ],
        )
      );
    } else if (viewType == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (viewType == "list") {
      return Column(
        children: posts,
      );
    }
  }

  setViewToggle(String viewType){
    setState(() {
      this.viewType = viewType;
    });
  }

  buildToggleView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Container(
            color: viewType == "grid" ? Colors.black : Color(0xFF121212),
            child: IconButton(
                icon: Icon(
                  Icons.grid_on,
                  color: viewType == "grid" ? Colors.white : Colors.grey,
                ),
                onPressed: () => setViewToggle("grid")),
          ),
        ),
        Expanded(
          child: Container(
            color: viewType == "list" ? Colors.black : Color(0xFF121212),
            child: IconButton(
                icon: Icon(
                  Icons.format_list_bulleted,
                  color: viewType == "list" ? Colors.white : Colors.grey,
                ),
                onPressed: () => setViewToggle("list")),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(isAppTitle: false, titleText: "Profile"),
//      appBar: AppBar(
//          backgroundColor: Color(0xFF121212),
//          title: Text(
//            currentUserName,
//            style: TextStyle(
//                fontSize: 22.0, fontFamily: "Signatra", letterSpacing: 2.0),
//          ),
//          centerTitle: true),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          buildToggleView(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts()
        ],
      ),
    );
  }
}
