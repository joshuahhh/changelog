module Symbol where

import Array exposing ( Array )
import Dict exposing ( Dict )
import Json.Encode

import JsonEncodeUtils

-- Here's the static world of definitions; unrendered logs

type alias SymbolId = String
type SymbolRef = BareNode | SymbolIdAsRef SymbolId

type alias Cloning =
  { id : String
  , symbolRef : SymbolRef
  }

type alias NodeId = String

type alias CompoundSymbol =
  { changes : Array Change
  }

type Change
  = SetRoot Cloning
  | AppendChild NodeId Cloning

type alias Environment =
  { symbols : Dict SymbolId CompoundSymbol }

environmentToJson : Environment -> Json.Encode.Value
environmentToJson environment =
  Json.Encode.object
    [ ( "symbols"
      , environment.symbols
        |> JsonEncodeUtils.mappedDict symbolToJson
      )
    ]

symbolToJson : CompoundSymbol -> Json.Encode.Value
symbolToJson symbol =
  Json.Encode.object
    [ ( "changes"
      , Json.Encode.array <| Array.map changeToJson symbol.changes
      )
    ]

changeToJson : Change -> Json.Encode.Value
changeToJson change =
  Json.Encode.object (
    case change of
      SetRoot cloning ->
        [ ( "type", Json.Encode.string "SetRoot" )
        , ( "cloningId", Json.Encode.string cloning.id )
        , ( "cloningSymbolId", symbolRefToJson cloning.symbolRef )
        ]
      AppendChild nodeId cloning ->
        [ ( "type", Json.Encode.string "SetRoot" )
        , ( "nodeId", Json.Encode.string nodeId )
        , ( "cloningId", Json.Encode.string cloning.id )
        , ( "cloningSymbolId", symbolRefToJson cloning.symbolRef )
        ])

symbolRefToJson : SymbolRef -> Json.Encode.Value
symbolRefToJson symbolRef =
  case symbolRef of
    BareNode ->
      Json.Encode.null
    SymbolIdAsRef symbolId ->
      Json.Encode.string symbolId
