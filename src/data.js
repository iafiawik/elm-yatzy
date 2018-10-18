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

const getUsers = () => {
  return new Promise(function(resolve, reject) {
    db
      .collection("users")
      .get()
      .then(snapshot => {
        snapshot.docs.forEach(user => {
          console.log(`${user.id} => ${JSON.stringify(user.data())}`);
        });

        resolve(
          snapshot.docs.map(user => {
            return { id: user.id, ...user.data() };
          })
        );
      })
      .catch(err => {
        reject(err);
      });
  });
};

const addUser = name => {
  db
    .collection("users")
    .add({
      first: "Ada",
      last: "Lovelace",
      born: 1815
    })
    .then(function(docRef) {
      console.log("Document written with ID: ", docRef.id);
    })
    .catch(function(error) {
      console.error("Error adding document: ", error);
    });
};

export default {
  addUser: addUser,
  getUsers: getUsers
};
