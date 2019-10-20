module Views.GlobalHighscoreInverted exposing (globalHighscoreInverted)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List.Extra exposing (count, uniqueBy)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Model.User exposing (User)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


countNumberOfGames : User -> List GlobalHighscoreItem -> Int
countNumberOfGames user items =
    List.length (List.filter (\highscoreItem -> highscoreItem.user.name == user.name) items)


uniqueByName : GlobalHighscoreItem -> String
uniqueByName item =
    item.user.name


globalHighscoreInverted : List GlobalHighscoreItem -> Int -> Html Msg
globalHighscoreInverted items year =
    let
        invertedHighscoreContent =
            if List.length items == 0 then
                loader "Laddar lista" False

            else
                table []
                    ([ tr [] [ th [] [ text "#" ], th [] [ text "Player" ], th [] [ text "Date" ], th [] [ text "Score" ] ] ]
                        ++ List.indexedMap
                            (\index item ->
                                let
                                    name =
                                        item.user.name

                                    score =
                                        item.score
                                in
                                tr [] [ td [] [ text (String.fromInt item.order ++ ". ") ], td [] [ text name ], td [] [ text item.date ], td [] [ text (String.fromInt score) ] ]
                            )
                            items
                    )
    in
    div
        [ class "" ]
        [ div [ class "global-highscore-content" ] [ h2 [] [ text ("Wall of shame " ++ String.fromInt year ++ " :)") ], invertedHighscoreContent ]
        ]
