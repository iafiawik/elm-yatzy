module Views.LastFinishedGames exposing (lastFinishedGames)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.Game exposing (Game)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


lastFinishedGames : List Game -> Html Msg
lastFinishedGames games =
    let
        content =
            if List.length games == 0 then
                loader "Loading games" True

            else
                table []
                    ([ tr []
                        [ th [] [ text "Date" ]
                        , th [] [ text "Players" ]
                        , th [] [ text "" ]
                        ]
                     ]
                        ++ List.indexedMap
                            (\index game ->
                                tr
                                    [ onClick (ShowScoreCardForGameAndUser game.id) ]
                                    [ td [] [ text game.dateCreated ]
                                    , td [] [ text (String.join ", " (List.map (\player -> player.user.userName) game.players)) ]
                                    , td [ class "link-column" ] [ text "Show" ]
                                    ]
                            )
                            games
                    )
    in
    div
        []
        [ div [ class "global-highscore-content" ] [ div [ class "scrollable-table" ] [ content ] ]
        ]
