module SymbolRendering where

import Json.Encode

import Util exposing ( mapWhen, idIs, find )
import Symbol exposing ( SymbolId, NodeId, SymbolRef(..), Cloning, Change(..) )

-- And here's the dynamic world of (partially) rendered logs

type alias SymbolRendering =
  { blocks : List Block
  , rootId : Maybe BlockId
  }

type alias BlockId = String

type alias Block =
  { id : BlockId
  , ownerId : Maybe BlockId
  , body : BlockBody
  }

type BlockBody = NodeBodyAsBlockBody NodeBody | CloningBodyAsBlockBody CloningBody

type alias NodeBody =
  { childIds: List BlockId }

type alias CloningBody =
  { rootId: Maybe BlockId, symbolId: SymbolId, nextChange: Int }

constructBlockId : Maybe BlockId -> NodeId -> BlockId
constructBlockId maybeBlockId nodeId =
  case maybeBlockId of
    Just blockId -> blockId ++ "/" ++ nodeId
    Nothing -> nodeId

cloningToBlock : Cloning -> Maybe BlockId -> Block
cloningToBlock cloning maybeOwnerId =
  let
    newId = constructBlockId maybeOwnerId cloning.id
    newBody = case cloning.symbolRef of
      BareNode ->
        NodeBodyAsBlockBody { childIds = [] }
      SymbolIdAsRef symbolId ->
        CloningBodyAsBlockBody { rootId = Nothing, symbolId = symbolId, nextChange = 0 }
  in
    Block newId maybeOwnerId newBody

appendChildToBlockWhichMustBeNode : BlockId -> Block -> Block
appendChildToBlockWhichMustBeNode childId block =
  let
    oldNodeBody = case block.body of
      NodeBodyAsBlockBody oldNodeBody -> oldNodeBody
      _ -> Debug.crash "you can only add a child to a node!"
    newBody = NodeBodyAsBlockBody { oldNodeBody | childIds = List.append oldNodeBody.childIds [childId] }
  in
    { block | body = newBody }

setRootOfBlockWhichMustBeCloning : BlockId -> Block -> Block
setRootOfBlockWhichMustBeCloning rootId block =
  let
    oldCloningBody = case block.body of
      CloningBodyAsBlockBody oldCloningBody -> oldCloningBody
      _ -> Debug.crash "you can only set the root of a cloning!"
    newBody = CloningBodyAsBlockBody { oldCloningBody | rootId = Just rootId }
  in
    { block | body = newBody }

type alias ChangeInContext =
  { change : Change
  , contextId : Maybe BlockId
  }

runChangeInContext : ChangeInContext -> SymbolRendering -> SymbolRendering
runChangeInContext {change, contextId} symbolRendering =
  case change of
    SetRoot cloning ->
      let
        newBlock = cloningToBlock cloning contextId
        newBlocks = newBlock ::
          case contextId of
            Just blockId ->
              mapWhen
                (idIs blockId)
                (setRootOfBlockWhichMustBeCloning newBlock.id)
                symbolRendering.blocks
            Nothing ->
              symbolRendering.blocks
        newRootId =
          case contextId of
            Just blockId -> symbolRendering.rootId
            Nothing -> Just cloning.id
      in
        { symbolRendering | blocks = newBlocks, rootId = newRootId }
    AppendChild nodeId cloning ->
      let
        newBlock = cloningToBlock cloning contextId
        blockIdOfParent = constructBlockId contextId nodeId
        newBlocks = newBlock ::
          mapWhen
            (idIs blockIdOfParent)
            (appendChildToBlockWhichMustBeNode (constructBlockId contextId cloning.id))
            symbolRendering.blocks
        newRootId = Just cloning.id
      in
        { symbolRendering | blocks = newBlocks }

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
    rootBlock = find (idIs rootId) blocks
  in
    case rootBlock.body of
      CloningBodyAsBlockBody cloningBody ->
        case cloningBody.rootId of
          Just rootId -> extractNodesFromRoot blocks rootId
          Nothing -> Nothing
      NodeBodyAsBlockBody blockBody ->
        Just (ExtractedNode
          { id = rootBlock.id
          , children = List.filterMap (extractNodesFromRoot blocks) blockBody.childIds })

jsonEncodeMaybeString : Maybe String -> Json.Encode.Value
jsonEncodeMaybeString maybeString =
  Maybe.map Json.Encode.string maybeString |> Maybe.withDefault Json.Encode.null


blockToThatJsonFormatIUse : Block -> Json.Encode.Value
blockToThatJsonFormatIUse {id, ownerId, body} =
  Json.Encode.object (
    case body of
      NodeBodyAsBlockBody {childIds} ->
        [ ( "type", Json.Encode.string "node" )
        , ( "id", Json.Encode.string id )
        , ( "ownerId", jsonEncodeMaybeString ownerId )
        , ( "childIds", Json.Encode.list (List.map Json.Encode.string childIds) )
        ]
      CloningBodyAsBlockBody {rootId} ->
        [ ( "type", Json.Encode.string "cloning" )
        , ( "id", Json.Encode.string id )
        , ( "ownerId", jsonEncodeMaybeString ownerId )
        , ( "rootId", jsonEncodeMaybeString rootId )
        ])


symbolRenderingToThatJsonFormatIUse : SymbolRendering -> Json.Encode.Value
symbolRenderingToThatJsonFormatIUse symbolRendering =
  let
    blockValues = List.map blockToThatJsonFormatIUse symbolRendering.blocks
  in
    Json.Encode.object
    [ ( "blocks", Json.Encode.list blockValues )
    , ( "rootId", jsonEncodeMaybeString symbolRendering.rootId)
    ]
