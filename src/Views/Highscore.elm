module Views.Highscore exposing (highscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.Game exposing (getRoundHighscore)
import Model.Player exposing (Player)
import Models exposing (Msg(..))


highscore : List Player -> Html Msg
highscore players =
    let
        numberOfPlayers =
            List.length players

        playerButtons =
            List.indexedMap
                (\index playerScore ->
                    let
                        name =
                            (\p -> p.user.name) (Tuple.first playerScore)

                        score =
                            Tuple.second playerScore
                    in
                    tr [] [ td [] [ text (String.fromInt (index + 1) ++ ". " ++ name) ], td [] [ text (String.fromInt score) ] ]
                )
                (getRoundHighscore players)
    in
    div [ class "highscore-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div
            [ classList
                [ ( "highscore dialog-content animated jackInTheBox", True )
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
                , table [] ([] ++ playerButtons)
                , button [ onClick HideHighscore, class "large-button" ] [ text "Stäng" ]
                ]
            ]
        ]
