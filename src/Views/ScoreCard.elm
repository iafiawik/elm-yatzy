module Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Logic exposing (getBonusValue, getBoxes, getTotalSum, getUpperSum, getValuesByPlayer, sum)
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Game exposing (Game)
import Model.Player exposing (Player)
import Model.Value exposing (Value)
import Models exposing (Model, Msg(..), PlayerAndNumberOfValues)
import Views.TopBar exposing (topBar)


getValueText : Int -> String
getValueText value =
    case value of
        0 ->
            "-"

        _ ->
            String.fromInt value


selectedPlayerExists selectedPlayerMaybe =
    case selectedPlayerMaybe of
        Just selectedPlayer ->
            True

        Nothing ->
            False


isPlayerTheSelectedPlayer selectedPlayerMaybe player =
    case selectedPlayerMaybe of
        Just selectedPlayer ->
            selectedPlayer == player

        Nothing ->
            False


scoreCard : Player -> Maybe Player -> Game -> Bool -> Bool -> Bool -> Html Msg
scoreCard currentPlayer selectedPlayer game showCountedValues allowInteraction showTotalSum =
    let
        boxes =
            getBoxes

        values =
            game.values

        players =
            game.players

        hasSelectedPlayer =
            selectedPlayerExists selectedPlayer

        boxItems =
            List.map
                (\box ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    renderCell box boxes values p currentPlayer selectedPlayer allowInteraction showTotalSum
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
            List.map
                (\player ->
                    let
                        isSelectedPlayer =
                            isPlayerTheSelectedPlayer selectedPlayer player

                        isCurrentPlayer =
                            player == currentPlayer

                        name =
                            if isSelectedPlayer then
                                player.user.name

                            else
                                player.user.name

                        classNames =
                            [ ( "active", isCurrentPlayer ), ( "selected", isSelectedPlayer ) ]
                    in
                    th [ classList classNames ] [ span [] [ text name ] ]
                )
                players

        currentTopBar =
            if game.finished == False then
                topBar (hasSelectedPlayer == True && isPlayerTheSelectedPlayer selectedPlayer currentPlayer == True) currentPlayer

            else
                div [] []
    in
    div [ class "score-card-wrapper" ]
        [ currentTopBar
        , table [ classList [ ( "score-card", True ), ( "has-selected-player", hasSelectedPlayer ) ] ]
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


staticScoreCard : Player -> Game -> Bool -> Bool -> Html Msg
staticScoreCard currentPlayer game showCountedValues showTotalSum =
    scoreCard currentPlayer Nothing game showCountedValues False showTotalSum


interactiveScoreCard : Player -> Maybe Player -> Game -> Bool -> Html Msg
interactiveScoreCard currentPlayer selectedPlayer game showCountedValues =
    scoreCard currentPlayer selectedPlayer game showCountedValues True False


renderCell : Box -> List Box -> List Value -> Player -> Player -> Maybe Player -> Bool -> Bool -> Html Msg
renderCell box boxes values player currentPlayer selectedPlayer allowInteraction showTotalSum =
    let
        hasSelectedPlayer =
            selectedPlayerExists selectedPlayer

        isSelectedPlayer =
            isPlayerTheSelectedPlayer selectedPlayer player

        isCurrentPlayer =
            player == currentPlayer

        allowEditAdd =
            ((hasSelectedPlayer == True && isSelectedPlayer && isCurrentPlayer) || (hasSelectedPlayer == False && isCurrentPlayer)) && allowInteraction

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
            let
                classNames =
                    [ ( "inactive", True ), ( "selected", isSelectedPlayer ), ( "new", value.new ) ]
            in
            if allowEditAdd then
                td [ classList classNames, onClick (ShowEditValue value) ] [ text (getValueText value.value) ]

            else
                td [ classList classNames ] [ text (getValueText value.value) ]

        Nothing ->
            if box.boxType == UpperSum then
                let
                    upperSum =
                        getUpperSum values player
                in
                td [ classList [ ( "inactive", True ), ( "selected", isSelectedPlayer ) ] ] [ text (String.fromInt upperSum) ]

            else if box.boxType == TotalSum then
                if showTotalSum then
                    td [ class "inactive" ] [ text (String.fromInt (getTotalSum values player)) ]

                else
                    td [ classList [ ( "inactive", True ), ( "selected", isSelectedPlayer ) ] ] [ text "" ]

            else if box.boxType == Bonus then
                let
                    upperSumText =
                        getUpperSumText boxes values player

                    bonusValue =
                        getBonusValue values player
                in
                td [ classList [ ( "inactive bonus", True ), ( "selected", isSelectedPlayer ), ( "animated bonus-cell", bonusValue > 0 ) ] ] [ upperSumText ]

            else if isCurrentPlayer || isSelectedPlayer && hasSelectedPlayer then
                let
                    classNames =
                        [ ( "active", isCurrentPlayer ), ( "selected", isSelectedPlayer ) ]
                in
                if box.category == None then
                    td [ classList classNames ] [ text "" ]

                else if allowEditAdd then
                    td [ classList classNames, onClick (ShowAddValue box) ] [ text "" ]

                else
                    td [ classList classNames ] [ text "" ]

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
