module Main exposing (main)

import Browser
import Element as ElmUiElement exposing (Element, alignRight, el, rgb, row, text)
import Element.Background as Background
import Element.Border as Border
import Html exposing (Html, div, input, label, li, span, table, td, text, th, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


stringEvents : Html String
stringEvents =
    button [ onClick "hello" ] [ text "String events" ]


intEvents : Html Int
intEvents =
    button [ onClick 1 ] [ text "Int events" ]


boolEvents : Html Bool
boolEvents =
    button [ onClick True ] [ text "Boolean events" ]



-- EVEN CUSTOM TYPES


type Color
    = Red
    | Blue
    | Green


colorEvent : Html Color
colorEvent =
    button [ onClick Red ] [ text "Color events" ]


staticHtml : Html msg
staticHtml =
    button [] [ text "no event handlers here!" ]



-- COMPILER WILL COMPLAIN SIGNATURE IS TOO GENERIC
-- EVENTS HERE CAN ONLY EVER BE INTS
-- SIGNATURE SHOULD BE Html Int


fakeStaticHtml : Html msg
fakeStaticHtml =
    button [ onClick 1 ] [ text "no event handlers here!" ]



--
-- passInAnyKindOfEvent : msg -> Html msg
-- passInAnyKindOfEvent value =
--   button [ onClick value ] [ text "passed in" ]
--
-- -- ALLOWS
--
-- passInAnyKindOfEvent "hi" -- Html String
--
-- passInAnyKindOfEvent 10 -- Html Int
--
-- passInAnyKindOfEvent True -- Html Bool
--
--
-- staticList : List a
-- staticList =
--   []
--
-- -- COMPILER WILL COMPLAIN SIGNATURE IS TOO GENERIC
-- -- TYPE SHOULD BE List Bool
-- fakeStaticList : List a
-- fakeStaticList =
--   [True]
--
-- passInValue : a -> List a
-- passInValue value =
--   [value]
--
-- -- ALLOWS
--
-- passInValue "hello" -- List String
-- passInValue 1 -- List Int
-- passInValue Bool -- List Bool
