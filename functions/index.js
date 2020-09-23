const functions = require('firebase-functions');
const admin = require("firebase-admin");
admin.initializeApp();


exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/followers/{followerId}")
    .onCreate(async (snapshot , context) => {
        const userId = context.params.userId;
        const followerId = context.params.followerId;

     //1) create followed user post ref
     const followedUserPostsRef = admin.firestore()
                                    .collection("posts")
                                    .doc(userId)
                                    .collection("userPosts");

     // 2) create following user timeline ref
     const timelinePostsRef = admin.firestore()
                                    .collection("timeline")
                                    .doc(followerId)
                                    .collection("timelinePosts");

     //3) get followed user posts
     const querySnapshot = await followedUserPostsRef.get();

     //4) add each user post to following user timeline
     querySnapshot.forEach(doc => {
        if(doc.exists){
            const postId = doc.id;
            const postData = doc.data();
            timelinePostsRef.doc(postId).set(postData);
         }
     })

    });


exports.onDeleteFollower = functions.firestore
     .document("/followers/{userId}/followers/{followerId}")
     .onDelete( async(snapshot , context) => {
           const userId = context.params.userId;
           const followerId = context.params.followerId;

           const timelinePostsRef = admin
               .firestore()
               .collection("timeline")
               .doc(followerId)
               .collection("timelinePosts")
               .where("ownerId" , "==" , userId );

           const querySnapshot = await timelinePostsRef.get();
           querySnapshot.forEach(doc => {
               if(doc.exists){
                  doc.ref.delete();
                   }
                });
   });


exports.onCreatePost = functions.firestore
        .document('/posts/{userId}/userPosts/{postId}')
        .onCreate(async (snapshot , context) => {
            const postCreated = snapshot.data();
            const userId = context.params.userId;
            const postId = context.params.postId;

            //get all the followers of the user
            const userFollowersRef = admin.firestore()
                        .collection("followers")
                        .doc(userId)
                        .collection("followers") ;
            const querySnapshot = await userFollowersRef.get();

            //add new post to each follower timeline
            querySnapshot.forEach((doc) => {
                   const followerId = doc.id ;
                    admin.firestore()
                        .collection("timeline")
                        .doc(followerId)
                        .collection("timelinePosts")
                        .doc(postId)
                        .set(postCreated);
            });
        });

exports.onUpdatePost = functions.firestore
            .document("/posts/{userId}/userPosts/{postId}")
            .onUpdate(async (change , context) => {
                const updatedPost = change.after.data();
                const userId = context.params.userId;
                const postId = context.params.postId;

               //get all the followers of the user
               const userFollowersRef = admin.firestore()
                       .collection("followers")
                       .doc(userId)
                       .collection("followers") ;
               const querySnapshot = await userFollowersRef.get();

               //add updated post to each follower timeline
               querySnapshot.forEach((doc) => {
                   const followerId = doc.id ;
                    admin.firestore()
                          .collection("timeline")
                          .doc(followerId)
                          .collection("timelinePosts")
                          .doc(postId)
                          .get().then(doc => {
                               if(doc.exists){
                                    doc.ref.update(updatedPost);
                               }
                          });
                });
      });


 exports.onDeletePost = functions.firestore
                .document("/posts/{userId}/userPosts/{postId}")
                .onDelete(async (snapshot , context) => {
                    const userId = context.params.userId;
                    const postId = context.params.postId;

                    //get all the followers of the user
                    const userFollowersRef = admin.firestore()
                            .collection("followers")
                            .doc(userId)
                            .collection("followers") ;
                    const querySnapshot = await userFollowersRef.get();

                    //delete post to each follower timeline
                    querySnapshot.forEach((doc) => {
                         const followerId = doc.id ;
                         admin.firestore()
                               .collection("timeline")
                               .doc(followerId)
                               .collection("timelinePosts")
                               .doc(postId)
                                .get().then(doc => {
                                    if(doc.exists){
                                        doc.ref.delete();
                                     }
                                });
                    });
                })


 exports.onCreateNotificationItem = functions.firestore.
                                                document('/notifications/{userId}/notificationItem/{notificationItem}')
                                                .onCreate(async(context , snapshot) => {

                                                //Get user connected to notification
                                                const userId = context.params.userId ;
                                                const userRef = admin.firestore().doc(`users/${userId}`);
                                                const doc = await userRef.get();

                                                //Once we have user, check whether they have a notification token , send notification if they have a token
                                                const androidNotificationToken = doc.data().androidNotificationToken ;
                                                if(androidNotificationToken) {
                                                    sendNotification(androidNotificationToken , snapshot.data());
                                                 } else {
                                                    console.log('no token found , notification not sent')
                                                 }

                                                 function sendNotification(androidNotificationToken , notificationItem) {
                                                    let body;
                                                    switch(notificationItem.type){
                                                        case "comment":
                                                            body = `${notificationItem.username} commented: ${notificationItem.commentData}`;
                                                        break;
                                                        case "like":
                                                            body = `${notificationItem.username} liked your post`;
                                                        break;
                                                        case "follow":
                                                            body = `${notificationItem.username} started following you`;
                                                        break;
                                                        default:
                                                        break;
                                                    }
                                                   //Create message for push notification
                                                   const message = {
                                                        notification : {body},
                                                        token: androidNotificationToken,
                                                        data: {recipient: userId}
                                                    };
                                                   //Send message with admin.messaging()
                                                   admin
                                                    .messaging()
                                                    .send(message)
                                                    .then(response => {
                                                        console.log('message sent successfully' , response);
                                                    })
                                                    .catch(error => {
                                                        console.log('Error sending message' , error);
                                                    });
                                                  }
                                                })

























