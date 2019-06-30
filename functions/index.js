// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

function calculateTotalScore (values) {
  const reducer = (accumulator, currentValue) => accumulator + currentValue.value;

  var upperSum = values.filter((value) => {
    if (value.boxId === "ones" || value.boxId === "twos" || value.boxId === "threes" || value.boxId === "fours" || value.boxId === "fives" || value.boxId ==="sixes") {
      return true;
    }
    else {
      return false;
    }
  }).reduce(reducer, 0);

  var bonusSum = 0;

  if (upperSum >= 63) {
    bonusSum = 50;
  }

  return (values.reduce(reducer, 0)) + bonusSum;
}

exports.calulateUserScores = functions.firestore.document('/games/{gameId}')
  .onUpdate((change, context) => {
    var gameId = context.params.gameId;
    console.error("Game " + gameId + " has been updated, trying to calculate user scores");
    // Get an object representing the current document
    const newGame = change.after.data();
    const game = newGame;

    // ...or the previous value before this update
    const oldGame = change.before.data();

    var valuesPromise = new Promise((resolve, reject) => {
      admin.firestore().collection("values").where("gameId", "==", gameId).get().then((snapshot) => {
         var values = snapshot.docs.map(value => {
          return value.data();
        });
        return resolve(values);
      })      .catch((e)=>{
              console.error("Unable to calculate scores for users.", e)
              return reject(new Error(e))
            })
      });

    var usersPromise = new Promise((resolve, reject) => {
      admin.firestore().collection("users").get().then((snapshot) => {
         var users = snapshot.docs.map(dbUser => {
           var user = dbUser.data();
           user.id = dbUser.id;
          return user;
        });

        return resolve(users);
      })
      .catch((e)=>{
          console.error("Unable to calculate scores for users.", e)
          return reject(new Error(e))
        })
      });

    const highscoreRef = admin.firestore().collection("global").doc("highscore");
    var highscorePromise = new Promise((resolve, reject) => {
        highscoreRef.get("list").then((snapshot) => {
          return resolve(snapshot.data().list);
      })
      .catch((e) => {
        console.error("Unable to calculate scores for users.", e)
        return reject(new Error(e))
      })
    });

    return new Promise((resolve, reject) => {
       Promise.all([valuesPromise, usersPromise,highscorePromise]).then((allValues) => {
        const values = allValues[0];
        const allUsers = allValues[1];
        const highscoreList = allValues[2];

        if (!game.finished || game.counted) {
          return resolve();
        }

        var users = game.users;

        users.forEach((user) => {
          user.score = calculateTotalScore(values.filter((value) => value.userId === user.userId));
        });

        var usersInThisGame = users.map((user)=>{
          var dbUser = allUsers.find((dbUser)=>dbUser.id === user.userId);

          if (!dbUser) {
            return reject(new Error("Unable to find user with ID " + user.userId));
          }

          return { user: dbUser, score: user.score, gameId: gameId, date: game.dateCreated};
        });

        var potentialHighscoreList = highscoreList ? highscoreList.concat(usersInThisGame) : usersInThisGame;

        potentialHighscoreList.sort((a, b) => b.score - a.score);

        var uniqueList = potentialHighscoreList.filter((highscoreEntry, index, self) =>
          index === self.findIndex((h) => (
            h.user.id === highscoreEntry.user.id && h.gameId === highscoreEntry.gameId
          ))
        );

        var lastOrder = 0;
        var lastScore = 0;

        var sortedList = uniqueList.map((user,index)=> {
          var dbUser = allUsers.find((dbUser)=>dbUser.id === user.user.id);

          if (!dbUser) {
            return reject(new Error("Unable to find user with ID " + user.id));
          }

          var currentOrder = 0;
          if (user.score === lastScore) {
            currentOrder = lastOrder;
          }
          else {
            currentOrder = (index)
          }

          lastOrder = currentOrder;
          lastScore = user.score;

          var sorted = user;
          sorted.order = currentOrder;
          sorted.user = dbUser;
          return sorted;
        });

        highscoreRef.set({
          list: uniqueList
        });

        return resolve(
          change.after.ref.set({
            counted: true,
            users: users
          }, { merge: true }));
      }).catch((e)=>{
        return reject(e);
      })
    });
});