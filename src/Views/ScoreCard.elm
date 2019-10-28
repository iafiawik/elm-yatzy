module Views.ScoreCard exposing (interactiveScoreCard, staticScoreCard)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List.Extra exposing (getAt)
import Model.Box exposing (Box, getAcceptedValues, getBoxes)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Game exposing (Game, getBonusValue, getTotalSum, getUpperSum, getValueByPlayerAndBox, sum)
import Model.Player exposing (Player, getShortNames)
import Model.Value exposing (Value)
import Model.Values exposing (Values)
import Models exposing (Model, Msg(..), PlayerAndNumberOfValues)
import Views.TopBar exposing (topBar)


getValueText : Int -> String
getValueText value =
    case value of
        0 ->
            "-"

        _ ->
            String.fromInt value


scoreCard : Maybe Player -> Game -> Bool -> Bool -> Bool -> Html Msg
scoreCard selectedPlayer game showCountedValues allowInteraction showTotalSum =
    let
        _ =
            Debug.log "scoreCard" (Debug.toString game.players)

        boxes =
            getBoxes

        players =
            game.players

        currentPlayer =
            game.activePlayer

        numberOfPlayers =
            List.length players

        minLengthOfPlayerNames =
            if numberOfPlayers > 2 then
                2

            else if numberOfPlayers > 4 then
                1

            else
                10

        playerNames =
            getShortNames (List.map (\player -> player.user.name) game.players) minLengthOfPlayerNames

        hasSelectedPlayer =
            selectedPlayer /= Nothing

        boxItems =
            List.map
                (\box ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    renderCell box boxes p currentPlayer selectedPlayer allowInteraction showTotalSum
                                )
                                players

                        isActiveBoxForCurrentPlayer =
                            isActiveBoxForPlayer currentPlayer.values box
                    in
                    tr []
                        ([ td [ classList [ ( "box", True ), ( "party-active", isActiveBoxForCurrentPlayer && not (isInactiveBoxCategory box) ) ] ] [ renderBox box ]
                         ]
                            ++ playerBoxes
                        )
                )
                boxes

        headers =
            List.indexedMap
                (\index player ->
                    let
                        isSelectedPlayer =
                            selectedPlayer == Just player

                        isCurrentPlayer =
                            player == currentPlayer

                        name =
                            Maybe.withDefault "" (getAt index playerNames)

                        classNames =
                            [ ( "active", isCurrentPlayer ), ( "selected", isSelectedPlayer ) ]
                    in
                    th [ classList classNames ] [ span [] [ text name ] ]
                )
                players
    in
    div [ classList [ ( "score-card-wrapper", True ), ( "has-selected-player", hasSelectedPlayer ) ] ]
        [ topBar (not game.finished) (hasSelectedPlayer == True && (selectedPlayer == Just currentPlayer)) currentPlayer
        , table [ classList [ ( "score-card", True ), ( "allow-interaction", allowInteraction == True ), ( "has-selected-player", hasSelectedPlayer ), ( "show-total-sum", showTotalSum ), ( "show-counted-values", showCountedValues ) ] ]
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


isInactiveBoxCategory : Box -> Bool
isInactiveBoxCategory box =
    box.boxType == UpperSum || box.boxType == TotalSum || box.boxType == Bonus


staticScoreCard : Game -> Bool -> Bool -> Html Msg
staticScoreCard game showCountedValues showTotalSum =
    scoreCard Nothing game showCountedValues False showTotalSum


interactiveScoreCard : Maybe Player -> Game -> Bool -> Html Msg
interactiveScoreCard selectedPlayer game showCountedValues =
    scoreCard selectedPlayer game showCountedValues True False


isActiveBoxForPlayer : Values -> Box -> Bool
isActiveBoxForPlayer values box =
    getValueByPlayerAndBox values box == Nothing


renderCell : Box -> List Box -> Player -> Player -> Maybe Player -> Bool -> Bool -> Html Msg
renderCell box boxes player currentPlayer selectedPlayer allowInteraction showTotalSum =
    let
        hasSelectedPlayer =
            selectedPlayer /= Nothing

        isSelectedPlayer =
            selectedPlayer == Just player

        isCurrentPlayer =
            player == currentPlayer

        allowEditAdd =
            ((hasSelectedPlayer == True && isSelectedPlayer && isCurrentPlayer) || (hasSelectedPlayer == False && isCurrentPlayer)) && allowInteraction

        boxValue =
            getValueByPlayerAndBox player.values box

        isActiveBoxForTheCurrentPlayer =
            isActiveBoxForPlayer currentPlayer.values box
    in
    case boxValue of
        Just value ->
            let
                classNames =
                    [ ( "inactive", True ), ( "partly-active", isActiveBoxForTheCurrentPlayer ), ( "selected", isSelectedPlayer ), ( "new", value.new ), ( "counted", value.counted ) ]
            in
            if allowEditAdd then
                td [ classList classNames, onClick (ShowEditValue value) ] [ text (getValueText value.value) ]

            else
                td [ classList classNames ] [ text (getValueText value.value) ]

        Nothing ->
            if box.boxType == UpperSum then
                let
                    upperSum =
                        getUpperSum player.values
                in
                td [ classList [ ( "inactive", True ), ( "selected", isSelectedPlayer ) ] ] [ text (String.fromInt upperSum) ]

            else if box.boxType == TotalSum then
                if showTotalSum then
                    td [ class "inactive" ] [ text (String.fromInt (getTotalSum player.values)) ]

                else
                    td [ classList [ ( "inactive", True ), ( "selected", isSelectedPlayer ) ] ] [ text "" ]

            else if box.boxType == Bonus then
                let
                    bonusValue =
                        getBonusValue player.values

                    upperSumText =
                        getUpperSumText bonusValue boxes player
                in
                td [ classList [ ( "inactive bonus", True ), ( "selected", isSelectedPlayer ), ( "animated bonus-cell", bonusValue > 0 ) ] ] [ upperSumText ]

            else if isCurrentPlayer || isSelectedPlayer && hasSelectedPlayer then
                let
                    classNames =
                        [ ( "active", isCurrentPlayer ), ( "selected", isSelectedPlayer ), ( "counted", False ) ]
                in
                if box.category == None then
                    td [ classList classNames ] [ text "" ]

                else if allowEditAdd then
                    td [ classList classNames, onClick (ShowAddValue box) ] [ text "" ]

                else
                    td [ classList classNames ] [ text "" ]

            else
                td [ classList [ ( "inactive", True ), ( "partly-active", isActiveBoxForTheCurrentPlayer ) ] ] [ text "" ]


renderBox : Box -> Html msg
renderBox box =
    span [] [ text <| "" ++ box.friendlyName ]


getUpperSumText : Int -> List Box -> Player -> Html Msg
getUpperSumText bonusValue boxes player =
    let
        upperBoxes =
            List.filter (\b -> b.category == Upper) boxes

        upperValues =
            List.filter (\v -> v.box.category == Upper && v.value /= -1) player.values
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
