import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as Im;
import 'package:pawsome_world/models/user.dart';
import 'package:pawsome_world/widgets/progress.dart';
import 'package:uuid/uuid.dart';

import 'home.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController locationTextController = TextEditingController();
  TextEditingController captionTextController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            backgroundColor: Color(0xFF262626),
            title: Text(
              'Upload Image',
              style: TextStyle(color: Colors.grey),
            ),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: handleTakePhoto,
                child: Padding(
                  padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                  child: Text(
                    'Upload with camera',
                    style: TextStyle(color: Color(0xFFF9FAF9), fontSize: 18.0),
                  ),
                ),
              ),
              SimpleDialogOption(
                  onPressed: handleChooseFromGallery,
                  child: Padding(
                    padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: Text(
                      'Choose from gallery',
                      style:
                          TextStyle(color: Color(0xFFF9FAF9), fontSize: 18.0),
                    ),
                  )),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 18.0),
                ),
              )
            ],
          );
        });
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async{
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(imageFile , quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  uploadImage(imageFile) async{
    StorageUploadTask uploadTask = storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFireStore({String mediaUrl , String description , String location}){
    postsRef.document(widget.currentUser.id).collection("userPosts").document(postId).setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {}
    });
  }

  handleShare() async{
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFireStore( mediaUrl: mediaUrl , location: locationTextController.text , description: captionTextController.text );
    captionTextController.clear();
    locationTextController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  Container buildUploadScreen() {
    return Container(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
//          Icon(
//            Icons.pets,
//            size: 150.0,
//            color: Colors.grey,
//          ),
              Container(
                child: Image(image: AssetImage('assets/images/upload.png')),
              ),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: RaisedButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                onPressed: () => selectImage(context),
                color: Color(0xFF262626),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text('Upload Image',
                      style: TextStyle(color: Colors.white, fontSize: 20.0)),
                )),
          )
        ]));
  }

  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF262626),
        leading:
            IconButton(icon: Icon(Icons.arrow_back), onPressed: clearImage),
        title: Text(
          'New Post',
          style: TextStyle(fontFamily: 'Signatra', fontSize: 28),
        ),
        actions: [
          FlatButton(
              onPressed: isUploading ? null : () => handleShare(),
              child: Text(
                'Share',
                style: TextStyle(color: Color(0xFF0194F5), fontSize: 14.0 ),
              ))
        ],
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(''),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: FileImage(file), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
          ListTile(
//            leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(widget.currentUser.photoUrl),),
            title: Container(
              child: TextFormField(
                controller: captionTextController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFF262626),
                    hintText: 'Write a caption... (optional)',
                    hintStyle: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          SizedBox(
            height: 5.0,
          ),
          ListTile(
            title: Container(
              child: TextFormField(
                controller: locationTextController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFF262626),
                    hintText: 'Add Location... (optional)',
                    hintStyle: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          RaisedButton(
              onPressed: getUserLocation,
              color: Color(0xFF000000),
              child: Text('Get Location', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 20.0),),)
        ],
      ),
    );
  }

  getUserLocation() async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String address = '${placemark.locality}, ${placemark.country}';
    locationTextController.text = address;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildUploadScreen() : buildUploadForm();
  }
}
