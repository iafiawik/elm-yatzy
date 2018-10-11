module Views.ScoreCard exposing (scoreCard)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Logic exposing (getBonusValue, getTotalSum, getUpperSum, getValuesByPlayer, sum)
import Models exposing (Box, BoxCategory(..), BoxType(..), Game(..), Model, Msg(..), Player, PlayerAndNumberOfValues, Value)


getValueText : Int -> String
getValueText value =
    case value of
        0 ->
            "-"

        _ ->
            String.fromInt value


scoreCard : Player -> Model -> Bool -> Html Msg
scoreCard currentPlayer model showCountedValues =
    let
        boxItems =
            List.map
                (\box ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    renderCell box model p (p == currentPlayer)
                                )
                                model.players
                    in
                    tr []
                        ([ td [ class "box" ] [ renderBox box ]
                         ]
                            ++ playerBoxes
                        )
                )
                model.boxes

        headers =
            List.map (\p -> th [] [ text p.name ]) model.players
    in
    div [ class "pad-wrapper" ]
        [ table [ class "pad" ]
            ([ tr []
                ([ th []
                    [ text "" ]
                 ]
                    ++ headers
                )
             ]
                ++ boxItems
            )
        ]


renderCell : Box -> Model -> Player -> Bool -> Html Msg
renderCell box model player isCurrentPlayer =
    let
        upperSumText =
            getUpperSumText model.boxes model.values player

        upperSum =
            getUpperSum model.values player

        bonusValue =
            getBonusValue model.values player

        boxValue =
            List.head
                (List.filter
                    (\v ->
                        v.box == box && v.player == player
                    )
                    model.values
                )
    in
    case boxValue of
        Just value ->
            td [ classList [ ( "inactive", True ), ( "counted", value.counted ) ] ] [ text (getValueText value.value) ]

        Nothing ->
            if box.boxType == UpperSum then
                td [ class "inactive" ] [ text (String.fromInt upperSum) ]

            else if box.boxType == TotalSum then
                if model.game == ShowResults || model.game == ShowCountedValues then
                    td [ class "inactive" ] [ text (String.fromInt (getTotalSum model.values player)) ]

                else
                    td [ class "inactive" ] [ text "" ]

            else if box.boxType == Bonus then
                td [ classList [ ( "inactive bonus", True ), ( "animated bonus-cell", bonusValue > 0 ) ] ] [ upperSumText ]

            else if isCurrentPlayer then
                if box.category == None then
                    td [ classList [ ( "active", True ) ] ] [ text "" ]

                else
                    td [ class "active", onClick (ShowAddValue box) ] [ text "" ]

            else
                td [ class "inactive" ] [ text "" ]


renderBox : Box -> Html msg
renderBox box =
    span [] [ text <| "" ++ box.friendlyName ]


getUpperSumText : List Box -> List Value -> Player -> Html Msg
getUpperSumText boxes values player =
    let
        upperBoxes =
            List.filter (\b -> b.category == Upper) boxes

        upperValues =
            List.filter (\v -> v.box.category == Upper) (getValuesByPlayer values player)

        bonusValue =
            getBonusValue values player
    in
    case List.length upperBoxes == List.length upperValues || List.length upperValues == 0 || bonusValue > 0 of
        True ->
            if bonusValue > 0 then
                span [ class "upper-sum bonus" ] [ text (String.fromInt bonusValue) ]

            else
                span [ class "upper-sum" ] [ text "-" ]

        False ->
            let
                totalDelta =
                    sum
                        (List.map
                            (\v ->
                                case v.box.boxType of
                                    Regular numberValue ->
                                        v.value - numberValue * 3

                                    _ ->
                                        0
                            )
                            upperValues
                        )
            in
            if totalDelta == 0 then
                span [ class "upper-sum neutral" ] [ text "+/-0" ]

            else if totalDelta > 0 then
                span [ class "upper-sum positive" ] [ text ("+" ++ String.fromInt totalDelta) ]

            else
                span [ class "upper-sum negative" ] [ text ("" ++ String.fromInt totalDelta) ]
