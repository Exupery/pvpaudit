# PvPAudit
### World of Warcraft PvP addon
PvPAudit helps you find appropriate PvP partners by making it easy to quickly see:
* your history with another player (arena only)
* the PvP experience and current ratings of another player (arena and RBGs)

## Partner History
For any player your current character has played one or more (rated) arena matches with the tooltip (both regular tooltip and the one used by the LFG tool) will display:
* win/loss record with that player
* MMR range of the games played with that player

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
* WoW's compare achievements functionality (used for determining what achievements the target has earned) returns achievements a player has earned on any character on that account by default, not just that specific character (players can toggle this in Interface => Display). As a result a character's highest rating may be lower than what would seem required for an achievement.
* WoW's API for getting arena info often has a short (about a second) delay, this is only slightly noticeable when auditing a single target but more pronounced if doing a group audit on a large raid

## Commands
* `/pvpaudit` - audit the current target
* `/pvpaudit i` or `/pvpaudit instance` - audit the current target and output to /instance
* `/pvpaudit p` or `/pvpaudit party` - audit the current target and output to /party
* `/pvpaudit r` or `/pvpaudit raid` - audit the current target and output to /raid
* `/pvpaudit ?` or `/pvpaudit help` - print the command list

To audit **all** current group members for a specific bracket append the bracket after any of the above audit commands. Arena brackets can be provided by either single (e.g. `3`) or three character identifiers (e.g. `3v3`)
Examples: `/pvpaudit 3v3`, `/pvpaudit i 2`, `/pvpaudit raid rbg`

Commands can be ran with `/pa` instead of `/pvpaudit` - unless another addon is in use that registers `/pa` (in which case the longer option should be used). Additionally, auditing the current target can be keybound via the WoW keybinding interface (Key Bindings => Addons => PvPAudit).

## TODOS
* add option to hide history from tooltips
* for past arena partners allow including a note for display in tooltip along with history
* implement a GUI showing win/loss percentage by a) partner b) comp c) enemy comp d) map