module Views.GameInfo exposing (gameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Models exposing (Msg(..))


gameInfo : Game -> Html Msg
gameInfo game =
    div [ class "game-info-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div []
            [ div [ class "game-info dialog-content animated jackInTheBox game-info-not-finished" ]
                [ button [ class "dialog-content-cancel-button button", onClick HideGameInfo ] [ text "X" ]
                , h1 [] [ text "Om du vill:" ]
                , h2 [] [ text "gör så här för att joina detta spel på din mobil" ]
                , ol []
                    [ li [] [ span [ class "game-info-link" ] [ span [] [ text "Gå till" ], a [ href "http://soph.se/yatzy" ] [ text "http://soph.se/yatzy" ] ] ]
                    , li [] [ span [] [ span [] [ text "Skriv i koden" ], span [ class "game-info-code" ] [ text game.code ] ] ]
                    , li [] [ text "Välj ditt namn" ]
                    , li [] [ text "Spela!" ]
                    ]
                , div [] [ button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick Restart ] [ text "Skapa ny omgång" ] ]
                , div [ class "game-info-restart" ]
                    [ span [] [ text "Om du vill lämna detta spel eller byta spelare kan du klicka på knappen nedan. Detta kommer inte ta bort dig från spelet från permanent - du kan ansluta till spelet igen genom att ange koden ovan." ]
                    , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick ShowStartPage ] [ text "Lämna spel" ]
                    ]
                ]
            ]
        ]
