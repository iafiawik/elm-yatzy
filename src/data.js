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

const getHighscore2 = onHighscoreChange => {
  db.collection("global").doc("highscore")
    .get()
    .then(function(snapshot) {
      const highscoreList = snapshot.data().list;

      const formattedHighscoreList = highscoreList.map((highscoreItem) => {

        var formattedHighscoreItem = highscoreItem;
        var creationDate = new Date(highscoreItem.date);

        formattedHighscoreItem.date = creationDate.toLocaleDateString("sv-SE");

        return formattedHighscoreItem;
      });

      onHighscoreChange && onHighscoreChange(highscoreList);
    });
};

const getResults = (options = {
  sortOrder: "desc",
  year: 2019
}) => {
  var minCreationDate = new Date(options.year, 0, 1).getTime();
  var maxCreationDate = new Date(options.year, 11, 31, 23, 59, 59).getTime();

  return new Promise(function(resolve, reject) {
     db
      .collection("results")
      .where("year", "==", options.year)
      .orderBy("score", options.sortOrder)
      .limit(20)
      .get()
      .then((snapshot) => {
        var results = snapshot.docs.map(result => {
          return { id: result.id, ...result.data() };
        });

        console.log("results", results);

        resolve(results);
      });
    });
}

const prepareResults = (results, users) => {
  return results.map((result, index) => {
    var combinedResult = {...result, user: users.find((user) => user.id === result.userId)};

    var creationDate = new Date(combinedResult.dateCreated);

    combinedResult.date = creationDate.toLocaleDateString("sv-SE");
    combinedResult.order = index + 1;

    delete combinedResult.userId;
    delete combinedResult.dateCreated;

    return combinedResult;
  });
}


const getHighscore = () => {
  var startYear = 2018;
  var currentYear = 2018;

  const yearPromises = [];

  var usersPromise = new Promise(function(resolve, reject) {
    getUsers((users) => resolve(users));
  });

  while(currentYear <= new Date().getFullYear()) {
    console.log("currentYear", currentYear)
    var year = currentYear;
    var resultsPromise = getResults({ sortOrder: "desc", year: year });
    var resultsInvertedPromise = getResults({ sortOrder: "asc", year: year });

    var yearPromise = new Promise((resolve, reject) => {
      Promise
        .all([resultsPromise, resultsInvertedPromise, usersPromise])
        .then((values) => {
          const results = values[0];
          const resultsInverted = values[1];
          const users = values[2];

          const resultsWithUsers = prepareResults(results, users);
          const resultsInvertedWithUsers = prepareResults(resultsInverted, users);

          var result = {
            year: results[0].year,
            normal: resultsWithUsers,
            inverted: resultsInvertedWithUsers
          };

          console.log("result", result)

          resolve(result)
        });
      });

      yearPromises.push(yearPromise);
      currentYear++;
    }

  var totalPromise = new Promise((resolve, reject) => {
    Promise.all(yearPromises).then(values => resolve(values.sort((a, b) => b.year - a.year)));
  });

  return totalPromise;
}

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
  db
    .collection("games")
    .where("finished", "==", false)
    .onSnapshot(function(snapshot) {
      var games = snapshot.docs.map(game => {
        return { id: game.id, ...game.data() };
      }).filter(game => {
        return game.dateCreated > (new Date().getTime() - 604800000);
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
        console.log("DbGames: ", dbGames);

        dbGames.sort(function(a, b) {
          return new Date(b.dateCreated) - new Date(a.dateCreated);
        });

        var formattedDbGames = dbGames.map(function(game) {
          var formattedGame = game;
          var creationDate = new Date(game.dateCreated);

          formattedGame.dateCreated = creationDate.toLocaleDateString("sv-SE");

          return formattedGame;
        });

        console.log("getGames, formattedDbGames: ", formattedDbGames);

        onGameChange && onGameChange(formattedDbGames);
      });
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

const getGame = gameCode => {
  return new Promise(function(resolve, reject) {
    db
      .collection("games")
      .where("code", "==", gameCode)
      .get()
      .then(function(snapshot) {
        var games = snapshot.docs.map(game => {
          return { id: game.id, ...game.data() };
        });

        if (games.length === 0) {
          reject("Unable to find a game with this game code: " + gameCode);
        } else {
          var game = games[0];

          var users = game.users.map(function(user) {
            return user.userId;
          });

          getUsersByIds(users).then(function(dbUsers) {
            var realUsers = game.users.map(function(user) {
              return {
                user: dbUsers.find(function(dbUser) {
                  return dbUser.id == user.userId;
                }),
                order: user.order,
                score: user.score
              };
            });

            var dateCreated = new Date(game.dateCreated);

            var dbGame = { ...game, users: realUsers, dateCreated: dateCreated.toLocaleDateString("sv-SE") };

            console.log("DbGame: ", dbGame);
            resolve(dbGame);
          });
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

const getGameByGameId = gameId => {
  return new Promise(function(resolve, reject) {
    db
      .collection("games")
      .doc(gameId)
      .get()
      .then(function(doc) {
        if (doc.exists) {
          var game = { id: doc.id, ...doc.data() };

          console.log("Game", game)

          var users = game.users.map(function(user) {
            return user.userId;
          });

          getUsersByIds(users).then(function(dbUsers) {
            var realUsers = game.users.map(function(user) {
              return {
                user: dbUsers.find(function(dbUser) {
                  return dbUser.id == user.userId;
                }),
                order: user.order,
                score: user.score
              };
            });

            var dateCreated = new Date(game.dateCreated);

            var dbGame = { ...game, users: realUsers, dateCreated: dateCreated.toLocaleDateString("sv-SE") };

            console.log("DbGame: ", dbGame);
            resolve(dbGame);
          });
        }
        else {
          throw new Error();
        }
      })
      .catch(function(error) {
        console.error(
          "Late return Unable to find a game with this game ID: ",
          gameId,
          ". Error: ",
          error
        );

        reject("Unable to find a game with that ID.");
      });
  });
};

const getUsersByIds = userIds => {
  return new Promise(function(resolve, reject) {
    // var docRef = db.collection("cities").doc(userIds);

    db
      .collection("users")
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
              var game = { id: doc.id, ...doc.data() };
              var users = game.users.map(function(user) {
                return user.userId;
              });

              getUsersByIds(users).then(function(dbUsers) {
                var realUsers = game.users.map(function(user) {
                  return {
                    user: dbUsers.find(function(dbUser) {
                      return dbUser.id == user.userId;
                    }),
                    order: user.order,
                    score: user.score
                  };
                });
                var dateCreated = new Date(game.dateCreated);

                var dbGame = { ...game, users: realUsers, dateCreated: dateCreated.toLocaleDateString("sv-SE") };

                console.log("DbGame: ", dbGame);
                resolve(dbGame);
              });
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
  return new Promise(function(resolve, reject) {
    var docRef = db
      .collection("games")
      .doc(gameId)
      .update({
        finished: game.finished
      })
      .then(function(updatedDoc) {
        console.log("editGame(): Game with ID " + gameId + " has been updated. Updates: ", game);
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
      value: value.value,
      dateCreated: Date.now()
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
      value: value.value,
      dateCreated: value.dateCreated
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
      // var addedValueIds = [];
      // snapshot.docChanges().forEach(function(change) {
      //   if (change.type === "added") {
      //     addedValueIds.push(change.doc.id);
      //     console.log("New city: ", change.doc.data());
      //   }
      //   if (change.type === "modified") {
      //     console.log("Modified city: ", change.doc.data());
      //   }
      //   if (change.type === "removed") {
      //     console.log("Removed city: ", change.doc.data());
      //   }
      // });

      var values = snapshot.docs.map(value => {
        return { id: value.id, ...value.data() };
      });

      onValuesChange && onValuesChange(values);

      console.log("data: , getValues(), values:", values);
      // return users;
    });
};

export default {
  getHighscore,
  createUser,
  getUsers,
  getGame,
  getGameByGameId,
  createGame,
  editGame,
  getGames,
  createValue,
  editValue,
  deleteValue,
  getValues
};
