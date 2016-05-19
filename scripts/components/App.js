import React from 'react';
import { Link } from 'react-router';
import _ from 'underscore';

import SimpleSymbolDiagram from './SimpleSymbolDiagram';
import Environment from './Environment';
import Story from './Story';

import {SymbolDiagram} from '../SymbolDiagram';

import ElmDemoGroupInGroup from 'exports?Elm!../DemoGroupInGroup';
import ElmDemoInfinite from 'exports?Elm!../DemoInfinite';
import ElmDemoAutoCatchUp from 'exports?Elm!../DemoAutoCatchUp';
const GroupInGroup = ElmDemoGroupInGroup.DemoGroupInGroup.make(ElmDemoGroupInGroup);
const Infinite = ElmDemoInfinite.DemoInfinite.make(ElmDemoInfinite);
const AutoCatchUp = ElmDemoAutoCatchUp.DemoAutoCatchUp.make(ElmDemoAutoCatchUp);
const demos = [{
  name: 'GroupInGroup',
  data: GroupInGroup,
  description: 'This demo shows the process of building a diagram consisting of a Group contained in a Group. At a few points, we explicitly tell the diagram to "catch up" some of its cloned symbols.'
}, {
  name: 'AutoCatchUp',
  data: AutoCatchUp,
  description: 'This demo shows that explicitly commanding clonings to "catch up" is unnecessary; running a change will automatically ensure that relevant clonings are caught up.'
}, {
  name: 'Infinite',
  data: Infinite,
  description: 'This demo shows how the laziness inherent in cloning symbols allows the construction of recursively-defined infinite diagrams.'
}];
window.demos = demos;

var App = React.createClass({
  render() {
    const {demoName} = this.props.params;

    if (!demoName) {
      return (
        <div style={{paddingTop: 20, paddingLeft: 20}}>
          {this.renderLinks()}
        </div>
      );
    }

    const demo = _.find(demos, {name: demoName});
    const {storyInJson, environmentInJson} = demo.data;

    return (
      <div style={{paddingTop: 20, paddingLeft: 20}}>
        {this.renderLinks()}
        <h1>{demoName} <small>Demo</small></h1>
        {demo.description}
        <h2>Environment</h2>
        <Environment environment={environmentInJson} />
        <h2>Demo Script</h2>
        <Story
          story={storyInJson}
          characterRenderer={(symbolRendering =>
            <SimpleSymbolDiagram
              symbolDiagram={new SymbolDiagram(symbolRendering.blocks, symbolRendering.rootId)}
              environment={environmentInJson} />
            )}
          showStart={true} />
      </div>
    );
  },

  renderLinks() {
    return (
      <div>
        {'| '}{demos.map(({name}) =>
          [<Link to={'/' + name}>{name}</Link>, ' | ']
        )}
      </div>
    );
  },
});

export default App;
