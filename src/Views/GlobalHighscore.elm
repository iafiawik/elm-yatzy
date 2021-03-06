module Views.GlobalHighscore exposing (globalHighscore)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


globalHighscore : List GlobalHighscoreItem -> String -> Html Msg
globalHighscore items heading =
    let
        content =
            if List.length items == 0 then
                loader "Laddar lista" False

            else
                table []
                    ([ tr []
                        [ th [] [ text "Player" ]
                        , th [] [ text "Date" ]
                        , th [] [ text "Score" ]
                        , th [] [ text "" ]
                        , th [ class "hidden" ] [ text "User ID" ]
                        , th [ class "hidden" ] [ text "Game ID" ]
                        ]
                     ]
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
                                tr
                                    [ onClick (ShowScoreCardForGameAndUser highscoreItem.gameId) ]
                                    [ td [] [ text name ]
                                    , td [] [ text highscoreItem.date ]
                                    , td [] [ text (String.fromInt score) ]
                                    , td [ class "link-column" ] [ text "Show" ]
                                    , td [ class "hidden" ] [ text highscoreItem.user.id ]
                                    , td [ class "hidden" ] [ text gameId ]
                                    ]
                            )
                            (List.take
                                20
                                items
                            )
                    )
    in
    div
        []
        [ div [ class "global-highscore-content" ] [ h1 [] [ text heading ], div [ class "scrollable-table" ] [ content ] ]
        ]
