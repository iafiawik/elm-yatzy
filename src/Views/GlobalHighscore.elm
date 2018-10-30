module Views.GlobalHighscore exposing (globalHighscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


globalHighscore : List GlobalHighscoreItem -> Html Msg
globalHighscore items =
    let
        content =
            if List.length items == 0 then
                loader "Laddar lista" False

            else
                table []
                    ([]
                        ++ List.indexedMap
                            (\index highscoreItem ->
                                let
                                    name =
                                        highscoreItem.player.user.name

                                    score =
                                        highscoreItem.player.score
                                in
                                tr [] [ td [] [ text (String.fromInt (index + 1) ++ ". " ++ name) ], td [] [ text (String.fromInt score) ] ]
                            )
                            (List.take
                                10
                                items
                            )
                    )
    in
    div
        [ class "global-highscore" ]
        [ div [ class "global-highscore-content" ] [ h1 [] [ text "Global topplista" ], content ]
        ]
