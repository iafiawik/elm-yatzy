module Main exposing (main)

import Browser
import Element as ElmUiElement exposing (Element, alignRight, el, rgb, row, text)
import Element.Background as Background
import Element.Border as Border
import Html exposing (Html, button, div, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


main =
    Browser.sandbox { init = init, update = update, view = view }


type alias Model =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , game : Game
    , currentValue : Int
    }


type BoxType
    = Regular Int
    | SameKind
    | Combination


type Game
    = Initializing
    | Idle { player : Player }
    | Input { player : Player, box : Box }
    | Error


type alias Box =
    { id_ : String, friendlyName : String, boxType : BoxType }


type alias Value =
    { boxId : String
    , playerId : String
    , value : Int
    }


type alias Player =
    { id_ : String, name : String }


init : Model
init =
    let
        players =
            [ { id_ = "1"
              , name = "Adam"
              }
            , { id_ = "2", name = "Eva" }
            ]
    in
    { boxes =
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
    , players = players
    , values = [ { boxId = "ones", playerId = "1", value = 1 } ]
    , game = Initializing
    , currentValue = 0
    }


validate : Box -> Int -> Bool
validate box value =
    if box.id_ == "ones" then
        List.any (\v -> v == value) (getAcceptedValues box)

    else if box.id_ == "twos" then
        List.any (\v -> v == value) [ 2, 4, 6, 8, 10 ]

    else if box.id_ == "threes" then
        List.any (\v -> v == value) [ 3, 6, 9, 12, 15 ]

    else if box.id_ == "fours" then
        List.any (\v -> v == value) [ 4, 8, 12, 16, 20 ]

    else if box.id_ == "fives" then
        List.any (\v -> v == value) [ 5, 10, 15, 20, 25 ]

    else if box.id_ == "sixes" then
        List.any (\v -> v == value) [ 6, 12, 18, 24, 30 ]

    else if box.id_ == "one_pair" then
        List.any (\v -> v == value) (List.map (\n -> n * 2) [ 1, 2, 3, 4, 5, 6 ])

    else
        True


getAcceptedValues : Box -> List Int
getAcceptedValues box =
    if box.id_ == "ones" then
        [ 1, 2, 3, 4, 5 ]

    else
        []


type Msg
    = Start
    | AddValue
    | ShowAddValue Player Box
    | InputValueChange String
    | UpdateCurrentPlayer Player
    | NextPlayer



-- getFirstPlayer : List Player -> a
-- getFirstPlayer players =
--     let
--         currentPlayerMaybe =
--             List.head players
--     in
--     case currentPlayerMaybe of
--         Just currentPlayer ->
--             -- do your logic here
--             -- probably set or change some value on the model
--             currentPlayer
--
--         Nothing ->
--             -- handle product not found here
--             -- likely return the model unchanged
--             -- or set an error message on the model
--             Nothing


update : Msg -> Model -> Model
update msg model =
    let
        players =
            List.map (\p -> ( getValuesByPlayer model.values p, p )) model.players

        playersByNumberOfValues =
            List.sortWith sortByValues players

        currentPlayerMaybe =
            List.head playersByNumberOfValues
    in
    case currentPlayerMaybe of
        Just currentPlayerComparable ->
            let
                currentPlayer =
                    Tuple.second currentPlayerComparable
            in
            case msg of
                Start ->
                    { model | game = Idle { player = currentPlayer }, currentValue = 0 }

                AddValue ->
                    case model.game of
                        Input { player, box } ->
                            let
                                _ =
                                    Debug.log "current user is" player.name
                            in
                            { model | game = Idle { player = currentPlayer }, currentValue = 0 }

                        _ ->
                            model

                InputValueChange value ->
                    { model | currentValue = String.toInt value |> Maybe.withDefault 0 }

                ShowAddValue player box ->
                    { model | game = Input { player = player, box = box } }

                UpdateCurrentPlayer player ->
                    model

                NextPlayer ->
                    model

        Nothing ->
            -- handle product not found here
            -- likely return the model unchanged
            -- or set an error message on the model
            { model | game = Error }


sum : List number -> number
sum list =
    List.foldl (\a b -> a + b) 0 list



-- sortPlayersByValues : List ( comparable, b ) -> List ( comparable, b )
-- sortPlayersByValues =
--     List.sortBy Tuple.first
--


getValuesByPlayer : List Value -> Player -> List Value
getValuesByPlayer values player =
    List.filter (\v -> v.playerId == player.id_) values


sortByValues a b =
    let
        playerA =
            List.length (Tuple.first a)

        playerB =
            List.length (Tuple.first b)
    in
    case compare playerA playerB of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT



-- getCurrentPlayer : Model -> Player
-- getCurrentPlayer model =
--     let
--         players =
--             List.map (\p -> ( getValuesByPlayer model.values p, p )) model.players
--
--         playersByNumberOfValues =
--             List.sortWith sortByValues players
--
--         currentPlayerMaybe =
--             List.head playersByNumberOfValues
--     in
--     case currentPlayerMaybe of
--         Just currentPlayer ->
--             Tuple.second currentPlayer
--
--
-- VIEW


renderBox : Box -> Html msg
renderBox box =
    span [] [ text <| "" ++ box.friendlyName ]


renderTable : Player -> Model -> Html Msg
renderTable player model =
    let
        cellStyle =
            style "border" "1px solid black"

        boxItems =
            List.map
                (\b ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    let
                                        boxValue =
                                            List.head
                                                (List.filter
                                                    (\v ->
                                                        v.boxId == b.id_ && v.playerId == p.id_
                                                    )
                                                    model.values
                                                )
                                    in
                                    case boxValue of
                                        Just value ->
                                            td [ cellStyle ] [ text (String.fromInt value.value) ]

                                        Nothing ->
                                            if player == p then
                                                td [ cellStyle, onClick (ShowAddValue p b) ] [ text "" ]

                                            else
                                                td [ cellStyle ] [ text "" ]
                                )
                                model.players
                    in
                    tr []
                        ([ td [ cellStyle ] [ renderBox b ]
                         ]
                            ++ playerBoxes
                        )
                )
                model.boxes

        headers =
            List.map (\p -> th [ cellStyle ] [ text p.name ]) model.players
    in
    table []
        ([ tr []
            ([ td [ cellStyle ]
                [ text "" ]
             ]
                ++ headers
            )
         ]
            ++ boxItems
        )


stateToString : Game -> String
stateToString state =
    case state of
        Initializing ->
            "Initializing"

        Idle { player } ->
            "Idle"

        Input { player, box } ->
            "Input" ++ player.name ++ box.friendlyName

        Error ->
            "Error"


view : Model -> Html Msg
view model =
    let
        inputDialog =
            div []
                [ input [ type_ "number", onInput InputValueChange, value (String.fromInt model.currentValue) ] []
                , button [ onClick AddValue ] [ text "Submit" ]
                ]

        content =
            case model.game of
                Initializing ->
                    div [] [ button [ onClick Start ] [ text "Start" ] ]

                Idle { player } ->
                    div []
                        [ div [] [ text player.name ]
                        , div [] [ renderTable player model ]
                        ]

                Input { player, box } ->
                    div []
                        [ div [] [ text player.name ]
                        , div [] [ inputDialog ]
                        , div [] [ renderTable player model ]
                        ]

                Error ->
                    div [] [ text "An error occured" ]
    in
    div
        []
        [ div [] [ text <| stateToString <| Debug.log "state:" model.game ]
        , div [] [ text (String.fromInt model.currentValue) ]
        , div [] [ content ]
        ]



-- boxes.map((b) => <td>{renderBox(b)}</td>)
-- R.map((b) => <td>{renderBox(b)</td>}, boxes);
--
-- view2 : Model -> Html Msg
-- view2 model =
--     let
--         myStyle =
--             style "border" "1px solid blue"
--     in
--     div []
--         [ div [] []
--         , div []
--             [ text "hej" ]
--         , div
--             []
--             [ table []
--                 [ tr [ myStyle ] [ th [] [ text "Ett" ], tableCell "Hej" ]
--                 , tr [ myStyle ] [ tableCell "Ett", tableCell "Hej" ]
--                 , tr [ myStyle ] [ tableCell "Två" ]
--                 , tr [ myStyle ] [ tableCell "Tre" ]
--                 , tr [ myStyle ] [ tableCell "Fyror" ]
--                 , tr [ myStyle ] [ tableCell "Femmor" ]
--                 , tr [ myStyle ] [ tableCell "Sexor" ]
--                 , tr [ myStyle ] [ tableCell "Summa" ]
--                 , tr [ myStyle ] [ tableCell "Bonus" ]
--                 , tr [ myStyle ] [ tableCell "1 par" ]
--                 , tr [ myStyle ] [ tableCell "2 par" ]
--                 , tr [ myStyle ] [ tableCell "Tretal" ]
--                 , tr [ myStyle ] [ tableCell "Fyrtal" ]
--                 , tr [ myStyle ] [ tableCell "Liten stege" ]
--                 , tr [ myStyle ] [ tableCell "Stor stege" ]
--                 , tr [ myStyle ] [ tableCell "Kåk" ]
--                 , tr [ myStyle ] [ tableCell "Chans" ]
--                 , tr [ myStyle ] [ tableCell "Yatzy" ]
--                 ]
--             ]
--         ]
--
--
-- tableCell : String -> Html msg
-- tableCell t =
--     let
--         myStyle =
--             style "border" "1px solid blue"
--     in
--     td [ myStyle ] [ text t ]
