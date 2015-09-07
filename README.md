# PvPAudit
### World of Warcraft PvP addon
PvPAudit makes it easy to quickly gauge the PvP experience of another player. Simply target another player and run `/pvpaudit` to see the current rating and experience for each arena bracket and rated battlegrounds.

Please note Blizzard requires some proximity to collect the necessary data so running `/pvpaudit` on a player a great distance away will result in an **OUT OF RANGE** error, an otherwise invalid target (e.g. a member of the opossing faction) will result in an **UNABLE TO AUDIT** message.

## Output
* Highest rating ever reached for each arena bracket and RBGs (the exact highest rating can only be obtained for arenas, for RBGs the highest achievement earned is used)
* Current rating for each arena bracket and RBGs (this will occasionally show zero even when the player has non-zero CR when ran inside an arena, see **TODOs**)
* Notable PvP achievements (e.g. Gladiator, Arena Master)

## Commands
* `/pvpaudit` - audit the current target
* `/pvpaudit ?` or `/pvpaudit help` - print the command list

Commands can be ran with `/pa` instead of `/pvpaudit` - unless another addon is in use that registers `/pa` (in which case the longer option should be used). Additionally, auditing the current target can be keybound via the WoW keybinding interface (Key Bindings => Addons => PvPAudit).

## TODOs
* investigate/fix erroneous zero CRs in arenas
* add option to output to /instance
* include number of honorable kills
