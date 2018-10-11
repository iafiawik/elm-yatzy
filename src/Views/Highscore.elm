module Views.Highscore exposing (highscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Logic exposing (getRoundHighscore)
import Models exposing (Model, Msg(..), Player)


highscore model =
    let
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
        [ class "highscore" ]
        [ div [ class "highscore-content" ] [ h1 [] [ text "Resultat" ], table [] ([] ++ playerButtons), button [ onClick Restart, class "large-button animated pulse infinite" ] [ text "Spela en gång till" ] ]
        ]
