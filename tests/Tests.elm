module Tests exposing (all)

import Expect
import Logic exposing (..)
import Models exposing (Box, BoxCategory(..), BoxType(..), Player, PlayerAndNumberOfValues, Value)
import Ordering exposing (Ordering)
import Test exposing (..)



-- Check out http://package.elm-lang.org/packages/elm-community/elm-test/latest to learn more about testing in Elm!


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
                    modelPlayers =
                        [ { id_ = 1
                          , name = "Adam"
                          }
                        , { id_ = 2, name = "Eva" }
                        ]

                    modelValues =
                        [ { box = { id_ = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper }
                          , player =
                                { id_ = 2
                                , name = "Eva"
                                }
                          , value = 2
                          }
                        , { box = { id_ = "twos", friendlyName = "Ettor", boxType = Regular 1, category = Upper }
                          , player =
                                { id_ = 1
                                , name = "Adam"
                                }
                          , value = 2
                          }
                        , { box = { id_ = "threes", friendlyName = "Ettor", boxType = Regular 1, category = Upper }
                          , player =
                                { id_ = 1
                                , name = "Adam"
                                }
                          , value = 2
                          }
                        ]

                    currentPlayerMaybe =
                        getCurrentPlayer modelValues modelPlayers
                in
                case currentPlayerMaybe of
                    Just currentPlayer ->
                        Expect.equal currentPlayer.name "Eva"

                    Nothing ->
                        Expect.equal currentPlayerMaybe Nothing
        ]
