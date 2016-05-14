module Main where

import Html
import Json.Encode
import Dict
import Array

import Util exposing ( force )
import SymbolRendering exposing (
  SymbolRendering, runChangeInSymbolRendering, BlockId, BlockBody(..), Block,
  symbolRenderingToThatJsonFormatIUse)
import Symbol exposing ( myEnvironment, Change(..), SymbolRef(..), CompoundSymbol )


group : CompoundSymbol
group = force (Dict.get "Group" myEnvironment.symbols)

transform : CompoundSymbol
transform = force (Dict.get "Transform" myEnvironment.symbols)


symbolRendering0 : SymbolRendering
symbolRendering0 = { blocks = [], rootId = Nothing }

symbolRendering1 : SymbolRendering
symbolRendering1 =
  runChangeInSymbolRendering
    symbolRendering0
    Nothing
    (SetRoot
      { id = "1"
      , symbolRef = SymbolIdAsRef "Group"
      }
    )

symbolRendering2 : SymbolRendering
symbolRendering2 =
  runChangeInSymbolRendering
    symbolRendering1
    (Just "1")
    (force (Array.get 0 group.changes))

symbolRendering3 : SymbolRendering
symbolRendering3 =
  runChangeInSymbolRendering
    symbolRendering2
    (Just "1")
    (force (Array.get 1 group.changes))

symbolRendering4 : SymbolRendering
symbolRendering4 =
  runChangeInSymbolRendering
    symbolRendering3
    (Just "1/transform")
    (force (Array.get 0 transform.changes))

finalSymbolRendering : SymbolRendering
finalSymbolRendering = symbolRendering4

finalJsonFormatIUse : Json.Encode.Value
finalJsonFormatIUse = symbolRenderingToThatJsonFormatIUse finalSymbolRendering

main : Html.Html
main =
  Html.div []
  [ Html.pre []
      [ Html.text (Json.Encode.encode 4 (symbolRenderingToThatJsonFormatIUse symbolRendering1)) ]
  , Html.pre []
      [ Html.text (Json.Encode.encode 4 (symbolRenderingToThatJsonFormatIUse symbolRendering2)) ]
  , Html.pre []
      [ Html.text (Json.Encode.encode 4 (symbolRenderingToThatJsonFormatIUse symbolRendering3)) ]
  , Html.pre []
      [ Html.text (Json.Encode.encode 4 (symbolRenderingToThatJsonFormatIUse symbolRendering4)) ]
  ]
  -- text (toString finalSymbolRendering)
