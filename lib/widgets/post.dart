import 'dart:async';
import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pawsome_world/models/user.dart';
import 'package:pawsome_world/screens/comments.dart';
import 'package:pawsome_world/screens/home.dart';
import 'package:pawsome_world/screens/notifications.dart';
import 'package:pawsome_world/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'image_loading.dart';

class Post extends StatefulWidget {
  final String ownerId;
  final String postId;
  final String username;
  final String mediaUrl;
  final String location;
  final String description;
  final dynamic likes;

  Post({ this.ownerId, this.postId, this.mediaUrl, this.location, this.username, this.description, this.likes, });

  factory Post.fromDocument( DocumentSnapshot doc ){
    return Post(
      ownerId: doc['ownerId'],
      postId: doc['postId'],
      username: doc['username'],
      mediaUrl: doc['mediaUrl'],
      location: doc['location'],
      description: doc['description'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes){
    if(likes == null){
      return 0;
    }
    int count = 0;
    likes.values.forEach((val)  {
      if(val == true){
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState( ownerId: this.ownerId, postId: this.postId, username: this.username, mediaUrl: this.mediaUrl, location: this.location, description: this.description, likes: this.likes, likesCount: getLikeCount(likes));
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String ownerId;
  final String postId;
  final String username;
  final String mediaUrl;
  final String location;
  final String description;
  Map likes;
  int likesCount;
  bool isLiked;
  bool showHeart = false;

  _PostState({ this.ownerId, this.postId, this.mediaUrl, this.location, this.username, this.description, this.likes, this.likesCount});

  handleLikePost(){
    bool _isLiked = likes[currentUserId] == true ;
    if(_isLiked) {
      postsRef.document(ownerId).collection("userPosts").document(postId)
          .updateData({
        'likes.$currentUserId' : false
      });
      removeLikeFromNotifications();
      setState(() {
        likesCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if(!_isLiked) {
      postsRef.document(ownerId).collection("userPosts").document(postId).updateData({
        'likes.$currentUserId' : true
      });
      addLikeToNotifications();
      setState(() {
        likesCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), (){setState(() {
        showHeart = false;
      });});
    }
  }

  removeLikeFromNotifications(){
    bool isPostOwner = ownerId == currentUserId;

    if(!isPostOwner) {
      notificationsRef.document(ownerId).collection("notificationItem").document(postId).get().then((doc) {
        if(doc.exists){
          doc.reference.delete();
        }
      });
    }
  }

  addLikeToNotifications() {
    bool isPostOwner = ownerId == currentUserId;

    if(!isPostOwner){
      notificationsRef.document(ownerId).collection("notificationItem").document(postId).setData({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUserId,
        "userProfileImage": currentUser.photoUrl,
        "timestamp": timestamp,
        "mediaUrl": mediaUrl,
        "postId": postId
      });
    }
  }

  showComments(BuildContext context , { String postId , String ownerId , String mediaUrl }){
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId,
        postOwnerId: ownerId,
        postMediaUrl: mediaUrl
      );
    }));
  }

  buildPostHeader(){
    return FutureBuilder(
        future: usersRef.document(ownerId).get(),
        builder: (context , snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          bool isPostOwner = ownerId == currentUserId;
          User user = User.fromDocument(snapshot.data);
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              backgroundColor: Colors.grey,
            ),
            title: GestureDetector(
              onTap: () => showProfile(context , profileId: user.id),
              child: Text(user.username , style: TextStyle(fontWeight: FontWeight.bold , color: Colors.white , fontSize: 14.0),),
            ),
            subtitle: Text(location, style: TextStyle(color: Colors.grey , fontSize: 12.0),),
            trailing: isPostOwner ? IconButton(icon: Icon(Icons.more_vert , color: Colors.white,), onPressed: ()=> handleDeletePost(context)) : Text(""),
          );
        }
    );
  }

  handleDeletePost(BuildContext parentContext){
    return showDialog(
        context: parentContext,
        builder: (context){
          return SimpleDialog(
            title: Text("Delete the post"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                  },
                child: Text("Delete" , style: TextStyle(
                  color: Color(0xFfed4956),
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0
                ),),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel" , style: TextStyle(color: Colors.black),),
              )
            ],
          );
        }
    );
  }

  deletePost() async{
    //delete post itself
    postsRef.document(ownerId).collection("userPosts").document(postId).get().then((doc) {if(doc.exists) {doc.reference.delete();}});
    //delete uploaded image for the post
    storageRef.child("post_$postId.jpg").delete();
    //delete notifications
    QuerySnapshot notificationsSnapshot = await notificationsRef.document(ownerId).collection("notificationItem").where("postId" , isEqualTo: postId ).getDocuments();
    notificationsSnapshot.documents.forEach((doc) {if(doc.exists){doc.reference.delete();}});
    //delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef.document(postId).collection("comments").getDocuments();
    commentsSnapshot.documents.forEach((doc) { if(doc.exists){doc.reference.delete();}});
  }

  buildPostImage(){
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart ? Animator(
            duration: Duration(milliseconds: 400),
            tween: Tween(begin: 0.6 , end: 5.0),
            curve: Curves.bounceOut,
            cycles: 0,
            builder: (context , anim , child) => Transform.scale(scale: anim.value,
            child: Icon(Icons.favorite, color: Color(0xFfed4956)),),
          ) : Text('')
//          showHeart ? Icon(Icons.favorite , size: 80.0 , color: Color(0xFfed4956),) : Text('')
        ],
      ),
    );
  }

  buildPostFooter(){
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0 , left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border ,
                color: Color(0xFfed4956),),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () =>  showComments(context , postId: postId , ownerId: ownerId , mediaUrl: mediaUrl ),
              child: Icon(Icons.chat , color: Colors.white,),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text('$likesCount likes' , style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: () =>  showComments(context , postId: postId , ownerId: ownerId , mediaUrl: mediaUrl ),
              child: Container(
                margin: EdgeInsets.only(left: 20.0 , top: 5.0),
                child: Text('View all comments' , style: TextStyle(fontWeight: FontWeight.bold),),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0 , top: 5.0),
              child: Text('$username  ' , style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            Expanded(child: Text(description))
          ],
        ),
        SizedBox(height: 10.0,),
        Divider(color: Colors.grey, )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true) ;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );
  }
}
