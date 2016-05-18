import React from 'react';
// import _ from 'underscore';

import SimpleSymbolDiagram from './SimpleSymbolDiagram';
import Story from './Story';

import {SymbolDiagram} from '../SymbolDiagram';

import ElmDemoGroupInGroup from 'exports?Elm!../DemoGroupInGroup';
import ElmDemoInfinite from 'exports?Elm!../DemoInfinite';
const DemoGroupInGroup = ElmDemoGroupInGroup.DemoGroupInGroup.make(ElmDemoGroupInGroup);
const DemoInfinite = ElmDemoInfinite.DemoInfinite.make(ElmDemoInfinite);
window.DemoGroupInGroup = DemoGroupInGroup;
window.DemoInfinite = DemoInfinite;


var App = React.createClass({
  render() {
    // const {storyInJson, environmentInJson} = DemoGroupInGroup;
    const {storyInJson, environmentInJson} = DemoInfinite;

    return (
      <div style={{paddingTop: 20, paddingLeft: 20}}>
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
});

export default App;
