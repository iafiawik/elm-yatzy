import firebase from 'firebase/app';
import 'firebase/firestore';

import config from "./config";

firebase.initializeApp(config);
var db = firebase.firestore();

const getResults = (
  options = {
    sortOrder: "desc",
    year: 2019
  }
) => {
  var minCreationDate = new Date(options.year, 0, 1).getTime();
  var maxCreationDate = new Date(options.year, 11, 31, 23, 59, 59).getTime();

  return new Promise(function(resolve, reject) {
    db.collection("results")
      .where("year", "==", options.year)
      .orderBy("score", options.sortOrder)
      .limit(20)
      .get()
      .then(snapshot => {
        var results = snapshot.docs.map(result => {
          return { id: result.id, ...result.data() };
        });

        resolve(results);
      });
  });
};

const fetchStatistics = () => {
  return new Promise(function(resolve, reject) {
    db.collection("statistics")
      .orderBy("numberOfGames", "desc")
      .get()
      .then(snapshot => {
        var statistics = snapshot.docs.map(result => {
          return { id: result.id, ...result.data() };
        });

        resolve(statistics);
      });
  });
};

const fetchLastGames = () => {
  return new Promise(function(resolve, reject) {
    db.collection("games-v2")
      .where("finished", "==", true)
      .orderBy("dateCreated", "desc")
      .limit(5)
      .get()
      .then(snapshot => {
        var games = snapshot.docs.map(game => {
          return { id: game.id, ...game.data() };
        });

        resolve(games);
      });
  });
};


const prepareResults = (results, users) => {
  return results.map((result, index) => {
    var combinedResult = {
      ...result,
      user: users.find(user => user.id === result.userId)
    };

    var creationDate = new Date(combinedResult.dateCreated);

    combinedResult.date = creationDate.toLocaleDateString("sv-SE");
    combinedResult.order = index + 1;

    delete combinedResult.userId;
    delete combinedResult.dateCreated;

    return combinedResult;
  });
};

const prepareStatistics = (statistics, users) => {
  return statistics.map((result, index) => {
    var combinedResult = {
      ...result,
      user: users.find(user => user.id === result.userId)
    };

    delete combinedResult.userId;
    delete combinedResult.id;

    return combinedResult;
  });
};

const getHighscore = () => {
  var startYear = 2018;
  var currentYear = 2018;

  const yearPromises = [];

  var usersPromise = new Promise(function(resolve, reject) {
    getUsers(users => resolve(users));
  });

  while (currentYear <= new Date().getFullYear()) {
    var year = currentYear;
    var resultsPromise = getResults({ sortOrder: "desc", year: year });
    var resultsInvertedPromise = getResults({ sortOrder: "asc", year: year });

    var yearPromise = new Promise((resolve, reject) => {
      Promise.all([resultsPromise, resultsInvertedPromise, usersPromise]).then(
        values => {
          const results = values[0];
          const resultsInverted = values[1];
          const users = values[2];

          const resultsWithUsers = prepareResults(results, users);
          const resultsInvertedWithUsers = prepareResults(
            resultsInverted,
            users
          );

          var result = {
            year: results[0] ? results[0].year : startYear,
            normal: resultsWithUsers,
            inverted: resultsInvertedWithUsers
          };


          resolve(result);
        }
      );
    });

    yearPromises.push(yearPromise);
    currentYear++;
  }

  var totalPromise = new Promise((resolve, reject) => {
    Promise.all(yearPromises).then(values =>
      resolve(values.sort((a, b) => b.year - a.year))
    );
  });

  return totalPromise;
};

const getStatistics = () => {
  var usersPromise = new Promise(function(resolve, reject) {
    getUsers(users => resolve(users));
  });

  return new Promise(function(resolve, reject) {
     Promise.all([fetchStatistics(), usersPromise]).then(values => {
      const statistics = values[0];
      const users = values[1];

      const populatedStatistics = prepareStatistics(statistics, users);
      resolve(populatedStatistics);
    });
  });
};

const getUsers = onUsersChange => {
  db.collection("users").onSnapshot(function(snapshot) {
    var users = snapshot.docs.map(user => {
      return { id: user.id, ...user.data() };
    });

    onUsersChange && onUsersChange(users);
  });
};

const getGames = onGameChange => {
  db.collection("games-v2")
    .where("finished", "==", false)
    .onSnapshot(function(snapshot) {
      var games = snapshot.docs
        .map(game => {
          return { id: game.id, ...game.data() };
        })
        .filter(game => {
          return game.dateCreated > new Date().getTime() - 604800000;
        });

      var users = games.map(function(game) {
        return game.users.map(function(user) {
          user.userId;
        });
      });

      getUsersByIds(users).then(function(dbUsers) {
        var dbGames = games.map(function(game) {
          var realUsers = [];
          game.users.forEach(function(user) {
            var dbUser = dbUsers.find(function(dbUser) {
              return dbUser.id == user.userId;
            });

            if (dbUser) {
              realUsers.push(dbUser);
            }
          });
          return { ...game, users: realUsers };
        });

        dbGames.sort(function(a, b) {
          return new Date(b.dateCreated) - new Date(a.dateCreated);
        });

        var formattedDbGames = dbGames.map(function(game) {
          var formattedGame = game;
          var creationDate = new Date(game.dateCreated);

          formattedGame.dateCreated = creationDate.toLocaleDateString("sv-SE");

          return formattedGame;
        });

        onGameChange && onGameChange(formattedDbGames);
      });
    });
};

const createUser = name => {
  db.collection("users")
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

const getGame = gameCode => {
  return new Promise(function(resolve, reject) {
    db.collection("games-v2")
      .where("code", "==", gameCode)
      .get()
      .then(function(snapshot) {
        var games = snapshot.docs.map(game => {
          return { id: game.id, ...game.data() };
        });

        if (games.length === 0) {
          reject("Unable to find a game by game code.");
        } else {
          var game = games[0];

          var dateCreated = new Date(game.dateCreated);

          var dbGame = {
            ...game,
            dateCreated: dateCreated.toLocaleDateString("sv-SE")
          };

          resolve(dbGame);
        }
      })
      .catch(function(error) {
        console.error(
          "Unable to find a game with this game code: ",
          gameCode,
          ". Error: ",
          error
        );

        reject("Unable to find a game with that code.");
      });
  });
};

const getLastFinishedGames = () => {
  var usersPromise = new Promise(function(resolve, reject) {
    getUsers(users => resolve(users));
  });

  return new Promise(function(resolve, reject) {
     Promise.all([fetchLastGames(), usersPromise]).then(values => {

      const games = values[0];

      var dbGames = games.map((dbGame) => {
        return { ...dbGame, dateCreated: formatDate(dbGame.dateCreated) };
      });

      resolve(dbGames);
    });
  });
};

const formatDate = date => {
  return new Date(date).toLocaleDateString("sv-SE");
};

const getGameByGameId = (gameId, onGameChange) => {
  return db.collection("games-v2")
    .doc(gameId)
    .onSnapshot(function(doc) {
      var game = { id: doc.id, ...doc.data() };

      console.log("Game", game);

      var dateCreated = new Date(game.dateCreated);

      var dbGame = { ...game, dateCreated: formatDate(game.dateCreated) };

      onGameChange && onGameChange(dbGame)
    });
};

const getUsersByIds = userIds => {
  return new Promise(function(resolve, reject) {
    db.collection("users")
      .get()
      .then(function(snapshot) {
        var users = snapshot.docs.map(user => {
          return { id: user.id, ...user.data() };
        });

        var filtered = users.filter(function(user) {
          return userIds.find(function(userId) {
            return userId == user.id;
          });
        });

        console.log(
          "getUsersByIds(), tried to fetch " +
            userIds.length +
            " users. Received " +
            filtered.length +
            " users."
        );
        resolve(filtered);
      })
      .catch(function(error) {
        console.error("Error getting documents: ", error);
        reject("Unable to get users");
      });
  });
};

const createGame = userIds => {
  console.log("createGame()", userIds);

  return fetch(config["routes"]["createNewGame"], {
    body: JSON.stringify({
      users: userIds
    }),
    method: "POST",
    mode: "cors",
    headers: {
      "Content-Type": "application/json"
    }
  })
    .then(response => {
      if (!response.ok) {
        throw new Error(response.statusText);
      }

      var contentType = response.headers.get("content-type");
      if (contentType && contentType.includes("application/json")) {
        return response.json();
      }
    })
    .catch(error => {
      console.log("error", error);
    });
};

const createValue = (userId, gameId, value, boxId) => {
  console.log("createValue()", userId, gameId, value, boxId);

  return fetch(config["routes"]["createValue"], {
    body: JSON.stringify({
      userId: userId,
      gameId: gameId,
      value: value,
      boxId: boxId
    }),
    method: "POST",
    mode: "cors",
    headers: {
      "Content-Type": "application/json"
    }
  })
    .then(response => {
      console.log("response", response);

      if (!response.ok) {
        // var error = new Error(response.statusText);
        // error.status = response.status;
        throw new Error(response.statusText);
      }

      var contentType = response.headers.get("content-type");
      if (contentType && contentType.includes("application/json")) {
        return response.json();
      }
    })
    .catch(error => {
      console.log("error", error);
    });
};

const editGame = (game, gameId) => {
  return new Promise(function(resolve, reject) {
    var docRef = db
      .collection("games-v2")
      .doc(gameId)
      .update({
        finished: game.finished
      })
      .then(function(updatedDoc) {
        console.log(
          "editGame(): Game with ID " + gameId + " has been updated. Updates: ",
          game
        );

        resolve();
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

export default {
  getHighscore,
  getStatistics,
  createUser,
  getUsers,
  getGame,
  getGameByGameId,
  createGame,
  editGame,
  getGames,
  getLastFinishedGames,
  createValue,
  formatDate
};
