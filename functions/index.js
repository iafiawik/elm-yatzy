// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require("firebase-functions");



// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require("firebase-admin");
admin.initializeApp();

const firestore = admin.firestore();
firestore.settings({ timestampsInSnapshots: true });


const cors = require("cors")({
  origin: true
});

function createScoreBoard() {
  return {
    ones: {
      v: null,
      c: 0
    },
    twos: {
      v: null,
      c: 0
    },
    threes: {
      v: null,
      c: 0
    },
    fives: {
      v: null,
      c: 0
    },
    sixes: {
      v: null,
      c: 0
    },
    one_pair: {
      v: null,
      c: 0
    },
    two_pairs: {
      v: null,
      c: 0
    },
    three_of_a_kind: {
      v: null,
      c: 0
    },
    four_of_a_kind: {
      v: null,
      c: 0
    },
    large_straight: {
      v: null,
      c: 0
    },
    yatzy: {
      v: null,
      c: 0
    }
  };
}
//
function generateGameCode() {
  var text = "";
  var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  for (var i = 0; i < 4; i++)
    text += possible.charAt(Math.floor(Math.random() * possible.length));

  return text.toUpperCase();
}

exports.test = functions
  .region("europe-west2")
  .https.onRequest((req, res) => {
    res.set("Access-Control-Allow-Origin", "*");

    if (req.method === "OPTIONS") {
      // Send response to OPTIONS requests
      res.set("Access-Control-Allow-Methods", "GET");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.set("Access-Control-Max-Age", "3600");
      res.status(204).send("");
    } else {
      res.status(200).send("Hello from test");
    }

    return false;
  });

exports.createNewGame = functions
  .region("europe-west2")
  .https.onRequest((req, res) => {
    res.set("Access-Control-Allow-Origin", "*");

    if (req.method === "OPTIONS") {
      // Send response to OPTIONS requests
      res.set("Access-Control-Allow-Methods", "GET");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.set("Access-Control-Max-Age", "3600");
      res.status(204).send("");
    } else {
      const users = req.body.users;
      admin
        .firestore()
        .collection("games")
        .add({
          code: generateGameCode(),
          dateCreated: new Date().getTime(),
          activeUserIndex: 0,
          users: users.map(user => {
            return {
              userId: user,
              values: createScoreBoard()
            };
          })
        })
        .then(docRef => {
          console.log("Document written with ID: ", docRef.id);

          res.json({ id: docRef.id });

          return false;
        })
        .catch(error => {
          console.error("Error adding document: ", error);

          res.end();
        });
    }
  });

// exports.createNewGame = functions.firestore
//   .document("/games/{gameId}")
//   .onCreate((snapshot, context) => {
//     var gameId = context.params.gameId;
//     const game = snapshot.data();
//
//     console.log("createNewGame(), A new game has been created.");
//
//     const users = game.users.map((user, index) => {
//       let userModel = user;
//       userModel.values = createScoreBoard();
//       userModel.active = user.order === 0;
//
//       return userModel;
//     });
//
//     console.log("createNewGame(), A new game has been created. Users: ", users.length);
//
//     snapshot.ref
//       .set(
//         {
//           users: users
//         },
//         {
//           merge: true
//         }
//       )
//       .then(() => {
//         console.log(
//           "createNewGame(), game updated."
//         );
//
//         return false;
//       })
//       .catch(e => {
//         console.error(
//           "createNewGame(), unable to create a new game.",
//           e
//         );
//       });
//   });
