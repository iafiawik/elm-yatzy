module Message.Msg exposing (Msg(..))

import Message.Game
import Message.GameSetup
import Message.Navigate
import Message.Remote
import Model.Player exposing (Player)


type Msg
    = NavigateMessage Message.Navigate.Msg
    | GameSetupMessage Message.GameSetup.Msg
    | GameMessage Message.Game.Msg
    | RemoteMessage Message.Remote.Msg
    | NoOp
    | FillWithDummyValues Player
