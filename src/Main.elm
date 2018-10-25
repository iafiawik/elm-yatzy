port module Main exposing (init, main, update, view)

import Browser
import Browser.Dom exposing (getViewport)
import Debug
import Html exposing (Html, button, div, h1, h2, img, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Lazy exposing (lazy)
import Json.Decode exposing (Decoder, field, int, map3, string)
import Json.Encode as E
import List.Extra exposing (find, findIndex, getAt, removeAt)
import Logic exposing (..)
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Error exposing (Error(..))
import Model.Game exposing (Game, encodeGame, gameDecoder, gameResultDecoder, gamesDecoder)
import Model.GameState exposing (GameState(..))
import Model.Player exposing (Player)
import Model.User exposing (User, usersDecoder)
import Model.Value exposing (DbValue, Value, encodeValue, encodeValues, valuesDecoder)
import Models exposing (GamePlaying, GameResult, GameResultState(..), GameSetup, GroupModel(..), IndividualModel(..), IndividualPlayingModel, MarkedPlayer(..), Mode(..), Model(..), Msg(..), PlayerAndNumberOfValues, PreGameState(..))
import Task
import Time
import Uuid
import Views.AddRemovePlayers exposing (addRemovePlayers)
import Views.EnterGameCode exposing (enterGameCode)
import Views.GameFinished exposing (gameFinished)
import Views.GameInfo exposing (gameInfo)
import Views.Highscore exposing (highscore)
import Views.IndividualGameInfo exposing (individualGameInfo)
import Views.IndividualHighscore exposing (individualHighscore)
import Views.IndividualJoinInfo exposing (individualJoinInfo)
import Views.Notification exposing (notification)
import Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)
import Views.ScoreDialog exposing (scoreDialog)
import Views.SelectPlayer exposing (selectPlayer)


port fillWithDummyValues : List E.Value -> Cmd msg


port getGame : E.Value -> Cmd msg


port getGames : () -> Cmd msg


port getUsers : () -> Cmd msg


port getValues : E.Value -> Cmd msg


port createUser : E.Value -> Cmd msg


port createGame : E.Value -> Cmd msg


port createValue : E.Value -> Cmd msg


port editGame : E.Value -> Cmd msg


port editValue : E.Value -> Cmd msg


port deleteValue : E.Value -> Cmd msg


port usersReceived : (Json.Decode.Value -> msg) -> Sub msg


port gameReceived : (Json.Decode.Value -> msg) -> Sub msg


port gamesReceived : (Json.Decode.Value -> msg) -> Sub msg


port valuesReceived : (Json.Decode.Value -> msg) -> Sub msg



---- MODEL ----


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    -- ( SelectedMode (Individual (EnterGameCode "RVBG")) [], Cmd.none )
    ( SelectedMode SelectMode, Cmd.none )



-- ( SelectedMode
--     (Group
--         (PreGame
--             { users = []
--             , game =
--                 { id = ""
--                 , code = ""
--                 , players = []
--                 , values = []
--                 , finished = False
--                 }
--             , error = Nothing
--             , currentNewPlayerName = ""
--             , state = ShowAddRemovePlayers
--             }
--         )
--     )
--     []
-- , Cmd.none
-- )
-- ( Group
--     (PreGame
--         { users = []
--         , game =
--             { id = ""
--             , code = ""
--             , players = []
--             , values = []
--             , finished = False
--             }
--         , error = Nothing
--         , currentNewPlayerName = ""
--         , state = ShowAddRemovePlayers
--         }
--     )
-- , Cmd.none
-- )


stateToString : a -> String
stateToString state =
    ""


errorToString : Error -> String
errorToString error =
    case error of
        UnableToDecodeUsers message ->
            "Unable to decode users from the database. Can not to continue without users."

        NoCurrentPlayer ->
            "No current player found. Unable to proceed from this state."

        UserAlreadyExists name ->
            "User " ++ name ++ " already exists. Try another name."



---- UPDATE ----


updatePreGame : Msg -> GameSetup -> ( GameSetup, Cmd Msg )
updatePreGame msg model =
    case msg of
        NewPlayerInputValueChange value ->
            ( { model | currentNewPlayerName = value }, Cmd.none )

        RemoteUsers users ->
            ( { model
                | users = users
              }
            , Cmd.none
            )

        GameReceived dbGameMaybe ->
            case dbGameMaybe of
                Just dbGame ->
                    let
                        currentGame =
                            model.game
                    in
                    ( { model
                        | game =
                            { currentGame
                                | id = dbGame.id
                                , code = dbGame.code
                                , players = dbGame.users
                            }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        AddUser ->
            if find (\u -> String.toLower u.name == String.toLower model.currentNewPlayerName) model.users == Nothing then
                let
                    name =
                        model.currentNewPlayerName
                in
                ( { model | currentNewPlayerName = "", error = Nothing }
                , createUser (E.string name)
                )

            else
                ( { model | error = Just (UserAlreadyExists model.currentNewPlayerName) }
                , Cmd.none
                )

        AddPlayer user ->
            let
                newPlayer =
                    { user = user, order = List.length model.game.players }

                newPlayers =
                    sortPlayersByOrder (newPlayer :: model.game.players)

                currentGame =
                    model.game
            in
            ( { model
                | game = { currentGame | players = newPlayers }
                , currentNewPlayerName = ""
              }
            , Cmd.none
            )

        RemovePlayer player ->
            let
                playerIndexMaybe =
                    findIndex (\a -> a.user.id == player.user.id) model.game.players
            in
            case playerIndexMaybe of
                Just playerIndex ->
                    let
                        newPlayers =
                            removeAt playerIndex model.game.players

                        currentGame =
                            model.game
                    in
                    ( { model | game = { currentGame | players = newPlayers } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        PlayersAdded ->
            let
                game =
                    { id = ""
                    , code = ""
                    , players = model.game.players
                    , values = []
                    , finished = False
                    }
            in
            ( { model | state = ShowIndividualJoinInfo }, createGame (encodeGame game) )

        _ ->
            ( model, Cmd.none )


getPlayerByUserId : String -> List Player -> Player
getPlayerByUserId id players =
    Maybe.withDefault { user = { name = "", userName = "", id = "" }, order = 0 } (find (\p -> p.user.id == id) players)


getBoxById : String -> Box
getBoxById id =
    Maybe.withDefault { id = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 0 } (find (\b -> b.id == id) getBoxes)


fromDbValueToValue : DbValue -> List Value -> List Player -> Value
fromDbValueToValue dbValue oldValues players =
    let
        player =
            getPlayerByUserId dbValue.userId players

        new =
            if find (\v -> v.id == dbValue.id) oldValues == Nothing then
                True

            else
                False
    in
    { id = dbValue.id
    , box = getBoxById dbValue.boxId
    , player = player
    , value = dbValue.value
    , counted = False
    , new = new
    }


updateValues : List DbValue -> List Value -> List Player -> List Value
updateValues dbValues oldValues players =
    List.map
        (\v ->
            fromDbValueToValue v oldValues players
        )
        dbValues


updateGame : Msg -> GamePlaying -> ( GamePlaying, Cmd Msg )
updateGame msg model =
    let
        currentPlayerMaybe =
            getCurrentPlayer model.game.values model.game.players
    in
    case currentPlayerMaybe of
        Just currentPlayer ->
            case msg of
                RemoteValuesReceived dbValues ->
                    let
                        currentGame =
                            model.game

                        values =
                            updateValues dbValues model.game.values model.game.players
                    in
                    ( { model
                        | game =
                            { currentGame
                                | values = values
                            }
                      }
                    , Cmd.none
                    )

                AddValue ->
                    case model.state of
                        Input box isEdit ->
                            if isEdit then
                                let
                                    existingValueMaybe =
                                        find
                                            (\v -> v.box == box && v.player == currentPlayer)
                                            model.game.values
                                in
                                case existingValueMaybe of
                                    Just existingValue ->
                                        let
                                            editedValue =
                                                existingValue
                                        in
                                        ( { model
                                            | state = Idle
                                            , currentValue = -1
                                          }
                                        , editValue (encodeValue { editedValue | value = model.currentValue })
                                        )

                                    Nothing ->
                                        ( model, Cmd.none )

                            else
                                let
                                    newValue =
                                        { id = ""
                                        , box = box
                                        , player = currentPlayer
                                        , value = model.currentValue
                                        , counted = False
                                        , new = False
                                        }
                                in
                                ( { model
                                    | state = Idle
                                    , currentValue = -1
                                  }
                                , createValue (encodeValue newValue)
                                )

                        _ ->
                            ( model, Cmd.none )

                RemoveValue ->
                    case model.state of
                        Input box isEdit ->
                            let
                                existingValueMaybe =
                                    find
                                        (\v -> v.box == box && v.player == currentPlayer)
                                        model.game.values
                            in
                            case existingValueMaybe of
                                Just existingValue ->
                                    let
                                        deletedValue =
                                            existingValue
                                    in
                                    ( { model
                                        | state = Idle
                                        , currentValue = -1
                                      }
                                    , deleteValue (encodeValue deletedValue)
                                    )

                                Nothing ->
                                    ( model, Cmd.none )

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

                ShowGameInfo ->
                    ( { model | showGameInfo = True }, Cmd.none )

                HideGameInfo ->
                    ( { model | showGameInfo = False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Nothing ->
            ( { model | error = Just NoCurrentPlayer }, Cmd.none )


updatePostGame : Msg -> GameResult -> ( GameResult, Cmd Msg )
updatePostGame msg model =
    case msg of
        CountValues ->
            ( { model | state = ShowCountedValues }, Cmd.none )

        CountValuesTick newTime ->
            let
                nextValueToAnimateMaybe =
                    getNextValueToAnimate model.game.players model.game.values
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
                                model.game.values

                        currentGame =
                            model.game
                    in
                    ( { model | game = { currentGame | values = updatedValues } }, Cmd.none )

                Nothing ->
                    ( { model | state = ShowResults }, Cmd.none )

        _ ->
            ( model, Cmd.none )


startIndividualGame : Game -> Player -> ( Model, Cmd Msg )
startIndividualGame game selectedPlayer =
    ( SelectedMode
        (Individual
            (IndividualPlaying
                { gamePlaying =
                    { game = game
                    , boxes = getBoxes
                    , state = Idle
                    , currentValue = -1
                    , showGameInfo = False
                    , error = Nothing
                    }
                , selectedPlayer = selectedPlayer
                }
            )
        )
    , Cmd.none
    )


startGroupGame : Game -> ( Model, Cmd Msg )
startGroupGame game =
    ( SelectedMode
        (Group
            (Playing
                { game =
                    { id = game.id
                    , code = game.code
                    , players = game.players
                    , values = []
                    , finished = False
                    }
                , boxes = getBoxes
                , state = Idle
                , currentValue = 0
                , showGameInfo = False
                , error = Nothing
                }
            )
        )
    , getValues (E.string game.id)
    )


isGameFinished game =
    areAllUsersFinished game.values game.players getBoxes


finishGame : Game -> Cmd Msg
finishGame game =
    let
        currentGame =
            { id = ""
            , code = game.code
            , players = game.players
            , values = game.values
            , finished = True
            }
    in
    editGame (encodeGame currentGame)


createDummyValues : Player -> List Value -> List Value
createDummyValues player existingValues =
    let
        playerValues =
            List.filter (\v -> v.player == player) existingValues

        boxes =
            List.filter
                (\b ->
                    if find (\existing -> existing.id == b.id) playerValues == Nothing then
                        True

                    else
                        False
                )
                getInteractiveBoxes
    in
    List.map
        (\box ->
            let
                acceptedValues =
                    getAcceptedValues box

                selectedValue =
                    Maybe.withDefault 0 (List.head acceptedValues)
            in
            { id = ""
            , box = box
            , player = player
            , value = selectedValue
            , counted = False
            , new = False
            }
        )
        boxes


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        SelectedMode mode ->
            case mode of
                SelectMode ->
                    case msg of
                        SelectIndividual ->
                            ( SelectedMode
                                (Individual
                                    (EnterGameCode
                                        ""
                                        []
                                    )
                                )
                            , getGames ()
                            )

                        SelectGroup ->
                            ( SelectedMode
                                (Group
                                    (PreGame
                                        { users = []
                                        , game =
                                            { id = ""
                                            , code = ""
                                            , players = []
                                            , values = []
                                            , finished = False
                                            }
                                        , error = Nothing
                                        , currentNewPlayerName = ""
                                        , state = ShowAddRemovePlayers
                                        }
                                    )
                                )
                            , getUsers ()
                            )

                        _ ->
                            ( model, Cmd.none )

                Individual individualModel ->
                    if msg == Restart then
                        ( SelectedMode
                            (Individual
                                (EnterGameCode
                                    ""
                                    []
                                )
                            )
                        , getGames ()
                        )

                    else
                        case individualModel of
                            EnterGameCode gameCode games ->
                                case msg of
                                    GamesReceived dbGames ->
                                        let
                                            currentModel =
                                                individualModel

                                            allGames =
                                                List.map
                                                    (\dbGame ->
                                                        { id = dbGame.id
                                                        , code = dbGame.code
                                                        , players = dbGame.users
                                                        , values = []
                                                        , finished = dbGame.finished
                                                        }
                                                    )
                                                    dbGames
                                        in
                                        ( SelectedMode (Individual (EnterGameCode (String.toUpper gameCode) allGames)), Cmd.none )

                                    EnterGame ->
                                        ( SelectedMode
                                            (Individual
                                                (WaitingForData
                                                    ( Nothing, Nothing )
                                                )
                                            )
                                        , getGame (E.string gameCode)
                                        )

                                    GameCodeInputChange value ->
                                        let
                                            currentModel =
                                                individualModel
                                        in
                                        ( SelectedMode (Individual (EnterGameCode (String.toUpper value) games)), Cmd.none )

                                    _ ->
                                        ( model, Cmd.none )

                            WaitingForData ( gameMaybe, dbValuesMaybe ) ->
                                case msg of
                                    GameReceived dbGameMaybe ->
                                        case dbGameMaybe of
                                            Just dbGame ->
                                                let
                                                    game =
                                                        { id = dbGame.id
                                                        , code = dbGame.code
                                                        , players = dbGame.users
                                                        , values = []
                                                        , finished = dbGame.finished
                                                        }
                                                in
                                                case dbValuesMaybe of
                                                    Nothing ->
                                                        ( SelectedMode
                                                            (Individual
                                                                (WaitingForData
                                                                    ( Just game
                                                                    , dbValuesMaybe
                                                                    )
                                                                )
                                                            )
                                                        , Cmd.none
                                                        )

                                                    Just dbValues ->
                                                        let
                                                            updatedValues =
                                                                updateValues dbValues game.values game.players

                                                            newGame =
                                                                { game | values = updatedValues }
                                                        in
                                                        ( SelectedMode
                                                            (Individual
                                                                (SelectPlayer
                                                                    { game = newGame
                                                                    , markedPlayer = NoPlayer
                                                                    }
                                                                )
                                                            )
                                                        , Cmd.none
                                                        )

                                            Nothing ->
                                                ( SelectedMode (Individual (EnterGameCode "" [])), Cmd.none )

                                    RemoteValuesReceived dbValues ->
                                        case gameMaybe of
                                            Nothing ->
                                                ( SelectedMode
                                                    (Individual
                                                        (WaitingForData
                                                            ( gameMaybe
                                                            , Just dbValues
                                                            )
                                                        )
                                                    )
                                                , Cmd.none
                                                )

                                            Just game ->
                                                let
                                                    updatedValues =
                                                        updateValues dbValues game.values game.players

                                                    newGame =
                                                        { game | values = updatedValues }
                                                in
                                                ( SelectedMode
                                                    (Individual
                                                        (SelectPlayer
                                                            { game = newGame
                                                            , markedPlayer = NoPlayer
                                                            }
                                                        )
                                                    )
                                                , Cmd.none
                                                )

                                    _ ->
                                        ( model, Cmd.none )

                            SelectPlayer selectPlayerModel ->
                                case msg of
                                    PlayerMarked player ->
                                        ( SelectedMode
                                            (Individual
                                                (SelectPlayer { selectPlayerModel | markedPlayer = Single player })
                                            )
                                        , Cmd.none
                                        )

                                    AllPlayersMarked ->
                                        ( SelectedMode
                                            (Individual
                                                (SelectPlayer { selectPlayerModel | markedPlayer = All })
                                            )
                                        , Cmd.none
                                        )

                                    Start ->
                                        case selectPlayerModel.markedPlayer of
                                            Single player ->
                                                startIndividualGame selectPlayerModel.game player

                                            All ->
                                                startGroupGame selectPlayerModel.game

                                            NoPlayer ->
                                                ( SelectedMode
                                                    (Individual
                                                        (SelectPlayer
                                                            { selectPlayerModel
                                                                | markedPlayer = NoPlayer
                                                            }
                                                        )
                                                    )
                                                , Cmd.none
                                                )

                                    _ ->
                                        ( model, Cmd.none )

                            IndividualPlaying individualPlayingModel ->
                                case msg of
                                    FillWithDummyValues player ->
                                        ( model, fillWithDummyValues (encodeValues (createDummyValues player individualPlayingModel.gamePlaying.game.values)) )

                                    _ ->
                                        let
                                            gameModel =
                                                updateGame msg individualPlayingModel.gamePlaying

                                            gamePlaying =
                                                Tuple.first gameModel
                                        in
                                        if isGameFinished gamePlaying.game then
                                            let
                                                game =
                                                    gamePlaying.game

                                                currentGame =
                                                    { id = ""
                                                    , code = game.code
                                                    , players = game.players
                                                    , values = game.values
                                                    , finished = True
                                                    }
                                            in
                                            ( SelectedMode
                                                (Individual
                                                    (IndividualPostGame
                                                        { game = currentGame, selectedPlayer = individualPlayingModel.selectedPlayer }
                                                    )
                                                )
                                            , Cmd.batch [ Tuple.second gameModel, finishGame currentGame ]
                                            )

                                        else
                                            ( SelectedMode (Individual (IndividualPlaying { gamePlaying = Tuple.first gameModel, selectedPlayer = individualPlayingModel.selectedPlayer }))
                                            , Tuple.second gameModel
                                            )

                            IndividualPostGame postGame ->
                                ( model, Cmd.none )

                Group groupModel ->
                    case groupModel of
                        PreGame preGame ->
                            if msg == Start then
                                startGroupGame preGame.game

                            else if msg == HideNotification then
                                ( SelectedMode (Group (PreGame { preGame | error = Nothing })), Cmd.none )

                            else
                                let
                                    newModel =
                                        Tuple.mapFirst PreGame <| updatePreGame msg preGame
                                in
                                ( SelectedMode (Group (Tuple.first newModel)), Tuple.second newModel )

                        Playing gamePlaying ->
                            case msg of
                                FillWithDummyValues player ->
                                    ( model, fillWithDummyValues (encodeValues (createDummyValues player gamePlaying.game.values)) )

                                _ ->
                                    let
                                        gameModel =
                                            Tuple.mapFirst Playing <| updateGame msg gamePlaying
                                    in
                                    case Tuple.first gameModel of
                                        Playing playingModel ->
                                            if isGameFinished playingModel.game then
                                                let
                                                    currentGame =
                                                        { id = ""
                                                        , code = playingModel.game.code
                                                        , players = playingModel.game.players
                                                        , values = playingModel.game.values
                                                        , finished = True
                                                        }
                                                in
                                                ( SelectedMode
                                                    (Group
                                                        (PostGame
                                                            { game = currentGame
                                                            , boxes = playingModel.boxes
                                                            , state = GameFinished
                                                            , countedPlayers = []
                                                            , countedValues = []
                                                            , error = Nothing
                                                            }
                                                        )
                                                    )
                                                , Cmd.batch [ Tuple.second gameModel, finishGame playingModel.game ]
                                                )

                                            else
                                                ( SelectedMode (Group (Tuple.first gameModel))
                                                , Tuple.second gameModel
                                                )

                                        _ ->
                                            ( model
                                            , Cmd.none
                                            )

                        PostGame postGame ->
                            if msg == Restart then
                                ( SelectedMode
                                    (Group
                                        (PreGame
                                            { users = []
                                            , currentNewPlayerName = ""
                                            , game =
                                                { id = ""
                                                , code = ""
                                                , players = postGame.game.players
                                                , values = []
                                                , finished = False
                                                }
                                            , error = Nothing
                                            , state = ShowAddRemovePlayers
                                            }
                                        )
                                    )
                                , getUsers ()
                                )

                            else
                                let
                                    newModel =
                                        Tuple.mapFirst PostGame <| updatePostGame msg postGame
                                in
                                ( SelectedMode (Group (Tuple.first newModel)), Tuple.second newModel )



---- VIEW ----


view : Model -> Html Msg
view model =
    case model of
        SelectedMode mode ->
            case mode of
                SelectMode ->
                    div [] [ div [ onClick SelectIndividual ] [ text "Joina spel" ], div [ onClick SelectGroup ] [ text "Skapa spel" ] ]

                Individual individualModel ->
                    case individualModel of
                        EnterGameCode gameCode games ->
                            enterGameCode gameCode games

                        WaitingForData ( game, values ) ->
                            div [] [ span [] [ text "Waiting for game ..." ] ]

                        SelectPlayer selectPlayerModel ->
                            selectPlayer selectPlayerModel.game selectPlayerModel.markedPlayer

                        IndividualPlaying gamePlayingModel ->
                            let
                                game =
                                    gamePlayingModel.gamePlaying.game

                                selectedPlayer =
                                    gamePlayingModel.selectedPlayer
                            in
                            if game.finished == True then
                                div [] [ individualHighscore selectedPlayer game.players game.values ]

                            else
                                let
                                    gameState =
                                        stateToString playingModel.state

                                    playingModel =
                                        gamePlayingModel.gamePlaying

                                    currentPlayerMaybe =
                                        getCurrentPlayer game.values game.players

                                    gameInformation =
                                        if playingModel.showGameInfo then
                                            individualGameInfo playingModel.game

                                        else
                                            div [] []
                                in
                                case currentPlayerMaybe of
                                    Just currentPlayer ->
                                        let
                                            content =
                                                case playingModel.state of
                                                    Idle ->
                                                        div []
                                                            [ gameInformation
                                                            , div [] [ interactiveScoreCard currentPlayer (Just gamePlayingModel.selectedPlayer) game False ]
                                                            ]

                                                    Input box isEdit ->
                                                        div []
                                                            [ div [] [ interactiveScoreCard currentPlayer (Just gamePlayingModel.selectedPlayer) game False ]
                                                            , div [] [ scoreDialog playingModel box currentPlayer isEdit ]
                                                            ]
                                        in
                                        div
                                            []
                                            [ div [ classList [ ( gameState, True ) ] ] [ content ]
                                            ]

                                    Nothing ->
                                        div [] [ text "No player found" ]

                        IndividualPostGame postGame ->
                            div [] [ individualHighscore postGame.selectedPlayer postGame.game.players postGame.game.values ]

                Group groupModel ->
                    case groupModel of
                        PreGame preGame ->
                            let
                                notificationHtml =
                                    case preGame.error of
                                        Just error ->
                                            notification (errorToString error)

                                        Nothing ->
                                            div [] []
                            in
                            case preGame.state of
                                ShowAddRemovePlayers ->
                                    div [] [ lazy addRemovePlayers preGame, notificationHtml ]

                                ShowIndividualJoinInfo ->
                                    div [] [ individualJoinInfo preGame.game ]

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
                                            getCurrentPlayer playingModel.game.values playingModel.game.players

                                        gameState =
                                            stateToString playingModel.state

                                        gameInformation =
                                            if playingModel.showGameInfo then
                                                gameInfo playingModel.game

                                            else
                                                div [] []
                                    in
                                    case currentPlayerMaybe of
                                        Just currentPlayer ->
                                            let
                                                content =
                                                    case playingModel.state of
                                                        Idle ->
                                                            div []
                                                                [ gameInformation
                                                                , div [] [ interactiveScoreCard currentPlayer Nothing playingModel.game False ]
                                                                ]

                                                        Input box isEdit ->
                                                            div []
                                                                [ div [] [ interactiveScoreCard currentPlayer Nothing playingModel.game False ]
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
                                    getCurrentPlayer finishedModel.game.values finishedModel.game.players

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
                                                        , div [] [ staticScoreCard currentPlayer finishedModel.game False False ]
                                                        , button [ onClick CountValues ] [ text "Count" ]
                                                        ]

                                                ShowCountedValues ->
                                                    div []
                                                        [ div [] [ staticScoreCard currentPlayer finishedModel.game False True ]
                                                        ]

                                                ShowResults ->
                                                    div []
                                                        [ div [] [ highscore finishedModel.game.players finishedModel.game.values ]
                                                        , div [] [ staticScoreCard currentPlayer finishedModel.game False True ]
                                                        ]
                                    in
                                    div
                                        []
                                        [ div [ classList [ ( gameState, True ) ] ] [ content ]
                                        ]

                                Nothing ->
                                    div [] [ text "No player found" ]


remoteUsersUpdated : Json.Decode.Value -> Msg
remoteUsersUpdated usersJson =
    let
        usersMaybe =
            Json.Decode.decodeValue usersDecoder usersJson
    in
    case usersMaybe of
        Ok users ->
            RemoteUsers users

        Err err ->
            NoOp


gameCreated : Json.Decode.Value -> Msg
gameCreated gameJson =
    let
        gameMaybe =
            Json.Decode.decodeValue gameResultDecoder gameJson
    in
    case gameMaybe of
        Ok gameResult ->
            GameReceived (Just gameResult.game)

        Err err ->
            GameReceived Nothing


gamesUpdated : Json.Decode.Value -> Msg
gamesUpdated gamesJson =
    let
        gamesMaybe =
            Json.Decode.decodeValue gamesDecoder gamesJson
    in
    case gamesMaybe of
        Ok games ->
            GamesReceived games

        Err err ->
            NoOp


remoteValuesUpdated : Json.Decode.Value -> Msg
remoteValuesUpdated valuesJson =
    let
        valuesMaybe =
            Json.Decode.decodeValue valuesDecoder valuesJson
    in
    case valuesMaybe of
        Ok values ->
            RemoteValuesReceived values

        Err err ->
            NoOp


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        allSubscriptions =
            [ usersReceived remoteUsersUpdated
            , gameReceived gameCreated
            , valuesReceived remoteValuesUpdated
            , gamesReceived gamesUpdated
            ]
    in
    case model of
        SelectedMode mode ->
            case mode of
                Group groupModel ->
                    case groupModel of
                        PostGame postGame ->
                            if postGame.state == ShowCountedValues then
                                Sub.batch
                                    [ Time.every 100
                                        CountValuesTick
                                    ]

                            else
                                Sub.batch
                                    allSubscriptions

                        _ ->
                            Sub.batch
                                allSubscriptions

                _ ->
                    Sub.batch
                        allSubscriptions



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
