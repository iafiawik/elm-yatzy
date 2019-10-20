module Views.StartPage exposing (startPage)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.GlobalHighscore exposing (GlobalHighscore)
import Models exposing (Msg(..))
import Views.GlobalHighscore exposing (globalHighscore)
import Views.GlobalHighscoreInverted exposing (globalHighscoreInverted)


startPage : List GlobalHighscore -> Html Msg
startPage highscores =
    let
        highscoreLists =
            List.map
                (\highscore ->
                    div []
                        [ globalHighscore highscore.normal highscore.year
                        , globalHighscoreInverted highscore.inverted highscore.year
                        ]
                )
                highscores
    in
    div [ class "start-page" ]
        [ div
            [ class "start-page-select-mode" ]
            [ div [ class "start-page-select-mode-content container" ]
                [ h1 []
                    [ text "iatzy" ]
                , p
                    []
                    [ text "Who administrates the Yatzy protocol?" ]
                , p [] [ text "Everyone." ]
                , p [] [ text "Enter your own values and watch how they turn up on a shared screen." ]
                , div
                    [ class "start-page-select-mode-buttons" ]
                    [ div [ class "large-button", onClick SelectGroup ] [ text "Create new game" ]
                    , div [ class "large-button", onClick SelectIndividual ] [ text "Join existing game" ]
                    ]
                ]
            , div [ class "start-page-arrow-down" ] []
            ]
        , div [ class "global-highscore start-page-global-highscore container" ]
            highscoreLists
        ]
