// import {Box, addAbsoluteValueToObjective} from './Constraints';
import {Box, NumericSolver, sq, pos} from './ConstraintsN';

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
    var solver = new NumericSolver();

    this.boxes.forEach((box) => {
      box.variables.forEach((variable) => solver.addVariable(variable));

      solver.addConstraintFunction(box.getConstraintFunction());
      solver.addConstraintFunction(() => (
        sq(box.width.value - 100) +
        sq(box.height.value - 50) +
        pos(box.left.value - 10) +
        pos(box.top.value - 10)))

      if (box.parentBox) {
        // Vertical constraint
        solver.addConstraintFunction(() => sq(box.top.value - (box.parentBox.bottom.value + 30)))
        // Horizontal objective
        // solver.addObjectiveFunction(() => sq(box.centerX.value - box.parentBox.centerX.value))
      }
    });

    this.boxesByLevel.forEach((boxesInLevel) => {
      var lastBox = null;
      boxesInLevel.forEach((box) => {
        if (lastBox) {
          solver.addConstraintFunction(() => pos(box.left.value - (lastBox.right.value + 100)));
        }
        lastBox = box;
      });
    });

    solver.resolve();
  }
}
