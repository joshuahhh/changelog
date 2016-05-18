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
    // const symbolDiagram = group.clone('Top-Group').appendChild('Top-Group/group/node', group.clone('Bottom-Group'));
    const {storyInJson, environmentInJson} = DemoGroupInGroup;
    // const symbolDiagrams = symbolRenderingsInJson.map((symbolDiagramJson) =>
    //   new SymbolDiagram(symbolDiagramJson.blocks, symbolDiagramJson.rootId));

    return (
      <div style={{paddingTop: 20}}>
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
