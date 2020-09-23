import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pawsome_world/screens/home.dart';
import 'package:pawsome_world/screens/post_screen.dart';
import 'package:pawsome_world/screens/profile.dart';
import 'package:pawsome_world/widgets/header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsome_world/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class Notifications extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {

  getNotifications() async{
    QuerySnapshot snapshot =  await notificationsRef.document(currentUser.id)
        .collection("notificationItem").orderBy("timestamp" , descending: true)
        .limit(50).getDocuments();
    List<NotificationItem> notificationItems = [];
    snapshot.documents.forEach((doc) {
      notificationItems.add(NotificationItem.fromDocument(doc));
    });
    return notificationItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(isAppTitle: false , titleText: 'Notifications'),
      body: FutureBuilder(
          future: getNotifications(),
        builder: (context , snapshot){
            if(!snapshot.hasData){
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
        },
      )
    );
  }
}

Widget mediaPreview;
String notificationItemText;

class NotificationItem extends StatelessWidget {
  final String postId;
  final String userId;
  final String type;
  final String commentData;
  final String userProfileImage;
  final String username;
  final String mediaUrl;
  final Timestamp timestamp;

  NotificationItem({this.postId , this.mediaUrl , this.timestamp , this.username , this.commentData , this.type, this.userId , this.userProfileImage});

  factory NotificationItem.fromDocument(DocumentSnapshot doc){
    return NotificationItem(
      username: doc["username"],
      postId: doc["postId"],
      type: doc["type"],
      commentData: doc["commentData"],
      userProfileImage: doc["userProfileImage"],
      userId: doc["userId"],
      mediaUrl: doc["mediaUrl"],
      timestamp: doc["timestamp"],
    );
  }
  
  showPost(context){
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
      PostScreen(postId: postId , userId: userId,)
    ));
  }

  configureMediaPreview(context){
    if(type == "like" || type == "comment"){
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(aspectRatio: 16 / 9 , child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: CachedNetworkImageProvider(mediaUrl)
              )
            ),
          ),),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if(type == "like"){
      notificationItemText = 'liked your post';
    } else if(type == "comment"){
      notificationItemText = "commented on your post";
    } else if(type == "follow"){
      notificationItemText = "is following you";
    } else {
      notificationItemText = "error";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Container(
      child: ListTile(
        title: GestureDetector(
          onTap: () => showProfile(context , profileId: userId),
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                color: Colors.white
              ),
              children: [
                TextSpan(
                  text: username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  )
                ),
                TextSpan(
                  text: ' $notificationItemText',
                )
              ]
            ),

          ),
        ),
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(userProfileImage),
        ),
        subtitle: Text(timeago.format(timestamp.toDate()) , overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.grey),),
        trailing: mediaPreview,
      ),
    );
  }
}

showProfile(BuildContext context , {String profileId} ){
  Navigator.push(context, MaterialPageRoute(builder: (context) => Profile(profileId: profileId,)));
}