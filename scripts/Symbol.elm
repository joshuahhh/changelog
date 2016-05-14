module Symbol ( SymbolId, NodeId, SymbolRef(..), Cloning, Change(..), myEnvironment, CompoundSymbol ) where

import Array exposing ( Array )
import Dict exposing ( Dict )

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
