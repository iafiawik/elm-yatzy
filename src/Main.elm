port module Main exposing (init, main, update, view)

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
import Models exposing (..)
import Task
import Time
import Uuid
import Views.AddRemovePlayers exposing (addRemovePlayers)
import Views.GameFinished exposing (gameFinished)
import Views.Highscore exposing (highscore)
import Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)
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
            ( PreGame
                { users = []
                , players = []
                , currentNewPlayerName = ""
                , error = Just (UnableToDecodeUsers (errorToHtml err))
                }
            , Cmd.none
            )

        -- ( { game = Initializing
        --   , users = []
        --   , values = []
        --   , players = []
        --   , boxes = []
        --   , countedPlayers = []
        --   , countedValues = []
        --   , currentValue = -1
        --   , currentNewPlayerName = ""
        --   , currentSeed = newSeed
        --   , currentUuid = Just newUuid
        --   , error = Just (UnableToDecodeUsers (errorToHtml err))
        --   }
        -- , Cmd.none
        -- )
        Ok users ->
            -- let
            --     boxes =
            --         getBoxes
            -- valueBoxes =
            --     List.filter (\b -> b.id_ /= "yatzy" && b.category /= None) boxes
            -- sophie =
            --     { id_ = getUniqueId currentSeed ++ "_sophie", order = 0, name = "Sophie" }
            --
            -- hugo =
            --     { id_ = getUniqueId currentSeed ++ "_hugo", order = 1, name = "Hugo" }
            --
            -- phoenix =
            --     { id_ = getUniqueId currentSeed ++ "_phoenix", order = 0, name = "Phoenix" }
            --
            -- louise =
            --     { id_ = getUniqueId currentSeed ++ "_louise", order = 1, name = "Louise" }
            -- in
            ( PreGame
                { users = users
                , players = []
                , error = Nothing
                , currentNewPlayerName = ""
                }
            , Cmd.none
            )



--
-- ( { boxes = boxes
--   , players =
--         []
--   , values =
--         List.concat
--             [ List.map
--                 (\b ->
--                     { box = b
--                     , player = sophie
--                     , value = getAt 3 (getAcceptedValues b) |> Maybe.withDefault 0
--                     , counted = False
--                     }
--                 )
--                 valueBoxes
--             , List.map
--                 (\b ->
--                     { box = b
--                     , player = hugo
--                     , value = getAt 2 (getAcceptedValues b) |> Maybe.withDefault 0
--                     , counted = False
--                     }
--                 )
--                 valueBoxes
--             , List.map
--                 (\b ->
--                     { box = b
--                     , player = phoenix
--                     , value = getAt 2 (getAcceptedValues b) |> Maybe.withDefault 0
--                     , counted = False
--                     }
--                 )
--                 valueBoxes
--             , List.map
--                 (\b ->
--                     { box = b
--                     , player = louise
--                     , value = getAt 2 (getAcceptedValues b) |> Maybe.withDefault 0
--                     , counted = False
--                     }
--                 )
--                 valueBoxes
--             ]
--   , game = ShowAddRemovePlayers
--   , users = users
--   , countedPlayers = []
--   , countedValues = []
--   , currentValue = -1
--   , currentNewPlayerName = ""
--   , currentSeed = newSeed
--   , currentUuid = Just newUuid
--   , error = Nothing
--   }
-- , Cmd.none
-- )


stateToString : a -> String
stateToString state =
    ""



-- case state of
--     Initializing ->
--         "initializing"
--
--     ShowAddRemovePlayers ->
--         "add-players"
--
--     Idle ->
--         "idle"
--
--     Input box isEdit ->
--         "input"
--
--     Finished ->
--         "finished"
--
--     ShowCountedValues ->
--         "show-counted-values"
--
--     ShowResults ->
--         "show-results"


errorToString : Error -> String
errorToString error =
    case error of
        UnableToDecodeUsers message ->
            "Unable to decode users from the database. Can not to continue without users."

        NoCurrentPlayer ->
            "No current player found. Unable to proceed from this state."



---- UPDATE ----


updatePreGame : Msg -> GameSetup -> ( GameSetup, Cmd Msg )
updatePreGame msg model =
    case msg of
        -- AddRemovePlayers ->
        --     ( { model | game = ShowAddRemovePlayers }, Cmd.none )
        NewPlayerInputValueChange value ->
            ( { model | currentNewPlayerName = value }, Cmd.none )

        AddUser ->
            if find (\u -> String.toLower u.name == String.toLower model.currentNewPlayerName) model.users == Nothing then
                let
                    name =
                        model.currentNewPlayerName
                in
                ( model
                , Cmd.none
                )

            else
                let
                    _ =
                        Debug.log "" "Name exists"
                in
                ( model
                , Cmd.none
                )

        AddPlayer user ->
            let
                newPlayer =
                    { user = user, order = List.length model.players }

                newPlayers =
                    sortPlayersByOrder (newPlayer :: model.players)
            in
            ( { model
                | players = newPlayers
                , currentNewPlayerName = ""
              }
            , Cmd.none
            )

        RemovePlayer player ->
            let
                playerIndexMaybe =
                    findIndex (\a -> a.user.id == player.user.id) model.players
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

        _ ->
            ( model, Cmd.none )


updateGame : Msg -> Game -> ( Game, Cmd Msg )
updateGame msg model =
    let
        _ =
            Debug.log "state2:" msg

        currentPlayerMaybe =
            getCurrentPlayer model.values model.players
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
            case msg of
                AddValue ->
                    case model.state of
                        Input box isEdit ->
                            if isEdit then
                                ( { model
                                    | state = Idle
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
                                ( { model
                                    | state = Idle
                                    , currentValue = -1
                                    , values = newValues
                                  }
                                , Cmd.none
                                )

                        _ ->
                            ( model, Cmd.none )

                RemoveValue ->
                    case model.state of
                        Input box isEdit ->
                            ( { model
                                | state = Idle
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

                ShowAddValue box ->
                    let
                        markedValueMaybe =
                            getDefaultMarkedValue box
                    in
                    case markedValueMaybe of
                        Just markedValue ->
                            ( { model | state = Input box False, currentValue = markedValue }, Cmd.none )

                        Nothing ->
                            ( { model | state = Input box False }, Cmd.none )

                ShowEditValue value ->
                    ( { model | state = Input value.box True, currentValue = value.value }, Cmd.none )

                HideAddValue ->
                    ( { model
                        | state = Idle
                        , currentValue = -1
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        Nothing ->
            let
                _ =
                    Debug.log "Nothing returned from Update:" msg
            in
            -- handle product not found here
            -- likely return the model unchanged
            -- or set an error message on the model
            ( { model | error = Just NoCurrentPlayer }, Cmd.none )


updatePostGame : Msg -> GameResult -> ( GameResult, Cmd Msg )
updatePostGame msg model =
    case msg of
        CountValues ->
            ( { model | state = ShowCountedValues }, Cmd.none )

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
                    ( { model | state = ShowResults }, Cmd.none )

        _ ->
            ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        PreGame preGame ->
            if msg == Start then
                ( Playing
                    { players = preGame.players
                    , boxes = getBoxes
                    , values = []
                    , state = Idle
                    , currentValue = 0
                    , error = Nothing
                    }
                , Cmd.none
                )

            else
                Tuple.mapFirst PreGame <| updatePreGame msg preGame

        Playing game ->
            let
                gameModel =
                    Tuple.mapFirst Playing <| updateGame msg game
            in
            case Tuple.first gameModel of
                Playing playingModel ->
                    if areAllUsersFinished playingModel.values playingModel.players playingModel.boxes then
                        ( PostGame
                            { players = playingModel.players
                            , boxes = playingModel.boxes
                            , values = playingModel.values
                            , state = GameFinished
                            , countedPlayers = []
                            , countedValues = []
                            , error = Nothing
                            }
                        , Cmd.none
                        )

                    else
                        ( Tuple.first gameModel
                        , Cmd.none
                        )

                _ ->
                    ( model
                    , Cmd.none
                    )

        PostGame postGame ->
            if msg == Restart then
                ( PreGame
                    { users = []
                    , currentNewPlayerName = ""
                    , players = []
                    , error = Nothing
                    }
                , Cmd.none
                )

            else
                Tuple.mapFirst PostGame <| updatePostGame msg postGame



---- VIEW ----


view : Model -> Html Msg
view model =
    case model of
        PreGame preGame ->
            div [] [ addRemovePlayers preGame ]

        Playing playingModel ->
            let
                errorMaybe =
                    playingModel.error
            in
            case errorMaybe of
                Just error ->
                    div [] [ text (errorToString error) ]

                Nothing ->
                    let
                        currentPlayerMaybe =
                            getCurrentPlayer playingModel.values playingModel.players

                        gameState =
                            stateToString playingModel.state
                    in
                    case currentPlayerMaybe of
                        Just currentPlayer ->
                            let
                                content =
                                    case playingModel.state of
                                        Idle ->
                                            div []
                                                [ div [] [ interactiveScoreCard currentPlayer playingModel.boxes playingModel.values playingModel.players False ]
                                                ]

                                        Input box isEdit ->
                                            div []
                                                [ div [] [ interactiveScoreCard currentPlayer playingModel.boxes playingModel.values playingModel.players False ]
                                                , div [] [ scoreDialog playingModel box currentPlayer isEdit ]
                                                ]
                            in
                            div
                                []
                                [ div [ classList [ ( gameState, True ) ] ] [ content ]
                                ]

                        Nothing ->
                            div [] [ text "No player found" ]

        PostGame finishedModel ->
            let
                currentPlayerMaybe =
                    getCurrentPlayer finishedModel.values finishedModel.players

                gameState =
                    stateToString finishedModel.state
            in
            case currentPlayerMaybe of
                Just currentPlayer ->
                    let
                        content =
                            case finishedModel.state of
                                GameFinished ->
                                    div []
                                        [ div [] [ gameFinished ]
                                        , div [] [ staticScoreCard currentPlayer finishedModel.boxes finishedModel.values finishedModel.players False False ]
                                        , button [ onClick CountValues ] [ text "Count" ]
                                        ]

                                ShowCountedValues ->
                                    div []
                                        [ div [] [ staticScoreCard currentPlayer finishedModel.boxes finishedModel.values finishedModel.players False True ]
                                        ]

                                ShowResults ->
                                    div []
                                        [ div [] [ highscore finishedModel.players finishedModel.values ]
                                        , div [] [ staticScoreCard currentPlayer finishedModel.boxes finishedModel.values finishedModel.players False True ]
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
    case model of
        PostGame postGame ->
            if postGame.state == ShowCountedValues then
                Time.every 100 CountValuesTick

            else
                Sub.none

        Playing playing ->
            Sub.none

        PreGame preGame ->
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
