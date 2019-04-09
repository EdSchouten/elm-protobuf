module Map exposing (..)

-- DO NOT EDIT
-- AUTOGENERATED BY THE ELM PROTOCOL BUFFER COMPILER
-- https://github.com/tiziano88/elm-protobuf
-- source file: map.proto

import Protobuf exposing (..)

import Json.Decode as JD
import Json.Encode as JE
import Dict


type alias MapValue =
    { field : Bool -- 1
    }
type MapValueMessage = MapValueMessage MapValue


mapValueDecoder : JD.Decoder MapValue
mapValueDecoder =
    JD.lazy <| \_ -> decode MapValue
        |> required "field" JD.bool False


mapValueEncoder : MapValue -> JE.Value
mapValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "field" JE.bool False v.field)
        ]


type alias MessageWithMaps =
    { stringToMessages : Dict.Dict String MapValueMessage -- 8
    , stringToStrings : Dict.Dict String String -- 7
    }
type MessageWithMapsMessage = MessageWithMapsMessage MessageWithMaps


messageWithMapsDecoder : JD.Decoder MessageWithMaps
messageWithMapsDecoder =
    JD.lazy <| \_ -> decode MessageWithMaps
        |> mapEntries "stringToMessages" (JD.map MapValueMessage mapValueDecoder)
        |> mapEntries "stringToStrings" JD.string


messageWithMapsEncoder : MessageWithMaps -> JE.Value
messageWithMapsEncoder v =
    JE.object <| List.filterMap identity <|
        [ (mapEntriesFieldEncoder "stringToMessages" (\(MapValueMessage f) -> mapValueEncoder f) v.stringToMessages)
        , (mapEntriesFieldEncoder "stringToStrings" JE.string v.stringToStrings)
        ]


type alias MessageWithMaps_StringToMessagesEntry =
    { key : String -- 1
    , value : Maybe MapValueMessage -- 2
    }
type MessageWithMaps_StringToMessagesEntryMessage = MessageWithMaps_StringToMessagesEntryMessage MessageWithMaps_StringToMessagesEntry


messageWithMaps_StringToMessagesEntryDecoder : JD.Decoder MessageWithMaps_StringToMessagesEntry
messageWithMaps_StringToMessagesEntryDecoder =
    JD.lazy <| \_ -> decode MessageWithMaps_StringToMessagesEntry
        |> required "key" JD.string ""
        |> optional "value" (JD.map MapValueMessage mapValueDecoder)


messageWithMaps_StringToMessagesEntryEncoder : MessageWithMaps_StringToMessagesEntry -> JE.Value
messageWithMaps_StringToMessagesEntryEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "key" JE.string "" v.key)
        , (optionalEncoder "value" (\(MapValueMessage f) -> mapValueEncoder f) v.value)
        ]


type alias MessageWithMaps_StringToStringsEntry =
    { key : String -- 1
    , value : String -- 2
    }
type MessageWithMaps_StringToStringsEntryMessage = MessageWithMaps_StringToStringsEntryMessage MessageWithMaps_StringToStringsEntry


messageWithMaps_StringToStringsEntryDecoder : JD.Decoder MessageWithMaps_StringToStringsEntry
messageWithMaps_StringToStringsEntryDecoder =
    JD.lazy <| \_ -> decode MessageWithMaps_StringToStringsEntry
        |> required "key" JD.string ""
        |> required "value" JD.string ""


messageWithMaps_StringToStringsEntryEncoder : MessageWithMaps_StringToStringsEntry -> JE.Value
messageWithMaps_StringToStringsEntryEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "key" JE.string "" v.key)
        , (requiredFieldEncoder "value" JE.string "" v.value)
        ]
