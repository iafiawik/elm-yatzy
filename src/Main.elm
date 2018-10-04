module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, img, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Logic exposing (..)
import Models exposing (Box, BoxCategory(..), BoxType(..), Game(..), Player, PlayerAndNumberOfValues, Value)



---- MODEL ----


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
      , game = Initializing
      , currentValue = 0
      }
    , Cmd.none
    )


stateToString : Game -> String
stateToString state =
    case state of
        Initializing ->
            "Initializing"

        Idle ->
            "Idle"

        Input { box } ->
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
                        Input { box } ->
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

                ShowAddValue box ->
                    ( { model | game = Input { box = box } }, Cmd.none )

                HideAddValue ->
                    ( { model
                        | game = Idle
                        , currentValue = 0
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


renderCell : Box -> Model -> Player -> Bool -> Html Msg
renderCell box model player isCurrentPlayer =
    let
        upperSum =
            getUpperSum model.values player

        totalSum =
            getTotalSum model.values player

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
            td [ class "inactive" ] [ text (String.fromInt value.value) ]

        Nothing ->
            if box.boxType == UpperSum then
                td [ class "inactive" ] [ text (String.fromInt upperSum) ]

            else if box.boxType == TotalSum then
                td [ class "inactive" ] [ text (String.fromInt totalSum) ]

            else if box.boxType == Bonus then
                td [ class "inactive" ] [ text (String.fromInt bonusValue) ]

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


view : Model -> Html Msg
view model =
    let
        currentPlayerMaybe =
            getCurrentPlayer model.values model.players
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
            let
                inputDialog =
                    div []
                        [ input [ type_ "number", onInput InputValueChange, value (String.fromInt model.currentValue) ] []
                        , button [ onClick AddValue ] [ text "Submit" ]
                        , button [ onClick HideAddValue ] [ text "Cancel" ]
                        ]

                content =
                    case model.game of
                        Initializing ->
                            div [] [ button [ onClick Start ] [ text "Start" ] ]

                        Idle ->
                            div []
                                [ div [] [ renderTable currentPlayer model False ]
                                ]

                        Input { box } ->
                            div []
                                [ div [] [ text currentPlayer.name ]
                                , div [] [ inputDialog ]
                                , div [] [ renderTable currentPlayer model False ]
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
                [ div [] [ text <| stateToString <| Debug.log "state:" model.game ]
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
