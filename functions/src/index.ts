import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

exports.notifyUsersOnNewNews = functions.firestore
  .document("news/{newsId}")
  .onCreate(async (snapshot: functions.firestore.DocumentSnapshot) => {
    const newsData = snapshot.data();
    if (!newsData) return null; // Exit if data is not found

    const category = newsData.category;

    // Fetch users interested in the news category
    const usersSnapshot = await admin.firestore().collection("users")
      .where("interest", "array-contains", category)
      .get();

    const tokens: string[] = [];
    usersSnapshot.forEach((user) => {
      if (user.data().fcmToken) {
        tokens.push(user.data().fcmToken);
      }
    });

    if (tokens.length === 0) return null;

    // Send notifications to the fetched users
    const message = {
      notification: {
        title: `New News in ${category}`,
        body: `Check out the latest news in ${category}!`,
      },
      tokens: tokens,
    };

    return admin.messaging().sendMulticast(message);
  });
