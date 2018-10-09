module Logic exposing (areAllUsersFinished, getAcceptedValues, getBonusValue, getBoxes, getCurrentPlayer, getNextValueToAnimate, getTotalSum, getUpperSum, getValuesByPlayer, playerOrdering, sortPLayers, sortPlayersByOrder, sum)

import List.Extra exposing (find, findIndex, removeAt)
import Models exposing (Box, BoxCategory(..), BoxType(..), Player, PlayerAndNumberOfValues, Value)
import Ordering exposing (Ordering)


getBoxes =
    [ { id_ = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper }
    , { id_ = "twos", friendlyName = "Tvåor", boxType = Regular 2, category = Upper }
    , { id_ = "threes", friendlyName = "Treor", boxType = Regular 3, category = Upper }
    , { id_ = "fours", friendlyName = "Fyror", boxType = Regular 4, category = Upper }
    , { id_ = "fives", friendlyName = "Femmor", boxType = Regular 5, category = Upper }
    , { id_ = "sixes", friendlyName = "Sexor", boxType = Regular 6, category = Upper }
    , { id_ = "bonus", friendlyName = "Bonus", boxType = Bonus, category = None }
    , { id_ = "upper_sum", friendlyName = "Övre summa", boxType = UpperSum, category = None }
    , { id_ = "one_pair", friendlyName = "Ett par", boxType = SameKind, category = Lower }
    , { id_ = "two_pairs", friendlyName = "Två par", boxType = Combination, category = Lower }
    , { id_ = "three_of_a_kind", friendlyName = "Tretal", boxType = SameKind, category = Lower }
    , { id_ = "four_of_a_kind", friendlyName = "Fyrtal", boxType = SameKind, category = Lower }
    , { id_ = "small_straight", friendlyName = "Liten stege", boxType = Combination, category = Lower }
    , { id_ = "large_straight", friendlyName = "Stor stege", boxType = Combination, category = Lower }
    , { id_ = "full_house", friendlyName = "Kåk", boxType = Combination, category = Lower }
    , { id_ = "chance", friendlyName = "Chans", boxType = Combination, category = Lower }
    , { id_ = "yatzy", friendlyName = "Yatzy", boxType = SameKind, category = Lower }
    , { id_ = "total_sum", friendlyName = "Summa", boxType = TotalSum, category = None }
    ]


getNextValueToAnimate : List Player -> List Value -> Maybe Value
getNextValueToAnimate players values =
    let
        allPlayers =
            sortPlayersByOrder players

        nextPlayerMaybe =
            find
                (\player ->
                    let
                        playerValues =
                            getValuesByPlayer values player
                    in
                    List.any (\v -> v.counted == False) playerValues
                )
                players

        _ =
            Debug.log "NextPlayer:" nextPlayerMaybe
    in
    case nextPlayerMaybe of
        Just nextPlayer ->
            let
                _ =
                    Debug.log ("NextPlayer: " ++ nextPlayer.name)

                playerValues =
                    getValuesByPlayer values nextPlayer

                nextValueMaybe =
                    find
                        (\v -> v.counted == False)
                        playerValues
            in
            case nextValueMaybe of
                Just nextValue ->
                    Just nextValue

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


getCurrentPlayer : List Value -> List Player -> Maybe Player
getCurrentPlayer values players =
    let
        sortablePlayers =
            List.map (\p -> { numberOfValues = List.length (getValuesByPlayer values p), player = p }) players

        playersByNumberOfValues =
            sortPLayers sortablePlayers

        currentPlayerMaybe =
            List.head playersByNumberOfValues
    in
    -- Maybe.map .player currentPlayerMaybe
    case currentPlayerMaybe of
        Just currentPlayerComparable ->
            let
                currentPlayer =
                    currentPlayerComparable.player
            in
            Just currentPlayer

        Nothing ->
            Nothing


getValuesByPlayer : List Value -> Player -> List Value
getValuesByPlayer values player =
    List.filter (\v -> v.player == player) values


sortPlayersByOrder : List Player -> List Player
sortPlayersByOrder players =
    List.sortBy .order players


sortPLayers : List PlayerAndNumberOfValues -> List PlayerAndNumberOfValues
sortPLayers players =
    List.sortWith playerOrdering players


playerOrdering : Ordering PlayerAndNumberOfValues
playerOrdering =
    Ordering.byField .numberOfValues
        |> Ordering.breakTiesWith (Ordering.byField (.player >> .order))


sum : List number -> number
sum list =
    List.foldl (\a b -> a + b) 0 list


getUpperSum : List Value -> Player -> Int
getUpperSum values player =
    let
        playerValues =
            getValuesByPlayer values player

        upperValues =
            List.filter (\v -> v.box.category == Upper) playerValues
    in
    sum (List.map (\v -> v.value) upperValues)


getTotalSum : List Value -> Player -> Int
getTotalSum values player =
    let
        playerValues =
            getValuesByPlayer values player

        countedValues =
            List.filter (\v -> v.counted == True) playerValues

        totalSum =
            sum (List.map (\v -> v.value) countedValues)

        bonusValue =
            getBonusValue values player
    in
    totalSum + bonusValue


getBonusValue : List Value -> Player -> Int
getBonusValue values player =
    let
        upperSum =
            getUpperSum values player
    in
    if upperSum >= 63 then
        50

    else
        0


areAllUsersFinished : List Value -> List Player -> List Box -> Bool
areAllUsersFinished values players boxes =
    let
        numberOfBoxes =
            List.length (List.filter (\b -> b.category /= None) boxes)

        numberOfValues =
            List.length values

        numberOfPlayers =
            List.length players
    in
    numberOfValues == numberOfBoxes * numberOfPlayers


getAcceptedValues : Box -> List Int
getAcceptedValues box =
    if box.id_ == "ones" then
        List.map (\n -> n * 1) [ 1, 2, 3, 4, 5 ]

    else if box.id_ == "twos" then
        List.map (\n -> n * 2) [ 1, 2, 3, 4, 5 ]

    else if box.id_ == "threes" then
        List.map (\n -> n * 3) [ 1, 2, 3, 4, 5 ]

    else if box.id_ == "fours" then
        List.map (\n -> n * 4) [ 1, 2, 3, 4, 5 ]

    else if box.id_ == "fives" then
        List.map (\n -> n * 5) [ 1, 2, 3, 4, 5 ]

    else if box.id_ == "sixes" then
        List.map (\n -> n * 6) [ 1, 2, 3, 4, 5 ]

    else if box.id_ == "one_pair" then
        List.map (\n -> n * 2) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id_ == "two_pairs" then
        [ 6, 8, 10, 12, 14, 16, 18, 20, 22 ]

    else if box.id_ == "three_of_a_kind" then
        List.map (\n -> n * 3) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id_ == "four_of_a_kind" then
        List.map (\n -> n * 4) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id_ == "small_straight" then
        [ 15 ]

    else if box.id_ == "large_straight" then
        [ 20 ]

    else if box.id_ == "full_house" then
        [ 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28 ]

    else if box.id_ == "chance" then
        List.range 5 30

    else if box.id_ == "yatzy" then
        [ 50 ]

    else
        []
