module Views.ScoreCardDialog exposing (scoreCardDialog)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.Game exposing (Game)
import Models exposing (MarkedPlayer(..), Msg(..))
import Views.Loader exposing (loader)
import Views.ScoreCard exposing (nakedScoreCard)


scoreCardDialog : Maybe Game -> Html Msg
scoreCardDialog gameMaybe =
    let
        content =
            case gameMaybe of
                Just game ->
                    nakedScoreCard All game True False True False

                Nothing ->
                    loader "Hämtar spel" True
    in
    div [ class "dialog-wrapper score-dialog-dialog-wrapper start-page-show-score-card" ]
        [ div [ class "dialog-background animated fadeIn", onClick HideScoreCardForGameAndUser ] []
        , div [ class "animated jackInTheBox", onClick HideScoreCardForGameAndUser ]
            [ div [] [ content ]
            ]
        ]
