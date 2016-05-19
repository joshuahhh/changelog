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
            { id = "transformNode"
            , symbolRef = BareNode
            }
          )
        ]
      }
    ),
    ( "Group",
      { changes = Array.fromList
        [ SetRoot (
            { id = "groupNode"
            , symbolRef = BareNode
            }
          ),
          AppendChild "groupNode" (
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
            "group1/groupNode"
            { id = "group2"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
      myEnvironment
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          AppendChild
            "group2/transform/transformNode"
            { id = "transformChild"
            , symbolRef = BareNode
            }
      }
      myEnvironment

storyInJson : Json.Encode.Value
storyInJson = story |> jsonEncodeStory jsonEncodeSymbolRendering

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
