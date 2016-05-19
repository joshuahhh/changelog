module DemoAutoCatchUp where

import Json.Encode
import Dict
import Array

import SymbolRendering exposing (
  SymbolRendering, runChangeInContextAsStep, catchUpCloning, jsonEncodeSymbolRendering)
import Symbol exposing (
  Environment, Change(..), SymbolRef(..), environmentToJson )
import Story exposing (
  Story, emptyStory, jsonEncodeStory )

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

story : Story SymbolRendering
story =
  emptyStory { blocks = [], rootId = Nothing }
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          SetRoot
            { id = "group1"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
      myEnvironment
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          AppendChild
            "group1/transform/node"
            { id = "transformChild"
            , symbolRef = BareNode
            }
      }
      myEnvironment

storyInJson : Json.Encode.Value
storyInJson = story |> jsonEncodeStory jsonEncodeSymbolRendering

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
