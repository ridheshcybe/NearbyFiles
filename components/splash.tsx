import React from "react";
// Note: This is illustrative; there is no official expo-bluetooth in managed workflow currently
import Welcome from "./splash/welcome";
import Checks from "./splash/checks";


export default function Splash({ done }: { done: () => void }) {
  /*
0- WELCOME
1-SETUP
  */
  const [state, changeState] = React.useState(0)

  let changeit = (index: number) => {
    return () => {
      const nextState = index + 1;
      if (nextState > 0) { // There is only one screen which is the welcome screen
        changeState(nextState);
      }
    };
  };
  let back = (index: number) => {
    return () => {
      if (index - 1 < 0) return;
      changeState(index - 1)
    }
  }
  return (
    <>
      {state == 0 && <Welcome done={changeit(0)} />}
      {state == 1 && <Checks done={changeit(1)} back={back(1)}/>}
    </>
  );
}