module Views.IndividualHighscore exposing (individualHighscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List.Extra exposing (find, findIndex, removeAt)
import Logic exposing (getRoundHighscore)
import Model.Player exposing (Player)
import Model.Value exposing (Value)
import Models exposing (Msg(..))


getPositionText : Int -> Html Msg
getPositionText position =
    let
        positionText =
            case position of
                0 ->
                    "Grattis, du vann! :)"

                1 ->
                    "Du kom på andra plats"

                2 ->
                    "Du kom på tredje plats"

                3 ->
                    "Du kom på fjärde plats"

                4 ->
                    "Du kom på femte plats"

                5 ->
                    "Du kom på sjätte plats"

                6 ->
                    "Du kom på sjunde plats"

                7 ->
                    "Du kom på åttonde plats"

                _ ->
                    ""
    in
    div [] [ text positionText ]


individualHighscore : Player -> List Player -> List Value -> Html Msg
individualHighscore currentPlayer players values =
    let
        numberOfPlayers =
            List.length players

        highscoreValues =
            List.map (\v -> { v | counted = True }) values

        highscore =
            getRoundHighscore players highscoreValues

        playerButtons =
            List.indexedMap
                (\index playerScore ->
                    let
                        isCurrentPlayer =
                            Tuple.first playerScore == currentPlayer

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

        position =
            Maybe.withDefault 0 (findIndex (\highscoreValue -> Tuple.first highscoreValue == currentPlayer) highscore)

        positionText =
            if List.length highscore <= 1 then
                div [] [ text "" ]

            else if (List.length highscore - 1) == position && List.length highscore > 1 then
                div [] [ text "Du kom sist :(" ]

            else
                getPositionText position
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
                , h2 [] [ positionText ]
                , table [] ([] ++ playerButtons)
                , button [ onClick Restart, class "large-button \n        " ] [ text "Avsluta" ]
                ]
            ]
        ]
