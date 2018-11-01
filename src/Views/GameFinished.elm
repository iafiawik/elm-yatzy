module Views.GameFinished exposing (gameFinished)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Models exposing (Model, Msg(..))


gameFinished =
    div [ class "game-finished-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div
            [ classList
                [ ( "game-finished dialog-content animated jackInTheBox", True )
                ]
            ]
            [ div [ class "game-finished-content container" ]
                [ h1 [] [ text "Spelet är slut!" ], button [ onClick CountValues, class "large-button animated pulse infinite" ] [ text "Visa resultat" ] ]
            ]
        ]
