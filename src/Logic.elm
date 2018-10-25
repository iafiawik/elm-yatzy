module Logic exposing (areAllUsersFinished, getAcceptedValues, getBonusValue, getBoxes, getCurrentPlayer, getDefaultMarkedValue, getInteractiveBoxes, getNextValueToAnimate, getRoundHighscore, getTotalSum, getUpperSum, getValuesByPlayer, playerOrdering, sortPLayers, sortPlayersByOrder, sum)

import List.Extra exposing (find, findIndex, removeAt)
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Player exposing (Player)
import Model.Value exposing (Value)
import Models exposing (Model, PlayerAndNumberOfValues)
import Ordering exposing (Ordering)


getBoxes : List Box
getBoxes =
    [ { id = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 0 }
    , { id = "twos", friendlyName = "Tvåor", boxType = Regular 2, category = Upper, order = 1 }
    , { id = "threes", friendlyName = "Treor", boxType = Regular 3, category = Upper, order = 2 }
    , { id = "fours", friendlyName = "Fyror", boxType = Regular 4, category = Upper, order = 3 }
    , { id = "fives", friendlyName = "Femmor", boxType = Regular 5, category = Upper, order = 4 }
    , { id = "sixes", friendlyName = "Sexor", boxType = Regular 6, category = Upper, order = 5 }
    , { id = "bonus", friendlyName = "Bonus", boxType = Bonus, category = None, order = -1 }
    , { id = "upper_sum", friendlyName = "Övre summa", boxType = UpperSum, category = None, order = -1 }
    , { id = "one_pair", friendlyName = "Ett par", boxType = SameKind, category = Lower, order = 6 }
    , { id = "two_pairs", friendlyName = "Två par", boxType = Combination, category = Lower, order = 7 }
    , { id = "three_of_a_kind", friendlyName = "Tretal", boxType = SameKind, category = Lower, order = 8 }
    , { id = "four_of_a_kind", friendlyName = "Fyrtal", boxType = SameKind, category = Lower, order = 9 }
    , { id = "small_straight", friendlyName = "Liten stege", boxType = Combination, category = Lower, order = 10 }
    , { id = "large_straight", friendlyName = "Stor stege", boxType = Combination, category = Lower, order = 11 }
    , { id = "full_house", friendlyName = "Kåk", boxType = Combination, category = Lower, order = 12 }
    , { id = "chance", friendlyName = "Chans", boxType = Combination, category = Lower, order = 13 }
    , { id = "yatzy", friendlyName = "Yatzy", boxType = SameKind, category = Lower, order = 14 }
    , { id = "total_sum", friendlyName = "Summa", boxType = TotalSum, category = None, order = -1 }
    ]


getInteractiveBoxes : List Box
getInteractiveBoxes =
    List.filter (\box -> box.category /= None) getBoxes


getDefaultMarkedValue : Box -> Maybe Int
getDefaultMarkedValue box =
    let
        acceptedValues =
            getAcceptedValues box
    in
    if List.length (getAcceptedValues box) == 1 then
        List.head acceptedValues

    else
        Nothing


getRoundHighscore : List Player -> List Value -> List ( Player, Int )
getRoundHighscore players values =
    let
        playerValues =
            List.map (\player -> ( player, getTotalSum values player )) players

        sortedPlayers =
            sortTupleBySecond playerValues

        --
        -- _ =
        --     Debug.log "sortedPlayers" sortedPlayers
    in
    sortedPlayers


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

        -- _ =
        --     Debug.log "NextPlayer:" nextPlayerMaybe
    in
    case nextPlayerMaybe of
        Just nextPlayer ->
            let
                -- _ =
                --     Debug.log ("NextPlayer: " ++ nextPlayer.user.name)
                playerValues =
                    getValuesByPlayer values nextPlayer

                sortedPlayerValues =
                    List.sortBy (\v -> v.box.order) playerValues

                nextValueMaybe =
                    find
                        (\v -> v.counted == False)
                        sortedPlayerValues
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


sortTupleBySecond : List ( a, comparable ) -> List ( a, comparable )
sortTupleBySecond =
    (\f lst ->
        List.sortWith (\a b -> compare (f b) (f a)) lst
    )
        Tuple.second


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
    numberOfValues >= numberOfBoxes * numberOfPlayers


getAcceptedValues : Box -> List Int
getAcceptedValues box =
    if box.id == "ones" then
        List.map (\n -> n * 1) [ 1, 2, 3, 4, 5 ]

    else if box.id == "twos" then
        List.map (\n -> n * 2) [ 1, 2, 3, 4, 5 ]

    else if box.id == "threes" then
        List.map (\n -> n * 3) [ 1, 2, 3, 4, 5 ]

    else if box.id == "fours" then
        List.map (\n -> n * 4) [ 1, 2, 3, 4, 5 ]

    else if box.id == "fives" then
        List.map (\n -> n * 5) [ 1, 2, 3, 4, 5 ]

    else if box.id == "sixes" then
        List.map (\n -> n * 6) [ 1, 2, 3, 4, 5 ]

    else if box.id == "one_pair" then
        List.map (\n -> n * 2) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id == "two_pairs" then
        [ 6, 8, 10, 12, 14, 16, 18, 20, 22 ]

    else if box.id == "three_of_a_kind" then
        List.map (\n -> n * 3) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id == "four_of_a_kind" then
        List.map (\n -> n * 4) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id == "small_straight" then
        [ 15 ]

    else if box.id == "large_straight" then
        [ 20 ]

    else if box.id == "full_house" then
        [ 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28 ]

    else if box.id == "chance" then
        List.range 5 30

    else if box.id == "yatzy" then
        [ 50 ]

    else
        []
