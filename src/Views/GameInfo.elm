module Views.GameInfo exposing (gameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Models exposing (Msg(..))


gameInfo : String -> Html Msg
gameInfo errorMsg =
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "game-info dialog-content animated jackInTheBox" ]
            [ h1 [] [ text "Om du vill:" ]
            , h2 [] [ text "gör så här för att joina detta spel på din mobil" ]
            , ol []
                [ li [] [ span [ class "game-info-link" ] [ span [] [ text "Gå till" ], a [ href "http://soph.se/yatzy/game" ] [ text "http://soph.se/yatzy/game" ] ] ]
                , li [] [ span [] [ span [] [ text "Skriv i koden" ], span [ class "game-info-code" ] [ text "1234" ] ] ]
                , li [] [ text "Välj ditt namn" ]
                , li [] [ text "Spela!" ]
                ]
            , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick Start ] [ text "Start" ]
            ]
        ]
