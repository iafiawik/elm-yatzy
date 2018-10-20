module Views.Notification exposing (notification)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Models exposing (Msg(..))


notification : String -> Html Msg
notification errorMsg =
    div [ onClick HideNotification, class "notification" ] [ text errorMsg ]
