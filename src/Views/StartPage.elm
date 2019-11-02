module Views.StartPage exposing (startPage)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.Game exposing (Game)
import Model.GlobalHighscore exposing (GlobalHighscore)
import Model.StatisticItem exposing (StatisticItem)
import Models exposing (Msg(..))
import Views.GlobalHighscores exposing (globalHighscores)
import Views.LastFinishedGames exposing (lastFinishedGames)
import Views.Statistics exposing (statistics)


startPage : List GlobalHighscore -> Int -> List StatisticItem -> List Game -> Html Msg
startPage highscores activeHighscoreTabIndex statisticItems finishedGames =
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
                    [ div [ class "large-button", onClick CreateGame ] [ text "Create new game" ]
                    , div [ class "large-button", onClick JoinExistingGame ] [ text "Join existing game" ]
                    ]
                ]
            , div [ class "start-page-arrow-down" ] []
            ]
        , div [ class "global-highscore start-page-global-highscore" ] [ globalHighscores highscores activeHighscoreTabIndex ]
        , div [ class "start-page-statistics" ]
            [ div [ class " container" ]
                [ h1 [] [ text "All-time statistics" ]
                , statistics statisticItems
                , h1 [] [ text "Last games" ]
                , lastFinishedGames finishedGames
                ]
            ]
        ]
