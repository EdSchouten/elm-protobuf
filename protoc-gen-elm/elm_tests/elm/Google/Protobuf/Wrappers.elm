module Google.Protobuf.Wrappers exposing (..)

import Json.Decode as JD
import Json.Encode as JE

import Dir.Other_dir
import Other


(<$>) : (a -> b) -> JD.Decoder a -> JD.Decoder b
(<$>) =
    JD.map


(<*>) : JD.Decoder (a -> b) -> JD.Decoder a -> JD.Decoder b
(<*>) f v =
    f |> JD.andThen (\x -> x <$> v)


optionalDecoder : JD.Decoder a -> JD.Decoder (Maybe a)
optionalDecoder decoder =
    JD.oneOf
        [ JD.map Just decoder
        , JD.succeed Nothing
        ]


requiredFieldDecoder : String -> a -> JD.Decoder a -> JD.Decoder a
requiredFieldDecoder name default decoder =
    withDefault default (JD.field name decoder)


optionalFieldDecoder : String -> JD.Decoder a -> JD.Decoder (Maybe a)
optionalFieldDecoder name decoder =
    optionalDecoder (JD.field name decoder)


repeatedFieldDecoder : String -> JD.Decoder a -> JD.Decoder (List a)
repeatedFieldDecoder name decoder =
    withDefault [] (JD.field name (JD.list decoder))


withDefault : a -> JD.Decoder a -> JD.Decoder a
withDefault default decoder =
    JD.oneOf
        [ decoder
        , JD.succeed default
        ]


optionalEncoder : String -> (a -> JE.Value) -> Maybe a -> Maybe ( String, JE.Value )
optionalEncoder name encoder v =
    case v of
        Just x ->
            Just ( name, encoder x )

        Nothing ->
            Nothing


requiredFieldEncoder : String -> (a -> JE.Value) -> a -> a -> Maybe ( String, JE.Value )
requiredFieldEncoder name encoder default v =
    if v == default then
        Nothing
    else
        Just ( name, encoder v )


repeatedFieldEncoder : String -> (a -> JE.Value) -> List a -> Maybe ( String, JE.Value )
repeatedFieldEncoder name encoder v =
    case v of
        [] ->
            Nothing
        _ ->
            Just (name, JE.list <| List.map encoder v)


bytesFieldDecoder : JD.Decoder (List Int)
bytesFieldDecoder =
    JD.succeed []


bytesFieldEncoder : (List Int) -> JE.Value
bytesFieldEncoder v =
    JE.list []


type alias DoubleValue =
    { value : Float -- 1
    }


doubleValueDecoder : JD.Decoder DoubleValue
doubleValueDecoder =
    JD.lazy <| \_ -> DoubleValue
        <$> (requiredFieldDecoder "value" 0.0 JD.float)


doubleValueEncoder : DoubleValue -> JE.Value
doubleValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.float 0.0 v.value)
        ]


type alias FloatValue =
    { value : Float -- 1
    }


floatValueDecoder : JD.Decoder FloatValue
floatValueDecoder =
    JD.lazy <| \_ -> FloatValue
        <$> (requiredFieldDecoder "value" 0.0 JD.float)


floatValueEncoder : FloatValue -> JE.Value
floatValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.float 0.0 v.value)
        ]


type alias Int64Value =
    { value : Int -- 1
    }


int64ValueDecoder : JD.Decoder Int64Value
int64ValueDecoder =
    JD.lazy <| \_ -> Int64Value
        <$> (requiredFieldDecoder "value" 0 JD.int)


int64ValueEncoder : Int64Value -> JE.Value
int64ValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.int 0 v.value)
        ]


type alias UInt64Value =
    { value : Int -- 1
    }


uInt64ValueDecoder : JD.Decoder UInt64Value
uInt64ValueDecoder =
    JD.lazy <| \_ -> UInt64Value
        <$> (requiredFieldDecoder "value" 0 JD.int)


uInt64ValueEncoder : UInt64Value -> JE.Value
uInt64ValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.int 0 v.value)
        ]


type alias Int32Value =
    { value : Int -- 1
    }


int32ValueDecoder : JD.Decoder Int32Value
int32ValueDecoder =
    JD.lazy <| \_ -> Int32Value
        <$> (requiredFieldDecoder "value" 0 JD.int)


int32ValueEncoder : Int32Value -> JE.Value
int32ValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.int 0 v.value)
        ]


type alias UInt32Value =
    { value : Int -- 1
    }


uInt32ValueDecoder : JD.Decoder UInt32Value
uInt32ValueDecoder =
    JD.lazy <| \_ -> UInt32Value
        <$> (requiredFieldDecoder "value" 0 JD.int)


uInt32ValueEncoder : UInt32Value -> JE.Value
uInt32ValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.int 0 v.value)
        ]


type alias BoolValue =
    { value : Bool -- 1
    }


boolValueDecoder : JD.Decoder BoolValue
boolValueDecoder =
    JD.lazy <| \_ -> BoolValue
        <$> (requiredFieldDecoder "value" False JD.bool)


boolValueEncoder : BoolValue -> JE.Value
boolValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.bool False v.value)
        ]


type alias StringValue =
    { value : String -- 1
    }


stringValueDecoder : JD.Decoder StringValue
stringValueDecoder =
    JD.lazy <| \_ -> StringValue
        <$> (requiredFieldDecoder "value" "" JD.string)


stringValueEncoder : StringValue -> JE.Value
stringValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" JE.string "" v.value)
        ]


type alias BytesValue =
    { value : (List Int) -- 1
    }


bytesValueDecoder : JD.Decoder BytesValue
bytesValueDecoder =
    JD.lazy <| \_ -> BytesValue
        <$> (requiredFieldDecoder "value" [] bytesFieldDecoder)


bytesValueEncoder : BytesValue -> JE.Value
bytesValueEncoder v =
    JE.object <| List.filterMap identity <|
        [ (requiredFieldEncoder "value" bytesFieldEncoder [] v.value)
        ]
