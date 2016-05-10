import {Box, addAbsoluteValueToObjective, addPseudoQuadraticToObjective} from './Constraints';
import _ from 'underscore';

// Constraints:
// * Each box has a fixed size
// * Each box is a certain distance below its parent
// * Each box is a certain distance away from its neighbors in its row
// * Each box is in the field
// Objectives:
// * Each box is horizontally as close as possible to its parent

export class TreeLayout {
  constructor(tree) {
    this.tree = tree;
    this.boxes = [];
    this.boxesByLevel = [];

    this.addSubtree(tree, 0, null);
  }

  addSubtree(subtree, level, parentBox) {
    if (!this.boxesByLevel[level]) {
      this.boxesByLevel[level] = [];
    }

    var rootBox = new Box(subtree.name, {width: 200, height: 100});
    rootBox.parentBox = parentBox;

    this.boxes.push(rootBox);
    this.boxesByLevel[level].push(rootBox);

    (subtree.children || []).forEach((child) =>
      this.addSubtree(child, level + 1, rootBox)
    );
  }

  resolve() {
    var solver = new c.SimplexSolver();
    window.solver = solver;

    var objectiveExpression = new c.Expression(0);

    this.boxes.forEach((box) => {
      box.getConstraints().forEach((constraint) => solver.addConstraint(constraint));
      solver.addConstraint(new c.Equation(box.width, 100));
      solver.addConstraint(new c.Equation(box.height, 50));
      solver.addConstraint(new c.Inequality(box.left, c.GEQ, 10));
      solver.addConstraint(new c.Inequality(box.top, c.GEQ, 10));

      if (box.parentBox) {
        // Vertical constraint
        solver.addConstraint(new c.Equation(box.top, c.plus(box.parentBox.bottom, 30)));
        // Horizontal objective
        // objectiveExpression = addAbsoluteValueToObjective(objectiveExpression, box.centerX, box.parentBox.centerX, solver);
        objectiveExpression = addPseudoQuadraticToObjective(objectiveExpression, box.centerX, box.parentBox.centerX, solver, 600, 200);
      }
    });

    this.boxesByLevel.forEach((boxesInLevel) => {
      var lastBox = null;
      boxesInLevel.forEach((box) => {
        if (lastBox) {
          solver.addConstraint(new c.Inequality(box.left, c.GEQ, c.plus(lastBox.right, 10)));
        }
        lastBox = box;
      });
    });

    var objectiveVariable = new c.Variable();
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression));
    window.objectiveVariable = objectiveVariable;
    window.objectiveExpression = objectiveExpression;
    solver.optimize(objectiveVariable);
    solver.resolve();

  }
}
