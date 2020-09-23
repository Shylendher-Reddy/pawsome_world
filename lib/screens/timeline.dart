import 'package:flutter/material.dart';
import 'package:pawsome_world/models/user.dart';
import 'package:pawsome_world/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsome_world/screens/search.dart';
import 'package:pawsome_world/widgets/header.dart';
import 'package:pawsome_world/widgets/post.dart';
import 'package:pawsome_world/widgets/progress.dart';


class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async{
    QuerySnapshot snapshot = await timelineRef.document(widget.currentUser.id).collection("timelinePosts").orderBy("timestamp" , descending: true).getDocuments();
    List<Post> posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async{
    QuerySnapshot snapshot = await followingRef.document(currentUser.id).collection("following").getDocuments();
    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  buildUsersToFollow(){
    return StreamBuilder(
        stream: usersRef.orderBy('timestamp' , descending: true).limit(30).snapshots(),
        builder: (context , snapshot) {
          if(!snapshot.hasData){
            return circularProgress();
          }
          List<UserResult> userResults = [];
          snapshot.data.documents.forEach((doc){
            User user = User.fromDocument(doc);
            final bool isAuth = currentUser.id == user.id;
            final bool isFollowing = followingList.contains(user.id);
            if(isAuth){
              return;
            } else if(isFollowing) {
              return ;
            } else {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          });
          return Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(child: Text("User Suggestions" , style: TextStyle(fontSize: 22.0 , fontStyle: FontStyle.italic),)),
                ),
                Column(children: userResults,)
              ],
            ),
          );
        }
    );
  }

  buildTimeline(){
    if(posts == null) {
      return circularProgress();
    } else if(posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(children: posts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: header(isAppTitle: true),
      body: RefreshIndicator(
          onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
