module Views.GlobalHighscore exposing (globalHighscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


globalHighscore : List GlobalHighscoreItem -> Int -> Html Msg
globalHighscore items year =
    let
        content =
            if List.length items == 0 then
                loader "Laddar lista" False

            else
                table []
                    ([ tr [] [ th [] [ text "#" ], th [] [ text "Player" ], th [] [ text "Date" ], th [] [ text "Score" ], th [ class "hidden" ] [ text "User ID" ], th [ class "hidden" ] [ text "Game ID" ] ] ]
                        ++ List.indexedMap
                            (\index highscoreItem ->
                                let
                                    name =
                                        highscoreItem.user.name

                                    score =
                                        highscoreItem.score

                                    gameId =
                                        highscoreItem.gameId
                                in
                                tr [] [ td [] [ text (String.fromInt (highscoreItem.order + 1) ++ ". ") ], td [] [ text name ], td [] [ text highscoreItem.date ], td [] [ text (String.fromInt score) ], td [ class "hidden" ] [ text highscoreItem.user.id ], td [ class "hidden" ] [ text gameId ] ]
                            )
                            (List.take
                                20
                                items
                            )
                    )
    in
    div
        []
        [ div [ class "global-highscore-content" ] [ h1 [] [ text ("Global highscore " ++ String.fromInt year) ], content ]
        ]
