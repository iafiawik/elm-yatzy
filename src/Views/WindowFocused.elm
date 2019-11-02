module Views.WindowFocused exposing (windowFocused)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model.Game exposing (Game)
import Models exposing (Msg(..))


windowFocused : Html Msg
windowFocused =
    let
        content =
            div [ class "game-info dialog-content animated fadeIn game-info-finished" ]
                [ h1 [] [ text "Återfick kontakten." ]
                , h3 [] [ text "Hämtar allt du missade under tiden ..." ]
                ]
    in
    div [ class "game-info-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background animated fadeIn" ] []
        , div []
            [ content
            ]
        ]
