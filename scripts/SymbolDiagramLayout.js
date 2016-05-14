/* global c */

import {byType} from './SymbolDiagram';
import {Box, addPseudoQuadraticToObjective, addAbsoluteValueToObjective} from './Constraints';
import _ from 'underscore';

const options = {
  nodeWidth: 60,
  nodeHeight: 30,
  cloningLabelWidth: 150,
  verticalSpacing: 10,
  paddingBetweenClonings: 10,
};

export class SymbolDiagramLayout {
  constructor(symbolDiagram) {
    _.extend(this, _.pick(symbolDiagram, 'blocks', 'rootCloningId'));
    this.blocksById = _.indexBy(this.blocks, 'id');
    // this.cloningsByRootId = _.indexBy(_.where(this.blocks, {type: 'cloning'}), 'rootId');

    this.blocks.forEach(byType({
      node: (node) => {
        node.outerBox = new Box(node.id + '-outer');

        node.subtreeLeft = new c.Variable(node.id + '-subtreeLeft');
        node.subtreeRight = new c.Variable(node.id + '-subtreeRight');
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

        eq(box.width, options.nodeWidth);
        eq(box.height, options.nodeHeight);

        ineq(box.left, c.GEQ, 20);
        ineq(box.top, c.GEQ, 20);

        var lastChild = null;
        node.childIds.forEach((childId) => {
          const child = this.blocksById[childId];
          // const doIt = (child.id == 'Bottom-Group');
          // doIt && console.log('do it!');

          ineq(c.plus(box.bottom, 2 * options.verticalSpacing), c.LEQ, child.outerBox.top);
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
            ineq(c.plus(ownerChain.outerBox.bottom, options.verticalSpacing * 2), c.LEQ, child.outerBox.top);
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

        ineq(innerBox.width, c.GEQ, options.nodeWidth);
        ineq(innerBox.height, c.GEQ, options.nodeHeight);

        objectiveExpression = objectiveExpression.plus(innerBox.width);
        objectiveExpression = objectiveExpression.plus(innerBox.height);

        ineq(outerBox.left, c.GEQ, 20);
        ineq(outerBox.top, c.GEQ, 20);

        eq(innerBox.left, outerBox.left);
        eq(innerBox.top, outerBox.top);
        eq(innerBox.bottom, outerBox.bottom);
        const cloningLabelWidth = 10 + cloning.id.length * 4;
        eq(c.plus(innerBox.right, cloningLabelWidth), outerBox.right);

        const root = this.blocksById[cloning.rootId];
        if (root) {
          eq(root.outerBox.top, innerBox.top);
          ineq(root.outerBox.left, c.GEQ, c.plus(innerBox.left, options.paddingBetweenClonings));
          ineq(root.outerBox.right, c.LEQ, c.plus(innerBox.right, -options.paddingBetweenClonings));
          ineq(root.outerBox.bottom, c.LEQ, c.plus(innerBox.bottom, -options.paddingBetweenClonings));
        }

        const ownerCloning = this.blocksById[cloning.ownerId];
        if (ownerCloning) {
          ineq(cloning.outerBox.top, c.GEQ, ownerCloning.innerBox.top);
          ineq(cloning.outerBox.left, c.GEQ, c.plus(ownerCloning.innerBox.left, options.paddingBetweenClonings));
          ineq(cloning.outerBox.right, c.LEQ, c.plus(ownerCloning.innerBox.right, -options.paddingBetweenClonings));
          ineq(cloning.outerBox.bottom, c.LEQ, c.plus(ownerCloning.innerBox.bottom, -options.paddingBetweenClonings));
        }
      }
    }));

    var objectiveVariable = new c.Variable();
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression));
    window.objectiveVariable = objectiveVariable;
    window.objectiveExpression = objectiveExpression;
    solver.optimize(objectiveVariable);
    solver.resolve();
  }
}
