module Views.ScoreCard exposing (interactiveScoreCard, nakedScoreCard, staticScoreCard)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy)
import List.Extra exposing (find, getAt)
import Model.Box exposing (Box, getAcceptedValues, getBoxes)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Game exposing (Game, getBonusValue, getTotalSum, getUpperSum, getValueByPlayerAndBox, sum)
import Model.Player exposing (Player, getShortNames)
import Model.Value exposing (Value)
import Model.Values exposing (Values)
import Models exposing (MarkedPlayer(..), Model, Msg(..))
import Views.TopBar exposing (topBar)


getValueText : Int -> String
getValueText value =
    case value of
        0 ->
            "-"

        _ ->
            String.fromInt value


isPlayerMarked : Player -> MarkedPlayer -> Bool
isPlayerMarked player markedPlayer =
    case markedPlayer of
        Single currentMarkedPlayer ->
            currentMarkedPlayer.user.id == player.user.id

        All ->
            False

        NoPlayer ->
            False


scoreCard : MarkedPlayer -> Game -> Bool -> Bool -> Bool -> Bool -> Html Msg
scoreCard markedPlayer game showCountedValues allowInteraction showTotalSum loading =
    let
        selectedPlayer =
            case markedPlayer of
                Single player ->
                    Just player

                _ ->
                    Nothing

        boxes =
            getBoxes

        players =
            game.players

        activePlayer =
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

        highlightedPlayer : Player
        highlightedPlayer =
            case markedPlayer of
                Single singleMarkedPlayer ->
                    Maybe.withDefault activePlayer
                        (find (\player -> player.user.id == singleMarkedPlayer.user.id) game.players)

                _ ->
                    activePlayer

        boxItems =
            List.map
                (\box ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    renderCell box boxes p activePlayer markedPlayer allowInteraction showTotalSum
                                )
                                players

                        isActiveBoxForHighlightedPlayer =
                            isActiveBoxForPlayer highlightedPlayer.values box

                        cells =
                            [ td [ classList [ ( "box", True ), ( "party-active", isActiveBoxForHighlightedPlayer && not (isInactiveBoxCategory box) ) ] ] [ renderBox box ]
                            ]
                                ++ playerBoxes
                    in
                    tr [] cells
                )
                boxes

        headers =
            List.indexedMap
                (\index player ->
                    let
                        isSelectedPlayer =
                            isPlayerMarked player markedPlayer

                        isactivePlayer =
                            player == activePlayer

                        name =
                            Maybe.withDefault "" (getAt index playerNames)

                        classNames =
                            [ ( "active", isactivePlayer ), ( "selected", isSelectedPlayer ) ]
                    in
                    th [ classList classNames ] [ span [] [ text name ] ]
                )
                players
    in
    div [ classList [ ( "score-card-wrapper", True ), ( "has-selected-player", hasSelectedPlayer ) ] ]
        [ topBar (not game.finished) (hasSelectedPlayer == True && (selectedPlayer == Just activePlayer)) activePlayer loading
        , nakedScoreCard markedPlayer game showCountedValues allowInteraction showTotalSum loading
        ]


nakedScoreCard : MarkedPlayer -> Game -> Bool -> Bool -> Bool -> Bool -> Html Msg
nakedScoreCard markedPlayer game showCountedValues allowInteraction showTotalSum loading =
    let
        selectedPlayer =
            case markedPlayer of
                Single player ->
                    Just player

                _ ->
                    Nothing

        boxes =
            getBoxes

        players =
            game.players

        activePlayer =
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

        highlightedPlayer : Player
        highlightedPlayer =
            case markedPlayer of
                Single singleMarkedPlayer ->
                    Maybe.withDefault activePlayer
                        (find (\player -> player.user.id == singleMarkedPlayer.user.id) game.players)

                _ ->
                    activePlayer

        boxItems =
            List.map
                (\box ->
                    let
                        playerBoxes =
                            List.map
                                (\p ->
                                    renderCell box boxes p activePlayer markedPlayer allowInteraction showTotalSum
                                )
                                players

                        isActiveBoxForHighlightedPlayer =
                            isActiveBoxForPlayer highlightedPlayer.values box

                        cells =
                            [ td [ classList [ ( "box", True ), ( "party-active", isActiveBoxForHighlightedPlayer && not (isInactiveBoxCategory box) ) ] ] [ renderBox box ]
                            ]
                                ++ playerBoxes
                    in
                    tr [] cells
                )
                boxes

        headers =
            List.indexedMap
                (\index player ->
                    let
                        isSelectedPlayer =
                            isPlayerMarked player markedPlayer

                        _ =
                            Debug.log "isSelectedPlayer" (Debug.toString isSelectedPlayer)

                        isactivePlayer =
                            player == activePlayer

                        name =
                            Maybe.withDefault "" (getAt index playerNames)

                        classNames =
                            [ ( "active", isactivePlayer ), ( "selected", isSelectedPlayer ) ]
                    in
                    th [ classList classNames ] [ span [] [ text name ] ]
                )
                players
    in
    table
        [ classList
            [ ( "score-card", True )
            , ( "loading", loading )
            , ( "allow-interaction", allowInteraction == True )
            , ( "has-selected-player", hasSelectedPlayer )
            , ( "show-total-sum", showTotalSum )
            , ( "show-counted-values", showCountedValues )
            ]
        ]
        ([ tr []
            ([ th []
                [ text "" ]
             ]
                ++ headers
            )
         ]
            ++ boxItems
        )


isInactiveBoxCategory : Box -> Bool
isInactiveBoxCategory box =
    box.boxType == UpperSum || box.boxType == TotalSum || box.boxType == Bonus


staticScoreCard : Game -> Bool -> Bool -> Html Msg
staticScoreCard game showCountedValues showTotalSum =
    scoreCard All game showCountedValues False showTotalSum False


interactiveScoreCard : MarkedPlayer -> Game -> Bool -> Bool -> Html Msg
interactiveScoreCard markedPlayer game showCountedValues loading =
    scoreCard markedPlayer game showCountedValues True False loading


isActiveBoxForPlayer : Values -> Box -> Bool
isActiveBoxForPlayer values box =
    getValueByPlayerAndBox values box == Nothing


renderCell : Box -> List Box -> Player -> Player -> MarkedPlayer -> Bool -> Bool -> Html Msg
renderCell box boxes player activePlayer selectedPlayer allowInteraction showTotalSum =
    let
        hasSelectedPlayer =
            selectedPlayer /= All && selectedPlayer /= NoPlayer

        isSelectedPlayer =
            isPlayerMarked player selectedPlayer

        isactivePlayer =
            player == activePlayer

        allowEditAdd =
            ((hasSelectedPlayer == True && isSelectedPlayer && isactivePlayer) || (hasSelectedPlayer == False && isactivePlayer)) && allowInteraction

        boxValue =
            getValueByPlayerAndBox player.values box

        isActiveBoxForTheactivePlayer =
            isActiveBoxForPlayer activePlayer.values box
    in
    case boxValue of
        Just value ->
            let
                classNames =
                    [ ( "inactive", True ), ( "partly-active", isActiveBoxForTheactivePlayer && not hasSelectedPlayer ), ( "selected", isSelectedPlayer ), ( "new", value.new ), ( "counted", False ) ]
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

            else if isactivePlayer || isSelectedPlayer && hasSelectedPlayer then
                let
                    classNames =
                        [ ( "active", isactivePlayer ), ( "selected", isSelectedPlayer ), ( "counted", False ) ]
                in
                if box.category == None then
                    td [ classList classNames ] [ text "" ]

                else if allowEditAdd then
                    td [ classList classNames, onClick (ShowAddValue box) ] [ text "" ]

                else
                    td [ classList classNames ] [ text "" ]

            else
                td [ classList [ ( "inactive", True ), ( "partly-active", isActiveBoxForTheactivePlayer ) ] ] [ text "" ]


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
