import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pawsome_world/models/user.dart';
import 'package:pawsome_world/screens/notifications.dart';
import 'package:pawsome_world/widgets/progress.dart';

import 'home.dart';


class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController textEditingController = TextEditingController();
  Future<QuerySnapshot> futureSearchResults;

  handleSearch(String query) {
    Future<QuerySnapshot> users = usersRef
        .where('displayName', isGreaterThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      futureSearchResults = users;
    });
  }

  Container buildNoContentScreen() {
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
//            Icon(
//              Icons.pets,
//              color: Colors.grey,
//              size: 150,
//            ),
          Container(
            child: Image(image: AssetImage('assets/images/cats_search.jpg')),
          ),

            Center(
                child: Text(
              'Search Pets...',
              style: TextStyle(
                  fontSize: 30.0,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ))
          ],
        ),
      ),
    );
  }

  buildSearchResultsScreen() {
    return FutureBuilder(
        future: futureSearchResults,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> searchResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            UserResult userResult = UserResult(user);
            searchResults.add(userResult);
          });
          return ListView(
            children: searchResults,
          );
        });
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF000000),
        title: TextFormField(
          onFieldSubmitted: handleSearch,
          controller: textEditingController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10.0)),
              filled: true,
              fillColor: Color(0xFF262626),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey,
              ),
              hintText: 'Search',
              hintStyle: TextStyle(color: Colors.grey),
              suffixIcon: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    textEditingController.clear();
                  })),
        ),
      ),
      body: futureSearchResults == null
          ? buildNoContentScreen()
          : buildSearchResultsScreen(),
    );
  }
}

class UserResult extends StatelessWidget {
  final user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context , profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                    color: Color(0xFFF9FAF9), fontWeight: FontWeight.w600),
              ),
              subtitle: Text(user.username,
                  style: TextStyle(color: Color(0xFFF9FAF9))),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.grey,
          )
        ],
      ),
    );
  }
}
