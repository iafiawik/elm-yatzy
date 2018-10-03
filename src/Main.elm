module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, img, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Ordering exposing (Ordering)



---- MODEL ----


type alias Model =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , game : Game
    , currentValue : Int
    }


type Game
    = Initializing
    | Idle
    | Input { player : Player, box : Box }
    | Finished
    | ShowCountedValues
    | Error


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


init : ( Model, Cmd Msg )
init =
    ( { boxes =
            [ { id_ = "ones", friendlyName = "Ettor", boxType = Regular 1 }

            -- , { id_ = "twos", friendlyName = "Tvåor", boxType = Regular 2 }
            -- , { id_ = "threes", friendlyName = "Treor", boxType = Regular 3 }
            -- , { id_ = "fours", friendlyName = "Fyror", boxType = Regular 4 }
            -- , { id_ = "fives", friendlyName = "Femmor", boxType = Regular 5 }
            -- , { id_ = "sixes", friendlyName = "Sexor", boxType = Regular 6 }
            -- , { id_ = "one_pair", friendlyName = "Ett par", boxType = SameKind }
            -- , { id_ = "two_pars", friendlyName = "Två par", boxType = Combination }
            -- , { id_ = "three_of_a_kind", friendlyName = "Tretal", boxType = SameKind }
            -- , { id_ = "four_of_a_kind", friendlyName = "Fyrtal", boxType = SameKind }
            -- , { id_ = "small_straight", friendlyName = "Liten stege", boxType = Combination }
            -- , { id_ = "large_straight", friendlyName = "Stor stege", boxType = Combination }
            -- , { id_ = "full_house", friendlyName = "Kåk", boxType = Combination }
            -- , { id_ = "chance", friendlyName = "Chans", boxType = Combination }
            -- , { id_ = "yatzy", friendlyName = "Yatzy", boxType = SameKind }
            ]
      , players =
            [ { id_ = 1
              , name = "Adam"
              }
            , { id_ = 2, name = "Eva" }
            ]
      , values = []
      , game = Initializing
      , currentValue = 0
      }
    , Cmd.none
    )


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


sum : List number -> number
sum list =
    List.foldl (\a b -> a + b) 0 list


getValuesByPlayer : List Value -> Player -> List Value
getValuesByPlayer values player =
    List.filter (\v -> v.player == player) values


sortPLayers : List PlayerAndNumberOfValues -> List PlayerAndNumberOfValues
sortPLayers players =
    List.sortWith myOrdering players


myOrdering : Ordering PlayerAndNumberOfValues
myOrdering =
    Ordering.byField .numberOfValues
        |> Ordering.breakTiesWith (Ordering.byField (\record -> record.player.id_))



-- sortByValues a b =
--     case compare (Tuple.first b) (Tuple.first a) of
--         GT ->
--             LT
--
--         EQ ->
--             EQ
--
--         LT ->
--             GT


stateToString : Game -> String
stateToString state =
    case state of
        Initializing ->
            "Initializing"

        Idle ->
            "Idle"

        Input { player, box } ->
            "Input" ++ player.name ++ box.friendlyName

        Finished ->
            "Finished"

        ShowCountedValues ->
            "ShowCountedValues"

        Error ->
            "Error"



---- UPDATE ----


type Msg
    = Start
    | AddValue
    | ShowAddValue Player Box
    | InputValueChange String
    | CountValues


getCurrentPlayer : Model -> Maybe Player
getCurrentPlayer model =
    let
        players =
            List.map (\p -> { numberOfValues = List.length (getValuesByPlayer model.values p), playerId = p.id_, player = p }) model.players

        playersByNumberOfValues =
            sortPLayers players

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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        currentPlayerMaybe =
            getCurrentPlayer model
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
            case msg of
                Start ->
                    ( { model | game = Idle, currentValue = 0 }, Cmd.none )

                AddValue ->
                    case model.game of
                        Input { player, box } ->
                            let
                                newValue =
                                    { box = box
                                    , player = currentPlayer
                                    , value = model.currentValue
                                    }

                                newValues =
                                    newValue :: model.values
                            in
                            if List.length newValues == (List.length model.players * List.length model.boxes) then
                                ( { model
                                    | game = Finished
                                    , currentValue = 0
                                    , values = newValues
                                  }
                                , Cmd.none
                                )

                            else
                                ( { model
                                    | game = Idle
                                    , currentValue = 0
                                    , values = newValues
                                  }
                                , Cmd.none
                                )

                        _ ->
                            ( model, Cmd.none )

                InputValueChange value ->
                    ( { model | currentValue = String.toInt value |> Maybe.withDefault 0 }, Cmd.none )

                ShowAddValue player box ->
                    ( { model | game = Input { player = player, box = box } }, Cmd.none )

                CountValues ->
                    ( { model | game = ShowCountedValues }, Cmd.none )

        Nothing ->
            -- handle product not found here
            -- likely return the model unchanged
            -- or set an error message on the model
            ( { model | game = Error }, Cmd.none )



---- VIEW ----


renderBox : Box -> Html msg
renderBox box =
    span [] [ text <| "" ++ box.friendlyName ]


renderTable : Player -> Model -> Html Msg
renderTable player model =
    let
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
                                                        v.box == b && v.player == p
                                                    )
                                                    model.values
                                                )
                                    in
                                    case boxValue of
                                        Just value ->
                                            td [] [ text (String.fromInt value.value) ]

                                        Nothing ->
                                            if player == p then
                                                td [ class "active", onClick (ShowAddValue p b) ] [ text "" ]

                                            else
                                                td [] [ text "" ]
                                )
                                model.players
                    in
                    tr []
                        ([ td [] [ renderBox b ]
                         ]
                            ++ playerBoxes
                        )
                )
                model.boxes

        headers =
            List.map (\p -> th [] [ text (p.name ++ String.fromInt (List.length (getValuesByPlayer model.values p))) ]) model.players
    in
    div []
        [ text "hej"
        , table []
            ([ tr []
                ([ td []
                    [ text "" ]
                 ]
                    ++ headers
                )
             ]
                ++ boxItems
            )
        ]


view : Model -> Html Msg
view model =
    let
        currentPlayerMaybe =
            getCurrentPlayer model
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
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

                        Idle ->
                            div []
                                [ div [] [ renderTable currentPlayer model ]
                                ]

                        Input { player, box } ->
                            div []
                                [ div [] [ text player.name ]
                                , div [] [ inputDialog ]
                                , div [] [ renderTable currentPlayer model ]
                                ]

                        Finished ->
                            div []
                                [ div [] [ renderTable currentPlayer model ]
                                , button [ onClick CountValues ] [ text "Count" ]
                                ]

                        ShowCountedValues ->
                            div []
                                [ div [] [ renderTable currentPlayer model ]
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

        Nothing ->
            div [] [ text "No player found" ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
