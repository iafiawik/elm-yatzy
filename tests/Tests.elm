module Tests exposing (all)

import Expect
import List.Extra exposing (find, findIndex, removeAt)
import Logic exposing (..)
import Models exposing (Box, BoxCategory(..), BoxType(..), Player, PlayerAndNumberOfValues, Value)
import Ordering exposing (Ordering)
import Test exposing (..)



-- Check out http://package.elm-lang.org/packages/elm-community/elm-test/latest to learn more about testing in Elm!


testCount : Test
testCount =
    describe "Test count animation"
        []


all : Test
all =
    describe "A Test Suite"
        [ test "Addition" <|
            \_ ->
                Expect.equal 10 (3 + 7)
        , test "String.left" <|
            \_ ->
                Expect.equal "a" (String.left 1 "abcdefg")
        , test "Sorting" <|
            \n ->
                let
                    adam =
                        { id_ = "1", order = 0, name = "Adam" }

                    eva =
                        { id_ = "2", order = 1, name = "Eva" }

                    ones =
                        { id_ = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper }

                    twos =
                        { id_ = "twos", friendlyName = "Ettor", boxType = Regular 1, category = Upper }

                    threes =
                        { id_ = "threes", friendlyName = "Ettor", boxType = Regular 1, category = Upper }

                    modelPlayers =
                        [ adam
                        , eva
                        ]

                    modelValues =
                        [ { box = ones
                          , player = eva
                          , value = 2
                          , counted = False
                          }
                        , { box = twos
                          , player = adam
                          , value = 2
                          , counted = False
                          }
                        , { box = threes
                          , player = adam
                          , value = 2
                          , counted = False
                          }
                        ]

                    currentPlayerMaybe =
                        getCurrentPlayer modelValues modelPlayers
                in
                case currentPlayerMaybe of
                    Just currentPlayer ->
                        Expect.all
                            [ Expect.equal currentPlayer.name
                            ]
                            "Eva"

                    Nothing ->
                        Expect.equal currentPlayerMaybe
                            Nothing
        , test
            "Next value to animate"
          <|
            \_ ->
                let
                    adam =
                        { id_ = "adam", order = 0, name = "Adam" }

                    eva =
                        { id_ = "eva", order = 1, name = "Eva" }

                    ones =
                        { id_ = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper }

                    twos =
                        { id_ = "twos", friendlyName = "Tvåor", boxType = Regular 1, category = Upper }

                    threes =
                        { id_ = "threes", friendlyName = "Treor", boxType = Regular 1, category = Upper }

                    modelPlayers =
                        [ adam
                        , eva
                        ]

                    modelValues =
                        [ { box = ones
                          , player = eva
                          , value = 2
                          , counted = False
                          }
                        , { box = ones
                          , player = adam
                          , value = 2
                          , counted = False
                          }
                        , { box = twos
                          , player = adam
                          , value = 2
                          , counted = False
                          }
                        ]

                    nextValueMaybe =
                        getNextValueToAnimate modelPlayers modelValues

                    _ =
                        Debug.log "NextPlayer:" nextValueMaybe
                in
                case nextValueMaybe of
                    Just nextValue ->
                        Expect.equal nextValue.player.id_ "adam"

                    Nothing ->
                        Expect.notEqual nextValueMaybe Nothing
        ]
