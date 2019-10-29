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
      v: -1,
      c: 0
    },
    twos: {
      v: -1,
      c: 0
    },
    threes: {
      v: -1,
      c: 0
    },
    fours: {
      v: -1,
      c: 0
    },
    fives: {
      v: -1,
      c: 0
    },
    sixes: {
      v: -1,
      c: 0
    },
    one_pair: {
      v: -1,
      c: 0
    },
    two_pairs: {
      v: -1,
      c: 0
    },
    three_of_a_kind: {
      v: -1,
      c: 0
    },
    four_of_a_kind: {
      v: -1,
      c: 0
    },
    small_straight: {
      v: -1,
      c: 0
    },
    large_straight: {
      v: -1,
      c: 0
    },
    full_house: {
      v: -1,
      c: 0
    },
    chance: {
      v: -1,
      c: 0
    },
    yatzy: {
      v: -1,
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

exports.test = functions.region("europe-west2").https.onRequest((req, res) => {
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

exports.createValue = functions
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
      console.log(req.body.userId);

      const userId = req.body.userId;
      const gameId = req.body.gameId;
      const value = req.body.value;
      const boxId = req.body.boxId;

      console.log("boxId", boxId);
      console.log("value", value);

      var docRef = admin
        .firestore()
        .collection("games")
        .doc(gameId);

      docRef
        .get()
        .then(doc => {
          var game = doc.data();

          let user = game.users.find(user => user.userId === userId);

          if (!user) {
            console.error("Unable to find user with id: ", userId);

            res.end();
          } else {
            var previousUser =
              game.users[Math.max(game.activeUserIndex - 1, 0)];

            var previousUserUnassignedValues = Object.keys(
              previousUser.values
            ).filter(boxId => {
              return previousUser.values[boxId].v === -1;
            }).length;

            user.values[boxId].v = value;

            var activeUserUnassignedValues = Object.keys(user.values).filter(
              boxId => {
                return user.values[boxId].v === -1;
              }
            ).length;

            if (
              activeUserUnassignedValues < previousUserUnassignedValues
              || (game.activeUserIndex === game.users.length - 1 && activeUserUnassignedValues === previousUserUnassignedValues)
            ) {
              game.activeUserIndex =
                game.activeUserIndex === game.users.length - 1
                  ? 0
                  : game.activeUserIndex + 1;
            }

            var anyValueIsUnassigned = game.users.some(user => {
              return Object.keys(user.values).some(boxId => {
                return user.values[boxId].v === -1;
              });
            });

            if (!anyValueIsUnassigned) {
              game.finished = true;
            }
          }

          docRef
            .set(game)
            .then(() => {
              console.log("Document with ID: ", docRef.id, " updated");
              game.id = docRef.id;

              res.json(game);

              return false;
            })
            .catch(error => {
              console.error("Error adding document: ", error);

              res.end();
            });

          return false;
        })
        .catch(error => {
          console.error("Error adding document: ", error);

          res.end();
        });
    }
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

      var game = {
        code: generateGameCode(),
        dateCreated: new Date().getTime(),
        finished: false,
        activeUserIndex: 0,
        users: users.map(user => {
          return {
            userId: user,
            values: createScoreBoard()
          };
        })
      };

      admin
        .firestore()
        .collection("games")
        .add(game)
        .then(newGameRef => {
          console.log("Document written with ID: ", newGameRef.id);

          game.id = newGameRef.id;

          res.json(game);

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
