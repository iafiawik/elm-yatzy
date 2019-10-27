// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require("firebase-functions");

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require("firebase-admin");
admin.initializeApp();

function calculateTotalScore(values) {
  const reducer = (accumulator, currentValue) =>
    accumulator + currentValue.value;

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
    .reduce(reducer, 0);

  var bonusSum = 0;

  if (upperSum >= 63) {
    bonusSum = 50;
  }

  return values.reduce(reducer, 0) + bonusSum;
}

function calculateResults(gameId) {
  const resultsRef = admin.firestore().collection("results");

  console.log("calculateResults(), gameId: ", gameId);

  var gamesRef = admin.firestore().collection("games");

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
          game.users.forEach(user => {
            // Do not include test users in the highscore
            // if (
            //   user.userId === "1mSEbTIQiiDCFRIsYCNy" ||
            //   user.userId === "vWAokowhN0XUTHTbyr2n"
            // ) {
            //   return false;
            // }

            if (user.score > 0 && !user.invalid) {
              results.push({
                userId: user.userId,
                score: user.score,
                dateCreated: game.dateCreated,
                gameId: game.id,
                year: new Date(game.dateCreated).getFullYear(),
                rank: user.rank,
                order: user.order,
                numberOfPlayers: game.users.length,
                yatzy: user.yatzy
              });
            }

            return false;
          });
        });

        console.log("calculateResults(), found results: ", results.length);

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

        console.log("calculateStatistics(), users found: ", users.length);

        return resolve(users);
      })
      .catch(e => {
        console.error(
          "calculateStatistics(), Unable to calculate scores for users.",
          e
        );
        return reject(new Error(e));
      });
  });
}

function getValues() {
  return new Promise((resolve, reject) => {
    admin
      .firestore()
      .collection("values")
      .limit(2000)
      .get()
      .then(snapshot => {
        var values = snapshot.docs.map(value => {
          return value.data();
        });

        console.log("getValues(), values found: ", values.length);
        console.log("getValues(), values[0]: ", values[0]);

        return resolve(values);
      })
      .catch(e => {
        console.error("getValues(), Unable to calculate scores for users.", e);
        return reject(new Error(e));
      });
  });
}

function calculateAverageScoreByUser(user, values) {
  var valuesByGame = groupBy(values, "gameId");
  var numberOfYatzy = values.filter(
    value => value.boxId === "yatyz" && value.value === 50
  );

  var totalScores = valuesByGame
    .map(gameValues => {
      return calculateTotalScore(gameValues);
    })
    .sort((a, b) => b - a);

  var highestScore = totalScores[0];
  var lowestScore = totalScores[totalScores.length - 1];

  var sum = totalScores.reduce(function(a, b) {
    return a + b;
  });

  var avg = sum / totalScores.length;

  return {
    average: avg,
    numberOfGames: valuesByGame.length,
    yatzyChance: numberOfYatzy / valuesByGame.length,
    highestScore: highestScore,
    lowestScore: lowestScore
  };
}

function groupBy(arr, prop) {
  const map = new Map(Array.from(arr, obj => [obj[prop], []]));
  arr.forEach(obj => map.get(obj[prop]).push(obj));
  return Array.from(map.values());
}

function calculateStatistics() {
  console.log("calculateStatistics() called.");

  return new Promise(function(resolve, reject) {
    Promise.all([getValues(), getUsers()])
      .then(allValues => {
        console.log("calculateStatistics(), fetched users and values");

        const statisticsRef = admin.firestore().collection("statistics");

        var values = allValues[0];
        var users = allValues[1];

        var valuesByUser = groupBy(values, "userId");

        var promises = [];

        console.log(
          "calculateStatistics(), grouped values by user, valuesByUser.length",
          valuesByUser.length
        );

        users.forEach(user => {
          const id = `user-${user.id}`;

          var valuesByUser = values.filter(value => value.userId === user.id);

          if (valuesByUser && valuesByUser.length > 0) {
            var statistics = calculateAverageScoreByUser(user, valuesByUser);
            statistics.userId = user.id;

            promises.push(statisticsRef.doc(id).set(statistics));
          }
        });

        console.log("calculateStatistics(),  calculated user statistics");

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
        console.error(
          "calculateStatistics(), Unable to write statistics. ",
          error
        );
        return false;
      });
  });
}

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

const game = {
  code: "XXXX",
  dateCreated: 123,
  finished: false,
  activeUserIndex: 0,
  users: [
    {
      userId: "djdjdjdj",
      order: 0,
      values: {
        "yatzy": {
          value: 50,
          dateCreated: 123
        },
        "threes": {
          value: 6,
          dateCreated: 456
        }
      },
      score: 323
    }
  ]
}

function addValue(boxId, value, userId, gameId) {}

exports.calculateGameResults = functions.firestore
  .document("/games/{gameId}")
  .onUpdate((change, context) => {
    var gameId = context.params.gameId;
    console.log(
      "calulateUserScores(), Game " +
        gameId +
        " has been updated, trying to calculate user scores."
    );
    const game = change.after.data();

    if (!game.finished) {
      console.log("calculateUserScores(), game is not finished.");
      return false;
    }

    console.log("calculateUserScores(), game is finished. Let's calculate.");

    var valuesPromise = new Promise((resolve, reject) => {
      admin
        .firestore()
        .collection("values")
        .where("gameId", "==", gameId)
        .get()
        .then(snapshot => {
          var values = snapshot.docs.map(value => {
            return value.data();
          });

          console.log("calulateUserScores(), values found: ", values.length);

          return resolve(values);
        })
        .catch(e => {
          console.error(
            "calculateUserScores(), Unable to calculate scores for users.",
            e
          );
          return reject(new Error(e));
        });
    });

    var usersPromise = new Promise((resolve, reject) => {
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

          console.log("calulateUserScores(), users found: ", users.length);

          return resolve(users);
        })
        .catch(e => {
          console.error(
            "calculateUserScores(), Unable to calculate scores for users.",
            e
          );
          return reject(new Error(e));
        });
    });

    var resultsPromise = new Promise((resolve, reject) => {
      Promise.all([valuesPromise, usersPromise])
        .then(allValues => {
          const values = allValues[0];
          const allUsers = allValues[1];

          var users = game.users;

          users.forEach(user => {
            var userValues = values.filter(
              value => value.userId === user.userId
            );

            user.score = calculateTotalScore(userValues);
            user.yatzy = userValues.some(
              value => value.boxId === "yatzy" && value.value === 50
            );
          });

          users = users.sort((a, b) => b.score - a.score);

          let rankedUsers = users.map((user, index) => {
            user.rank = index + 1;

            return user;
          });

          console.log("calulateUserScores(), all users updated.");

          change.after.ref
            .set(
              {
                counted: true,
                users: rankedUsers
              },
              {
                merge: true
              }
            )
            .then(() => {
              console.log(
                "calulateUserScores(), game updated. Trying to write to results ..."
              );

              return calculateResults(gameId).then(() => resolve());
            })
            .catch(e => {
              console.error(
                "calulateUserScores(), unable to write user scores. ",
                e
              );

              reject(e);
            });

          return false;
        })
        .catch(error => {
          console.error(
            "calculateUserScores(), Unable to write user scores. ",
            error
          );
          return false;
        });
    });

    return resultsPromise;
  });
