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


globalHighscoreInverted : List GlobalHighscoreItem -> Html Msg
globalHighscoreInverted items =
    let
        invertedHighscore =
            List.reverse items

        realItems =
            List.filter
                (\highscoreItem -> highscoreItem.user.name /= "z Alexis (test user)" && highscoreItem.user.name /= "z Clementine (test user)")
                invertedHighscore

        uniqueItems =
            uniqueBy (\highscoreItem -> highscoreItem.user.name)
                realItems

        playersAndNumberOfGames =
            List.map
                (\highscoreItem ->
                    let
                        numberOfGames =
                            countNumberOfGames highscoreItem.user items
                    in
                    ( highscoreItem, numberOfGames )
                )
                uniqueItems

        qualifiedPlayers =
            List.filter (\highscoreItem -> Tuple.second highscoreItem > 5) playersAndNumberOfGames

        mostActiveUsers =
            List.reverse (List.sortBy (\highscoreItem -> Tuple.second highscoreItem) qualifiedPlayers)

        invertedHighscoreContent =
            if List.length items == 0 then
                loader "Laddar lista" False

            else
                table []
                    ([ tr [] [ th [] [ text "#" ], th [] [ text "Player" ], th [] [ text "Date" ], th [] [ text "Games" ], th [] [ text "Score" ] ] ]
                        ++ List.indexedMap
                            (\index item ->
                                let
                                    highscoreItem =
                                        Tuple.first item

                                    numberOfGames =
                                        Tuple.second item

                                    name =
                                        highscoreItem.user.name

                                    score =
                                        highscoreItem.score
                                in
                                tr [] [ td [] [ text (String.fromInt (index + 1) ++ ". ") ], td [] [ text name ], td [] [ text highscoreItem.date ], td [] [ text (String.fromInt numberOfGames) ], td [] [ text (String.fromInt score) ] ]
                            )
                            qualifiedPlayers
                    )

        mostActiveUsersContent =
            if List.length items == 0 then
                loader "Laddar lista" False

            else
                table []
                    ([ tr [] [ th [] [ text "#" ], th [] [ text "Player" ], th [] [ text "Games" ] ] ]
                        ++ List.indexedMap
                            (\index item ->
                                let
                                    highscoreItem =
                                        Tuple.first item

                                    numberOfGames =
                                        Tuple.second item

                                    name =
                                        highscoreItem.user.name

                                    score =
                                        highscoreItem.score
                                in
                                tr [] [ td [] [ text (String.fromInt (index + 1) ++ ". ") ], td [] [ text name ], td [] [ text (String.fromInt numberOfGames) ] ]
                            )
                            mostActiveUsers
                    )
    in
    div
        [ class "" ]
        [ div [ class "global-highscore-content" ] [ h2 [] [ text "Wall of shame :)" ], invertedHighscoreContent ]
        , div [ class "global-highscore-content" ] [ h2 [] [ text "Most active users" ], mostActiveUsersContent ]
        ]
