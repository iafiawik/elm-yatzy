module Model.GameState exposing (GameState(..))

import Model.Box exposing (Box)


type GameState
    = Idle
    | Input Box Bool
    | WaitingForValueToBeCreated
