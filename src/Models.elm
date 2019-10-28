module Models exposing (BlurredModel(..), GameAndUserId, GamePlaying, GameResult, GameResultState(..), GameSetup, GroupModel(..), IndividualModel(..), IndividualPlayingModel, IndividualPostGameModel, MarkedPlayer(..), Mode(..), Model, Msg(..), PlayerAndNumberOfValues, PreGameState(..))

import Json.Decode exposing (Decoder, field, int, map3, string)
import Model.Box exposing (Box)
import Model.Error exposing (Error(..))
import Model.Game exposing (DbGame, Game)
import Model.GameState exposing (GameState)
import Model.GlobalHighscore exposing (GlobalHighscore)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Model.Value exposing (Value)
import Model.WindowState exposing (WindowState)
import Time


type Msg
    = ShowStartPage
    | ChangeActiveHighscoreTab Int
    | SelectGroup
    | SelectIndividual
    | EnterGame
    | PlayerMarked Player
    | AllPlayersMarked
    | AddRemovePlayers
    | AddUser
    | RemoteUsers (List User)
    | RemoteValuesReceived (List Value)
    | GameReceived Game
    | GamesReceived (List Game)
    | GlobalHighscoreReceived (List GlobalHighscore)
    | WindowFocusedReceived Game String
    | WindowBlurredReceived
    | AddPlayer User
    | RemovePlayer Player
    | NewPlayerInputValueChange String
    | PlayersAdded
    | Start
    | AddValue
    | RemoveValue
    | ShowAddValue Box
    | ShowEditValue Value
    | ValueMarked Int
    | HideAddValue
    | InputValueChange String
    | GameCodeInputChange String
    | CountValues
    | CountValuesTick Time.Posix
    | HideHighscore
    | Restart
    | HideNotification
    | ShowGameInfo
    | ReloadGame
    | HideGameInfo
    | FillWithDummyValues Player
    | NoOp



-- type Error a b
--     = Just a b
--     | Nothing


type alias Model =
    { mode : Mode
    , game : Maybe Game
    , users : List User
    , highscoreList : List GlobalHighscore
    , windowState : WindowState
    , isAdmin : Bool
    }


type Mode
    = StartPage Int
    | Individual IndividualModel
    | Group GroupModel
    | BlurredGame BlurredModel


type BlurredModel
    = Reconnecting Game String
    | Inactive


type IndividualModel
    = EnterGameCode String (List Game)
    | WaitingForGame
    | SelectPlayer MarkedPlayer
    | IndividualPlaying IndividualPlayingModel
    | IndividualPostGame IndividualPostGameModel


type GroupModel
    = PreGame GameSetup
    | Playing GamePlaying
    | PostGame GameResult


type MarkedPlayer
    = Single Player
    | All
    | NoPlayer


type alias IndividualPlayingModel =
    { gamePlaying : GamePlaying
    , selectedPlayer : Player
    }


type alias IndividualPostGameModel =
    { selectedPlayer : Player
    }


type alias GameSetup =
    { players : List Player
    , currentNewPlayerName : String
    , state : PreGameState
    , error : Maybe Error
    }


type alias GamePlaying =
    { boxes : List Box
    , state : GameState
    , currentValue : Int
    , showGameInfo : Bool
    , error : Maybe Error
    }


type alias GameResult =
    { boxes : List Box
    , state : GameResultState
    , countedPlayers : List Player
    , countedValues : List Value
    , showGameInfo : Bool
    , error : Maybe Error
    }


type GameResultState
    = GameFinished
    | ShowCountedValues
    | ShowResults
    | HideResults


type PreGameState
    = ShowAddRemovePlayers
    | ShowIndividualJoinInfo


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    }


type alias GameAndUserId =
    { game : DbGame
    , userId : String
    }
