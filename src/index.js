import { Elm } from "./Main.elm";
import { unregister } from "./registerServiceWorker";

import "./styles/app.scss";

Elm.Main.init({
  node: document.getElementById("root"),
  flags: Math.floor(Math.random() * 0x0fffffff)
});

unregister();
