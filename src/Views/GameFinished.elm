module Views.GameFinished exposing (gameFinished)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Models exposing (Model, Msg(..))


gameFinished =
    div [ class "game-finished" ]
        [ div [ class "game-finished-content" ] [ h1 [] [ text "OK, all done!" ], button [ onClick CountValues, class "large-button animated pulse infinite" ] [ text "Show results" ] ]
        ]
