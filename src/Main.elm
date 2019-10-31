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
import Model.Box exposing (Box, getAcceptedValues, getBoxById, getBoxes, getDefaultMarkedValue, getInteractiveBoxes)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Game exposing (DbGame, Game, fromDbGameToGame, gameDecoder, gamesDecoder, getActivePlayer, getTotalSum, getValueByPlayerAndBox)
import Model.GameState exposing (GameState(..))
import Model.GlobalHighscore exposing (GlobalHighscore, globalHighscoresDecoder)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem, globalHighscoreItemDecoder, globalHighscoreItemsDecoder)
import Model.Player exposing (Player)
import Model.User exposing (User, userDecoder, usersDecoder)
import Model.Value exposing (DbValue, Value, encodeValue, valueDecoder)
import Model.WindowState exposing (WindowState(..))
import Models exposing (GameAndUserId, MarkedPlayer(..), Mode(..), Model, Msg(..))
import Views.AddRemovePlayers exposing (addRemovePlayers)
import Views.EnterGameCode exposing (enterGameCode)
import Views.GameFinished exposing (gameFinished)
import Views.GameHighscore exposing (gameHighscore)
import Views.GameInfo exposing (gameInfo)
import Views.GlobalHighscore exposing (globalHighscore)
import Views.Highscore exposing (highscore)
import Views.IndividualJoinInfo exposing (individualJoinInfo)
import Views.Loader exposing (loader)
import Views.Notification exposing (notification)
import Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)
import Views.ScoreCardDialog exposing (scoreCardDialog)
import Views.ScoreDialog exposing (scoreDialog)
import Views.SelectPlayer exposing (selectPlayer)
import Views.StartPage exposing (startPage)
import Views.WaitingForGame exposing (waitingForGame)
import Views.WindowBlurred exposing (windowBlurred)
import Views.WindowFocused exposing (windowFocused)


port fillWithDummyValues : ( E.Value, E.Value, List E.Value ) -> Cmd msg


port getGlobalHighscore : () -> Cmd msg


port getGameByGameCode : E.Value -> Cmd msg


port getGameByGameId : E.Value -> Cmd msg


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


type alias Flags =
    { isAdmin : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model (StartPage 0) [] [] [] Focused flags.isAdmin, Cmd.batch [ getUsers (), getGames (), getGlobalHighscore () ] )


createDummyValues : Player -> List E.Value
createDummyValues player =
    let
        dummyValues =
            List.map
                (\value ->
                    let
                        acceptedValues =
                            getAcceptedValues value.box

                        selectedValue =
                            if value.value < 0 then
                                Maybe.withDefault 0 (List.head acceptedValues)

                            else
                                value.value
                    in
                    ( selectedValue, value.box.id )
                )
                player.values

        encodedValues =
            List.map
                (\dummyValue ->
                    E.object
                        [ ( "value", E.int (Tuple.first dummyValue) )
                        , ( "boxId", E.string (Tuple.second dummyValue) )
                        ]
                )
                dummyValues
    in
    encodedValues


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "update(): " (Debug.toString msg)
    in
    case msg of
        ShowStartPage ->
            ( { model | mode = StartPage 0 }, Cmd.batch [ getGlobalHighscore (), endGameCommand () ] )

        ShowScoreCardForGameAndUser userId gameId ->
            ( { model | mode = ScoreCardForGameAndUser userId Nothing }, getGameByGameId (E.string gameId) )

        HideScoreCardForGameAndUser ->
            ( { model | mode = StartPage 0 }, Cmd.none )

        GlobalHighscoreReceived highscore ->
            ( { model | highscoreList = highscore }, Cmd.none )

        WindowBlurredReceived ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( { model | windowState = Blurred }, Cmd.none )

                StartPage activeHighscoreTabIndex ->
                    ( { model | windowState = Blurred }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        WindowFocusedReceived ->
            ( { model | windowState = Focused }, Cmd.none )

        WindowFocusedAndGameReceived upatedGame userId ->
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
                    ( { model | windowState = Focused }, Cmd.none )

        ReloadGame ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( model, getGameByGameCode (E.string game.code) )

                ShowFinishedScoreCard game markedPlayer showGameInfo ->
                    ( model, getGameByGameCode (E.string game.code) )

                _ ->
                    ( model, Cmd.none )

        FillWithDummyValues player ->
            case model.mode of
                Playing game markedPlayer gameState currentValue showGameInfo ->
                    ( model
                    , fillWithDummyValues
                        ( E.string game.id
                        , E.string game.activePlayer.user.id
                        , createDummyValues
                            game.activePlayer
                        )
                    )

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
                    , getGameByGameCode (E.string gameCode)
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
                ShowAddRemovePlayers addedUsers currentNewPlayerName ->
                    ( { model | mode = ShowAddRemovePlayers addedUsers value }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CreateUser ->
            case model.mode of
                ShowAddRemovePlayers addedUsers currentNewPlayerName ->
                    let
                        isUserNameUnique =
                            List.length
                                (List.filter
                                    (\user ->
                                        currentNewPlayerName == user.userName
                                    )
                                    model.users
                                )
                                == 0
                    in
                    if isUserNameUnique then
                        ( { model | mode = ShowAddRemovePlayers addedUsers "" }
                        , createUser (E.string currentNewPlayerName)
                        )

                    else
                        ( { model | mode = ShowAddRemovePlayers addedUsers currentNewPlayerName }
                        , Cmd.none
                        )

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
                        if gameState == WaitingForValueToBeCreated then
                            ( { model | mode = Playing updatedGame markedPlayer Idle currentValue showGameInfo }, Cmd.none )

                        else
                            ( { model | mode = Playing updatedGame markedPlayer gameState currentValue showGameInfo }, Cmd.none )

                    else
                        ( { model | mode = ShowGameFinished updatedGame markedPlayer }, endGameCommand () )

                ScoreCardForGameAndUser userId game ->
                    ( { model | mode = ScoreCardForGameAndUser userId (Just updatedGame) }, Cmd.none )

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
                        ( { model | mode = ShowFinishedScoreCard game markedPlayer False }, Cmd.none )

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
                        ( { model | mode = Playing game markedPlayer Idle -1 False }
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
                            ( { model | mode = Playing game markedPlayer WaitingForValueToBeCreated -1 showGameInfo }
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

                ShowFinishedScoreCard game markedPlayer showGameInfo ->
                    ( { model | mode = ShowFinishedScoreCard game markedPlayer False }, Cmd.none )

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

        ScoreCardForGameAndUser userId gameMaybe ->
            div [] [ scoreCardDialog gameMaybe, startPage model.highscoreList 0 ]

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
            in
            case gameState of
                Idle ->
                    div []
                        [ gameInformation
                        , div [] [ interactiveScoreCard markedPlayer game True False ]
                        ]

                WaitingForValueToBeCreated ->
                    div [] [ interactiveScoreCard markedPlayer game True True ]

                Input box isEdit ->
                    div []
                        [ div [] [ interactiveScoreCard markedPlayer game True False ]
                        , div [] [ scoreDialog currentValue box game.activePlayer isEdit ]
                        ]

        ShowGameFinished game markedPlayer ->
            div
                []
                [ div [] [ gameFinished ]
                , div [] [ staticScoreCard game False False ]
                ]

        ShowGameResults game markedPlayer ->
            div [] [ gameHighscore markedPlayer game.players ]

        ShowFinishedScoreCard game markedPlayer showGameInfo ->
            let
                gameInformation =
                    if showGameInfo then
                        gameInfo game

                    else
                        div [] []
            in
            div [] [ gameInformation, staticScoreCard game True True ]


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
            WindowFocusedAndGameReceived
                (fromDbGameToGame focusedGameAndUser.game model.users)
                focusedGameAndUser.userId

        Err err ->
            let
                _ =
                    Debug.log "windowStateFocused" (Debug.toString err)
            in
            WindowFocusedReceived


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


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
