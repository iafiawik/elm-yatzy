module Views.StartPage exposing (startPage)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Models exposing (Msg(..))
import Views.GlobalHighscore exposing (globalHighscore)


startPage : List GlobalHighscoreItem -> Html Msg
startPage highscoreItems =
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
            ]
        , div [ class "start-page-global-highscore container" ]
            [ globalHighscore highscoreItems
            ]
        ]
