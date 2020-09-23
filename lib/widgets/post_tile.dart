import 'package:flutter/material.dart';
import 'package:pawsome_world/screens/post_screen.dart';
import 'package:pawsome_world/widgets/post.dart';

import 'image_loading.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);

  showPost(context){
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
        PostScreen(postId: post.postId , userId: post.ownerId,)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
