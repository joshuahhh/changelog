module DemoGroupInGroup where

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
    ( "Transform"
    , { changes = Array.fromList
        [ SetRoot (
            { id = "node"
            , symbolRef = BareNode
            }
          )
        ]
      }
    ),
    ( "Group",
      { changes = Array.fromList
        [ SetRoot (
            { id = "node"
            , symbolRef = BareNode
            }
          ),
          AppendChild "node" (
            { id = "transform"
            , symbolRef = SymbolIdAsRef "Transform"
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
            { id = "group1"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
  , catchUpCloningInSymbolRendering myEnvironment "group1"
  , catchUpCloningInSymbolRendering myEnvironment "group1/transform"
  , runChangeInContext
      { contextId = Nothing
      , change =
          AppendChild
            "group1/node"
            { id = "group2"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
  , catchUpCloningInSymbolRendering myEnvironment "group2"
  ]

descriptionsInJson : Json.Encode.Value
descriptionsInJson =
  [ "Start with an empty diagram."
  , "Clone a Group as the root."
  , "Tell the Group to catch up."
  , "Tell the Transform inside the Group to catch up."
  , "Clone a Group as a new child of the root node."
  , "Tell the second Group to catch up."
  ]
  |> List.map Json.Encode.string
  |> Json.Encode.list

symbolRenderingsInJson : Json.Encode.Value
symbolRenderingsInJson =
  symbolRenderings
  |> List.map jsonEncodeSymbolRendering
  |> Json.Encode.list

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
