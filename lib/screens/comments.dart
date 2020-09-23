import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pawsome_world/widgets/header.dart';
import 'package:pawsome_world/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'home.dart';

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({this.postId , this.postMediaUrl , this.postOwnerId});

  @override
  _CommentsState createState() => _CommentsState(
      postId: this.postId , postMediaUrl: this.postMediaUrl , postOwnerId: this.postOwnerId
  );
}

class _CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  _CommentsState({this.postId , this.postMediaUrl , this.postOwnerId});

  buildComments(){
    return StreamBuilder(
        stream: commentsRef.document(postId).collection("comments").orderBy("timestamp",descending: false).snapshots(),
        builder: (context , snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.documents.forEach((doc){
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        }
    );
  }

  addComment(){
    commentsRef.document(postId).collection("comments").add({
      "username": currentUser.username,
      "userId": currentUser.id,
      "comment": commentController.text,
      "timestamp": timestamp,
      "avatarUrl": currentUser.photoUrl,
    });
    bool isPostOwner = postOwnerId == currentUser.id ;
    if(!isPostOwner){
      notificationsRef.document(postOwnerId).collection("notificationItem").add({
        "type": "comment",
        "commentData": commentController.text,
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImage": currentUser.photoUrl,
        "timestamp": timestamp,
        "mediaUrl": postMediaUrl,
        "postId": postId
      });
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(isAppTitle: false , titleText: 'Comments'),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(color: Colors.grey,height: 0.0),
          Container(
            height: 60.0,
            child: ListTile(
              title: TextField(
                style: TextStyle(color: Colors.white),
                controller: commentController,
                decoration: InputDecoration(hintText: 'Add a comment...', hintStyle: TextStyle(color: Colors.grey) , border: OutlineInputBorder(borderSide: BorderSide.none)),
              ),
              trailing: OutlineButton(onPressed: addComment , borderSide: BorderSide.none ,child: Text('Submit' , style: TextStyle(color: Color(0xFF0194F5)),),),
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String userId;
  final String username;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({this.timestamp , this.username , this.avatarUrl , this.comment , this.userId});

  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(
      username: doc["username"],
      userId: doc["userId"],
      avatarUrl: doc["avatarUrl"],
      comment: doc["comment"],
      timestamp: doc["timestamp"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(username , style: TextStyle(color: Colors.white , fontWeight: FontWeight.bold)),
          subtitle: Text(comment , style: TextStyle(color: Colors.white)),
          leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(avatarUrl),),
          trailing: Text(timeago.format(timestamp.toDate()) , style: TextStyle(color: Colors.grey , fontSize: 12.0)),
        ),
        Divider(height: 0.0,color: Colors.grey,)
      ],
    );
  }
}
