module Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Logic exposing (getBonusValue, getTotalSum, getUpperSum, getValuesByPlayer, sum)
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Game exposing (Game)
import Model.Player exposing (Player)
import Model.Value exposing (Value)
import Models exposing (Model, Msg(..), PlayerAndNumberOfValues)


getValueText : Int -> String
getValueText value =
    case value of
        0 ->
            "-"

        _ ->
            String.fromInt value


scoreCard : Player -> List Box -> List Value -> List Player -> Bool -> Bool -> Bool -> Html Msg
scoreCard currentPlayer boxes values players showCountedValues allowInteraction showTotalSum =
    let
        boxItems =
            List.map
                (\box ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    renderCell box boxes values p (p == currentPlayer) allowInteraction showTotalSum
                                )
                                players
                    in
                    tr []
                        ([ td [ class "box" ] [ renderBox box ]
                         ]
                            ++ playerBoxes
                        )
                )
                boxes

        headers =
            List.map (\p -> th [] [ text p.user.name ]) players
    in
    div [ class "score-card-wrapper" ]
        [ table [ class "score-card" ]
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


staticScoreCard : Player -> List Box -> List Value -> List Player -> Bool -> Bool -> Html Msg
staticScoreCard currentPlayer boxes values players showCountedValues showTotalSum =
    scoreCard currentPlayer boxes values players showCountedValues False showTotalSum


interactiveScoreCard : Player -> List Box -> List Value -> List Player -> Bool -> Html Msg
interactiveScoreCard currentPlayer boxes values players showCountedValues =
    scoreCard currentPlayer boxes values players showCountedValues True False


renderCell : Box -> List Box -> List Value -> Player -> Bool -> Bool -> Bool -> Html Msg
renderCell box boxes values player isCurrentPlayer allowInteraction showTotalSum =
    let
        boxValue =
            List.head
                (List.filter
                    (\v ->
                        v.box == box && v.player == player
                    )
                    values
                )
    in
    case boxValue of
        Just value ->
            if isCurrentPlayer && allowInteraction then
                td [ classList [ ( "inactive", True ), ( "counted", value.counted ) ], onClick (ShowEditValue value) ] [ text (getValueText value.value) ]

            else
                td [ classList [ ( "inactive", True ), ( "counted", value.counted ) ] ] [ text (getValueText value.value) ]

        Nothing ->
            if box.boxType == UpperSum then
                let
                    upperSum =
                        getUpperSum values player
                in
                td [ class "inactive" ] [ text (String.fromInt upperSum) ]

            else if box.boxType == TotalSum then
                if showTotalSum then
                    td [ class "inactive" ] [ text (String.fromInt (getTotalSum values player)) ]

                else
                    td [ class "inactive" ] [ text "" ]

            else if box.boxType == Bonus then
                let
                    upperSumText =
                        getUpperSumText boxes values player

                    bonusValue =
                        getBonusValue values player
                in
                td [ classList [ ( "inactive bonus", True ), ( "animated bonus-cell", bonusValue > 0 ) ] ] [ upperSumText ]

            else if isCurrentPlayer then
                if box.category == None then
                    td [ classList [ ( "active", True ) ] ] [ text "" ]

                else if allowInteraction then
                    td [ class "active", onClick (ShowAddValue box) ] [ text "" ]

                else
                    td [ class "active" ] [ text "" ]

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
