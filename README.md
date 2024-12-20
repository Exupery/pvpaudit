# PvPAudit
### World of Warcraft PvP addon
PvPAudit helps you find appropriate PvP partners by making it easy to quickly see:

* your history with another player (arena only)
* your history with each comp you've played (arena only)
* your history on each map (arena only)
* the current ratings of another player (arena, RBGs, Solo Shuffle, and BG Blitz)
* the highest ratings of another player (arena and RBGs only)

## Arena History
For any player your current character has played one or more (rated) arena matches with the tooltip (both regular tooltip and the one used by the LFG tool) will display:

* win/loss record with that player
* MMR range of the games played with that player

Your win/loss record with each player, comp, and map can be seen in the history viewer (`/pvpaudit history`).

**Note:** if you leave the arena instance before the end-of-arena scoreboard is shown that match will **not** be included in your match history (i.e. stay until the scoreboard is displayed if you want accurate data).

## Player Audit
Simply target another player and run `/pvpaudit` to see the current rating and experience for each arena bracket and rated battlegrounds. The default command outputs this so it is only visible to you but there are options to output to various chat channels.

Please note Blizzard requires some proximity to collect the necessary data so running `/pvpaudit` on a player a great distance away will result in an **OUT OF RANGE** error, an otherwise invalid target (e.g. a member of the opposing faction) will result in an **UNABLE TO AUDIT** message. The data is cached so if you attempt to audit a player you had previously (successfully) audited but is currently out of range it will display the cached results (as well as the age of the results), cached results are purged after 30 days.

### Output
* Highest rating ever reached for each arena bracket and RBGs.
* Current rating for each arena bracket and RBGs.
* Notable PvP achievements (e.g. Gladiator, Arena Master).

### Caveats
* The exact highest rating can only be obtained for arenas, for RBGs the highest achievement earned is used.
* Blizzard's in-game API currently doesn't support retrieving a player's historical high for either Solo Shuffle or BG Blitz.
* WoW's compare achievements functionality (used for determining what achievements the target has earned) returns achievements a player has earned on any character on that account by default, not just that specific character (players can toggle this in Interface => Display). As a result a character's highest rating may be lower than what would seem required for an achievement.
* WoW's API for getting arena info often has a short (about a second) delay, this is only slightly noticeable when auditing a single target but more pronounced if doing a group audit on a large raid

## Player Audit Commands
* `/pvpaudit` - audit the current target
* `/pvpaudit i` or `/pvpaudit instance` - audit the current target and output to /instance
* `/pvpaudit p` or `/pvpaudit party` - audit the current target and output to /party
* `/pvpaudit r` or `/pvpaudit raid` - audit the current target and output to /raid
* `/pvpaudit o` or `/pvpaudit officer` - audit the current target and output to /officer
## Arena History Commands
* `/pvpaudit h` or `/pvpaudit history` - open the arena partner/comps/maps history viewer
* `/pvpaudit clear players` - removes all players from arena history
* `/pvpaudit clear comps` - removes all team compositions from arena history
* `/pvpaudit clear maps` - removes all maps from arena history
* `/pvpaudit clear all` - removes ALL data from arena history
## General Commands
* `/pvpaudit config` - open the configuration panel
* `/pvpaudit ?` or `/pvpaudit help` - print the command list

To audit **all** current group members for a specific bracket append the bracket after any of the above audit commands. Arena brackets can be provided by either single (e.g. `3`) or three character identifiers (e.g. `3v3`)
Examples: `/pvpaudit 3v3`, `/pvpaudit i 2`, `/pvpaudit raid rbg`

Commands can be ran with `/pa` instead of `/pvpaudit` - unless another addon is in use that registers `/pa` (in which case the longer option should be used). Additionally, auditing the current target can be keybound via the WoW keybinding interface (Key Bindings => Addons => PvPAudit).

