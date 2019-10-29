module Views.WaitingForGame exposing (waitingForGame)

import Html exposing (..)
import Html.Attributes exposing (..)
import Models exposing (Msg(..))
import Views.Loader exposing (loader)


waitingForGame : Bool -> Html Msg
waitingForGame isNewGame =
    let
        loadingText =
            if isNewGame == True then
                "Skapar spel"

            else
                "Ansluter till spel"
    in
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ classList [ ( "individual-join-info dialog-content animated jackInTheBox", True ), ( "loading", True ) ] ]
            [ loader loadingText True ]
        ]
