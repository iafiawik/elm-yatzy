import firebase from "firebase";

require("firebase/firestore");

import config from "./config";

firebase.initializeApp(config);

// Initialize Cloud Firestore through Firebase
var db = firebase.firestore();

// Disable deprecated features
db.settings({
  timestampsInSnapshots: true
});

// const getUsers = () => {
//   return new Promise(function(resolve, reject) {
//     db
//       .collection("users")
//       .get()
//       .then(snapshot => {
//         snapshot.docs.forEach(user => {
//           console.log(`${user.id} => ${JSON.stringify(user.data())}`);
//         });
//
//         resolve(
//           snapshot.docs.map(user => {
//             return { id: user.id, ...user.data() };
//           })
//         );
//       })
//       .catch(err => {
//         reject(err);
//       });
//   });

const getUsers = onUsersChange => {
  db.collection("users").onSnapshot(function(snapshot) {
    var users = snapshot.docs.map(user => {
      return { id: user.id, ...user.data() };
    });

    onUsersChange && onUsersChange(users);

    console.log("users", users);
    // return users;
  });
};

const getGames = onGameChange => {
  db.collection("games").onSnapshot(function(snapshot) {
    var games = snapshot.docs.map(game => {
      return { id: game.id, ...game.data() };
    });

    onGameChange && onGameChange(game);

    console.log("game", game);
  });
};

const createUser = name => {
  db
    .collection("users")
    .add({
      name: name,
      userName: name
    })
    .then(function(docRef) {
      console.log("Document written with ID: ", docRef.id);
    })
    .catch(function(error) {
      console.error("Error adding document: ", error);
    });
};

const createGame = users => {
  function id() {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    for (var i = 0; i < 4; i++)
      text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text.toUpperCase();
  }
  var gameId = id();

  return new Promise(function(resolve, reject) {
    db
      .collection("games")
      .add({
        users: users,
        dateCreated: Date.now(),
        finished: false,
        code: gameId
      })
      .then(function(game) {
        console.log("Game created written with ID: ", game);
        // resolve({ id: game.id, ...game.data() });

        var docRef = db.collection("games").doc(game.id);

        docRef
          .get()
          .then(function(doc) {
            if (doc.exists) {
              resolve({ id: doc.id, ...doc.data() });
              console.log("Document data:", doc.data());
            } else {
              // doc.data() will be undefined in this case
              console.log("No such document!");
              reject("No such document!");
            }
          })
          .catch(function(error) {
            console.log("Error getting document:", error);
            reject(error);
          });
      })
      .catch(function(error) {
        console.error("Error adding document: ", error);
        reject(error);
      });
  });
};

const editGame = (game, gameId) => {
  debugger;
  return new Promise(function(resolve, reject) {
    var docRef = db
      .collection("games")
      .doc(gameId)
      .update({
        finished: game.finished
      })
      .then(function(updatedDoc) {
        console.log("editGame(): Game with ID " + gameId + " has been.");
      })
      .catch(function(error) {
        console.log(
          "editGame(): Unable to update game with ID " + gameId + ". Error: ",
          error
        );
        reject(error);
      });
  });
};

const createValue = (value, gameId) => {
  db
    .collection("values")
    .add({
      gameId: gameId,
      boxId: value.boxId,
      userId: value.userId,
      value: value.value
    })
    .then(function(docRef) {
      console.log("createValue(): Document written with ID: ", docRef.id);
    })
    .catch(function(error) {
      console.error("Error adding document: ", error);
    });
};

const editValue = (value, gameId) => {
  var docRef = db.collection("values").doc(value.id);

  docRef
    .set({
      gameId: gameId,
      boxId: value.boxId,
      userId: value.userId,
      value: value.value
    })
    .then(function() {
      console.log(
        "editValue(): Value with ID " +
          value.id +
          " has been updated with value " +
          value.value
      );
    })
    .catch(function(error) {
      console.error(
        "Unable to update value with ID " + value.id + ". Error : ",
        error
      );
    });
};

const deleteValue = value => {
  var docRef = db.collection("values").doc(value.id);

  docRef
    .delete()
    .then(function(docRef) {
      console.log(
        "deleteValue(): Value with ID " + value.id + " has been deleted."
      );
    })
    .catch(function(error) {
      console.error(
        "Unable to delete value with ID " + value.id + ". Error : ",
        error
      );
    });
};

const getValues = (gameId, onValuesChange) => {
  db
    .collection("values")
    .where("gameId", "==", gameId)
    .onSnapshot(function(snapshot) {
      var values = snapshot.docs.map(value => {
        return { id: value.id, ...value.data() };
      });

      onValuesChange && onValuesChange(values);

      console.log("data: , getValues(), values:", values);
      // return users;
    });
};

export default {
  createUser,
  getUsers,
  createGame,
  editGame,
  getGames,
  createValue,
  editValue,
  deleteValue,
  getValues
};
