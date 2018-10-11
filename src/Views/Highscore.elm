module Views.Highscore exposing (highscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Logic exposing (getRoundHighscore)
import Models exposing (Model, Msg(..), Player)


highscore model =
    let
        playerButtons =
            List.map
                (\playerScore ->
                    let
                        name =
                            .name (Tuple.first playerScore)

                        score =
                            Tuple.second playerScore
                    in
                    tr [] [ td [] [ text name ], td [] [ text (String.fromInt score) ] ]
                )
                (getRoundHighscore model.players model.values)
    in
    div
        [ class "highscore" ]
        [ div [ class "highscore-content" ] [ h1 [] [ text "Results are in" ], table [] ([] ++ playerButtons), button [ onClick Restart, class "large-button animated pulse infinite" ] [ text "Play again" ] ]
        ]
