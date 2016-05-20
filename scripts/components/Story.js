import React from 'react';
// import _ from 'underscore';

const nl2br = (text) => text.split('\n').map((line) =>
  <span>
    {line}
    <br/>
  </span>
);

// const storyIsNotEmpty = (story) =>
//   _.any(story.steps.map((step) => step.narration));


const Story = ({story, characterRenderer, showStart}) =>
  <table>
    <tbody>
      {showStart &&
        <tr>
          <td style={{textAlign: 'right', verticalAlign: 'top', paddingRight: 30}}>
            start
          </td>
          <td style={{textAlign: 'left', verticalAlign: 'top', paddingRight: 30, paddingBottom: 35}}>
            {characterRenderer(story.before)}
          </td>
        </tr>
      }
      {story.steps.map((step, i) =>
        step.narration &&
          <tr key={i}>
            <td style={{textAlign: 'right', verticalAlign: 'top', paddingRight: 30}}>
              {nl2br(step.narration)}
            </td>
            <td style={{textAlign: 'left', verticalAlign: 'top', paddingRight: 30, paddingBottom: 35}}>
              { step.subStory.steps.length > 0
              ? <div style={{border: '1px solid gray', padding: 10, boxShadow: '0px 0px 10px lightgray'}}>
                  <Story story={step.subStory} characterRenderer={characterRenderer} />
                </div>
              : characterRenderer(step.subStory.after)
              }
            </td>
          </tr>
      )}
    </tbody>
  </table>;

export default Story;
