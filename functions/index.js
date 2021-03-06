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

exports.createValue = functions.https.onRequest((req, res) => {
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

    var docRef = admin
      .firestore()
      .collection("games-v2")
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
          var oldValue = user.values[boxId].v;
          var isNewValue = oldValue === -1;

          user.values[boxId].v = value;

          if (isNewValue) {
            user.values[boxId].c = new Date().getTime();
          }

          var usersAndNumberOfUnassignedValues = game.users.map(
            (user, index) => {
              return {
                index,
                numberOfUnassignedValues: Object.keys(user.values).filter(
                  boxId => user.values[boxId].v === -1
                ).length
              };
            }
          );

          usersAndNumberOfUnassignedValues.sort(function(vote1, vote2) {
            if (vote1.numberOfUnassignedValues > vote2.numberOfUnassignedValues)
              return -1;
            if (vote1.numberOfUnassignedValues < vote2.numberOfUnassignedValues)
              return 1;

            if (vote1.index > vote2.index) return 1;
            if (vote1.index < vote2.index) return -1;
          });

          var nextActiveIndex = usersAndNumberOfUnassignedValues[0].index;

          game.activeUserIndex = nextActiveIndex;

          if (
            usersAndNumberOfUnassignedValues[0].numberOfUnassignedValues === 0
          ) {
            game.finished = true;
          }
        }

        docRef
          .set(game)
          .then(() => {
            game.id = docRef.id;

            res.json(game);

            console.log("createValue(), returning ", game);

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

exports.createNewGame = functions.https.onRequest((req, res) => {
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
      .collection("games-v2")
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

exports.calculateResultsOnRequest = functions.https.onRequest((req, res) => {
  console.log("calculateResultsOnRequest() called.");

  calculateResults()
    .then(() => {
      res.end();

      console.log("calculateResultsOnRequest(), results are calculated.");

      return false;
    })
    .catch(error => {
      res.send();

      return false;
    });
});

exports.calculateStatisticsOnRequest = functions.https.onRequest((req, res) => {
  console.log("calculateStatisticsOnRequest() called.");

  calculateStatistics()
    .then(() => {
      res.end();

      console.log("calculateStatisticsOnRequest(), statistics are calculated.");

      return false;
    })
    .catch(error => {
      res.send();

      return false;
    });
});

function onGameFinished(game) {
  return new Promise((resolve, reject) => {
    if (!game.finished) {
      console.log("onGameFinished(), game is not finished.");
      resolve();
    }

    console.log(
      "onGameFinished(), Game " +
        game.id +
        " is finished, trying to calculate results."
    );

    var users = game.users;

    game.users.forEach(user => {
      user.score = calculateTotalScore(user.values);
    });

    users = users.sort((a, b) => b.score - a.score);

    let lastRank = 0;
    let lastValue = users[0].score;

    let rankedUsers = users.map((user, index) => {
      if (user.score < lastValue) {
        user.rank = lastRank + 1;

        lastValue = user.score;
        lastRank++;
      } else {
        user.rank = lastRank;
      }

      return user;
    });

    var gameRef = admin
      .firestore()
      .collection("games-v2")
      .doc(game.id);

    delete game.id;

    gameRef
      .set(game)
      .then(() => {
        console.log(
          "onGameFinished(), game updated. Trying to write to results ..."
        );

        return calculateResults(gameRef.id).then(() => {
          console.log("Wrote results, time to calculate statistics");

          calculateStatistics()
            .then(() => {
              resolve();
              return false;
            })
            .catch(e => {
              console.error(
                "onGameFinished(), unable to write statistics. ",
                e
              );

              reject(e);
            });

          return false;
        });
      })
      .catch(e => {
        console.error("onGameFinished(), unable to write user scores. ", e);

        reject(e);
      });

    return false;
  });
}

function hasBonus(values) {
  var upperSum = values
    .filter(value => {
      if (
        value.boxId === "ones" ||
        value.boxId === "twos" ||
        value.boxId === "threes" ||
        value.boxId === "fours" ||
        value.boxId === "fives" ||
        value.boxId === "sixes"
      ) {
        return true;
      } else {
        return false;
      }
    })
    .reduce((accumulator, currentValue) => accumulator + currentValue.value, 0);

  return upperSum >= 63;
}

function calculateTotalScore(valueObject) {
  var values = Object.keys(valueObject).map(boxId => {
    return {
      boxId: boxId,
      value: valueObject[boxId].v
    };
  });

  const reducer = (accumulator, currentValue) =>
    accumulator + currentValue.value;

  var bonusSum = hasBonus(values) ? 50 : 0;

  return values.reduce(reducer, 0) + bonusSum;
}

function calculateResults(gameId) {
  const resultsRef = admin.firestore().collection("results");

  console.log("calculateResults(), gameId: ", gameId);

  var gamesRef = admin.firestore().collection("games-v2");

  if (gameId) {
    gamesRef = gamesRef.doc(gameId);
  } else {
    gamesRef = gamesRef.where("finished", "==", true);
  }

  return new Promise((resolve, reject) => {
    gamesRef
      .get()
      .then(snapshot => {
        var rawGames = [];
        var games;

        if (!Array.isArray(snapshot.docs)) {
          rawGames.push(snapshot);
        } else {
          rawGames = snapshot.docs;
        }

        console.log("calculateResults(), fetched games. ", rawGames.length);

        try {
          games = rawGames.map(game => {
            var g = game.data();
            g.id = game.id;
            return g;
          });
        } catch (e) {
          console.error("calculateResults(), unable to extract game data, ", e);
        }

        var results = [];

        games.forEach(game => {
          game.users.forEach((user, index) => {
            //Do not include test users in the highscore
            if (
              user.userId === "1mSEbTIQiiDCFRIsYCNy" ||
              user.userId === "vWAokowhN0XUTHTbyr2n"
            ) {
              return false;
            }

            if (user.score > 0 && !user.invalid) {
              results.push({
                userId: user.userId,
                score: user.score,
                dateCreated: game.dateCreated,
                gameId: game.id,
                year: new Date(game.dateCreated).getFullYear(),
                rank: user.rank,
                order: index,
                numberOfPlayers: game.users.length
              });
            }

            return false;
          });
        });

        console.log("calculateResults(), found results: ", results);

        var promises = [];
        results.forEach((result, index) => {
          const resultId = `${result.gameId}-${result.userId}`;

          var promise = resultsRef.doc(resultId).set(result);

          promises.push(promise);
        });

        Promise.all(promises)
          .then(() => {
            resolve();
            return false;
          })
          .catch(e => {
            reject(e);
          });

        return false;
      })
      .catch(error => {
        console.error("calculateResults(), an error occured: ", error);
        reject(error);
        return false;
      });

    return false;
  });
}

function calculateStatisticsByUser(userValues, averageWinningScore) {
  var numberOfGames = userValues.length;

  var numberOfYatzy = userValues.filter(
    values => values.values["yatzy"].v === 50
  ).length;

  var totalScores = userValues
    .map(values => {
      return calculateTotalScore(values.values);
    })
    .sort((a, b) => b - a);

  var numberOfGamesWithBonus = userValues
    .map(values => {
      return hasBonus(
        Object.keys(values.values).map(boxId => {
          return {
            boxId: boxId,
            value: values.values[boxId].v
          };
        })
      );
    })
    .filter(bonus => bonus === true).length;

  var highestScore = totalScores[0];
  var lowestScore = totalScores[totalScores.length - 1];

  var sum = totalScores.reduce(function(a, b) {
    return a + b;
  });

  var avg = sum / totalScores.length;

  var gamesWithMoreThanOnePlayer = userValues.filter(
    userValue => userValue.numberOfPlayers > 1
  );

  var statisticallyWonGames = gamesWithMoreThanOnePlayer.filter(
    userValue => userValue.score >= averageWinningScore
  ).length;

  return {
    average: avg,
    numberOfGames: numberOfGames,
    bonusChance: numberOfGamesWithBonus / numberOfGames,
    yatzyChance: numberOfYatzy / numberOfGames,
    winChance: statisticallyWonGames / gamesWithMoreThanOnePlayer.length,
    highestScore: highestScore,
    lowestScore: lowestScore
  };
}

function isTestUser(user) {
  return (
    user.id === "1mSEbTIQiiDCFRIsYCNy" || user.id === "vWAokowhN0XUTHTbyr2n"
  );
}

function calculateStatistics() {
  console.log("calculateStatistics(), called");

  return new Promise(function(resolve, reject) {
    Promise.all([getGames(), getUsers()])
      .then(allValues => {
        console.log("calculateStatistics(), fetched games and users");

        const statisticsRef = admin.firestore().collection("statistics");

        var games = allValues[0];
        var users = allValues[1];

        var promises = [];

        var winningGames = games.filter(
          game => game.finished && game.users.length > 1
        );

        var winners = winningGames.map(game =>
          game.users.filter(user => user.rank === 0 && !isTestUser(user))
        );

        winners = [].concat.apply([], winners);

        var averageWinningScore =
          winners.reduce((total, winner) => total + winner.score, 0) /
          winners.length;

        users.forEach(user => {
          //Do not include test users in statistics
          if (isTestUser(user)) {
            return false;
          }

          const id = `user-${user.id}`;

          var userValues = [];
          var finishedGames = games.filter(game => game.finished);

          finishedGames.forEach(game => {
            game.users.forEach(gameUser => {
              if (gameUser.userId === user.id) {
                gameUser.numberOfPlayers = game.users.length;

                userValues.push(gameUser);
              }
            });
          });

          if (userValues.length > 5) {
            var statistics = calculateStatisticsByUser(
              userValues,
              averageWinningScore
            );
            statistics.userId = user.id;

            promises.push(statisticsRef.doc(id).set(statistics));
          }
        });

        console.log(
          "calculateStatistics(), calculated user statistics. Calculated statistics for ",
          promises.length,
          " users"
        );

        Promise.all(promises)
          .then(() => {
            resolve();
            return false;
          })
          .catch(e => {
            console.log(
              "calculateStatistics(),  unable to calculate statistics. Error: ",
              e
            );
            reject(e);
          });

        return false;
      })
      .catch(error => {
        console.error(
          "calculateStatistics(), Unable to write statistics. ",
          error
        );
        return false;
      });
  });
}

function getGames() {
  return new Promise((resolve, reject) => {
    admin
      .firestore()
      .collection("games-v2")
      .get()
      .then(snapshot => {
        var games = snapshot.docs.map(dbGame => {
          var game = dbGame.data();
          game.id = dbGame.id;
          return game;
        });

        console.log("getGames(), games found: ", games.length);

        return resolve(games);
      })
      .catch(e => {
        console.error("getGames(), Unable to get games.", e);
        return reject(new Error(e));
      });
  });
}

function getUsers() {
  return new Promise((resolve, reject) => {
    admin
      .firestore()
      .collection("users")
      .get()
      .then(snapshot => {
        var users = snapshot.docs.map(dbUser => {
          var user = dbUser.data();
          user.id = dbUser.id;
          return user;
        });

        console.log("getUsers(), users found: ", users.length);

        return resolve(users);
      })
      .catch(e => {
        console.error("getUsers(), Unable to calculate scores for users.", e);
        return reject(new Error(e));
      });
  });
}

exports.onGameUpdated = functions.firestore
  .document("/games-v2/{gameId}")
  .onUpdate((change, context) => {
    const game = change.after.data();
    game.id = change.after.ref.id;

    if (game.finished) {
      console.log(
        "onGameUpdated(), game is finished. Time to calculate results and statistics."
      );

      return onGameFinished(game)
        .then(() => {
          console.log("onGameUpdated(), calculated results and statistics.");
          return false;
        })
        .catch(error => {
          console.error(
            "onGameUpdated(), unable to calculated results and statistics. Error: ",
            error
          );
        });
    } else {
      return false;
    }
  });
