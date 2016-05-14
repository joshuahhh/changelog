// import _ from 'underscore';
import update from 'react-addons-update';

export const byType = (funcForEachType) => (obj) => funcForEachType[obj.type](obj);

export class SymbolDiagram {
  constructor(blocks, rootId) {
    this.blocks = blocks;
    this.rootId = rootId;
  }

  clone(cloningId) {
    const idFunc = (id) => id ? cloningId + '/' + id : null;
    const idFuncWithDefault = (id) => id ? cloningId + '/' + id : cloningId;

    const newRootCloning = {
      type: 'cloning',
      id: cloningId,
      rootId: idFunc(this.rootId),
      ownerId: null
    };

    const newBlocks = this.blocks.map(byType({
      node: (node) =>
        update(node, {
          id: {$apply: idFunc},
          ownerId: {$apply: idFuncWithDefault},
          childIds: {$apply: (l) => l.map(idFunc)}}),
      cloning: (cloning) =>
        update(cloning, {
          id: {$apply: idFunc},
          ownerId: {$apply: idFuncWithDefault},
          rootId: {$apply: idFunc}})
    })).concat([newRootCloning]);

    return new SymbolDiagram(newBlocks, newRootCloning.id);
  }

  appendChild(parentId, child) {
    const newBlocks = this.blocks.map(byType({
      node: (node) => {
        if (node.id == parentId) {
          return update(node, {childIds: {$push: [child.rootId]}});
        } else {
          return node;
        }
      },
      cloning: (cloning) => cloning
    })).concat(child.blocks);

    return new SymbolDiagram(newBlocks, this.rootId);
  }
}

export const node =
  new SymbolDiagram([{type: 'node', id: 'node', childIds: []}], 'node');

export const attribute =
  node.clone('attribute');

export const transform =
  node.clone('transform')
  .appendChild('transform/node', attribute.clone('transform-attribute'));

export const group =
  node.clone('group')
  .appendChild('group/node', transform.clone('group-transform'));
