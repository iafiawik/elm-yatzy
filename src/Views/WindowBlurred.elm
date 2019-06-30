module Views.WindowBlurred exposing (windowBlurred)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Models exposing (Msg(..))


windowBlurred : Html Msg
windowBlurred =
    let
        content =
            div [ class "game-info dialog-content animated fadeIn game-info-finished" ]
                [ h1 [] [ text "Tappade kontakten." ]
                , h3 [] [ text "Försöker återansluta ..." ]
                ]
    in
    div [ class "game-info-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div []
            [ content
            ]
        ]
