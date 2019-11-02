module Model.User exposing (User, userDecoder, usersDecoder)

import Json.Decode as Decode exposing (Decoder)


usersDecoder : Decoder (List User)
usersDecoder =
    Decode.list userDecoder


userDecoder : Decoder User
userDecoder =
    Decode.map3 User
        (Decode.field "id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "userName" Decode.string)


type alias User =
    { id : String, name : String, userName : String }
