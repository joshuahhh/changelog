/* global c */

import {byType} from './SymbolDiagram';
import {Box, addPseudoQuadraticToObjective} from './Constraints';
import _ from 'underscore';

const defaultOptions = {
  nodeWidth: 60,
  nodeHeight: 30,
  cloningLabelWidth: 150,
  verticalSpacing: 20,
  paddingBetweenClonings: 10,
  cloningLabelExtractor: (cloning) => cloning.localId + '\n' + cloning.symbolId,
};

const textWidth = (text) => {
  const maxChar = _.max(_.pluck(text.split('\n'), 'length'));
  return 10 + maxChar * 4;
};

export class SymbolDiagramLayout {
  constructor(symbolDiagram, options={}) {
    _.extend(this, _.pick(symbolDiagram, 'blocks', 'rootCloningId'));
    this.options = _.defaults(options, defaultOptions);
    this.blocksById = _.indexBy(this.blocks, 'id');
    // this.cloningsByRootId = _.indexBy(_.where(this.blocks, {type: 'cloning'}), 'rootId');

    this.blocks.forEach(byType({
      node: (node) => {
        node.outerBox = new Box(node.id + '-outer');

        node.subtreeLeft = new c.Variable(node.id + '-subtreeLeft');
        node.subtreeRight = new c.Variable(node.id + '-subtreeRight');

        node.deepestRootId = node.id;
      },
      cloning: (cloning) => {
        cloning.outerBox = new Box(cloning.id + '-outer');
        cloning.innerBox = new Box(cloning.id + '-inner');

        var rootChain = cloning;
        while (rootChain.rootId) {
          rootChain = this.blocksById[rootChain.rootId];
        }
        cloning.deepestRootId = rootChain.id;
      }
    }));
  }

  resolve() {
    var solver = new c.SimplexSolver();
    var objectiveExpression = new c.Expression(0);

    const eq = (x, y) => solver.addConstraint(new c.Equation(x, y));
    const ineq = (x, r, y) => solver.addConstraint(new c.Inequality(x, r, y));

    this.blocks.forEach(byType({
      node: (node) => {
        const box = node.outerBox;

        box.constrain(solver);

        eq(box.width, this.options.nodeWidth);
        eq(box.height, this.options.nodeHeight);

        ineq(box.left, c.GEQ, 1);
        ineq(box.top, c.GEQ, 1);

        var lastChild = null;
        node.childIds.forEach((childId) => {
          const child = this.blocksById[childId];
          // const doIt = (child.id == 'Bottom-Group');
          // doIt && console.log('do it!');

          ineq(c.plus(box.bottom, 2 * this.options.verticalSpacing), c.LEQ, child.outerBox.top);
          objectiveExpression = objectiveExpression.plus(c.minus(child.outerBox.top, box.bottom));

          const deepestRoot = this.blocksById[child.deepestRootId];
          // TODO: get rid of this if a node gets an innerBox
          const deepestRootBox = deepestRoot.innerBox || deepestRoot.outerBox;
          objectiveExpression = addPseudoQuadraticToObjective(
            objectiveExpression,
            box.centerX, deepestRootBox.centerX, solver, 600, 50);

          // Climb up the parent's owner hierarchy.
          var ownerChain = this.blocksById[node.ownerId];
          while (ownerChain && child.ownerId !== ownerChain.id) {
            ineq(c.plus(ownerChain.outerBox.bottom, this.options.verticalSpacing * 2), c.LEQ, child.outerBox.top);
            ownerChain = this.blocksById[ownerChain.ownerId];
          }

          if (lastChild) {
            ineq(child.outerBox.left, c.GEQ, c.plus(lastChild.outerBox.right, 10));
          }
          lastChild = child;
        });
      },
      cloning: (cloning) => {
        const {outerBox, innerBox} = cloning;

        outerBox.constrain(solver);
        innerBox.constrain(solver);

        ineq(innerBox.width, c.GEQ, this.options.nodeWidth);
        ineq(innerBox.height, c.GEQ, this.options.nodeHeight);

        objectiveExpression = objectiveExpression.plus(innerBox.width);
        objectiveExpression = objectiveExpression.plus(innerBox.height);

        ineq(outerBox.left, c.GEQ, 1);
        ineq(outerBox.top, c.GEQ, 2);

        eq(innerBox.left, outerBox.left);
        eq(innerBox.top, outerBox.top);
        eq(innerBox.bottom, outerBox.bottom);
        // TODO: hacky text width calculation follows:
        const cloningLabelWidth = textWidth(this.options.cloningLabelExtractor(cloning));
        eq(c.plus(innerBox.right, cloningLabelWidth), outerBox.right);

        const root = this.blocksById[cloning.rootId];
        if (root) {
          eq(root.outerBox.top, innerBox.top);
        }
      }
    }));

    this.blocks.forEach((block) => {
      const ownerCloning = this.blocksById[block.ownerId];
      if (ownerCloning) {
        ineq(block.outerBox.top, c.GEQ, ownerCloning.innerBox.top);
        ineq(block.outerBox.left, c.GEQ, c.plus(ownerCloning.innerBox.left, this.options.paddingBetweenClonings));
        ineq(block.outerBox.right, c.LEQ, c.plus(ownerCloning.innerBox.right, -this.options.paddingBetweenClonings));
        ineq(block.outerBox.bottom, c.LEQ, c.plus(ownerCloning.innerBox.bottom, -this.options.paddingBetweenClonings));
      }
    });

    var objectiveVariable = new c.Variable();
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression));
    window.objectiveVariable = objectiveVariable;
    window.objectiveExpression = objectiveExpression;
    solver.optimize(objectiveVariable);
    solver.resolve();
  }
}
