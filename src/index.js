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

console.log("index.js: initElm");

var app = Elm.Main.init({
  node: document.getElementById("root"),
  flags: {
    random: Math.floor(Math.random() * 0x0fffffff)
  }
});

Data.getUsers(users => {
  console.log("index.js: Data.getUsers", users);
  app.ports.usersReceived.send(users);
});

app.ports.fillWithDummyValues.subscribe(function(values) {
  values.forEach(function(value) {
    Data.createValue(value, gameId);
  });
});

app.ports.getUsers.subscribe(function() {
  Data.getUsers(users => {
    console.log("index.js: Data.getUsers", users);
    app.ports.usersReceived.send(users);
  });
});

app.ports.getValues.subscribe(function(gameId) {
  Data.getValues(gameId, values => {
    console.log("index.js: Data.getValues", values);
    app.ports.valuesReceived.send(values);
  });
});
app.ports.getGames.subscribe(function() {
  Data.getGames(games => {
    console.log("index.js: Data.getGames", games);
    app.ports.gamesReceived.send(games);
  });
});
// Data.getGames(games => {
//   console.log("app.ports", app.ports);
//   app.ports.remoteUsers.send(users);
// });

var gameId = "";

app.ports.getGame.subscribe(function(gameCode) {
  console.log("index.js: getGame " + gameCode);
  Data.getGame(gameCode)
    .then(function(game) {
      gameId = game.id;

      Data.getValues(game.id, values => {
        console.log("index.js: Data.getValues", values);
        app.ports.valuesReceived.send(values);
      });

      app.ports.gameReceived.send({ game: game, result: "ok" });
    })
    .catch(function(error) {
      console.error("index.js: getGame(): Unable to get game. Error: ", error);

      app.ports.gameReceived.send({ game: {}, result: "not found" });
    });
});

app.ports.createUser.subscribe(function(name) {
  console.log("index.js: Create user " + name);
  Data.createUser(name);
});

app.ports.createGame.subscribe(function(game) {
  Data.createGame(game.users).then(function(dbGame) {
    gameId = dbGame.id;

    Data.getValues(gameId, values => {
      console.log("index.js: Data.getValues", values);
      app.ports.valuesReceived.send(values);
    });

    app.ports.gameReceived.send({ game: dbGame, result: "ok" });
  });
});

app.ports.editGame.subscribe(function(game) {
  alert("index.js: Edit game " + JSON.stringify(game));
  Data.editGame(game, gameId);
});

app.ports.createValue.subscribe(function(value) {
  console.log("index.js: Create value " + JSON.stringify(value));
  Data.createValue(value, gameId);
});

app.ports.editValue.subscribe(function(value) {
  console.log("Edit value " + JSON.stringify(value));
  Data.editValue(value, gameId);
});

app.ports.deleteValue.subscribe(function(value) {
  console.log("index.js: Delete value " + JSON.stringify(value));
  Data.deleteValue(value);
});

unregister();
