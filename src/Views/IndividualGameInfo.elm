module Views.IndividualGameInfo exposing (individualGameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Models exposing (Msg(..))


individualGameInfo : Game -> Html Msg
individualGameInfo game =
    div [ class "individual-game-info-dialog-wrapper dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "individual-game-info dialog-content animated jackInTheBox" ]
            [ button [ class "dialog-content-cancel-button button", onClick HideGameInfo ] [ text "X" ]
            , h1 [] [ text "Information" ]
            , h2 [] [ text "Du spelar ett spel med denna kod:" ]
            , span [ class "game-info-code" ] [ text game.code ]
            , div [ class "indivudal-game-info-restart" ]
                [ span [] [ text "Om du vill lämna detta spel eller byta spelare kan du klicka på knappen nedan. Detta kommer inte ta bort dig från spelet från permanent - du kan ansluta till spelet igen genom att ange koden ovan." ]
                , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick ShowStartPage ] [ text "Lämna spel" ]
                ]
            ]
        ]
