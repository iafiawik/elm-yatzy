module Tests exposing (all)

import Expect
import Ordering exposing (Ordering)
import Test exposing (..)



-- Check out http://package.elm-lang.org/packages/elm-community/elm-test/latest to learn more about testing in Elm!


type BoxType
    = Regular Int
    | SameKind
    | Combination


type alias Box =
    { id_ : String, friendlyName : String, boxType : BoxType }


type alias Value =
    { box : Box
    , player : Player
    , value : Int
    }


type alias Player =
    { id_ : Int, name : String }


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    , playerId : Int
    }


getValuesByPlayer : List Value -> Player -> List Value
getValuesByPlayer values player =
    List.filter (\v -> v.player == player) values


sortPLayers : List PlayerAndNumberOfValues -> List PlayerAndNumberOfValues
sortPLayers players =
    List.sortWith myOrdering players


myOrdering : Ordering PlayerAndNumberOfValues
myOrdering =
    Ordering.byField .numberOfValues
        |> Ordering.breakTiesWith (Ordering.byField .playerId)


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

                    boxes =
                        [ { id_ = "ones", friendlyName = "Ettor", boxType = Regular 1 }
                        , { id_ = "twos", friendlyName = "Tvåor", boxType = Regular 2 }
                        , { id_ = "threes", friendlyName = "Treor", boxType = Regular 3 }
                        , { id_ = "fours", friendlyName = "Fyror", boxType = Regular 4 }
                        , { id_ = "fives", friendlyName = "Femmor", boxType = Regular 5 }
                        , { id_ = "sixes", friendlyName = "Sexor", boxType = Regular 6 }
                        , { id_ = "one_pair", friendlyName = "Ett par", boxType = SameKind }
                        , { id_ = "two_pars", friendlyName = "Två par", boxType = Combination }
                        , { id_ = "three_of_a_kind", friendlyName = "Tretal", boxType = SameKind }
                        , { id_ = "four_of_a_kind", friendlyName = "Fyrtal", boxType = SameKind }
                        , { id_ = "small_straight", friendlyName = "Liten stege", boxType = Combination }
                        , { id_ = "large_straight", friendlyName = "Stor stege", boxType = Combination }
                        , { id_ = "full_house", friendlyName = "Kåk", boxType = Combination }
                        , { id_ = "chance", friendlyName = "Chans", boxType = Combination }
                        , { id_ = "yatzy", friendlyName = "Yatzy", boxType = SameKind }
                        ]

                    values =
                        [ { box = { id_ = "ones", friendlyName = "Ettor", boxType = Regular 1 }
                          , player =
                                { id_ = 2
                                , name = "Eva"
                                }
                          , value = 2
                          }
                        , { box = { id_ = "twos", friendlyName = "Ettor", boxType = Regular 1 }
                          , player =
                                { id_ = 1
                                , name = "Adam"
                                }
                          , value = 2
                          }
                        , { box = { id_ = "threes", friendlyName = "Ettor", boxType = Regular 1 }
                          , player =
                                { id_ = 1
                                , name = "Adam"
                                }
                          , value = 2
                          }
                        ]

                    players =
                        List.map (\p -> { numberOfValues = List.length (getValuesByPlayer values p), playerId = p.id_, player = p }) modelPlayers

                    playersByNumberOfValues =
                        sortPLayers players

                    currentPlayerMaybe =
                        List.head playersByNumberOfValues

                    _ =
                        Debug.log "hej"
                in
                case currentPlayerMaybe of
                    Just currentPlayerComparable ->
                        let
                            currentPlayer =
                                currentPlayerComparable.player
                        in
                        Expect.equal "Eva" currentPlayer.name

                    Nothing ->
                        Expect.equal 2 1
        ]
