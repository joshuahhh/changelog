module DemoInfinite where

import Json.Encode
import Dict
import Array

import SymbolRendering exposing (
  SymbolRendering, ChangeInContext,
  runChangeInContext, catchUpCloningInSymbolRendering,
  jsonEncodeSymbolRendering)
import Symbol exposing (
  Environment, Change(..), SymbolRef(..),
  environmentToJson )

myEnvironment : Environment
myEnvironment =
  { symbols = Dict.fromList [
    ( "∞List"
    , { changes = Array.fromList
        [ SetRoot (
            { id = "pair"
            , symbolRef = BareNode
            }
          ),
          AppendChild "pair" (
            { id = "left"
            , symbolRef = BareNode
            }
          ),
          AppendChild "pair" (
            { id = "right"
            , symbolRef = SymbolIdAsRef "∞List"
            }
          )
        ]
      }
    )
  ]}

symbolRenderings : List SymbolRendering
symbolRenderings = List.scanl (<|)
  { blocks = [], rootId = Nothing }
  [ runChangeInContext
      { contextId = Nothing
      , change =
          SetRoot
            { id = "root"
            , symbolRef = SymbolIdAsRef "∞List"
            }
      }
  , catchUpCloningInSymbolRendering myEnvironment "root"
  , catchUpCloningInSymbolRendering myEnvironment "root/right"
  , catchUpCloningInSymbolRendering myEnvironment "root/right/right"
  ]

descriptionsInJson : Json.Encode.Value
descriptionsInJson = Json.Encode.list []

symbolRenderingsInJson : Json.Encode.Value
symbolRenderingsInJson =
  symbolRenderings
  |> List.map jsonEncodeSymbolRendering
  |> Json.Encode.list

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
