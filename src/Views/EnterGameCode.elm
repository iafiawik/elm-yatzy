module Views.EnterGameCode exposing (enterGameCode)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Model.Game exposing (Game)
import Models exposing (Msg(..))


enterGameCode : String -> Html Msg
enterGameCode gameCode =
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "enter-game-code dialog-content animated jackInTheBox" ]
            [ h1 [] [ text "Ange spelets kod" ]
            , h2 [] [ text "Koden består av fyra bokstäver" ]
            , input [ value gameCode, onInput GameCodeInputChange ] []
            , button [ classList [ ( "large-button", True ), ( "enabled", String.length gameCode == 4 ) ], onClick EnterGame, disabled (String.length gameCode /= 4) ] [ text "Start" ]
            ]
        ]
