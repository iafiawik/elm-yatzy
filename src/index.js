import { Elm } from "./Main.elm";
import { unregister } from "./registerServiceWorker";
import Data from "./data";

import "./styles/app.scss";

// db
//   .collection("users")
//   .get()
//   .then(querySnapshot => {
//     alert(querySnapshot.length);
//   });

// usersRef2.on("value", function(snapshot) {
//   alert(snapshot.val());
// });
//
// Promise.all([Data.getUsers()]).then(function(values) {
//   console.log("All promises resolved", values);
//
//   initElm(values[0]);
// });

console.log("initElm");

var app = Elm.Main.init({
  node: document.getElementById("root"),
  flags: {
    random: Math.floor(Math.random() * 0x0fffffff),
    remoteUsers: [],
    remoteGames: []
  }
});

Data.getUsers(users => {
  console.log("app.ports", app.ports);
  app.ports.usersReceived.send(users);
});

Data.getValues(values => {
  console.log("app.ports", app.ports);
  app.ports.valuesReceived.send(values);
});

// Data.getGames(games => {
//   console.log("app.ports", app.ports);
//   app.ports.remoteUsers.send(users);
// });

app.ports.createUser.subscribe(function(name) {
  console.log("Create user " + name);
  Data.createUser(name);
});

var gameId = "";

app.ports.createGame.subscribe(function(game) {
  Data.createGame(game.users).then(function(dbGame) {
    app.ports.gameReceived.send(dbGame);
  });
});

app.ports.createValue.subscribe(function(value) {
  alert("Create value " + JSON.stringify(value));
  Data.createValue(value);
});

app.ports.editValue.subscribe(function(value) {
  alert("Edit value " + JSON.stringify(value));
  Data.editValue(value);
});

app.ports.deleteValue.subscribe(function(value) {
  alert("Delete value " + JSON.stringify(value));
  Data.deleteValue(value);
});

unregister();

// Initialize Firebase
// var config = {
//   apiKey: "AIzaSyDpLTMW0O94t-OKm6tTMxD2Ww0zOyFsw9c",
//   authDomain: "elm-yatzy.firebaseapp.com",
//   databaseURL: "https://elm-yatzy.firebaseio.com",
//   projectId: "elm-yatzy",
//   storageBucket: "",
//   messagingSenderId: "222344465987"
// };
