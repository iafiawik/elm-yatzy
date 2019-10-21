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
                year: new Date(game.dateCreated).getFullYear()
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
            user.score = calculateTotalScore(
              values.filter(value => value.userId === user.userId)
            );
          });

          console.log("calulateUserScores(), all users updated.");

          change.after.ref
            .set(
              {
                counted: true,
                users: users
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
            e
          );
          return false;
        });
    });

    return resultsPromise;

  });
