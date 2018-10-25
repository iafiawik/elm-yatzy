module Views.EnterGameCode exposing (enterGameCode)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Model.Game exposing (Game)
import Models exposing (Msg(..))


enterGameCode : String -> List Game -> Html Msg
enterGameCode gameCode games =
    let
        gameButtons =
            List.map (\g -> button [ class "enter-game-code-active-game-button", onClick (GameCodeInputChange g.code) ] [ span [] [ text g.code ] ]) games
    in
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "enter-game-code dialog-content animated jackInTheBox" ]
            [ h1 [] [ text "Ange spelets kod" ]
            , h2 [] [ text "Skriv den fyrsiffriga koden här:" ]
            , input [ value gameCode, onInput GameCodeInputChange ] []
            , h2 [] [ text "... eller leta upp koden här:" ]
            , div [ class "enter-game-code-active-game-codes" ] gameButtons
            , button
                [ classList [ ( "large-button", True ), ( "enabled", String.length gameCode == 4 ) ]
                , onClick EnterGame
                , disabled (String.length gameCode /= 4)
                ]
                [ text "Start" ]
            ]
        ]
