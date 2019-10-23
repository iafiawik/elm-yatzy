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
import List.Extra exposing (find, findIndex, getAt, notMember, removeAt)
import Logic exposing (..)
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Error exposing (Error(..))
import Model.Game exposing (DbGame, Game, encodeGame, gameDecoder, gameResultDecoder, gamesDecoder)
import Model.GameState exposing (GameState(..))
import Model.GlobalHighscore exposing (GlobalHighscore, globalHighscoresDecoder)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem, globalHighscoreItemDecoder, globalHighscoreItemsDecoder)
import Model.Player exposing (Player)
import Model.User exposing (User, userDecoder, usersDecoder)
import Model.Value exposing (DbValue, Value, encodeValue, encodeValues, valuesDecoder)
import Model.WindowState exposing (WindowState(..))
import Models exposing (BlurredModel(..), GameAndUserId, GamePlaying, GameResult, GameResultState(..), GameSetup, GroupModel(..), IndividualModel(..), IndividualPlayingModel, MarkedPlayer(..), Mode(..), Model, Msg(..), PlayerAndNumberOfValues, PreGameState(..))
import Task
import Time
import Views.AddRemovePlayers exposing (addRemovePlayers)
import Views.EnterGameCode exposing (enterGameCode)
import Views.GameFinished exposing (gameFinished)
import Views.GameInfo exposing (gameInfo)
import Views.GlobalHighscore exposing (globalHighscore)
import Views.Highscore exposing (highscore)
import Views.IndividualGameInfo exposing (individualGameInfo)
import Views.IndividualHighscore exposing (individualHighscore)
import Views.IndividualJoinInfo exposing (individualJoinInfo)
import Views.Loader exposing (loader)
import Views.Notification exposing (notification)
import Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)
import Views.ScoreDialog exposing (scoreDialog)
import Views.SelectPlayer exposing (selectPlayer)
import Views.StartPage exposing (startPage)
import Views.WindowBlurred exposing (windowBlurred)
import Views.WindowFocused exposing (windowFocused)


port fillWithDummyValues : List E.Value -> Cmd msg


port getGlobalHighscore : () -> Cmd msg


port getGame : E.Value -> Cmd msg


port startIndividualGameCommand : ( E.Value, E.Value, E.Value ) -> Cmd msg


port startGroupGameCommand : E.Value -> Cmd msg


port endGameCommand : () -> Cmd msg


port getGames : () -> Cmd msg


port getValues : () -> Cmd msg


port getUsers : () -> Cmd msg


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


port highscoreReceived : (Json.Decode.Value -> msg) -> Sub msg


port onBlurReceived : (Int -> msg) -> Sub msg


port onFocusReceived : (Json.Decode.Value -> msg) -> Sub msg



---- MODEL ----


type alias Flags =
    { isAdmin : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model (SelectMode 0) [] Focused flags.isAdmin, Cmd.none )


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
                    { user = user, order = List.length model.game.players, score = 0 }

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
                    , players = List.map (\p -> { p | score = getTotalSum model.game.values p }) model.game.players
                    , values = []
                    , finished = False
                    , dateCreated = ""
                    }
            in
            ( { model | state = ShowIndividualJoinInfo }, createGame (encodeGame game) )

        _ ->
            ( model, Cmd.none )


getPlayerByUserId : String -> List Player -> Player
getPlayerByUserId id players =
    Maybe.withDefault { user = { name = "", userName = "", id = "" }, order = 0, score = 0 } (find (\p -> p.user.id == id) players)


getBoxById : String -> Box
getBoxById id =
    Maybe.withDefault { id = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 0 } (find (\b -> b.id == id) getBoxes)


fromDbValueToValue : DbValue -> Maybe DbValue -> List Player -> Value
fromDbValueToValue dbValue newestDbValueMaybe players =
    let
        player =
            getPlayerByUserId dbValue.userId players

        new =
            case newestDbValueMaybe of
                Just newestDbValue ->
                    newestDbValue.id == dbValue.id

                Nothing ->
                    False
    in
    { id = dbValue.id
    , box = getBoxById dbValue.boxId
    , player = player
    , value = dbValue.value
    , counted = False
    , new = new
    , dateCreated = dbValue.dateCreated
    }


flippedComparison a b =
    case compare a.dateCreated b.dateCreated of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT


updateValues : List DbValue -> List Value -> List Player -> List Value
updateValues dbValues oldValues players =
    let
        newestMaybe =
            List.head (List.sortWith flippedComparison dbValues)
    in
    List.map
        (\v ->
            fromDbValueToValue v newestMaybe players
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

                                            valueIndex =
                                                findIndex (\v -> v.player == currentPlayer && v.box == box && v.value == model.currentValue) model.game.values

                                            valueExists =
                                                case valueIndex of
                                                    Just index ->
                                                        if index > -1 then
                                                            True

                                                        else
                                                            False

                                                    Nothing ->
                                                        False
                                        in
                                        ( { model
                                            | state = Idle
                                            , currentValue = -1
                                          }
                                        , if valueExists then
                                            Cmd.none

                                          else
                                            editValue (encodeValue { editedValue | value = model.currentValue })
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
                                        , dateCreated = 1
                                        }

                                    valueIndex =
                                        findIndex (\v -> v.player == currentPlayer && v.box == box) model.game.values
                                in
                                ( { model
                                    | state = Idle
                                    , currentValue = -1
                                  }
                                , case valueIndex of
                                    Just index ->
                                        -- let
                                        --     _ =
                                        --         Debug.log "AddValue" "add value, value already exists"
                                        -- in
                                        Cmd.none

                                    Nothing ->
                                        -- let
                                        --     _ =
                                        --         Debug.log "AddValue" "add value, value does not exist - create it"
                                        -- in
                                        createValue (encodeValue newValue)
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

        HideHighscore ->
            ( { model | state = HideResults }, Cmd.none )

        ShowGameInfo ->
            ( { model | showGameInfo = True }, Cmd.none )

        HideGameInfo ->
            ( { model | showGameInfo = False }, Cmd.none )

        _ ->
            ( model, Cmd.none )


startIndividualGame : Game -> Player -> List GlobalHighscore -> Bool -> ( Model, Cmd Msg )
startIndividualGame game selectedPlayer globalHighscore isAdmin =
    ( Model
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
        globalHighscore
        Focused
        isAdmin
    , startIndividualGameCommand ( E.string selectedPlayer.user.id, E.string game.id, E.string game.code )
    )


startGroupGame : Game -> List GlobalHighscore -> Bool -> ( Model, Cmd Msg )
startGroupGame game globalHighscore isAdmin =
    ( Model
        (Group
            (Playing
                { game =
                    { id = game.id
                    , code = game.code
                    , players = game.players
                    , values = []
                    , finished = False
                    , dateCreated = game.dateCreated
                    }
                , boxes = getBoxes
                , state = Idle
                , currentValue = 0
                , showGameInfo = False
                , error = Nothing
                }
            )
        )
        globalHighscore
        Focused
        isAdmin
    , startGroupGameCommand (encodeGame game)
    )


isGameFinished game =
    areAllUsersFinished game.values game.players getBoxes


finishGame : Game -> Cmd Msg
finishGame game =
    let
        currentGame =
            { id = ""
            , code = game.code
            , players =
                List.map
                    (\p ->
                        let
                            score =
                                getTotalSum (List.map (\v -> { v | counted = True }) game.values) p
                        in
                        { p | score = score }
                    )
                    game.players
            , values = game.values
            , finished = True
            , dateCreated = game.dateCreated
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
            , dateCreated = 1
            }
        )
        boxes


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowStartPage ->
            ( Model (SelectMode 0) model.highscoreList Focused False, Cmd.batch [ endGameCommand (), getGlobalHighscore () ] )

        WindowFocusedReceived dbGame userId ->
            ( Model (BlurredGame (Reconnecting dbGame userId)) model.highscoreList Blurred False
            , startIndividualGameCommand
                ( E.string
                    userId
                , E.string dbGame.id
                , E.string dbGame.code
                )
            )

        WindowBlurredReceived ->
            ( Model (BlurredGame Inactive) model.highscoreList Blurred False, Cmd.none )

        GlobalHighscoreReceived highscore ->
            ( Model model.mode highscore model.windowState model.isAdmin, Cmd.none )

        ReloadGame ->
            ( model, getValues () )

        _ ->
            case model.mode of
                BlurredGame blurredModel ->
                    case blurredModel of
                        Reconnecting dbGame userId ->
                            case msg of
                                RemoteValuesReceived dbValues ->
                                    let
                                        updatedValues =
                                            updateValues dbValues [] dbGame.users

                                        game =
                                            { id = dbGame.id
                                            , code = dbGame.code
                                            , players = dbGame.users
                                            , values = updatedValues
                                            , finished = dbGame.finished
                                            , dateCreated = dbGame.dateCreated
                                            }

                                        newGame =
                                            { game | values = updatedValues }

                                        playerMaybe =
                                            find (\p -> p.user.id == userId) dbGame.users
                                    in
                                    case playerMaybe of
                                        Just player ->
                                            ( Model
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
                                                        , selectedPlayer = player
                                                        }
                                                    )
                                                )
                                                model.highscoreList
                                                Focused
                                                model.isAdmin
                                            , Cmd.none
                                            )

                                        Nothing ->
                                            ( Model
                                                (Group
                                                    (Playing
                                                        { game = game
                                                        , boxes = getBoxes
                                                        , state = Idle
                                                        , currentValue = -1
                                                        , showGameInfo = False
                                                        , error = Nothing
                                                        }
                                                    )
                                                )
                                                model.highscoreList
                                                Focused
                                                model.isAdmin
                                            , Cmd.none
                                            )

                                _ ->
                                    ( model, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                SelectMode activeHighscoreTabIndex ->
                    case msg of
                        ChangeActiveHighscoreTab nextActiveHighscoreTabIndex ->
                            ( Model (SelectMode nextActiveHighscoreTabIndex) model.highscoreList model.windowState model.isAdmin, Cmd.none )

                        SelectIndividual ->
                            ( Model
                                (Individual
                                    (EnterGameCode
                                        ""
                                        []
                                    )
                                )
                                model.highscoreList
                                model.windowState
                                model.isAdmin
                            , getGames ()
                            )

                        SelectGroup ->
                            ( Model
                                (Group
                                    (PreGame
                                        { users = []
                                        , game =
                                            { id = ""
                                            , code = ""
                                            , players = []
                                            , values = []
                                            , finished = False
                                            , dateCreated = ""
                                            }
                                        , error = Nothing
                                        , currentNewPlayerName = ""
                                        , state = ShowAddRemovePlayers
                                        }
                                    )
                                )
                                model.highscoreList
                                model.windowState
                                model.isAdmin
                            , getUsers ()
                            )

                        _ ->
                            ( model, Cmd.none )

                Individual individualModel ->
                    if msg == Restart then
                        ( Model
                            (Individual
                                (EnterGameCode
                                    ""
                                    []
                                )
                            )
                            model.highscoreList
                            model.windowState
                            model.isAdmin
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
                                                        , dateCreated = dbGame.dateCreated
                                                        }
                                                    )
                                                    dbGames
                                        in
                                        ( Model (Individual (EnterGameCode (String.toUpper gameCode) allGames)) model.highscoreList model.windowState model.isAdmin, Cmd.none )

                                    EnterGame ->
                                        ( Model
                                            (Individual
                                                (WaitingForData
                                                    ( Nothing, Nothing )
                                                )
                                            )
                                            model.highscoreList
                                            model.windowState
                                            model.isAdmin
                                        , getGame (E.string gameCode)
                                        )

                                    GameCodeInputChange value ->
                                        let
                                            currentModel =
                                                individualModel
                                        in
                                        ( Model (Individual (EnterGameCode (String.toUpper value) games)) model.highscoreList model.windowState model.isAdmin, Cmd.none )

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
                                                        , dateCreated = dbGame.dateCreated
                                                        }
                                                in
                                                case dbValuesMaybe of
                                                    Nothing ->
                                                        ( Model
                                                            (Individual
                                                                (WaitingForData
                                                                    ( Just game
                                                                    , dbValuesMaybe
                                                                    )
                                                                )
                                                            )
                                                            model.highscoreList
                                                            model.windowState
                                                            model.isAdmin
                                                        , Cmd.none
                                                        )

                                                    Just dbValues ->
                                                        let
                                                            updatedValues =
                                                                updateValues dbValues game.values game.players

                                                            newGame =
                                                                { game | values = updatedValues }
                                                        in
                                                        ( Model
                                                            (Individual
                                                                (SelectPlayer
                                                                    { game = newGame
                                                                    , markedPlayer = NoPlayer
                                                                    }
                                                                )
                                                            )
                                                            model.highscoreList
                                                            model.windowState
                                                            model.isAdmin
                                                        , Cmd.none
                                                        )

                                            Nothing ->
                                                ( Model (Individual (EnterGameCode "" [])) model.highscoreList model.windowState model.isAdmin, getGames () )

                                    RemoteValuesReceived dbValues ->
                                        case gameMaybe of
                                            Nothing ->
                                                ( Model
                                                    (Individual
                                                        (WaitingForData
                                                            ( gameMaybe
                                                            , Just dbValues
                                                            )
                                                        )
                                                    )
                                                    model.highscoreList
                                                    model.windowState
                                                    model.isAdmin
                                                , Cmd.none
                                                )

                                            Just game ->
                                                let
                                                    updatedValues =
                                                        updateValues dbValues game.values game.players

                                                    newGame =
                                                        { game | values = updatedValues }
                                                in
                                                ( Model
                                                    (Individual
                                                        (SelectPlayer
                                                            { game = newGame
                                                            , markedPlayer = NoPlayer
                                                            }
                                                        )
                                                    )
                                                    model.highscoreList
                                                    model.windowState
                                                    model.isAdmin
                                                , Cmd.none
                                                )

                                    _ ->
                                        ( model, Cmd.none )

                            SelectPlayer selectPlayerModel ->
                                case msg of
                                    PlayerMarked player ->
                                        ( Model
                                            (Individual
                                                (SelectPlayer { selectPlayerModel | markedPlayer = Single player })
                                            )
                                            model.highscoreList
                                            model.windowState
                                            model.isAdmin
                                        , Cmd.none
                                        )

                                    AllPlayersMarked ->
                                        ( Model
                                            (Individual
                                                (SelectPlayer { selectPlayerModel | markedPlayer = All })
                                            )
                                            model.highscoreList
                                            model.windowState
                                            model.isAdmin
                                        , Cmd.none
                                        )

                                    Start ->
                                        case selectPlayerModel.markedPlayer of
                                            Single player ->
                                                startIndividualGame selectPlayerModel.game player model.highscoreList model.isAdmin

                                            All ->
                                                startGroupGame selectPlayerModel.game model.highscoreList model.isAdmin

                                            NoPlayer ->
                                                ( Model
                                                    (Individual
                                                        (SelectPlayer
                                                            { selectPlayerModel
                                                                | markedPlayer = NoPlayer
                                                            }
                                                        )
                                                    )
                                                    model.highscoreList
                                                    model.windowState
                                                    model.isAdmin
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
                                                    , dateCreated = game.dateCreated
                                                    }
                                            in
                                            ( Model
                                                (Individual
                                                    (IndividualPostGame
                                                        { game = currentGame, selectedPlayer = individualPlayingModel.selectedPlayer }
                                                    )
                                                )
                                                model.highscoreList
                                                model.windowState
                                                model.isAdmin
                                            , Cmd.batch [ Tuple.second gameModel, finishGame currentGame ]
                                            )

                                        else
                                            ( Model (Individual (IndividualPlaying { gamePlaying = Tuple.first gameModel, selectedPlayer = individualPlayingModel.selectedPlayer })) model.highscoreList model.windowState model.isAdmin
                                            , Tuple.second gameModel
                                            )

                            IndividualPostGame postGame ->
                                ( model, Cmd.none )

                Group groupModel ->
                    case groupModel of
                        PreGame preGame ->
                            if msg == Start then
                                startGroupGame preGame.game model.highscoreList model.isAdmin

                            else if msg == HideNotification then
                                ( Model (Group (PreGame { preGame | error = Nothing })) model.highscoreList model.windowState model.isAdmin, Cmd.none )

                            else
                                let
                                    newModel =
                                        Tuple.mapFirst PreGame <| updatePreGame msg preGame
                                in
                                ( Model (Group (Tuple.first newModel)) model.highscoreList model.windowState model.isAdmin, Tuple.second newModel )

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
                                                        , dateCreated = playingModel.game.dateCreated
                                                        }
                                                in
                                                ( Model
                                                    (Group
                                                        (PostGame
                                                            { game = currentGame
                                                            , boxes = playingModel.boxes
                                                            , state = GameFinished
                                                            , countedPlayers = []
                                                            , countedValues = []
                                                            , showGameInfo = False
                                                            , error = Nothing
                                                            }
                                                        )
                                                    )
                                                    model.highscoreList
                                                    model.windowState
                                                    model.isAdmin
                                                , Cmd.batch [ Tuple.second gameModel, finishGame playingModel.game ]
                                                )

                                            else
                                                ( Model
                                                    (Group (Tuple.first gameModel))
                                                    model.highscoreList
                                                    model.windowState
                                                    model.isAdmin
                                                , Tuple.second gameModel
                                                )

                                        _ ->
                                            ( model
                                            , Cmd.none
                                            )

                        PostGame postGame ->
                            if msg == Restart then
                                ( Model
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
                                                , dateCreated = ""
                                                }
                                            , error = Nothing
                                            , state = ShowAddRemovePlayers
                                            }
                                        )
                                    )
                                    model.highscoreList
                                    model.windowState
                                    model.isAdmin
                                , getUsers ()
                                )

                            else
                                let
                                    newModel =
                                        Tuple.mapFirst PostGame <| updatePostGame msg postGame
                                in
                                ( Model (Group (Tuple.first newModel)) model.highscoreList model.windowState model.isAdmin, Tuple.second newModel )



---- VIEW ----


view : Model -> Html Msg
view model =
    case model.mode of
        BlurredGame blurredModel ->
            case blurredModel of
                Inactive ->
                    windowBlurred

                Reconnecting game userId ->
                    windowFocused

        SelectMode activeHighscoreTabIndex ->
            startPage model.highscoreList activeHighscoreTabIndex

        Individual individualModel ->
            case model.windowState of
                Blurred ->
                    windowBlurred

                _ ->
                    case individualModel of
                        EnterGameCode gameCode games ->
                            enterGameCode gameCode
                                games

                        WaitingForData ( game, values ) ->
                            div [ class "waiting-for-game" ]
                                [ loader "Ansluter till spelet ..." True
                                ]

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
                                                            [ div [] [ scoreDialog playingModel box currentPlayer isEdit ]
                                                            , div [] [ interactiveScoreCard currentPlayer (Just gamePlayingModel.selectedPlayer) game False ]
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

                        gameInformation =
                            if finishedModel.showGameInfo then
                                gameInfo finishedModel.game

                            else
                                div [] []
                    in
                    case currentPlayerMaybe of
                        Just currentPlayer ->
                            let
                                content =
                                    case finishedModel.state of
                                        GameFinished ->
                                            div []
                                                [ gameInformation
                                                , div [] [ gameFinished ]
                                                , div [] [ staticScoreCard currentPlayer finishedModel.game False False ]
                                                ]

                                        ShowCountedValues ->
                                            div []
                                                [ gameInformation
                                                , div [] [ staticScoreCard currentPlayer finishedModel.game True True ]
                                                ]

                                        ShowResults ->
                                            div []
                                                [ gameInformation
                                                , div [] [ highscore finishedModel.game.players finishedModel.game.values ]
                                                , div [] [ staticScoreCard currentPlayer finishedModel.game False True ]
                                                ]

                                        HideResults ->
                                            div []
                                                [ gameInformation
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

        -- _ =
        --     Debug.log "gameCreated()" (Debug.toString gameMaybe)
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
            -- let
            --     _ =
            --         Debug.log "gamesUpdated" (Debug.toString err)
            -- in
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
            -- let
            --     _ =
            --         Debug.log "remoteValuesUpdated" (Debug.toString err)
            -- in
            NoOp


globalHighscoreUpdated : Json.Decode.Value -> Msg
globalHighscoreUpdated valuesJson =
    let
        itemsMaybe =
            Json.Decode.decodeValue globalHighscoresDecoder valuesJson
    in
    case itemsMaybe of
        Ok items ->
            GlobalHighscoreReceived items

        Err err ->
            -- let
            --     _ =
            --         Debug.log "globalHighscoreUpdated" (Debug.toString err)
            -- in
            NoOp


windowBlurUpdated : Int -> Msg
windowBlurUpdated windowState =
    WindowBlurredReceived


windowStateFocused : Json.Decode.Value -> Msg
windowStateFocused valuesJson =
    let
        focusedGameAndUserMaybe =
            Json.Decode.decodeValue
                (Json.Decode.map2 GameAndUserId
                    (Json.Decode.field "game" gameDecoder)
                    (Json.Decode.field "userId" Json.Decode.string)
                )
                valuesJson
    in
    case focusedGameAndUserMaybe of
        Ok focusedGameAndUser ->
            WindowFocusedReceived
                focusedGameAndUser.game
                focusedGameAndUser.userId

        Err err ->
            -- let
            --     _ =
            --         Debug.log "windowStateFocused" (Debug.toString err)
            -- in
            NoOp


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        allSubscriptions =
            [ usersReceived remoteUsersUpdated
            , gameReceived gameCreated
            , valuesReceived remoteValuesUpdated
            , gamesReceived gamesUpdated
            , highscoreReceived globalHighscoreUpdated
            , onBlurReceived windowBlurUpdated
            , onFocusReceived windowStateFocused
            ]
    in
    case model.mode of
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
