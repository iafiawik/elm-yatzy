module Views.WindowBlurred exposing (windowBlurred)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


windowBlurred : Html Msg
windowBlurred =
    let
        content =
            div [ class "game-info dialog-content animated fadeIn game-info-finished" ]
                [ h1 []
                    [ text "Tappade kontakten." ]
                , br
                    []
                    []
                , br
                    []
                    []
                , loader "Ansluter till det senast spelade spelet" False
                ]
    in
    div [ class "game-info-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div []
            [ content
            ]
        ]
