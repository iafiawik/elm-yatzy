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
  devMode: true
}

window.gameId = "";
window.isAdmin = isUserAdmin();



// Data.getGames2(games => {
//   console.log("index.js: Data.getGames", games);
//
//   games.forEach(game => {
//     Data.editGame((Object.assign(game, {finished: true})), game.id).then(() => {
//       console.log("Game " + game.id + " is now finished")
//     });
//   })
// });

function isUserAdmin() {
  var field = 'admin';
  var url = window.location.href;
  if(url.indexOf('?' + field) != -1)
      return true;
  else if(url.indexOf('&' + field) != -1)
      return true;
  return false
}

function createAdminInputField(parent, placeholder, buttonText) {
  var container = document.createElement("div");
  container.style.marginBottom = "10px";

  var btn = createButton(buttonText);

  container.appendChild(createInput(placeholder));
  container.appendChild(btn);
  parent.appendChild(container);

  return btn;
}

function createAdminInputFields(parent, placeholder1, placeholder2, buttonText) {
  var container = document.createElement("div");
  container.style.marginBottom = "10px";

  var btn = createButton(buttonText);

  container.appendChild(createInput(placeholder1));
  container.appendChild(createInput(placeholder2));

  container.appendChild(btn);
  parent.appendChild(container);

  return btn;
}


function createInput(placeholder) {
  var input = document.createElement("input");
  input.placeholder = placeholder;
  return input;
}

function createButton(buttonText) {
  var btn = document.createElement("button");
  btn.innerHTML = buttonText;

  return btn;
}

if (window.isAdmin) {
  var root = document.getElementById("container");
  root.classList.add("is-admin");

  var container = document.createElement("div");
  container.style.position = "absolute";
  container.style.top = "0px";
  container.style.left = "0px";

  var toggleFinishedStateByGameCodeButton = createAdminInputField(container, "Game code", "Toggle finished state");
  var toggleFinishedStateByGameIdButton = createAdminInputField(container, "Game ID", "Toggle finished state");

  var recalculateHighscoreButton = document.createElement("a");
  recalculateHighscoreButton.innerHTML = "Recalculate results";
  recalculateHighscoreButton.href = "https://us-central1-elm-yatzy.cloudfunctions.net/calculateResultsOnRequest";
  recalculateHighscoreButton.target = "_blank";

  var recalculateHighscoreButton = document.createElement("a");
  recalculateHighscoreButton.innerHTML = "Recalculate statistics";
  recalculateHighscoreButton.href = "https://us-central1-elm-yatzy.cloudfunctions.net/calculateStatisticsOnRequest";
  recalculateHighscoreButton.target = "_blank";

  container.appendChild(recalculateHighscoreButton);

  document.body.appendChild(container);

  toggleFinishedStateByGameCodeButton.onclick = () => {
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

  toggleFinishedStateByGameIdButton.onclick = () => {
    var gameId = toggleFinishedStateByGameIdButton.previousSibling.value;

    Data.getGameByGameId(gameId)
      .then(function(game) {
        Data.editGame((Object.assign(game, {finished: !game.finished})), game.id).then(() => {
          alert("hej");
        }).catch((e)=>{
          alert("error", e);
          console.error("error", e);
        })

      });
  };
}

window.onblur = function() {
  console.log('blur');
  //
  // if (oldGameAndUserExist())
  // {
  //   const gameCode = getGameInLocalStorage();
  //
  //   Data.getGame(gameCode)
  //     .then(function(game) {
  //       console.log("window.onblur(), gameId: ", game.id)
  //
  //       app.ports.onBlurReceived.send(1);
  //
  //     }).catch(function() {
  //       console.log("window.onblur(), could not find game with code ", gameCode);
  //     });
  // }
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
    random: Math.floor(Math.random() * 0x0fffffff),
    isAdmin: !!isAdmin
  }
});

Data.getUsers(users => {
  console.log("index.js: Data.getUsers", users);
  app.ports.usersReceived.send(users);
});

Data.getHighscore().then((highscores) => {
  console.log("index.js: Data.getHighscore", highscores);

  app.ports.highscoreReceived.send(highscores);
}).catch((error) => console.error("index.js, Data.getHighscore error: ", error));


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

app.ports.getValues.subscribe(function() {
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
    // gameId = dbGame.id;
    //
    // Data.getValues(gameId, values => {
    //   console.log("index.js: Data.getValues", values);
    //   app.ports.valuesReceived.send(values);
    // });

    console.log("dbGame", dbGame)

    Data.getGameByGameId(dbGame.id).then((game) => {
      console.log("game", game)
      app.ports.gameReceived.send({ game: game, result: "ok" });
    })


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
