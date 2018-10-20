module Model.Error exposing (Error(..))


type Error
    = NoCurrentPlayer
    | UserAlreadyExists String
    | UnableToDecodeUsers String
