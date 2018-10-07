module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed exposing (..)
import Logic exposing (..)
import Models exposing (Box, BoxCategory(..), BoxType(..), Player, PlayerAndNumberOfValues, Value)



---- MODEL ----


type Game
    = Initializing
    | AddPlayers
    | Idle
    | Input Box
    | Finished
    | ShowCountedValues
    | Error


type alias Model =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , game : Game
    , currentValue : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { boxes = getBoxes
      , players =
            [ { id_ = 1
              , name = "Sophie"
              }
            , { id_ = 2
              , name = "Hugo"
              }
            ]
      , values = []
      , game = AddPlayers
      , currentValue = -1
      }
    , Cmd.none
    )


stateToString : Game -> String
stateToString state =
    case state of
        Initializing ->
            "Initializing"

        AddPlayers ->
            "AddPlayers"

        Idle ->
            "Idle"

        Input box ->
            "Input" ++ box.friendlyName

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
    | ShowAddValue Box
    | ValueMarked Int
    | HideAddValue
    | InputValueChange String
    | CountValues


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        currentPlayerMaybe =
            getCurrentPlayer model.values model.players
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
            case msg of
                Start ->
                    ( { model | game = Idle, currentValue = 0 }, Cmd.none )

                AddValue ->
                    case model.game of
                        Input box ->
                            let
                                newValue =
                                    { box = box
                                    , player = currentPlayer
                                    , value = model.currentValue
                                    }

                                newValues =
                                    newValue :: model.values
                            in
                            if areAllUsersFinished newValues model.players model.boxes then
                                ( { model
                                    | game = Finished
                                    , currentValue = -1
                                    , values = newValues
                                  }
                                , Cmd.none
                                )

                            else
                                ( { model
                                    | game = Idle
                                    , currentValue = -1
                                    , values = newValues
                                  }
                                , Cmd.none
                                )

                        _ ->
                            ( model, Cmd.none )

                ValueMarked value ->
                    ( { model | currentValue = value }, Cmd.none )

                InputValueChange value ->
                    ( { model | currentValue = String.toInt value |> Maybe.withDefault 0 }, Cmd.none )

                ShowAddValue box ->
                    let
                        markedValueMaybe =
                            getMarkedValue model box
                    in
                    case markedValueMaybe of
                        Just markedValue ->
                            ( { model | game = Input box, currentValue = markedValue }, Cmd.none )

                        Nothing ->
                            ( { model | game = Input box }, Cmd.none )

                HideAddValue ->
                    ( { model
                        | game = Idle
                        , currentValue = -1
                      }
                    , Cmd.none
                    )

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


getUpperSumText : List Box -> List Value -> Player -> Html Msg
getUpperSumText boxes values player =
    let
        playerValues =
            getValuesByPlayer values player

        upperBoxes =
            List.filter (\b -> b.category == Upper) boxes

        upperValues =
            List.filter (\v -> v.box.category == Upper) playerValues

        totalSum =
            sum (List.map (\v -> v.value) upperValues)

        bonusValue =
            getBonusValue values player
    in
    case List.length upperBoxes == List.length upperValues || List.length upperValues == 0 || bonusValue > 0 of
        True ->
            if bonusValue > 0 then
                span [ class "upper-sum bonus" ] [ text (String.fromInt bonusValue) ]

            else
                span [ class "upper-sum" ] [ text "-" ]

        False ->
            let
                totalDelta =
                    sum
                        (List.map
                            (\v ->
                                case v.box.boxType of
                                    Regular numberValue ->
                                        v.value - numberValue * 3

                                    _ ->
                                        0
                            )
                            upperValues
                        )
            in
            if totalDelta == 0 then
                span [ class "upper-sum neutral" ] [ text "+/-0" ]

            else if totalDelta > 0 then
                span [ class "upper-sum positive" ] [ text ("+" ++ String.fromInt totalDelta) ]

            else
                span [ class "upper-sum negative" ] [ text ("" ++ String.fromInt totalDelta) ]


renderCell : Box -> Model -> Player -> Bool -> Html Msg
renderCell box model player isCurrentPlayer =
    let
        upperSumText =
            getUpperSumText model.boxes model.values player

        totalSum =
            getTotalSum model.values player

        upperSum =
            getUpperSum model.values player

        bonusValue =
            getBonusValue model.values player

        boxValue =
            List.head
                (List.filter
                    (\v ->
                        v.box == box && v.player == player
                    )
                    model.values
                )
    in
    case boxValue of
        Just value ->
            td [ class "inactive" ] [ text (getValueText value.value) ]

        Nothing ->
            if box.boxType == UpperSum then
                td [ class "inactive" ] [ text (String.fromInt upperSum) ]

            else if box.boxType == TotalSum then
                td [ class "inactive" ] [ text (String.fromInt totalSum) ]

            else if box.boxType == Bonus then
                td [ classList [ ( "inactive bonus", True ), ( "animated bonus-cell", bonusValue > 0 ) ] ] [ upperSumText ]

            else if isCurrentPlayer then
                if box.category == None then
                    td [ class "active" ] [ text "" ]

                else
                    td [ class "active", onClick (ShowAddValue box) ] [ text "" ]

            else
                td [ class "inactive" ] [ text "" ]


renderTable : Player -> Model -> Bool -> Html Msg
renderTable currentPlayer model showCountedValues =
    let
        boxItems =
            List.map
                (\box ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    renderCell box model p (p == currentPlayer)
                                )
                                model.players
                    in
                    tr []
                        ([ td [ class "box" ] [ renderBox box ]
                         ]
                            ++ playerBoxes
                        )
                )
                model.boxes

        headers =
            List.map (\p -> th [] [ text p.name ]) model.players
    in
    div [ class "table-wrapper" ]
        [ table []
            ([ tr []
                ([ th []
                    [ text "" ]
                 ]
                    ++ headers
                )
             ]
                ++ boxItems
            )
        ]


getMarkedValue : Model -> Box -> Maybe Int
getMarkedValue model box =
    let
        acceptedValues =
            getAcceptedValues box
    in
    if List.length (getAcceptedValues box) == 1 then
        List.head acceptedValues

    else
        Nothing


inputDialogButton : Bool -> Int -> String -> String -> Html Msg
inputDialogButton isMarked value buttonText class =
    button
        [ classList
            [ ( "input-dialog-number-button button", True )
            , ( "marked", isMarked )
            , ( class, True )
            ]
        , onClick (ValueMarked value)
        ]
        [ text buttonText ]


inputDialog : Model -> Box -> Player -> Html Msg
inputDialog model box currentPlayer =
    let
        acceptedValues =
            getAcceptedValues box

        acceptedValuesButtons =
            List.map
                (\v ->
                    inputDialogButton (model.currentValue == v) v (String.fromInt v) "hej"
                )
                acceptedValues
    in
    div [ class "input-dialog-wrapper" ]
        [ div [ class "input-dialog-background animated fadeIn", onClick HideAddValue ] []
        , div [ class "input-dialog animated jackInTheBox" ]
            [ div []
                [ button [ class "input-dialog-cancel-button button", onClick HideAddValue ] [ text "X" ]
                , h1 [] [ text box.friendlyName ]
                , h2 [] [ text currentPlayer.name ]
                ]
            , div [ classList [ ( "input-dialog-number-buttons", True ), ( "" ++ box.id_, True ) ] ]
                (acceptedValuesButtons ++ [ inputDialogButton (model.currentValue == 0) 0 ":(" "skip-button" ])
            , div []
                [ input [ class "input-dialog-input-field", type_ "number", onInput InputValueChange, value (String.fromInt model.currentValue) ] []
                ]
            , button [ classList [ ( "input-dialog-submit-button button", True ), ( "enabled animated pulse infinite", model.currentValue >= 0 ) ], disabled (model.currentValue < 0), onClick AddValue ] [ text "Spara" ]
            ]
        ]


getValueText : Int -> String
getValueText value =
    case value of
        0 ->
            "-"

        _ ->
            String.fromInt value


addPlayers : List Player -> Html Msg
addPlayers players =
    div [ class "add-players-dialog-wrapper" ]
        [ div [ class "add-players-dialog-background animated fadeIn", onClick HideAddValue ] []
        , div [ class "add-players-dialog animated jackInTheBox" ] []
        ]


view : Model -> Html Msg
view model =
    let
        currentPlayerMaybe =
            getCurrentPlayer model.values model.players
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
            let
                content =
                    case model.game of
                        Initializing ->
                            div [] [ button [ onClick Start ] [ text "Start" ] ]

                        AddPlayers ->
                            div [] [ addPlayers model.players ]

                        Idle ->
                            div []
                                [ div [] [ renderTable currentPlayer model False ]
                                ]

                        Input box ->
                            div []
                                [ div [] [ renderTable currentPlayer model False ]
                                , div [] [ inputDialog model box currentPlayer ]
                                ]

                        Finished ->
                            div []
                                [ div [] [ renderTable currentPlayer model False ]
                                , button [ onClick CountValues ] [ text "Count" ]
                                ]

                        ShowCountedValues ->
                            div []
                                [ div [] [ renderTable currentPlayer model True ]
                                ]

                        Error ->
                            div [] [ text "An error occured" ]
            in
            div
                []
                [ div [] [ content ]
                , div [] [ text <| stateToString <| Debug.log "state:" model.game ]
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
