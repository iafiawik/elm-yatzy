module Main exposing (init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (find, findIndex, getAt, removeAt)
import Logic exposing (..)
import Models exposing (Box, BoxCategory(..), BoxType(..), Game(..), Model, Msg(..), Player, PlayerAndNumberOfValues, Value)
import Random exposing (Seed, initialSeed, step)
import Task
import Time
import Uuid
import Views.AddRemovePlayers exposing (addRemovePlayers)
import Views.GameFinished exposing (gameFinished)
import Views.Highscore exposing (highscore)
import Views.ScoreCard exposing (scoreCard)
import Views.ScoreDialog exposing (scoreDialog)



---- MODEL ----


init : Int -> ( Model, Cmd Msg )
init seed =
    let
        currentSeed =
            initialSeed seed

        ( newUuid, newSeed ) =
            step Uuid.uuidGenerator currentSeed

        boxes =
            getBoxes

        valueBoxes =
            List.filter (\b -> b.id_ /= "ones" && b.category /= None) boxes

        sophie =
            { id_ = getUniqueId currentSeed ++ "_sophie", order = 0, name = "Sophie" }

        hugo =
            { id_ = getUniqueId currentSeed ++ "_hugo", order = 1, name = "Hugo" }
    in
    ( { boxes = boxes
      , players =
            [ sophie
            , hugo
            ]
      , values = []

      -- [ { box = ones
      --   , player = sophie
      --   , value = 1
      --   , counted = False
      --   }
      -- , { box = ones
      --   , player = hugo
      --   , value = 3
      --   , counted = False
      --   }
      -- , { box = twos
      --   , player = sophie
      --   , value = 2
      --   , counted = False
      --   }
      -- , { box = twos
      --   , player = hugo
      --   , value = 4
      --   , counted = False
      --   }
      -- ]
      , game = Idle
      , countedPlayers = []
      , countedValues = []
      , currentValue = -1
      , currentNewPlayerName = ""
      , currentSeed = newSeed
      , currentUuid = Just newUuid
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

        AddPlayers ->
            "add-players"

        Idle ->
            "idle"

        Input box ->
            "input"

        Finished ->
            "finished"

        ShowCountedValues ->
            "show-counted-values"

        ShowResults ->
            "show-results"

        Error ->
            "error"



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
                        Input box ->
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
                    ( { model | game = AddPlayers, values = [] }, Cmd.none )

        Nothing ->
            let
                _ =
                    Debug.log "Nothing returned from Update:" msg
            in
            -- handle product not found here
            -- likely return the model unchanged
            -- or set an error message on the model
            ( { model | game = Error }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
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
                            div [] [ button [ onClick Start ] [ text "Start" ] ]

                        AddPlayers ->
                            div [] [ addRemovePlayers model ]

                        Idle ->
                            div []
                                [ div [] [ scoreCard currentPlayer model False ]
                                ]

                        Input box ->
                            div []
                                [ div [] [ scoreCard currentPlayer model False ]
                                , div [] [ scoreDialog model box currentPlayer ]
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

                        Error ->
                            div [] [ text "An error occured" ]
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


main : Program Int Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
