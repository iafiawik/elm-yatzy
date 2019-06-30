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


window.config = {
  devMode: false
}

window.gameId = "";

var container = document.createElement("div");   // Create a <button> element
container.style.position = "absolute";
container.style.top = "0px";
container.style.left = "0px";

var input = document.createElement("input");   // Create a <button> element
input.value = "OUVV";

var btn = document.createElement("button");   // Create a <button> element
btn.innerHTML = "CLICK ME";

container.appendChild(input);
container.appendChild(btn);
document.body.appendChild(container);

btn.onclick = () => {
  var gameCode = input.value;

  Data.getGame(gameCode)
    .then(function(game) {
      Data.editGame((Object.assign(game, {finished: !game.finished})), game.id).then(() => {
        alert("hej");
      }).catch((e)=>{
        alert("error", e);
        console.error("error", e);
      })

    });
};

window.onblur = function() {
  console.log('blur');

  if (oldGameAndUserExist())
  {
    const gameCode = getGameInLocalStorage();

    Data.getGame(gameCode)
      .then(function(game) {
        console.log("window.onblur(), gameId: ", game.id)

        app.ports.onBlurReceived.send(1);

      }).catch(function() {
        console.log("window.onblur(), could not find game with code ", gameCode);
      });
  }
}

window.onfocus = function() { console.log('focus', gameId); checkLastPlayedGame(); }
window.onload = function() { console.log("load"); checkLastPlayedGame(); }

const gameIdKey = "last-played-game-code";
const userIdKey = "last-played-user-id";

const checkLastPlayedGame = () => {

  if (oldGameAndUserExist()) {
    const gameCode = getGameInLocalStorage();
    const userId = getUserIdInLocalStorage();

    Data.getGame(gameCode)
      .then(function(game) {
        console.log("checkLastPlayedGame(), gameId: ", game.id)

        window.gameId = game.id;

        app.ports.onFocusReceived.send({game: game, userId: userId});
      }).catch(function() {
        console.log("checkLastPlayedGame(), could not find game with code ", gameCode);
      });
      console.log("checkLastPlayedGame(), last played game was gameId ", gameId, " and userId ", userId)
  }
  else {
    console.log("checkLastPlayedGame(), either no game or no user was found.")
  }
}

const oldGameAndUserExist = () => {
  const lastGame = getGameInLocalStorage();
  const lastUser = getUserIdInLocalStorage();


  const exists = typeof lastGame !== "undefined" && typeof lastUser !== "undefined";;
  console.log("oldGameAndUserExist", lastGame, lastUser, exists)
  return exists;
}

const setGameInLocalStorage = (gameId) => {
  setValueInLocalStorage(gameIdKey, gameId);
}

const getGameInLocalStorage = () => {
  return getValueInLocalStorage(gameIdKey);
}

const deleteGameInLocalStorage = () => {
  deleteValueInLocalStorage(gameIdKey);
}

const setUserIdInLocalStorage = (userId) => {
  setValueInLocalStorage(userIdKey, userId);
}

const getUserIdInLocalStorage = () => {
  return getValueInLocalStorage(userIdKey);
}

const deleteUserIdInLocalStorage = () => {
  deleteValueInLocalStorage(userIdKey);
}

const setValueInLocalStorage = (key, value) => {
  localStorage.setItem("iatzy-" + key, value)
}

const getValueInLocalStorage = (key) => {
  return localStorage.getItem("iatzy-" + key)
}

const deleteValueInLocalStorage = (key) => {
  localStorage.removeItem("iatzy-" + key)
}

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

Data.getHighscore(highscore => {
  console.log("index.js: Data.getHighscore", highscore);
  app.ports.highscoreReceived.send(highscore);
});

app.ports.fillWithDummyValues.subscribe(function(values) {
  console.log("fillWithDummyValues")
  if (window.config.devMode) {
    values.forEach(function(value) {
      Data.createValue(value, window.gameId);
    });
  }
});

// app.ports.getGlobalHighscore.subscribe(function() {
//   Data.getHighscore(highscore => {
//     console.log("index.js: Data.getHighscore", highscore);
//     app.ports.highscoreReceived.send(highscore);
//   });
// });

app.ports.getUsers.subscribe(function() {
  Data.getUsers(users => {
    console.log("index.js: Data.getUsers", users);
    app.ports.usersReceived.send(users);
  });
});

const getValues = (gameId) => {
  Data.getValues(gameId, values => {
    console.log("index.js: Data.getValues", values);
    app.ports.valuesReceived.send(values);
  });
}

// app.ports.getValues.subscribe(function(gameId) {
//   getValues(gameId);
// });

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

app.ports.startIndividualGameCommand.subscribe(function(params) {
    const userId = params[0];
    const gameId = params[1];
    const gameCode = params[2];

    setUserIdInLocalStorage(userId);
    setGameInLocalStorage(gameCode);

    getValues(gameId);
});

app.ports.startGroupGameCommand.subscribe(function(game) {
    setUserIdInLocalStorage("all");
    setGameInLocalStorage(game.code);

    getValues(game.id);
});

app.ports.endGameCommand.subscribe(function(game) {
  deleteGameInLocalStorage();
  deleteUserIdInLocalStorage();

  Data.getHighscore(highscore => {
    console.log("index.js: Data.getHighscore", highscore);
    app.ports.highscoreReceived.send(highscore);
  });
});

const getGame = (gameCode) => {
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
}

app.ports.getGame.subscribe(function(gameCode) {
    getGame(gameCode);
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
  console.log("index.js: Edit game " + JSON.stringify(game));

  deleteGameInLocalStorage();
  deleteUserIdInLocalStorage();

  Data.editGame(game, gameId);
});

app.ports.createValue.subscribe(function(value) {
  console.log("index.js: Create value " + JSON.stringify(value), "gameId", window.gameId);
  Data.createValue(value, window.gameId);
});

app.ports.editValue.subscribe(function(value) {
  console.log("Edit value " + JSON.stringify(value));
  Data.editValue(value, window.gameId);
});

app.ports.deleteValue.subscribe(function(value) {
  console.log("index.js: Delete value " + JSON.stringify(value));
  Data.deleteValue(value);
});

unregister();
