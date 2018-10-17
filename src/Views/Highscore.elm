module Views.Highscore exposing (highscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Logic exposing (getRoundHighscore)
import Models exposing (Model, Msg(..), Player)


highscore model =
    let
        numberOfPlayers =
            List.length model.players

        playerButtons =
            List.indexedMap
                (\index playerScore ->
                    let
                        name =
                            .name (Tuple.first playerScore)

                        score =
                            Tuple.second playerScore
                    in
                    tr [] [ td [] [ text (String.fromInt (index + 1) ++ ". " ++ name) ], td [] [ text (String.fromInt score) ] ]
                )
                (getRoundHighscore model.players model.values)
    in
    div
        [ classList
            [ ( "highscore", True )
            , ( "two-players", numberOfPlayers == 2 )
            , ( "three-players", numberOfPlayers == 3 )
            , ( "four-players", numberOfPlayers == 4 )
            , ( "five-players", numberOfPlayers == 5 )
            , ( "six-players", numberOfPlayers == 6 )
            , ( "seven-players", numberOfPlayers == 7 )
            , ( "eight-players", numberOfPlayers == 8 )
            ]
        ]
        [ div [ class "highscore-content" ] [ h1 [] [ text "Resultat" ], table [] ([] ++ playerButtons), button [ onClick Restart, class "large-button \n        " ] [ text "Spela en gång till" ] ]
        ]
