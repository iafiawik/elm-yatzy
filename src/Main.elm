module Main exposing (init, main, update, view)

import Browser
import Browser.Dom exposing (getViewport)
import Debug
import Html exposing (Html, button, div, h1, h2, img, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode exposing (Decoder, field, int, map3, string)
import Json.Encode as E
import List.Extra exposing (find, findIndex, getAt, removeAt)
import Logic exposing (..)
import Model.User exposing (usersDecoder)
import Models exposing (Box, BoxCategory(..), BoxType(..), Error(..), Game(..), Model, Msg(..), Player, PlayerAndNumberOfValues, Value)
import Random exposing (Seed, initialSeed, step)
import Task
import Time
import Uuid
import Views.AddRemovePlayers exposing (addRemovePlayers)
import Views.GameFinished exposing (gameFinished)
import Views.Highscore exposing (highscore)
import Views.ScoreCard exposing (scoreCard)
import Views.ScoreDialog exposing (scoreDialog)


errorToHtml : Json.Decode.Error -> String
errorToHtml error =
    "Error in decoder: " ++ Json.Decode.errorToString error



---- MODEL ----


type alias Flags =
    { users : Json.Decode.Value
    , random : Int
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        currentSeed =
            initialSeed flags.random

        ( newUuid, newSeed ) =
            step Uuid.uuidGenerator currentSeed

        usersMaybe =
            Json.Decode.decodeValue usersDecoder flags.users

        _ =
            Debug.log "flags.users" flags
    in
    case usersMaybe of
        Err err ->
            let
                _ =
                    Debug.log "" (errorToHtml err)
            in
            ( { game = Initializing
              , users = []
              , values = []
              , players = []
              , boxes = []
              , countedPlayers = []
              , countedValues = []
              , currentValue = -1
              , currentNewPlayerName = ""
              , currentSeed = newSeed
              , currentUuid = Just newUuid
              , error = Just (UnableToDecodeUsers (errorToHtml err))
              }
            , Cmd.none
            )

        Ok users ->
            let
                boxes =
                    getBoxes

                valueBoxes =
                    List.filter (\b -> b.id_ /= "yatzy" && b.category /= None) boxes

                sophie =
                    { id_ = getUniqueId currentSeed ++ "_sophie", order = 0, name = "Sophie" }

                hugo =
                    { id_ = getUniqueId currentSeed ++ "_hugo", order = 1, name = "Hugo" }

                phoenix =
                    { id_ = getUniqueId currentSeed ++ "_phoenix", order = 0, name = "Phoenix" }

                louise =
                    { id_ = getUniqueId currentSeed ++ "_louise", order = 1, name = "Louise" }
            in
            ( { boxes = boxes
              , players =
                    [ sophie
                    , hugo
                    , phoenix
                    , louise
                    ]
              , values =
                    List.concat
                        [ List.map
                            (\b ->
                                { box = b
                                , player = sophie
                                , value = getAt 3 (getAcceptedValues b) |> Maybe.withDefault 0
                                , counted = False
                                }
                            )
                            valueBoxes
                        , List.map
                            (\b ->
                                { box = b
                                , player = hugo
                                , value = getAt 2 (getAcceptedValues b) |> Maybe.withDefault 0
                                , counted = False
                                }
                            )
                            valueBoxes
                        , List.map
                            (\b ->
                                { box = b
                                , player = phoenix
                                , value = getAt 2 (getAcceptedValues b) |> Maybe.withDefault 0
                                , counted = False
                                }
                            )
                            valueBoxes
                        , List.map
                            (\b ->
                                { box = b
                                , player = louise
                                , value = getAt 2 (getAcceptedValues b) |> Maybe.withDefault 0
                                , counted = False
                                }
                            )
                            valueBoxes
                        ]
              , game = ShowAddRemovePlayers
              , users = []
              , countedPlayers = []
              , countedValues = []
              , currentValue = -1
              , currentNewPlayerName = ""
              , currentSeed = newSeed
              , currentUuid = Just newUuid
              , error = Nothing
              }
            , Cmd.none
            )


getUniqueId currentSeed =
    Uuid.toString (Tuple.first (step Uuid.uuidGenerator currentSeed))


stateToString : Game -> String
stateToString state =
    case state of
        Initializing ->
            "initializing"

        ShowAddRemovePlayers ->
            "add-players"

        Idle ->
            "idle"

        Input box isEdit ->
            "input"

        Finished ->
            "finished"

        ShowCountedValues ->
            "show-counted-values"

        ShowResults ->
            "show-results"


errorToString : Error -> String
errorToString error =
    case error of
        UnableToDecodeUsers message ->
            "Unable to decode users from the database. Can not to continue without users."

        NoCurrentPlayer ->
            "No current player found. Unable to proceed from this state."



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "state2:" msg

        currentPlayerMaybe =
            getCurrentPlayer model.values model.players
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
            case msg of
                AddRemovePlayers ->
                    ( { model | game = ShowAddRemovePlayers }, Cmd.none )

                AddPlayer ->
                    let
                        ( newUuid, newSeed ) =
                            step Uuid.uuidGenerator model.currentSeed

                        newPlayer =
                            { id_ = getUniqueId model.currentSeed, order = List.length model.players, name = model.currentNewPlayerName }

                        newPlayers =
                            sortPlayersByOrder (newPlayer :: model.players)
                    in
                    ( { model
                        | players = newPlayers
                        , currentNewPlayerName = ""
                        , currentUuid = Just newUuid
                        , currentSeed = newSeed
                      }
                    , Cmd.none
                    )

                RemovePlayer player ->
                    let
                        playerIndexMaybe =
                            findIndex (\a -> a.id_ == player.id_) model.players
                    in
                    case playerIndexMaybe of
                        Just playerIndex ->
                            let
                                newPlayers =
                                    removeAt playerIndex model.players
                            in
                            ( { model | players = newPlayers }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Start ->
                    ( { model | game = Idle, currentValue = 0 }, Cmd.none )

                AddValue ->
                    case model.game of
                        Input box isEdit ->
                            if isEdit then
                                ( { model
                                    | game = Idle
                                    , currentValue = -1
                                    , values =
                                        List.map
                                            (\item ->
                                                if (\v -> v.box == box && v.player == currentPlayer) item then
                                                    { box = box
                                                    , player = currentPlayer
                                                    , value = model.currentValue
                                                    , counted = False
                                                    }

                                                else
                                                    item
                                            )
                                            model.values
                                  }
                                , Cmd.none
                                )

                            else
                                let
                                    newValue =
                                        { box = box
                                        , player = currentPlayer
                                        , value = model.currentValue
                                        , counted = False
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

                RemoveValue ->
                    case model.game of
                        Input box isEdit ->
                            ( { model
                                | game = Idle
                                , currentValue = -1
                                , values = List.filter (not << (\v -> v.box == box && v.player == currentPlayer)) model.values
                              }
                            , Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                ValueMarked value ->
                    ( { model | currentValue = value }, Cmd.none )

                InputValueChange value ->
                    ( { model | currentValue = String.toInt value |> Maybe.withDefault 0 }, Cmd.none )

                NewPlayerInputValueChange value ->
                    ( { model | currentNewPlayerName = value }, Cmd.none )

                ShowAddValue box ->
                    let
                        markedValueMaybe =
                            getDefaultMarkedValue model box
                    in
                    case markedValueMaybe of
                        Just markedValue ->
                            ( { model | game = Input box False, currentValue = markedValue }, Cmd.none )

                        Nothing ->
                            ( { model | game = Input box False }, Cmd.none )

                ShowEditValue value ->
                    ( { model | game = Input value.box True, currentValue = value.value }, Cmd.none )

                HideAddValue ->
                    ( { model
                        | game = Idle
                        , currentValue = -1
                      }
                    , Cmd.none
                    )

                CountValues ->
                    ( { model | game = ShowCountedValues }, Cmd.none )

                CountValuesTick newTime ->
                    let
                        _ =
                            Debug.log "Update(), CountValuesTick:" newTime

                        nextValueToAnimateMaybe =
                            getNextValueToAnimate model.players model.values
                    in
                    case nextValueToAnimateMaybe of
                        Just nextValue ->
                            let
                                updatedValues =
                                    List.map
                                        (\v ->
                                            if v.box == nextValue.box && v.player == nextValue.player then
                                                { v | counted = True }

                                            else
                                                v
                                        )
                                        model.values
                            in
                            ( { model | values = updatedValues }, Cmd.none )

                        Nothing ->
                            ( { model | game = ShowResults }, Cmd.none )

                Restart ->
                    ( { model | game = ShowAddRemovePlayers, values = [] }, Cmd.none )

        Nothing ->
            let
                _ =
                    Debug.log "Nothing returned from Update:" msg
            in
            -- handle product not found here
            -- likely return the model unchanged
            -- or set an error message on the model
            ( { model | error = Just NoCurrentPlayer }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        errorMaybe =
            model.error
    in
    case errorMaybe of
        Just error ->
            div [] [ text (errorToString error) ]

        Nothing ->
            let
                currentPlayerMaybe =
                    getCurrentPlayer model.values model.players

                gameState =
                    stateToString model.game
            in
            case currentPlayerMaybe of
                Just currentPlayer ->
                    let
                        content =
                            case model.game of
                                Initializing ->
                                    div [] [ button [ onClick AddRemovePlayers ] [ text "Start" ] ]

                                ShowAddRemovePlayers ->
                                    div [] [ addRemovePlayers model ]

                                Idle ->
                                    div []
                                        [ div [] [ scoreCard currentPlayer model False ]
                                        ]

                                Input box isEdit ->
                                    div []
                                        [ div [] [ scoreCard currentPlayer model False ]
                                        , div [] [ scoreDialog model box currentPlayer isEdit ]
                                        ]

                                Finished ->
                                    div []
                                        [ div [] [ gameFinished ]
                                        , div [] [ scoreCard currentPlayer model False ]
                                        , button [ onClick CountValues ] [ text "Count" ]
                                        ]

                                ShowCountedValues ->
                                    div []
                                        [ div [] [ scoreCard currentPlayer model True ]
                                        ]

                                ShowResults ->
                                    div []
                                        [ div [] [ highscore model ]
                                        , div [] [ scoreCard currentPlayer model True ]
                                        ]
                    in
                    div
                        []
                        [ div [ classList [ ( gameState, True ) ] ] [ content ]
                        ]

                Nothing ->
                    div [] [ text "No player found" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.game == ShowCountedValues then
        Time.every 100 CountValuesTick

    else
        Sub.none



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
