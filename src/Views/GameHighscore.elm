module Views.GameHighscore exposing (gameHighscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List.Extra exposing (find, findIndex, removeAt)
import Model.Game exposing (getRoundHighscore)
import Model.Player exposing (Player)
import Model.Value exposing (Value)
import Models exposing (MarkedPlayer(..), Msg(..))


getRows : Maybe Player -> List ( Player, Int ) -> List (Html Msg)
getRows player highscore =
    case player of
        Just currentPlayer ->
            List.indexedMap
                (\index playerScore ->
                    let
                        playerUser =
                            Tuple.first playerScore

                        isCurrentPlayer =
                            playerUser.user.id == currentPlayer.user.id

                        name =
                            (\p ->
                                if isCurrentPlayer then
                                    p.user.name ++ " (du)"

                                else
                                    p.user.name
                            )
                                (Tuple.first playerScore)

                        score =
                            Tuple.second playerScore
                    in
                    tr [ classList [ ( "highscore-row-current-player", isCurrentPlayer ) ] ] [ td [] [ text (String.fromInt (index + 1) ++ ". " ++ name) ], td [] [ text (String.fromInt score) ] ]
                )
                highscore

        _ ->
            List.indexedMap
                (\index playerScore ->
                    let
                        name =
                            (\p ->
                                p.user.name
                            )
                                (Tuple.first playerScore)

                        score =
                            Tuple.second playerScore
                    in
                    tr [] [ td [] [ text (String.fromInt (index + 1) ++ ". " ++ name) ], td [] [ text (String.fromInt score) ] ]
                )
                highscore


getPosition : Player -> List ( Player, Int ) -> Int
getPosition currentPlayer highscore =
    Maybe.withDefault 0 (findIndex (\highscoreValue -> Tuple.first highscoreValue == currentPlayer) highscore)


gameHighscore : MarkedPlayer -> List Player -> Html Msg
gameHighscore markedPlayer players =
    let
        currentPlayer : Maybe Player
        currentPlayer =
            case markedPlayer of
                Single player ->
                    Just player

                _ ->
                    Nothing

        numberOfPlayers =
            List.length players

        highscore =
            getRoundHighscore players

        highscoreRows =
            getRows currentPlayer highscore
    in
    div [ class "highscore-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div
            [ classList
                [ ( "highscore", True )
                , ( "one-player", numberOfPlayers == 1 )
                , ( "two-players", numberOfPlayers == 2 )
                , ( "three-players", numberOfPlayers == 3 )
                , ( "four-players", numberOfPlayers == 4 )
                , ( "five-players", numberOfPlayers == 5 )
                , ( "six-players", numberOfPlayers == 6 )
                , ( "seven-players", numberOfPlayers == 7 )
                , ( "eight-players", numberOfPlayers == 8 )
                ]
            ]
            [ div [ class "highscore-content container" ]
                [ h1 [] [ text "Resultat" ]
                , table [] ([] ++ highscoreRows)
                , button [ onClick HideGameHighscore, class "large-button \n        " ] [ text "Avsluta" ]
                ]
            ]
        ]
