import 'package:flutter/material.dart';
import 'package:pawsome_world/screens/home.dart';
import 'package:pawsome_world/widgets/header.dart';
import 'package:pawsome_world/widgets/post.dart';
import 'package:pawsome_world/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String postId;
  final String userId;

  PostScreen({this.userId , this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: postsRef.document(userId)
            .collection("userPosts").document(postId).get(),
        builder: (context , snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          Post post = Post.fromDocument(snapshot.data);
          return Center(
            child: Scaffold(
              appBar: header(isAppTitle: false, titleText: post.description.length != 0 ? post.description : "Post"),
              body: ListView(
                children: <Widget>[
                  Container(
                    child: post,
                  )
                ],
              ),
            ),
          );
        },
      );

  }
}
