module Views.GlobalHighscores exposing (globalHighscores)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List.Extra exposing (getAt)
import Model.GlobalHighscore exposing (GlobalHighscore)
import Models exposing (Msg(..))
import Views.GlobalHighscore exposing (globalHighscore)
import Views.Loader exposing (loader)


globalHighscores : List GlobalHighscore -> Int -> Html Msg
globalHighscores lists activeIndex =
    if List.length lists == 0 then
        div [] [ loader "Laddar highscores" False ]

    else
        let
            tabs =
                List.indexedMap
                    (\index highscore ->
                        div [ onClick (ChangeActiveHighscoreTab index), classList [ ( "tab", True ), ( "active", activeIndex == index ) ] ]
                            [ text (String.fromInt highscore.year)
                            ]
                    )
                    lists

            content =
                List.indexedMap
                    (\index highscore ->
                        div [ classList [ ( "tab-content", True ), ( "active", activeIndex == index ) ] ]
                            [ globalHighscore highscore.normal ("Global highscore " ++ String.fromInt highscore.year)
                            , globalHighscore highscore.inverted ("Wall of shame " ++ String.fromInt highscore.year ++ " :)")
                            ]
                    )
                    lists
        in
        div []
            [ div [ class "global-highscores-tabs" ] [ div [ class "container" ] tabs ]
            , div [ class "global-highscores container" ] content
            ]
