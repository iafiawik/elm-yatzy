module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (find, findIndex, getAt, removeAt)
import Logic exposing (..)
import Models exposing (Box, BoxCategory(..), BoxType(..), Player, PlayerAndNumberOfValues, Value)
import Random exposing (Seed, initialSeed, step)
import Task
import Time
import Uuid



---- MODEL ----


type Game
    = Initializing
    | AddPlayers
    | Idle
    | Input Box
    | Finished
    | ShowCountedValues
    | ShowResults
    | Error


type alias Model =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , game : Game
    , countedPlayers : List Player
    , countedValues : List Value
    , currentNewPlayerName : String
    , currentValue : Int
    , currentSeed : Seed
    , currentUuid : Maybe Uuid.Uuid
    }


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
                ]

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


type Msg
    = Start
    | AddPlayer
    | RemovePlayer Player
    | NewPlayerInputValueChange String
    | AddValue
    | ShowAddValue Box
    | ValueMarked Int
    | HideAddValue
    | InputValueChange String
    | CountValues
    | CountValuesTick Time.Posix


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

        Nothing ->
            let
                _ =
                    Debug.log "Nothing returned from Update:" msg
            in
            -- handle product not found here
            -- likely return the model unchanged
            -- or set an error message on the model
            ( { model | game = Error }, Cmd.none )



--
-- updateElement2 : List Value -> Box -> Player -> List Value
-- updateElement2 list box player =
--     let
--         toggle idx value =
--             if id == idx then
--                 { value | counted = True }
--
--             else
--                 value
--     in
--     List.indexedMap toggle list
--
--
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
            td [ classList [ ( "inactive", True ), ( "counted", value.counted ) ] ] [ text (getValueText value.value) ]

        Nothing ->
            if box.boxType == UpperSum then
                td [ class "inactive" ] [ text (String.fromInt upperSum) ]

            else if box.boxType == TotalSum then
                td [ class "inactive" ] [ text (String.fromInt totalSum) ]

            else if box.boxType == Bonus then
                td [ classList [ ( "inactive bonus", True ), ( "animated bonus-cell", bonusValue > 0 ) ] ] [ upperSumText ]

            else if isCurrentPlayer then
                if box.category == None then
                    td [ classList [ ( "active", True ) ] ] [ text "" ]

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
    div [ class "table-wrapper pad" ]
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
    div [ class "input-dialog-wrapper dialog-wrapper" ]
        [ div [ class "input-dialog-background dialog-background  animated fadeIn", onClick HideAddValue ] []
        , div [ class "input-dialog dialog-content animated jackInTheBox" ]
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


playerButton : Player -> List (Html Msg) -> Html Msg
playerButton player content =
    button [ class "add-players-dialog-player-button" ] [ span [] [ text (player.name ++ player.id_) ], button [ onClick (RemovePlayer player), class "add-players-dialog-player-button-delete" ] [ text "X" ], div [] ([] ++ content) ]


addPlayers : Model -> Html Msg
addPlayers model =
    let
        playerButtons =
            List.map
                (\p ->
                    playerButton p
                        []
                )
                model.players
    in
    div [ class "add-players-dialog-wrapper dialog-wrapper" ]
        [ div [ class "add-players-dialog-background dialog-background animated fadeIn", onClick HideAddValue ] []
        , div [ class "add-players-dialog dialog-content a animated jackInTheBox" ]
            [ div [] [ h1 [] [ text "Yatzy" ], h2 [] [ text "Add players" ] ]
            , div [ class "add-players-dialog-player-buttons" ] playerButtons
            , div []
                [ input [ class "add-players-dialog-input-field", type_ "text", onInput NewPlayerInputValueChange, value model.currentNewPlayerName ] []
                , button [ onClick AddPlayer ] [ text "Add new player" ]
                ]
            , button [ onClick Start ] [ text "Start" ]
            ]
        ]


showResultsButton =
    div [ class "show-results" ]
        [ div [ class "show-results-content" ] [ h1 [] [ text "OK, all done!" ], button [ onClick CountValues, class "large-button animated pulse infinite" ] [ text "Show results" ] ]
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
                            div [] [ addPlayers model ]

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
                                [ div [] [ showResultsButton ]
                                , div [] [ renderTable currentPlayer model False ]
                                , button [ onClick CountValues ] [ text "Count" ]
                                ]

                        ShowCountedValues ->
                            div []
                                [ div [] [ renderTable currentPlayer model True ]
                                ]

                        ShowResults ->
                            div []
                                [ div [] [ renderTable currentPlayer model True ]
                                ]

                        Error ->
                            div [] [ text "An error occured" ]
            in
            div
                []
                [ div [ classList [ ( gameState, True ) ] ] [ content ]
                , div [] [ text <| gameState ]
                ]

        Nothing ->
            div [] [ text "No player found" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.game == ShowCountedValues then
        Time.every 200 CountValuesTick

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
