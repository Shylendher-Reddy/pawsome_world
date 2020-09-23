import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String displayName;
  final String email;
  final String bio;
  final String username;
  final String photoUrl;

  User({this.username , this.photoUrl , this.displayName , this.email , this.id , this.bio});

  factory User.fromDocument(DocumentSnapshot doc){
    return User(
      id: doc['id'],
      email: doc['email'],
      username: doc['username'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      photoUrl: doc['photoUrl']
    );
  }

}