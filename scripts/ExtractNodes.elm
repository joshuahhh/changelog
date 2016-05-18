module ExtractNodes where

import Util exposing ( idIs, find, unwrapOrCrash )
import Block exposing ( Block, BlockId, BlockBody(..) )
import SymbolRendering exposing ( SymbolRendering )

type ExtractedNode =
  ExtractedNode { id : BlockId, children : List ExtractedNode }

extractNodes : SymbolRendering -> Maybe ExtractedNode
extractNodes { blocks, rootId } =
  case rootId of
    Just rootId -> extractNodesFromRoot blocks rootId
    Nothing -> Nothing

extractNodesFromRoot : List Block -> BlockId -> Maybe ExtractedNode
extractNodesFromRoot blocks rootId =
  let
    rootBlock = find (idIs rootId) blocks |> unwrapOrCrash "Could not find root block"
  in
    case rootBlock.body of
      CloningBlockBody cloningBody ->
        case cloningBody.rootId of
          Just rootId -> extractNodesFromRoot blocks rootId
          Nothing -> Nothing
      NodeBlockBody blockBody ->
        Just (ExtractedNode
          { id = rootBlock.id
          , children = List.filterMap (extractNodesFromRoot blocks) blockBody.childIds })
