module Views.GameInfo exposing (gameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Models exposing (Msg(..))


gameInfo : Game -> Html Msg
gameInfo game =
    let
        content =
            if game.finished then
                div []
                    [ button [ class "score-dialog-cancel-button button", onClick HideGameInfo ] [ text "X" ]
                    , h1 [] [ text "Spelet är slut!" ]
                    , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick Restart ] [ text "Skapa nytt spel" ]
                    ]

            else
                div []
                    [ h1 [] [ text "Om du vill:" ]
                    , h2 [] [ text "gör så här för att joina detta spel på din mobil" ]
                    , ol []
                        [ li [] [ span [ class "game-info-link" ] [ span [] [ text "Gå till" ], a [ href "http://soph.se/yatzy" ] [ text "http://soph.se/yatzy" ] ] ]
                        , li [] [ span [] [ span [] [ text "Skriv i koden" ], span [ class "game-info-code" ] [ text game.code ] ] ]
                        , li [] [ text "Välj ditt namn" ]
                        , li [] [ text "Spela!" ]
                        ]
                    , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick HideGameInfo ] [ text "Stäng" ]
                    ]
    in
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "game-info dialog-content animated jackInTheBox" ]
            [ content
            ]
        ]
