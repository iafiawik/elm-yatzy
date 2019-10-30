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
import Model.Box exposing (Box, getAcceptedValues, getBoxById, getBoxes, getDefaultMarkedValue, getInteractiveBoxes)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Error exposing (Error(..))
import Model.Game exposing (DbGame, Game, fromDbGameToGame, gameDecoder, gamesDecoder, getActivePlayer, getTotalSum, getValueByPlayerAndBox)
import Model.GameState exposing (GameState(..))
import Model.GlobalHighscore exposing (GlobalHighscore, globalHighscoresDecoder)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem, globalHighscoreItemDecoder, globalHighscoreItemsDecoder)
import Model.Player exposing (Player)
import Model.User exposing (User, userDecoder, usersDecoder)
import Model.Value exposing (DbValue, Value, encodeValue, valueDecoder)
import Model.WindowState exposing (WindowState(..))
import Models exposing (BlurredModel(..), GameAndUserId, MarkedPlayer(..), Mode(..), Model, Msg(..))
import Task
import Time
import Views.AddRemovePlayers exposing (addRemovePlayers)
import Views.EnterGameCode exposing (enterGameCode)
import Views.GameFinished exposing (gameFinished)
import Views.GameInfo exposing (gameInfo)
import Views.GlobalHighscore exposing (globalHighscore)
import Views.Highscore exposing (highscore)
import Views.IndividualHighscore exposing (individualHighscore)
import Views.IndividualJoinInfo exposing (individualJoinInfo)
import Views.Loader exposing (loader)
import Views.Notification exposing (notification)
import Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)
import Views.ScoreDialog exposing (scoreDialog)
import Views.SelectPlayer exposing (selectPlayer)
import Views.StartPage exposing (startPage)
import Views.WaitingForGame exposing (waitingForGame)
import Views.WindowBlurred exposing (windowBlurred)
import Views.WindowFocused exposing (windowFocused)


port fillWithDummyValues : List E.Value -> Cmd msg


port getGlobalHighscore : () -> Cmd msg


port getGame : E.Value -> Cmd msg


port startGameCommand : E.Value -> Cmd msg


port startGameWithMarkedPlayerCommand : ( E.Value, E.Value ) -> Cmd msg


port endGameCommand : () -> Cmd msg


port getGames : () -> Cmd msg


port getUpdatedGame : () -> Cmd msg


port getUsers : () -> Cmd msg


port createUser : E.Value -> Cmd msg


port createGame : E.Value -> Cmd msg


port createValue : E.Value -> Cmd msg


port editValue : E.Value -> Cmd msg


port deleteValue : E.Value -> Cmd msg


port usersReceived : (Json.Decode.Value -> msg) -> Sub msg


port gameReceived : (Json.Decode.Value -> msg) -> Sub msg


port gamesReceived : (Json.Decode.Value -> msg) -> Sub msg


port highscoreReceived : (Json.Decode.Value -> msg) -> Sub msg


port onBlurReceived : (Int -> msg) -> Sub msg


port onFocusReceived : (Json.Decode.Value -> msg) -> Sub msg



---- MODEL ----


type alias Flags =
    { isAdmin : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model (StartPage 0) [] [] [] Focused flags.isAdmin, Cmd.batch [ getUsers (), getGames () ] )


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
-- updatePreGame : Msg -> GameSetup -> List User -> ( GameSetup, Cmd Msg )
-- updatePreGame msg model users =
--     let
--         _ =
--             Debug.log "updatePreGame"
--     in
--     case msg of
--         NewPlayerInputValueChange value ->
--             ( { model | currentNewPlayerName = value }, Cmd.none )
--
--         GameReceived game ->
--             ( model
--             , Cmd.none
--             )
--
--         AddUser ->
--             if find (\u -> String.toLower u.name == String.toLower model.currentNewPlayerName) users == Nothing then
--                 let
--                     name =
--                         model.currentNewPlayerName
--                 in
--                 ( { model | currentNewPlayerName = "", error = Nothing }
--                 , createUser (E.string name)
--                 )
--
--             else
--                 ( { model | error = Just (UserAlreadyExists model.currentNewPlayerName) }
--                 , Cmd.none
--                 )
--
--         AddPlayer user ->
--             let
--                 newPlayer =
--                     { user = user, values = [] }
--
--                 newPlayers =
--                     newPlayer :: model.players
--             in
--             ( { model
--                 | players = newPlayers
--                 , currentNewPlayerName = ""
--               }
--             , Cmd.none
--             )
--
--         RemovePlayer player ->
--             let
--                 playerIndexMaybe =
--                     findIndex (\a -> a.user.id == player.user.id) model.players
--             in
--             case playerIndexMaybe of
--                 Just playerIndex ->
--                     let
--                         newPlayers =
--                             removeAt playerIndex model.players
--                     in
--                     ( { model | players = newPlayers }, Cmd.none )
--
--                 Nothing ->
--                     ( model, Cmd.none )
--
--         PlayersAdded ->
--             ( { model | state = ShowIndividualJoinInfo }, createGame (E.list E.string (List.map (\p -> p.user.id) model.players)) )
--
--         _ ->
--             ( model, Cmd.none )


flippedComparison a b =
    case compare a.dateCreated b.dateCreated of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT



-- updateGame : Msg -> GamePlaying -> Game -> ( GamePlaying, Cmd Msg )
-- updateGame msg model game =
--     let
--         _ =
--             Debug.log "UpdateGame()" (Debug.toString msg)
--     in
--     case msg of
--         AddValue ->
--             case model.state of
--                 Input box isEdit ->
--                     ( { model
--                         | state = Idle
--                         , currentValue = -1
--                       }
--                     , createValue
--                         (E.object
--                             [ ( "userId", E.string game.activePlayer.user.id )
--                             , ( "gameId", E.string game.id )
--                             , ( "value", E.int model.currentValue )
--                             , ( "boxId", E.string box.id )
--                             ]
--                         )
--                     )
--
--                 _ ->
--                     ( model, Cmd.none )
--
--         RemoveValue ->
--             case model.state of
--                 Input box isEdit ->
--                     ( { model
--                         | state = Idle
--                         , currentValue = -1
--                       }
--                     , deleteValue
--                         (E.object
--                             [ ( "userId", E.string game.activePlayer.user.id )
--                             , ( "gameId", E.string game.id )
--                             , ( "boxId", E.string box.id )
--                             ]
--                         )
--                     )
--
--                 _ ->
--                     ( model, Cmd.none )
--
--         ValueMarked value ->
--             ( { model | currentValue = value }, Cmd.none )
--
--         InputValueChange value ->
--             ( { model | currentValue = String.toInt value |> Maybe.withDefault 0 }, Cmd.none )
--
--         ShowAddValue box ->
--             let
--                 markedValueMaybe =
--                     getDefaultMarkedValue box
--             in
--             case markedValueMaybe of
--                 Just markedValue ->
--                     ( { model | state = Input box False, currentValue = markedValue }, Cmd.none )
--
--                 Nothing ->
--                     ( { model | state = Input box False }, Cmd.none )
--
--         ShowEditValue value ->
--             ( { model | state = Input value.box True, currentValue = value.value }, Cmd.none )
--
--         HideAddValue ->
--             ( { model
--                 | state = Idle
--                 , currentValue = -1
--               }
--             , Cmd.none
--             )
--
--         ShowGameInfo ->
--             ( { model | showGameInfo = True }, Cmd.none )
--
--         HideGameInfo ->
--             ( { model | showGameInfo = False }, Cmd.none )
--
--         _ ->
--             ( model, Cmd.none )
-- updatePostGame : Msg -> GameResult -> ( GameResult, Cmd Msg )
-- updatePostGame msg model =
--     case msg of
--         CountValues ->
--             ( { model | state = ShowCountedValues }, Cmd.none )
--
--         -- CountValuesTick newTime ->
--         --     let
--         --         nextValueToAnimateMaybe =
--         --             getNextValueToAnimate model.game.players model.game.values
--         --     in
--         --     case nextValueToAnimateMaybe of
--         --         Just nextValue ->
--         --             let
--         --                 updatedValues =
--         --                     List.map
--         --                         (\v ->
--         --                             if v.box == nextValue.box && v.player == nextValue.player then
--         --                                 { v | counted = True }
--         --
--         --                             else
--         --                                 v
--         --                         )
--         --                         model.game.values
--         --
--         --                 currentGame =
--         --                     model.game
--         --             in
--         --             ( { model | game = { currentGame | values = updatedValues } }, Cmd.none )
--         --
--         --         Nothing ->
--         --             ( { model | state = ShowResults }, Cmd.none )
--         HideHighscore ->
--             ( { model | state = HideResults }, Cmd.none )
--
--         ShowGameInfo ->
--             ( { model | showGameInfo = True }, Cmd.none )
--
--         HideGameInfo ->
--             ( { model | showGameInfo = False }, Cmd.none )
--
--         _ ->
--             ( model, Cmd.none )
--
--
--
-- --
-- startIndividualGame : Model -> Player -> ( Model, Cmd Msg )
-- startIndividualGame model selectedPlayer =
--     let
--         _ =
--             Debug.log "startIndividualGame" (Debug.toString model.game)
--
--         gameMaybe =
--             model.game
--     in
--     case gameMaybe of
--         Nothing ->
--             ( model, Cmd.none )
--
--         Just game ->
--             ( Model
--                 (Individual
--                     (IndividualPlaying
--                         { gamePlaying =
--                             { boxes = getBoxes
--                             , state = Idle
--                             , currentValue = -1
--                             , showGameInfo = False
--                             , error = Nothing
--                             }
--                         , selectedPlayer = selectedPlayer
--                         }
--                     )
--                 )
--                 (Just game)
--                 model.users
--                 model.highscoreList
--                 model.windowState
--                 model.isAdmin
--             , startIndividualGameCommand ( E.string selectedPlayer.user.id, E.string game.id, E.string game.code )
--             )
--
-- startGroupGame : Model -> ( Model, Cmd Msg )
-- startGroupGame model =
--     let
--         _ =
--             Debug.log "startGroupCommand" (Debug.toString model.game)
--
--         gameMaybe =
--             model.game
--     in
--     case gameMaybe of
--         Nothing ->
--             ( model, Cmd.none )
--
--         Just game ->
--             ( Model
--                 (Group
--                     (Playing
--                         { boxes = getBoxes
--                         , state = Idle
--                         , currentValue = 0
--                         , showGameInfo = False
--                         , error = Nothing
--                         }
--                     )
--                 )
--                 (Just game)
--                 model.users
--                 model.highscoreList
--                 model.windowState
--                 model.isAdmin
--             , startGroupGameCommand ( E.string game.id, E.string game.code )
--             )
--


isGameFinished : Game -> Bool
isGameFinished game =
    game.finished



--
-- finishGame : Game -> Cmd Msg
-- finishGame game =
--     let
--         currentGame =
--             { id = ""
--             , code = game.code
--             , players =
--                 List.map
--                     (\p ->
--                         let
--                             score =
--                                 getTotalSum (List.map (\v -> { v | counted = True }) game.values) p
--                         in
--                         { p | score = score }
--                     )
--                     game.players
--             , values = game.values
--             , finished = True
--             , dateCreated = game.dateCreated
--             }
--     in
--     editGame (  (E.object
--           [ ( "userId", E.string model.activePlayer.user.userId )
--           , ( "gameId", E.string model.game.id )
--           , ( "boxId", E.string box.id )
--           ]
--       ))
--
-- createDummyValues : Player -> List Value -> List Value
-- createDummyValues player existingValues =
--     let
--         playerValues =
--             List.filter (\v -> v.player == player) existingValues
--
--         boxes =
--             List.filter
--                 (\b ->
--                     if find (\existing -> existing.id == b.id) playerValues == Nothing then
--                         True
--
--                     else
--                         False
--                 )
--                 getInteractiveBoxes
--     in
--     List.map
--         (\box ->
--             let
--                 acceptedValues =
--                     getAcceptedValues box
--
--                 selectedValue =
--                     Maybe.withDefault 0 (List.head acceptedValues)
--             in
--             { id = ""
--             , box = box
--             , player = player
--             , value = selectedValue
--             , counted = False
--             , new = False
--             , dateCreated = 1
--             }
--         )
--         boxes


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "update(): " (Debug.toString msg)
    in
    case msg of
        ShowStartPage ->
            ( { model | mode = StartPage 0 }, Cmd.batch [ getGlobalHighscore (), endGameCommand () ] )

        WindowBlurredReceived ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | windowState = Blurred }, Cmd.none )

                StartPage activeHighscoreTabIndex ->
                    ( { model | windowState = Blurred }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        WindowFocusedReceived upatedGame userId ->
            let
                previouslyMarkedPlayer =
                    case find (\player -> player.user.id == userId) upatedGame.players of
                        Just player ->
                            Single player

                        Nothing ->
                            All
            in
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | windowState = Focused, mode = Playing upatedGame previouslyMarkedPlayer gameState currentValue showGameInfo }, Cmd.none )

                StartPage activeHighscoreTabIndex ->
                    ( { model | windowState = Focused, mode = Playing upatedGame previouslyMarkedPlayer Idle -1 False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ReloadGame ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( model, getGame (E.string game.code) )

                ShowFinishedScoreCard game markedPlayer showGameInfo ->
                    ( model, getGame (E.string game.code) )

                _ ->
                    ( model, Cmd.none )

        CreateGame ->
            ( { model | mode = ShowAddRemovePlayers [] "" }, Cmd.none )

        JoinExistingGame ->
            ( { model | mode = EnterGameCode "" }, getGames () )

        EnterGame ->
            case model.mode of
                EnterGameCode gameCode ->
                    ( { model | mode = WaitForGame False }
                    , getGame (E.string gameCode)
                    )

                _ ->
                    ( model, Cmd.none )

        GameCodeInputChange value ->
            ( { model | mode = EnterGameCode (String.toUpper value) }, Cmd.none )

        RemoteUsers users ->
            ( { model
                | users = users
              }
            , Cmd.none
            )

        AddPlayer user ->
            case model.mode of
                ShowAddRemovePlayers users currentNewPlayerName ->
                    ( { model | mode = ShowAddRemovePlayers (user :: users) "" }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        RemovePlayer user ->
            case model.mode of
                ShowAddRemovePlayers users currentNewPlayerName ->
                    let
                        playerIndexMaybe =
                            findIndex (\a -> a.id == user.id) users
                    in
                    case playerIndexMaybe of
                        Just playerIndex ->
                            ( { model | mode = ShowAddRemovePlayers (removeAt playerIndex users) "" }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        NewPlayerInputValueChange value ->
            case model.mode of
                ShowAddRemovePlayers users currentNewPlayerName ->
                    ( { model | mode = ShowAddRemovePlayers users value }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CreateUser ->
            case model.mode of
                ShowAddRemovePlayers users currentNewPlayerName ->
                    if find (\u -> String.toLower u.name == String.toLower currentNewPlayerName) users == Nothing then
                        ( { model | mode = ShowAddRemovePlayers users "" }, createUser (E.string currentNewPlayerName) )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PlayersAdded ->
            case model.mode of
                ShowAddRemovePlayers users currentNewPlayerName ->
                    ( { model | mode = WaitForGame True }, createGame (E.list E.string (List.map (\user -> user.id) users)) )

                _ ->
                    ( model, Cmd.none )

        GameReceived updatedGame ->
            case model.mode of
                WaitForGame isNewGame ->
                    if isNewGame == True then
                        if List.length updatedGame.players == 1 then
                            ( { model | mode = Playing updatedGame All Idle -1 False }
                            , startGameCommand
                                (E.string updatedGame.id)
                            )

                        else
                            ( { model | mode = ShowGameCode updatedGame }, Cmd.none )

                    else if List.length updatedGame.players == 1 then
                        ( { model | mode = Playing updatedGame All Idle -1 False }
                        , startGameCommand
                            (E.string updatedGame.id)
                        )

                    else
                        ( { model | mode = SelectPlayer updatedGame NoPlayer }, Cmd.none )

                Playing game markedPlayer gameState currentValue showGameInfo ->
                    if updatedGame.finished /= True then
                        ( { model | mode = Playing updatedGame markedPlayer gameState currentValue showGameInfo }, Cmd.none )

                    else
                        ( { model | mode = ShowGameFinished updatedGame markedPlayer }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GamesReceived allGames ->
            ( { model | games = allGames }, Cmd.none )

        ShowSelectPlayer ->
            case model.mode of
                ShowGameCode game ->
                    if List.length game.players == 1 then
                        ( { model | mode = Playing game All Idle -1 False }
                        , startGameCommand
                            (E.string game.id)
                        )

                    else
                        ( { model | mode = SelectPlayer game NoPlayer }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PlayerMarked player ->
            case model.mode of
                SelectPlayer game previouslyMarkedPlayer ->
                    ( { model | mode = SelectPlayer game (Single player) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        AllPlayersMarked ->
            case model.mode of
                SelectPlayer game previouslyMarkedPlayer ->
                    ( { model | mode = SelectPlayer game All }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Start ->
            case model.mode of
                SelectPlayer game markedPlayer ->
                    if game.finished == True then
                        ( { model | mode = ShowFinishedScoreCard game (getMarkedPlayer markedPlayer) False }, Cmd.none )

                    else
                        let
                            cmd =
                                case markedPlayer of
                                    Single player ->
                                        startGameWithMarkedPlayerCommand
                                            ( E.string game.id, E.string player.user.id )

                                    _ ->
                                        startGameCommand
                                            (E.string game.id)
                        in
                        ( { model | mode = Playing game (getMarkedPlayer markedPlayer) Idle -1 False }
                        , cmd
                        )

                _ ->
                    ( model, Cmd.none )

        ShowEditValue value ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | mode = Playing game markedPlayer (Input value.box True) value.value showGameInfo }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ShowAddValue box ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    let
                        markedValueMaybe =
                            getDefaultMarkedValue box
                    in
                    case markedValueMaybe of
                        Just markedValue ->
                            ( { model | mode = Playing game markedPlayer (Input box False) markedValue showGameInfo }, Cmd.none )

                        Nothing ->
                            ( { model | mode = Playing game markedPlayer (Input box False) -1 showGameInfo }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        HideAddValue ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | mode = Playing game markedPlayer Idle -1 showGameInfo }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ValueMarked value ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | mode = Playing game markedPlayer gameState value showGameInfo }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        AddValue ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    case gameState of
                        Input box isEdit ->
                            ( { model | mode = Playing game markedPlayer Idle -1 showGameInfo }
                            , createValue
                                (E.object
                                    [ ( "userId", E.string game.activePlayer.user.id )
                                    , ( "gameId", E.string game.id )
                                    , ( "value", E.int currentValue )
                                    , ( "boxId", E.string box.id )
                                    ]
                                )
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        RemoveValue ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    case gameState of
                        Input box isEdit ->
                            ( { model | mode = Playing game markedPlayer Idle -1 showGameInfo }
                            , createValue
                                (E.object
                                    [ ( "userId", E.string game.activePlayer.user.id )
                                    , ( "gameId", E.string game.id )
                                    , ( "value", E.int -1 )
                                    , ( "boxId", E.string box.id )
                                    ]
                                )
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ShowGameInfo ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | mode = Playing game markedPlayer gameState currentValue True }, Cmd.none )

                ShowFinishedScoreCard game markedPlayer showGameInfo ->
                    ( { model | mode = ShowFinishedScoreCard game markedPlayer True }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        HideGameInfo ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | mode = Playing game markedPlayer gameState currentValue False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ShowGameHighscore ->
            case model.mode of
                ShowGameFinished game markedPlayer ->
                    ( { model | mode = ShowGameResults game markedPlayer }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        HideGameHighscore ->
            case model.mode of
                ShowGameResults game markedPlayer ->
                    ( { model | mode = ShowFinishedScoreCard game markedPlayer False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Restart ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | mode = ShowAddRemovePlayers (List.map (\player -> player.user) game.players) "" }, Cmd.none )

                ShowFinishedScoreCard game markedPlayer showGameInfo ->
                    ( { model | mode = ShowAddRemovePlayers (List.map (\player -> player.user) game.players) "" }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


getMarkedPlayer : MarkedPlayer -> MarkedPlayer
getMarkedPlayer markedPlayer =
    markedPlayer



-- case markedPlayer of
--     Single player ->
--         Just player
--
--     _ ->
--         Nothing
-- update : Msg -> Model -> ( Model, Cmd Msg )
-- update msg model =
--     let
--         _ =
--             Debug.log "update(), msg" (Debug.toString msg)
--
--         _ =
--             Debug.log "update(), model" (Debug.toString model)
--     in
--     case msg of
--         ShowStartPage ->
--             ( Model (StartPage 0) model.game model.users model.highscoreList Focused False, Cmd.batch [ endGameCommand (), getGlobalHighscore () ] )
--
--         WindowFocusedReceived game userId ->
--             ( Model (BlurredGame (Reconnecting game userId)) model.game model.users model.highscoreList model.windowState False
--             , startIndividualGameCommand
--                 ( E.string
--                     userId
--                 , E.string game.id
--                 , E.string game.code
--                 )
--             )
--
--         WindowBlurredReceived ->
--             ( Model (BlurredGame Inactive) model.game model.users model.highscoreList Blurred False, Cmd.none )
--
--         GlobalHighscoreReceived highscore ->
--             ( Model model.mode model.game model.users highscore model.windowState model.isAdmin, Cmd.none )
--
--         ReloadGame ->
--             ( model, getUsers () )
--
--         -- Individual WaitingForGame ->
--         --     ( Model (Individual (SelectPlayer NoPlayer)) (Just game) model.users model.highscoreList model.windowState model.isAdmin, Cmd.none )
--         --
--         -- Group (PreGame preGame) ->
--         --     ( Model (Group (PreGame { preGame | state = ShowIndividualJoinInfo })) (Just game) model.users model.highscoreList model.windowState model.isAdmin, Cmd.none )
--         --
--         -- IndividualPlaying ->
--         -- _ ->
--         --     ( { model
--         --         | game = Just game
--         --       }
--         --     , Cmd.none
--         --     )
--         RemoteUsers users ->
--             ( { model
--                 | users = users
--               }
--             , Cmd.none
--             )
--
--         _ ->
--             case model.mode of
--                 BlurredGame blurredModel ->
--                     case blurredModel of
--                         _ ->
--                             ( model, Cmd.none )
--
--                 StartPage activeHighscoreTabIndex ->
--                     case msg of
--                         ChangeActiveHighscoreTab nextActiveHighscoreTabIndex ->
--                             ( Model (StartPage nextActiveHighscoreTabIndex) model.game model.users model.highscoreList model.windowState model.isAdmin, Cmd.none )
--
--                         SelectIndividual ->
--                             ( Model
--                                 (Individual
--                                     (EnterGameCode
--                                         ""
--                                         []
--                                     )
--                                 )
--                                 model.game
--                                 model.users
--                                 model.highscoreList
--                                 model.windowState
--                                 model.isAdmin
--                             , getGames ()
--                             )
--
--                         SelectGroup ->
--                             ( Model
--                                 (Group
--                                     (PreGame
--                                         { players = []
--                                         , error = Nothing
--                                         , currentNewPlayerName = ""
--                                         , state = ShowAddRemovePlayers
--                                         }
--                                     )
--                                 )
--                                 model.game
--                                 model.users
--                                 model.highscoreList
--                                 model.windowState
--                                 model.isAdmin
--                             , getUsers ()
--                             )
--
--                         _ ->
--                             ( model, Cmd.none )
--
--                 Individual individualModel ->
--                     if msg == Restart then
--                         ( Model
--                             (Individual
--                                 (EnterGameCode
--                                     ""
--                                     []
--                                 )
--                             )
--                             model.game
--                             model.users
--                             model.highscoreList
--                             model.windowState
--                             model.isAdmin
--                         , getGames ()
--                         )
--
--                     else
--                         case individualModel of
--                             EnterGameCode gameCode games ->
--                                 case msg of
--                                     GamesReceived allGames ->
--                                         let
--                                             currentModel =
--                                                 individualModel
--                                         in
--                                         ( Model (Individual (EnterGameCode (String.toUpper gameCode) allGames)) model.game model.users model.highscoreList model.windowState model.isAdmin, Cmd.none )
--
--                                     EnterGame ->
--                                         ( Model
--                                             (Individual
--                                                 WaitingForGame
--                                             )
--                                             model.game
--                                             model.users
--                                             model.highscoreList
--                                             model.windowState
--                                             model.isAdmin
--                                         , getGame (E.string gameCode)
--                                         )
--
--                                     GameCodeInputChange value ->
--                                         let
--                                             currentModel =
--                                                 individualModel
--                                         in
--                                         ( Model (Individual (EnterGameCode (String.toUpper value) games)) model.game model.users model.highscoreList model.windowState model.isAdmin, Cmd.none )
--
--                                     _ ->
--                                         ( model, Cmd.none )
--
--                             SelectPlayer markedPlayer ->
--                                 let
--                                     gameMaybe =
--                                         model.game
--                                 in
--                                 case gameMaybe of
--                                     Nothing ->
--                                         ( model, Cmd.none )
--
--                                     Just game ->
--                                         case msg of
--                                             PlayerMarked player ->
--                                                 ( Model
--                                                     (Individual
--                                                         (SelectPlayer (Single player))
--                                                     )
--                                                     model.game
--                                                     model.users
--                                                     model.highscoreList
--                                                     model.windowState
--                                                     model.isAdmin
--                                                 , Cmd.none
--                                                 )
--
--                                             AllPlayersMarked ->
--                                                 ( Model
--                                                     (Individual
--                                                         (SelectPlayer All)
--                                                     )
--                                                     model.game
--                                                     model.users
--                                                     model.highscoreList
--                                                     model.windowState
--                                                     model.isAdmin
--                                                 , Cmd.none
--                                                 )
--
--                                             Start ->
--                                                 case markedPlayer of
--                                                     Single player ->
--                                                         startIndividualGame model player
--
--                                                     All ->
--                                                         startGroupGame model
--
--                                                     NoPlayer ->
--                                                         ( Model
--                                                             (Individual
--                                                                 (SelectPlayer
--                                                                     NoPlayer
--                                                                 )
--                                                             )
--                                                             model.game
--                                                             model.users
--                                                             model.highscoreList
--                                                             model.windowState
--                                                             model.isAdmin
--                                                         , Cmd.none
--                                                         )
--
--                                             _ ->
--                                                 ( model, Cmd.none )
--
--                             IndividualPlaying individualPlayingModel ->
--                                 let
--                                     gameMaybe =
--                                         model.game
--                                 in
--                                 case gameMaybe of
--                                     Nothing ->
--                                         ( model, Cmd.none )
--
--                                     Just game ->
--                                         case msg of
--                                             -- FillWithDummyValues player ->
--                                             --     ( model, fillWithDummyValues (encodeValues (createDummyValues player individualPlayingModel.gamePlaying.game.values)) )
--                                             _ ->
--                                                 let
--                                                     gameModel =
--                                                         updateGame msg individualPlayingModel.gamePlaying game
--
--                                                     gamePlaying =
--                                                         Tuple.first gameModel
--                                                 in
--                                                 if game.finished then
--                                                     ( Model
--                                                         (Individual
--                                                             (IndividualPostGame
--                                                                 { selectedPlayer = individualPlayingModel.selectedPlayer }
--                                                             )
--                                                         )
--                                                         (Just game)
--                                                         model.users
--                                                         model.highscoreList
--                                                         model.windowState
--                                                         model.isAdmin
--                                                     , Cmd.batch [ Tuple.second gameModel ]
--                                                     )
--
--                                                 else
--                                                     ( Model (Individual (IndividualPlaying { gamePlaying = Tuple.first gameModel, selectedPlayer = individualPlayingModel.selectedPlayer })) model.game model.users model.highscoreList model.windowState model.isAdmin
--                                                     , Tuple.second gameModel
--                                                     )
--
--                             IndividualPostGame postGame ->
--                                 ( model, Cmd.none )
--
--                             _ ->
--                                 ( model, Cmd.none )
--
--                 Group groupModel ->
--                     case groupModel of
--                         PreGame preGame ->
--                             case msg of
--                                 Start ->
--                                     startGroupGame model
--
--                                 GameReceived updatedGame ->
--                                     ( { model
--                                         | game = Just updatedGame
--                                       }
--                                     , Cmd.none
--                                     )
--
--                                 _ ->
--                                     let
--                                         newModel =
--                                             Tuple.mapFirst PreGame <| updatePreGame msg preGame model.users
--                                     in
--                                     ( Model (Group (Tuple.first newModel)) model.game model.users model.highscoreList model.windowState model.isAdmin, Tuple.second newModel )
--
--                         Playing gamePlaying ->
--                             case msg of
--                                 -- FillWithDummyValues player ->
--                                 --     ( model, fillWithDummyValues (encodeValues (createDummyValues player gamePlaying.game.values)) )
--                                 GameReceived updatedGame ->
--                                     ( { model
--                                         | game = Just updatedGame
--                                       }
--                                     , Cmd.none
--                                     )
--
--                                 _ ->
--                                     let
--                                         gameModel =
--                                             Tuple.mapFirst Playing <| updateGame msg gamePlaying game
--                                     in
--                                     case Tuple.first gameModel of
--                                         Playing playingModel ->
--                                             if game.finished then
--                                                 ( Model
--                                                     (Group
--                                                         (PostGame
--                                                             { boxes = playingModel.boxes
--                                                             , state = GameFinished
--                                                             , countedPlayers = []
--                                                             , countedValues = []
--                                                             , showGameInfo = False
--                                                             , error = Nothing
--                                                             }
--                                                         )
--                                                     )
--                                                     (Just game)
--                                                     model.users
--                                                     model.highscoreList
--                                                     model.windowState
--                                                     model.isAdmin
--                                                 , Cmd.batch [ Tuple.second gameModel ]
--                                                 )
--
--                                             else
--                                                 ( Model
--                                                     (Group (Tuple.first gameModel))
--                                                     model.game
--                                                     model.users
--                                                     model.highscoreList
--                                                     model.windowState
--                                                     model.isAdmin
--                                                 , Tuple.second gameModel
--                                                 )
--
--                                         _ ->
--                                             ( model
--                                             , Cmd.none
--                                             )
--
--                         PostGame postGame ->
--                             if msg == Restart then
--                                 ( Model
--                                     (Group
--                                         (PreGame
--                                             { currentNewPlayerName = ""
--                                             , players = []
--                                             , error = Nothing
--                                             , state = ShowAddRemovePlayers
--                                             }
--                                         )
--                                     )
--                                     model.game
--                                     model.users
--                                     model.highscoreList
--                                     model.windowState
--                                     model.isAdmin
--                                 , getUsers ()
--                                 )
--
--                             else
--                                 let
--                                     newModel =
--                                         Tuple.mapFirst PostGame <| updatePostGame msg postGame
--                                 in
--                                 ( Model (Group (Tuple.first newModel)) Nothing model.users model.highscoreList model.windowState model.isAdmin, Tuple.second newModel )
--
--
--
-- ---- VIEW ----
--
--


view : Model -> Html Msg
view model =
    let
        content =
            getContent model

        windowStateInfo =
            if model.windowState == Blurred then
                windowBlurred

            else
                div [] []
    in
    div [] [ windowStateInfo, content ]


getContent : Model -> Html Msg
getContent model =
    -- let
    --     _ =
    --         Debug.log "view: " Debug.toString model.mode
    -- in
    case model.mode of
        StartPage activeHighscoreTabIndex ->
            startPage model.highscoreList activeHighscoreTabIndex

        EnterGameCode gameCode ->
            enterGameCode gameCode model.games

        ShowAddRemovePlayers users currentNewPlayerName ->
            div [] [ addRemovePlayers users currentNewPlayerName model.users ]

        WaitForGame isNewGame ->
            waitingForGame isNewGame

        ShowGameCode game ->
            individualJoinInfo game

        SelectPlayer game markedPlayer ->
            selectPlayer game markedPlayer

        Playing game markedPlayer gameState currentValue showGameInfo ->
            let
                gameInformation =
                    if showGameInfo then
                        gameInfo game

                    else
                        div [] []

                selectedPlayerName =
                    case markedPlayer of
                        Single player ->
                            "Selected player: " ++ player.user.name

                        _ ->
                            "No selected player"

                playerInfo =
                    div [] [ text selectedPlayerName ]

                activePlayerInfo =
                    div [] [ text ("active player: " ++ game.activePlayer.user.name) ]
            in
            case gameState of
                Idle ->
                    div []
                        [ gameInformation
                        , div [] [ interactiveScoreCard markedPlayer game True ]
                        , playerInfo
                        , activePlayerInfo
                        ]

                Input box isEdit ->
                    div []
                        [ div [] [ interactiveScoreCard markedPlayer game True ]
                        , div [] [ scoreDialog currentValue box game.activePlayer isEdit ]
                        ]

        ShowGameFinished game markedPlayer ->
            div
                []
                [ div [] [ gameFinished ]
                , div [] [ staticScoreCard game False False ]
                ]

        ShowGameResults game markedPlayer ->
            div [] [ individualHighscore markedPlayer game.players ]

        ShowFinishedScoreCard game markedPlayer showGameInfo ->
            let
                gameInformation =
                    if showGameInfo then
                        gameInfo game

                    else
                        div [] []
            in
            div [] [ gameInformation, staticScoreCard game True True ]

        _ ->
            div [] []



-- view : Model -> Html Msg
-- view model =
--     case model.windowState of
--         Blurred ->
--             windowBlurred
--
--         _ ->
--             let
--                 gameMaybe =
--                     model.game
--             in
--             case gameMaybe of
--                 Nothing ->
--                     case model.mode of
--                         StartPage activeHighscoreTabIndex ->
--                             startPage model.highscoreList activeHighscoreTabIndex
--
--                         BlurredGame blurredModel ->
--                             case blurredModel of
--                                 Inactive ->
--                                     windowBlurred
--
--                                 Reconnecting gameToFocus userId ->
--                                     windowFocused
--
--                         Individual individualModel ->
--                             case individualModel of
--                                 EnterGameCode gameCode games ->
--                                     enterGameCode gameCode
--                                         games
--
--                                 WaitingForGame ->
--                                     div [ class "waiting-for-game" ]
--                                         [ loader "Ansluter till spelet ..." True
--                                         ]
--
--                                 _ ->
--                                     div [] [ text "hejw" ]
--
--                         Group groupModel ->
--                             case groupModel of
--                                 PreGame preGame ->
--                                     case preGame.state of
--                                         ShowAddRemovePlayers ->
--                                             div [] [ addRemovePlayers preGame model.users ]
--
--                                         ShowIndividualJoinInfo ->
--                                             div [] [ individualJoinInfo Nothing ]
--
--                                 _ ->
--                                     div [] [ text "hej4" ]
--
--                 Just game ->
--                     case model.mode of
--                         StartPage activeHighscoreTabIndex ->
--                             startPage model.highscoreList activeHighscoreTabIndex
--
--                         BlurredGame blurredModel ->
--                             case blurredModel of
--                                 Inactive ->
--                                     windowBlurred
--
--                                 Reconnecting gameToFocus userId ->
--                                     windowFocused
--
--                         Individual individualModel ->
--                             case individualModel of
--                                 SelectPlayer markedPlayer ->
--                                     selectPlayer game markedPlayer
--
--                                 IndividualPlaying gamePlayingModel ->
--                                     let
--                                         selectedPlayer =
--                                             gamePlayingModel.selectedPlayer
--                                     in
--                                     if game.finished == True then
--                                         div [] [ individualHighscore selectedPlayer game.players ]
--
--                                     else
--                                         let
--                                             gameState =
--                                                 stateToString playingModel.state
--
--                                             playingModel =
--                                                 gamePlayingModel.gamePlaying
--
--                                             gameInformation =
--                                                 if playingModel.showGameInfo then
--                                                     individualGameInfo game
--
--                                                 else
--                                                     div [] []
--
--                                             content =
--                                                 case playingModel.state of
--                                                     Idle ->
--                                                         div []
--                                                             [ gameInformation
--                                                             , div [] [ interactiveScoreCard (Just gamePlayingModel.selectedPlayer) game False ]
--                                                             ]
--
--                                                     Input box isEdit ->
--                                                         div []
--                                                             [ div [] [ scoreDialog playingModel box game.activePlayer isEdit ]
--                                                             , div [] [ interactiveScoreCard (Just gamePlayingModel.selectedPlayer) game False ]
--                                                             ]
--                                         in
--                                         div
--                                             []
--                                             [ div [ classList [ ( gameState, True ) ] ] [ content ]
--                                             ]
--
--                                 IndividualPostGame postGame ->
--                                     div [] [ individualHighscore postGame.selectedPlayer game.players ]
--
--                                 _ ->
--                                     div [] [ text "hej3" ]
--
--                         Group groupModel ->
--                             case groupModel of
--                                 PreGame preGame ->
--                                     let
--                                         notificationHtml =
--                                             case preGame.error of
--                                                 Just error ->
--                                                     notification (errorToString error)
--
--                                                 Nothing ->
--                                                     div [] []
--                                     in
--                                     case preGame.state of
--                                         ShowAddRemovePlayers ->
--                                             div [] [ addRemovePlayers preGame model.users, notificationHtml ]
--
--                                         ShowIndividualJoinInfo ->
--                                             div [] [ individualJoinInfo (Just game) ]
--
--                                 Playing playingModel ->
--                                     let
--                                         errorMaybe =
--                                             playingModel.error
--                                     in
--                                     case errorMaybe of
--                                         Just error ->
--                                             div [] [ text (errorToString error) ]
--
--                                         Nothing ->
--                                             let
--                                                 gameState =
--                                                     stateToString playingModel.state
--
--                                                 gameInformation =
--                                                     if playingModel.showGameInfo then
--                                                         gameInfo game
--
--                                                     else
--                                                         div [] []
--
--                                                 content =
--                                                     case playingModel.state of
--                                                         Idle ->
--                                                             div []
--                                                                 [ gameInformation
--                                                                 , div [] [ interactiveScoreCard Nothing game False ]
--                                                                 ]
--
--                                                         Input box isEdit ->
--                                                             div []
--                                                                 [ div [] [ interactiveScoreCard Nothing game False ]
--                                                                 , div [] [ scoreDialog playingModel box game.activePlayer isEdit ]
--                                                                 ]
--                                             in
--                                             div
--                                                 []
--                                                 [ div [ classList [ ( gameState, True ) ] ] [ content ]
--                                                 ]
--
--                                 PostGame finishedModel ->
--                                     let
--                                         gameState =
--                                             stateToString finishedModel.state
--
--                                         gameInformation =
--                                             if finishedModel.showGameInfo then
--                                                 gameInfo game
--
--                                             else
--                                                 div [] []
--
--                                         content =
--                                             case finishedModel.state of
--                                                 GameFinished ->
--                                                     div []
--                                                         [ gameInformation
--                                                         , div [] [ gameFinished ]
--                                                         , div [] [ staticScoreCard game False False ]
--                                                         ]
--
--                                                 ShowCountedValues ->
--                                                     div []
--                                                         [ gameInformation
--                                                         , div [] [ staticScoreCard game True True ]
--                                                         ]
--
--                                                 ShowResults ->
--                                                     div []
--                                                         [ gameInformation
--                                                         , div [] [ highscore game.players ]
--                                                         , div [] [ staticScoreCard game False True ]
--                                                         ]
--
--                                                 HideResults ->
--                                                     div []
--                                                         [ gameInformation
--                                                         , div [] [ staticScoreCard game False True ]
--                                                         ]
--                                     in
--                                     div
--                                         []
--                                         [ div [ classList [ ( gameState, True ) ] ] [ content ]
--                                         ]
--


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


gameUpdated : Model -> Json.Decode.Value -> Msg
gameUpdated model gameJson =
    let
        gameMaybe =
            Json.Decode.decodeValue gameDecoder gameJson

        _ =
            Debug.log "gameUpdated()" (Debug.toString gameMaybe)

        _ =
            Debug.log "gameUpdated()" (Debug.toString gameJson)
    in
    case gameMaybe of
        Ok game ->
            GameReceived (fromDbGameToGame game model.users)

        Err err ->
            NoOp


gamesUpdated : Model -> Json.Decode.Value -> Msg
gamesUpdated model gamesJson =
    let
        gamesMaybe =
            Json.Decode.decodeValue gamesDecoder gamesJson
    in
    case gamesMaybe of
        Ok games ->
            GamesReceived (List.map (\game -> fromDbGameToGame game model.users) games)

        Err err ->
            -- let
            --     _ =
            --         Debug.log "gamesUpdated" (Debug.toString err)
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


windowStateFocused : Model -> Json.Decode.Value -> Msg
windowStateFocused model valuesJson =
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
                (fromDbGameToGame focusedGameAndUser.game model.users)
                focusedGameAndUser.userId

        Err err ->
            let
                _ =
                    Debug.log "windowStateFocused" (Debug.toString err)
            in
            NoOp


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        allSubscriptions =
            [ usersReceived remoteUsersUpdated
            , gameReceived (gameUpdated model)
            , gamesReceived (gamesUpdated model)
            , highscoreReceived globalHighscoreUpdated
            , onBlurReceived windowBlurUpdated
            , onFocusReceived (windowStateFocused model)
            ]
    in
    Sub.batch
        allSubscriptions



-- case model.mode of
--     Group groupModel ->
--         case groupModel of
--             PostGame postGame ->
--                 if postGame.state == ShowCountedValues then
--                     Sub.batch
--                         [ Time.every 100
--                             CountValuesTick
--                         ]
--
--                 else
--                     Sub.batch
--                         allSubscriptions
--
--             _ ->
--                 Sub.batch
--                     allSubscriptions
--
--     _ ->
--         Sub.batch
--             allSubscriptions
---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
