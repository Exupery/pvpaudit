# PvPAudit
### World of Warcraft PvP addon
PvPAudit makes it easy to quickly gauge the PvP experience of another player. Simply target another player and run `/pvpaudit` to see the current rating and experience for each arena bracket and rated battlegrounds.

Please note Blizzard requires some proximity to collect the necessary data so running `/pvpaudit` on a player a great distance away will result in an **UNABLE TO AUDIT** message.

## Output
* Current rating for each arena bracket and RBGs
* Highest rating ever reached for each arena bracket and RBGs
* Notable PvP achievements (e.g. Gladiator, Arena Master)

## Commands
* /pvpaudit - audit the current target
* /pvpaudit ? or /pvpaudit help - Print the command list

Commands can be ran with `/pa` instead of `/pvpaudit` - unless another addon is in use that registers `/pa` (in which case the longer option should be used).

## TODOs
* add option to output to /instance
* include number of honorable kills
