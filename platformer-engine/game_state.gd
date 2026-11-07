extends Node
## Autoload (name it GameState). Remembers progress between scenes.

var solved := {}   # e.g. {"guardian_1": true}
var insight := 1   # RPG stat: number of hints per duel
