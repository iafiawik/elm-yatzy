module Views.TopBar exposing (topBar)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.Player exposing (Player)
import Models exposing (Msg(..))


topBar : Bool -> Bool -> Player -> Html Msg
topBar showCurrentPlayer isMyTurn currentPlayer =
    let
        currentPlayerInfo =
            if showCurrentPlayer == False then
                div [] []

            else if isMyTurn then
                div [ class "top-bar-not-waiting", onClick (FillWithDummyValues currentPlayer) ] [ span [] [ text "Det är din tur!" ] ]

            else
                div [ class "top-bar-waiting", onClick (FillWithDummyValues currentPlayer) ] [ span [] [ text "Väntar på" ], span [] [ text currentPlayer.user.name ] ]
    in
    div [ class "top-bar" ] [ currentPlayerInfo, button [ class "top-bar-info-button", onClick ShowGameInfo ] [] ]
