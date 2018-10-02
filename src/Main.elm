module Main exposing (main)

import Browser
import Element as ElmUiElement exposing (Element, alignRight, el, rgb, row, text)
import Element.Background as Background
import Element.Border as Border
import Html exposing (Html, div, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


main =
    Browser.sandbox { init = init, update = update, view = view }


type alias Model =
    { players : List Player, boxes : List Box, state : State }


type BoxType
    = Regular Int
    | SameKind
    | Combination


type State
    = Normal
    | Input


type alias Box =
    { id_ : String, friendlyName : String, boxType : BoxType }


type alias Value =
    { boxId : String
    , value : Int
    }


type alias Player =
    { id_ : String, name : String, values : List Value }


init : Model
init =
    let
        players =
            [ { id_ = "1"
              , name = "Adam"
              , values =
                    [ { boxId = "ones", value = 1 }
                    , { boxId = "twos", value = 6 }
                    ]
              }
            , { id_ = "2", name = "Eva", values = [ { boxId = "ones", value = 4 }, { boxId = "twos", value = 2 } ] }
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
    , state = Normal
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
    = AddValue Player Box Value
    | ShowAddValue Player Box
    | UpdateCurrentPlayer Player
    | NextPlayer


update : Msg -> Model -> Model
update msg model =
    case msg of
        AddValue player box value ->
            model

        ShowAddValue player box ->
            { model | state = Input }

        UpdateCurrentPlayer player ->
            model

        NextPlayer ->
            model



-- VIEW


renderBox : Box -> Html msg
renderBox box =
    span [] [ text <| "" ++ box.friendlyName ]


renderTable : Model -> Html Msg
renderTable model =
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
                                                        v.boxId == b.id_
                                                    )
                                                    p.values
                                                )
                                    in
                                    case boxValue of
                                        Just value ->
                                            td [ cellStyle ] [ text (String.fromInt value.value) ]

                                        Nothing ->
                                            td [ cellStyle, onClick (ShowAddValue p b) ] [ text "" ]
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


view : Model -> Html Msg
view model =
    let
        _ =
            Debug.log "This will log model.state" model.state
    in
    div
        []
        [ div []
            []
        , div
            []
            [ renderTable model
            ]
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
