import "./main.css";
import "./animate.css";
import { Elm } from "./Main.elm";
import { unregister } from "./registerServiceWorker";

Elm.Main.init({
  node: document.getElementById("root"),
  flags: Math.floor(Math.random() * 0x0fffffff)
});

unregister();
