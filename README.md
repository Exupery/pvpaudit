# PvPAudit
### World of Warcraft PvP addon
PvPAudit makes it easy to quickly gauge the PvP experience of another player. Simply target another player and run `/pvpaudit` to see the current rating and experience for each arena bracket and rated battlegrounds. The default command outputs this so it is only visible to you but there are options to output to various chat channels.

Please note Blizzard requires some proximity to collect the necessary data so running `/pvpaudit` on a player a great distance away will result in an **OUT OF RANGE** error, an otherwise invalid target (e.g. a member of the opossing faction) will result in an **UNABLE TO AUDIT** message.

## Output
* Highest rating ever reached for each arena bracket and RBGs.
* Current rating for each arena bracket and RBGs.
* Notable PvP achievements (e.g. Gladiator, Arena Master).

## Caveats
* The exact highest rating can only be obtained for arenas, for RBGs the highest achievement earned is used.
* WoW's compare achievements functionality (used for determining what achievements the target has earned) returns achievements a player has earned on any character on that account by default, not just that specific character (players can toggle this in Interface => Display). As a result a character's highest rating may be lower than what would seem required for an achievement.

## Commands
* `/pvpaudit` - audit the current target
* `/pvpaudit i` or `/pvpaudit instance` - audit the current target and output to /instance
* `/pvpaudit p` or `/pvpaudit party` - audit the current target and output to /party
* `/pvpaudit r` or `/pvpaudit raid` - audit the current target and output to /raid
* `/pvpaudit ?` or `/pvpaudit help` - print the command list

Commands can be ran with `/pa` instead of `/pvpaudit` - unless another addon is in use that registers `/pa` (in which case the longer option should be used). Additionally, auditing the current target can be keybound via the WoW keybinding interface (Key Bindings => Addons => PvPAudit).

## TODOs
* add option to output all members of party/raid for a given bracket
* add option to include number of honorable kills
