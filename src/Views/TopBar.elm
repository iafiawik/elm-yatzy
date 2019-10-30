module Views.TopBar exposing (topBar)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model.Player exposing (Player)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


topBar : Bool -> Bool -> Player -> Bool -> Html Msg
topBar showCurrentPlayer isMyTurn currentPlayer loading =
    let
        currentPlayerInfo =
            if loading then
                loader "" True

            else if showCurrentPlayer == False then
                div [] [ text "Spelet är slut!" ]

            else if isMyTurn then
                div [ class "top-bar-not-waiting", onClick (FillWithDummyValues currentPlayer) ] [ span [] [ text "Det är din tur!" ] ]

            else
                div [ class "top-bar-waiting", onClick (FillWithDummyValues currentPlayer) ] [ span [] [ text "Väntar på" ], span [] [ text currentPlayer.user.name ] ]
    in
    div [ classList [ ( "top-bar", True ), ( "loading", loading ) ] ] [ button [ class "top-bar-refresh-button", onClick ReloadGame ] [], currentPlayerInfo, button [ class "top-bar-info-button", onClick ShowGameInfo ] [] ]
