module Views.Statistics exposing (statistics)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.StatisticItem exposing (StatisticItem)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


statistics : List StatisticItem -> Html Msg
statistics items =
    let
        content =
            if List.length items == 0 then
                loader "Loading statistics" True

            else
                table []
                    ([ tr []
                        [ th [] [ text "Player" ]
                        , th [] [ text "# of games" ]
                        , th [] [ text "Average" ]
                        , th [] [ text "Lowest" ]
                        , th [] [ text "Highest" ]
                        , th [] [ text "Yatzy %" ]
                        , th [] [ text "Win %" ]
                        ]
                     ]
                        ++ List.indexedMap
                            (\index statisticItem ->
                                tr
                                    []
                                    [ td [] [ text statisticItem.user.name ]
                                    , td [] [ text (String.fromInt statisticItem.numberOfGames) ]
                                    , td [] [ text (String.fromInt (round statisticItem.average)) ]
                                    , td [] [ text (String.fromInt statisticItem.highestScore) ]
                                    , td [] [ text (String.fromInt statisticItem.lowestScore) ]
                                    , td [] [ text (String.fromInt (round (statisticItem.yatzyChance * 100)) ++ "%") ]
                                    , td [] [ text (String.fromInt (round (statisticItem.winChance * 100)) ++ "%") ]
                                    ]
                            )
                            items
                    )
    in
    div
        []
        [ div [ class "global-highscore-content" ] [ div [ class "scrollable-table" ] [ content ] ]
        ]
