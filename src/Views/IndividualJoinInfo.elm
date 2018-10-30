module Views.IndividualJoinInfo exposing (individualJoinInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


individualJoinInfo : Game -> Html Msg
individualJoinInfo game =
    let
        content =
            if game.code == "" then
                loader "Skapar spel" True

            else
                div []
                    [ h1 [] [ text "Om du vill:" ]
                    , h2 [] [ text "gör så här för att joina detta spel på din mobil" ]
                    , ol []
                        [ li [] [ span [ class "individual-join-info-link" ] [ span [] [ text "Gå till" ], a [ href "http://soph.se/yatzy" ] [ text "http://soph.se/yatzy" ] ] ]
                        , li [] [ span [] [ span [] [ text "Skriv i koden" ], span [ class "individual-join-info-code" ] [ text game.code ] ] ]
                        , li [] [ text "Välj ditt namn" ]
                        , li [] [ text "Spela!" ]
                        ]
                    , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick Start ] [ text "Start" ]
                    ]
    in
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ classList [ ( "individual-join-info dialog-content animated jackInTheBox", True ), ( "loading", game.code == "" ) ] ]
            [ content ]
        ]
