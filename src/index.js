import { Elm } from "./Main.elm";
import { unregister } from "./registerServiceWorker";
import Data from "./data";

import "./styles/app.scss";

window.config = {
  devMode: true
};

window.isAdmin = isUserAdmin();

function isUserAdmin() {
  var field = "admin";
  var url = window.location.href;
  if (url.indexOf("?" + field) != -1) return true;
  else if (url.indexOf("&" + field) != -1) return true;
  return false;
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

function createAdminInputFields(
  parent,
  placeholder1,
  placeholder2,
  buttonText
) {
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

  var toggleFinishedStateByGameCodeButton = createAdminInputField(
    container,
    "Game code",
    "Toggle finished state"
  );
  var toggleFinishedStateByGameIdButton = createAdminInputField(
    container,
    "Game ID",
    "Toggle finished state"
  );

  var recalculateHighscoreButton = document.createElement("a");
  recalculateHighscoreButton.innerHTML = "Recalculate results";
  recalculateHighscoreButton.href =
    "https://us-central1-elm-yatzy.cloudfunctions.net/calculateResultsOnRequest";
  recalculateHighscoreButton.target = "_blank";

  var recalculateHighscoreButton = document.createElement("a");
  recalculateHighscoreButton.innerHTML = "Recalculate statistics";
  recalculateHighscoreButton.href =
    "https://us-central1-elm-yatzy.cloudfunctions.net/calculateStatisticsOnRequest";
  recalculateHighscoreButton.target = "_blank";

  container.appendChild(recalculateHighscoreButton);

  document.body.appendChild(container);

  toggleFinishedStateByGameCodeButton.onclick = () => {
    var gameCode = input.value;

    Data.getGame(gameCode).then(function(game) {
      Data.editGame(Object.assign(game, { finished: !game.finished }), game.id)
        .then(() => {
          alert("hej");
        })
        .catch(e => {
          alert("error", e);
          console.error("error", e);
        });
    });
  };

  toggleFinishedStateByGameIdButton.onclick = () => {
    var gameId = toggleFinishedStateByGameIdButton.previousSibling.value;

    Data.getGameByGameId(gameId).then(function(game) {
      Data.editGame(Object.assign(game, { finished: !game.finished }), game.id)
        .then(() => {
          alert("hej");
        })
        .catch(e => {
          alert("error", e);
          console.error("error", e);
        });
    });
  };
}

window.onblur = function() {
  console.log("window.onblur ");

  if (oldGameAndUserExist()) {
    const gameId = getGameInLocalStorage();

    console.log(
      "window.onblur, Old game exists, so sending blur. Game id: ",
      gameId
    );

    app.ports.onBlurReceived.send(1);
  } else {
    console.log("window.onblur , No old game found, so no need to send blur");
  }
};
//
window.onfocus = function() {
  checkLastPlayedGame();
};

window.onload = function() {
  checkLastPlayedGame();
};

const gameIdKey = "last-played-game-id";
const userIdKey = "last-played-user-id";

const checkLastPlayedGame = () => {
  if (oldGameAndUserExist()) {
    app.ports.onBlurReceived.send(1);

    const gameId = getGameInLocalStorage();
    const userId = getUserIdInLocalStorage();

    Data.getGameByGameId(gameId)
      .then(function(game) {
        console.log("checkLastPlayedGame(), game: ", game);

        if (!game.finished) {
          console.log(
            "checkLastPlayedGame(), a not finished game is to be sent to Elm"
          );

          app.ports.onFocusReceived.send({ game: game, userId: userId });
        }
      })
      .catch(function() {
        console.log(
          "checkLastPlayedGame(), could not find game with id ",
          gameId
        );
      });

    console.log(
      "checkLastPlayedGame(), last played game was gameId ",
      gameId,
      " and userId ",
      userId
    );
  } else {
    console.log("checkLastPlayedGame(), either no game or no user was found.");
  }
};

const oldGameAndUserExist = () => {
  const lastGame = getGameInLocalStorage();
  const lastUser = getUserIdInLocalStorage();

  const exists =
    lastGame &&
    typeof lastGame !== "undefined" &&
    lastUser &&
    typeof lastUser !== "undefined";
  console.log("oldGameAndUserExist", lastGame, lastUser, exists);
  return exists;
};

const setGameInLocalStorage = gameId => {
  setValueInLocalStorage(gameIdKey, gameId);
};

const getGameInLocalStorage = () => {
  return getValueInLocalStorage(gameIdKey);
};

const deleteGameInLocalStorage = () => {
  deleteValueInLocalStorage(gameIdKey);
};

const setUserIdInLocalStorage = userId => {
  setValueInLocalStorage(userIdKey, userId);
};

const getUserIdInLocalStorage = () => {
  return getValueInLocalStorage(userIdKey);
};

const deleteUserIdInLocalStorage = () => {
  deleteValueInLocalStorage(userIdKey);
};

const setValueInLocalStorage = (key, value) => {
  localStorage.setItem("iatzy-" + key, value);
};

const getValueInLocalStorage = key => {
  return localStorage.getItem("iatzy-" + key);
};

const deleteValueInLocalStorage = key => {
  localStorage.removeItem("iatzy-" + key);
};

console.log("index.js: initElm");

var app = Elm.Main.init({
  node: document.getElementById("root"),
  flags: {
    isAdmin: !!isAdmin
  }
});

Data.getUsers(users => {
  console.log("index.js: Data.getUsers", users);
  app.ports.usersReceived.send(users);
});

Data.getHighscore()
  .then(highscores => {
    console.log("index.js: Data.getHighscore", highscores);

    app.ports.highscoreReceived.send(highscores);
  })
  .catch(error => console.error("index.js, Data.getHighscore error: ", error));

app.ports.fillWithDummyValues.subscribe(function(params) {
  var gameId = params[0];
  var userId = params[1];
  var values = params[2];

  if (window.config.devMode) {
    console.log("fillWithDummyValues, ", userId, ", gameId ", gameId);

    values.forEach(function(value, index) {
      setTimeout(function() {
        Data.createValue(userId, gameId, value.value, value.boxId).then(
          game => {
            game.dateCreated = Data.formatDate(game.dateCreated);

            app.ports.gameReceived.send(game);
          }
        );
      }, 2000 * index);
    });
  }
});

app.ports.getGlobalHighscore.subscribe(function() {
  Data.getHighscore(highscore => {
    console.log("index.js: Data.getHighscore", highscore);
    app.ports.highscoreReceived.send(highscore);
  });
});

app.ports.getUsers.subscribe(function() {
  Data.getUsers(users => {
    console.log("index.js: Data.getUsers", users);
    app.ports.usersReceived.send(users);
  });
});

app.ports.getGames.subscribe(function() {
  console.log("index.js: app.ports.getGames called");

  Data.getGames(games => {
    console.log("index.js: Data.getGames", games);
    app.ports.gamesReceived.send(games);
  });
});

app.ports.startGameWithMarkedPlayerCommand.subscribe(function(params) {
  const gameId = params[0];
  const userId = params[1];

  console.log("startGameWithMarkedPlayerCommand", params);
  setUserIdInLocalStorage(userId);
  setGameInLocalStorage(gameId);
});

app.ports.startGameCommand.subscribe(function(gameId) {
  console.log("startGameCommand", gameId);
  setUserIdInLocalStorage("all");
  setGameInLocalStorage(gameId);
});

app.ports.endGameCommand.subscribe(function(game) {
  deleteGameInLocalStorage();
  deleteUserIdInLocalStorage();
});


const getGameByCode = gameCode => {
  console.log("index.js: getGameByCode " + gameCode);
  Data.getGame(gameCode).then(function(game) {
    app.ports.gameReceived.send(game);
  });
};

app.ports.getGameByGameCode.subscribe(function(gameCode) {
  getGameByCode(gameCode);
});

app.ports.getGameByGameId.subscribe(function(gameId) {
  console.log("index.js: getGameByGameId " + gameId);
  Data.getGameByGameId(gameId).then(function(game) {
    app.ports.gameReceived.send(game);
  });
});

app.ports.createUser.subscribe(function(name) {
  console.log("index.js: Create user " + name);
  Data.createUser(name);
});

app.ports.createGame.subscribe(function(users) {
  Data.createGame(users).then(function(dbGame) {
    dbGame.dateCreated = Data.formatDate(dbGame.dateCreated);

    app.ports.gameReceived.send(dbGame);
  });
});

app.ports.createValue.subscribe(function(params) {
  console.log("index.js: Create value, userId: ", params);
  Data.createValue(params.userId, params.gameId, params.value, params.boxId)
    .then(game => {
      console.log("index.js:createValue(), game updated: ", game);

      game.dateCreated = Data.formatDate(game.dateCreated);

      app.ports.gameReceived.send(game);
    })
    .catch(error => {
      console.log("index.js:createValue(), an error occured: ", error);
    });
});

unregister();
