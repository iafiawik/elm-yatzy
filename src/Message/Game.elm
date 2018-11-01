module Message.Game exposing (Msg(..))

import Model.Box exposing (Box)
import Model.Value exposing (DbValue, Value)
import Time


type Msg
    = AddValue
    | RemoveValue
    | ShowAddValue Box
    | ShowEditValue Value
    | ValueMarked Int
    | HideAddValue
    | CountValues
    | CountValuesTick Time.Posix
