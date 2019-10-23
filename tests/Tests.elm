module Tests exposing (all)

import Expect
import List.Extra exposing (find, findIndex, removeAt)
import Logic exposing (..)
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Player exposing (Player)
import Model.Value exposing (Value)
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
                        { score = 22
                        , order = 0
                        , user =
                            { id = "1"
                            , name = "Adam"
                            , userName = "Adam"
                            }
                        }

                    eva =
                        { score = 23
                        , order = 1
                        , user =
                            { id = "2"
                            , name = "Eva"
                            , userName = "Eva"
                            }
                        }

                    ones =
                        { id = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 1 }

                    twos =
                        { id = "twos", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 2 }

                    threes =
                        { id = "threes", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 3 }

                    modelPlayers =
                        [ adam
                        , eva
                        ]

                    modelValues =
                        [ { id = "1"
                          , box = ones
                          , player = eva
                          , value = 2
                          , counted = False
                          , new = False
                          , dateCreated = 1
                          }
                        , { id = "2"
                          , box = twos
                          , player = adam
                          , value = 2
                          , counted = False
                          , new = False
                          , dateCreated = 1
                          }
                        , { id = "3"
                          , box = threes
                          , player = adam
                          , value = 2
                          , counted = False
                          , new = False
                          , dateCreated = 1
                          }
                        ]

                    currentPlayerMaybe =
                        getCurrentPlayer modelValues modelPlayers
                in
                case currentPlayerMaybe of
                    Just currentPlayer ->
                        Expect.all
                            [ Expect.equal currentPlayer.user.name
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
                        { score = 1
                        , order = 0
                        , user =
                            { id = "adam"
                            , name = "Adam"
                            , userName = "Adam"
                            }
                        }

                    eva =
                        { score = 2
                        , order = 1
                        , user =
                            { id = "eva"
                            , name = "Eva"
                            , userName = "Eva"
                            }
                        }

                    ones =
                        { id = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 1 }

                    twos =
                        { id = "twos", friendlyName = "Tvåor", boxType = Regular 1, category = Upper, order = 2 }

                    threes =
                        { id = "threes", friendlyName = "Treor", boxType = Regular 1, category = Upper, order = 3 }

                    modelPlayers =
                        [ adam
                        , eva
                        ]

                    modelValues =
                        [ { id = "1"
                          , box = ones
                          , player = eva
                          , value = 2
                          , counted = False
                          , new = False
                          , dateCreated = 1
                          }
                        , { id = "2"
                          , box = ones
                          , player = adam
                          , value = 2
                          , counted = False
                          , new = False
                          , dateCreated = 1
                          }
                        , { id = "3"
                          , box = twos
                          , player = adam
                          , value = 2
                          , counted = False
                          , new = False
                          , dateCreated = 1
                          }
                        ]

                    nextValueMaybe =
                        getNextValueToAnimate modelPlayers modelValues

                    _ =
                        Debug.log "NextPlayer:" nextValueMaybe
                in
                case nextValueMaybe of
                    Just nextValue ->
                        Expect.equal nextValue.player.user.id "adam"

                    Nothing ->
                        Expect.notEqual nextValueMaybe Nothing
        ]
