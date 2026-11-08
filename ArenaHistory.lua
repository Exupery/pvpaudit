local PURPLE_TEAM = 0
local GOLD_TEAM = 1
local SPEC_ID_MAP = {}

local NOTES = "notes"
local SHUFFLE = "Shuffle"
local ARENA_BRACKETS = { "2v2", "3v3" }

-- The sub-tables each top level `arenaDb` table is split into
local DB_SUBTABLES = {
  players = ARENA_BRACKETS,
  comps = ARENA_BRACKETS,
  opposingComps = ARENA_BRACKETS,
  maps = { "2v2", "3v3", SHUFFLE },
  shuffleSpecs = { "with", "against" },
}

local eventFrame = nil
local arenaDb = nil
local notesDb = nil
local currentMatch = {}

local playerName = GetUnitName("player", false)

function PvPAuditGetPlayerAndRealm()
  return playerName .. "-" .. (GetRealmName():gsub("%s+", ""))
end

-- The current arena season as numbered internally (i.e. not e.g. "Midnight Season 1"), nil if
-- it's unknown (not loaded yet or between seasons)
local function currentSeason()
  local season = GetCurrentArenaSeason()
  if type(season) ~= "number" or season <= 0 then return nil end
  return season
end

-- Alongside its all-time W/L every record (map, comp, spec or player) keeps a `season` table with
-- its W/L for the season it was last updated in, so data from previous seasons can be purged while
-- keeping the current season's. Returns that table (reset if it's for an older season) or nil if
-- the current season is unknown (or somehow older than the season the record was last updated in)
local function seasonRecord(wlTable)
  local season = currentSeason()
  if season == nil then return nil end
  if wlTable.season == nil or wlTable.season.id < season then
    wlTable.season = { id = season, w = 0, l = 0 }
  elseif wlTable.season.id > season then
    return nil
  end
  return wlTable.season
end

local function updateWinLossCount(isWin, wlTable)
  if wlTable.w == nil then wlTable.w = 0 end
  if wlTable.l == nil then wlTable.l = 0 end
  local seasonWL = seasonRecord(wlTable)
  if isWin then
    wlTable.w = wlTable.w + 1
    if seasonWL then seasonWL.w = seasonWL.w + 1 end
  else
    wlTable.l = wlTable.l + 1
    if seasonWL then seasonWL.l = seasonWL.l + 1 end
  end
end

local function updateWL(isWin, arenaDbKey, currentMatchKey)
  local currentBracket = arenaDb[arenaDbKey][currentMatch.bracket]
  local bracketKey = currentMatch[currentMatchKey]
  if currentBracket[bracketKey] == nil then
    currentBracket[bracketKey] = { w=0, l=0 }
  end

  updateWinLossCount(isWin, currentBracket[bracketKey])
end

local function updateMapWL(isWin)
  updateWL(isWin, "maps", "mapName")
end

local function updateCompWL(isWin)
  updateWL(isWin, "comps", "comp")
end

local function updateOpposingCompWL(isWin)
  updateWL(isWin, "opposingComps", "opposingComp")
end

local function updatePlayers(isWin)
  local currentBracket = arenaDb["players"][currentMatch.bracket]
  for name, player in pairs(currentMatch.players) do
    if name ~= playerName and currentMatch.playerTeam == player.team then
      if currentBracket[name] == nil then
        currentBracket[name] = { w=0, l=0, lowMmr=9999, hiMmr=0 }
      end

      local pTable = currentBracket[name]
      local mmr = currentMatch.mmr
      if mmr < pTable.lowMmr then pTable.lowMmr = mmr end
      if mmr > pTable.hiMmr then pTable.hiMmr = mmr end
      updateWinLossCount(isWin, pTable)

      local seasonTable = seasonRecord(pTable)
      if seasonTable then
        if seasonTable.lowMmr == nil or mmr < seasonTable.lowMmr then seasonTable.lowMmr = mmr end
        if seasonTable.hiMmr == nil or mmr > seasonTable.hiMmr then seasonTable.hiMmr = mmr end
      end
    end
  end
end

local function addCurrentMatchToDb()
  local isWin = currentMatch.playerTeam == currentMatch.winner
  updateMapWL(isWin)
  updateCompWL(isWin)
  updateOpposingCompWL(isWin)
  updatePlayers(isWin)
end

local function storeTempMetadata()
  for b = 1, GetMaxBattlefieldID() do
    local status, mapName, _, _, _, queueType = GetBattlefieldStatus(b)
    if status == "active" then
      currentMatch.mapName = mapName
      currentMatch.ranked = queueType == "ARENA"
      currentMatch.season = GetCurrentArenaSeason()
      currentMatch.playerTeam = GetBattlefieldArenaFaction()
      return
    end
  end
end

local function getComp(specTable)
  local comp = ""
  table.sort(specTable)
  for _, specId in ipairs(specTable) do
    comp = comp .. specId .. "_"
  end
  return string.sub(comp, 1, -2)
end

local function matchFinished()
  if currentMatch.players ~= nil then return end
  local teamSpecs = {}
  local enemySpecs = {}
  currentMatch.players = {}
  for p = 1, GetNumBattlefieldScores() do
    local name, _, _, _, _, team, _, _, classToken, damageDone, healingDone, _, _, _, _, specName = GetBattlefieldScore(p)
    local specId = SPEC_ID_MAP[specName .. classToken]
    currentMatch.players[name] = {}
    currentMatch.players[name].class = classToken
    currentMatch.players[name].specId = specId
    currentMatch.players[name].damage = damageDone
    currentMatch.players[name].healing = healingDone
    currentMatch.players[name].team = team

    if team == currentMatch.playerTeam then
      table.insert(teamSpecs, specId)
    else
      table.insert(enemySpecs, specId)
    end
  end

  local _, _, _, teamMmr = GetBattlefieldTeamInfo(currentMatch.playerTeam)
  currentMatch.mmr = teamMmr
  local opposingTeam = (currentMatch.playerTeam == PURPLE_TEAM) and GOLD_TEAM or PURPLE_TEAM
  local _, _, _, opposingMmr = GetBattlefieldTeamInfo(opposingTeam)
  currentMatch.opposingMmr = opposingMmr

  local totalPlayers = GetNumBattlefieldScores()
  local teamSize = (totalPlayers > 4) and 3 or 2
  currentMatch.bracket = teamSize .. "v" .. teamSize

  currentMatch.winner = GetBattlefieldWinner()
  currentMatch.comp = getComp(teamSpecs)
  currentMatch.opposingComp = getComp(enemySpecs)

  local evenMatch = totalPlayers == 6 or totalPlayers == 4
  if currentMatch.ranked and evenMatch then
    addCurrentMatchToDb()
  end
end

-- Solo Shuffle is tracked per round rather than per match. Since Midnight, specs (and the
-- scoreboard) are secret to addons until the match is complete so each round only records
-- the player's teammates and the outcome, specs are resolved from the final scoreboard.

local function isSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- Strips the realm (if any) from a "Name-Realm" string
local function baseName(name)
  return string.match(name, "^[^-]+")
end

local function anyDead(units)
  for _, unit in ipairs(units) do
    if UnitIsDeadOrGhost(unit) then return true end
  end
  return false
end

-- Returns whether anyone on the player's team is dead and whether anyone on the enemy team is dead
local function shuffleDeaths()
  local ok, teamDead, enemyDead = pcall(function()
    return anyDead({ "player", "party1", "party2" }), anyDead({ "arena1", "arena2", "arena3" })
  end)
  if not ok then return false, false end
  return teamDead, enemyDead
end

-- How long (in seconds) after a round ends to keep watching for deaths. A player dying on each
-- team within about a second of each other makes the round a tie and the second death can reach
-- the client after the round has already ended
local SHUFFLE_TIE_WINDOW = 1

local function startShuffleRound()
  local teammates = {}
  for i = 1, 2 do
    local name = UnitName("party" .. i)
    if name and not isSecret(name) then table.insert(teammates, name) end
  end

  if currentMatch.rounds == nil then currentMatch.rounds = {} end
  currentMatch.roundId = (currentMatch.roundId or 0) + 1
  currentMatch.roundTeammates = teammates
  currentMatch.roundOpen = true
  currentMatch.roundResolving = false
end

-- Maps the (realm-less) name of every other player in the lobby to their spec ID (false if
-- unknown), returns nil if the scoreboard isn't available yet
local function shuffleLobbySpecs()
  local numScores = GetNumBattlefieldScores()
  if numScores == 0 then return nil end

  local lobby = {}
  for i = 1, numScores do
    local info = C_PvP.GetScoreInfo(i)
    if info == nil or isSecret(info.talentSpec) then return nil end
    local name = baseName(info.name)
    if name ~= playerName then
      local specId = SPEC_ID_MAP[info.talentSpec .. info.classToken] or false
      -- players sharing a name (on different realms) can't be told apart so neither is used
      if lobby[name] ~= nil then specId = false end
      lobby[name] = specId
    end
  end
  return lobby
end

local function shuffleSpecWL(group, specId)
  local specs = arenaDb.shuffleSpecs[group]
  if specs[specId] == nil then specs[specId] = { w=0, l=0 } end
  return specs[specId]
end

local function recordShuffleRound(round, lobby, mapWL)
  if mapWL then updateWinLossCount(round.won, mapWL) end

  local isTeammate = {}
  for _, name in ipairs(round.teammates) do isTeammate[name] = true end

  -- a spec is counted once per round even if more than one player had it
  local withSpecs = {}
  local againstSpecs = {}
  local teammatesFound = 0
  for name, specId in pairs(lobby) do
    if isTeammate[name] then
      teammatesFound = teammatesFound + 1
      if specId then withSpecs[specId] = true end
    elseif specId then
      againstSpecs[specId] = true
    end
  end

  -- without both teammates there's no telling who was on which team that round
  if teammatesFound ~= 2 then return end

  for specId in pairs(withSpecs) do
    updateWinLossCount(round.won, shuffleSpecWL("with", specId))
  end
  for specId in pairs(againstSpecs) do
    updateWinLossCount(round.won, shuffleSpecWL("against", specId))
  end
end

local finishShuffleRound

local function shuffleFinished()
  if currentMatch.shuffleRecorded or not C_PvP.IsMatchComplete() then return end
  if currentMatch.roundOpen then
    -- calls back into this function once the final round has been resolved
    finishShuffleRound()
    return
  end

  local lobby = shuffleLobbySpecs()
  if lobby == nil then return end
  currentMatch.shuffleRecorded = true
  if not C_PvP.IsRatedSoloShuffle() then return end

  local mapWL = nil
  if currentMatch.mapName then
    local maps = arenaDb.maps[SHUFFLE]
    if maps[currentMatch.mapName] == nil then maps[currentMatch.mapName] = { w=0, l=0 } end
    mapWL = maps[currentMatch.mapName]
  end

  for _, round in ipairs(currentMatch.rounds or {}) do
    recordShuffleRound(round, lobby, mapWL)
  end
end

finishShuffleRound = function()
  if not currentMatch.roundOpen or currentMatch.roundResolving then return end
  currentMatch.roundResolving = true

  -- deaths seen now or within the tie window both count (dead players may be revived for the next
  -- round before the window ends and a death may not have reached the client yet)
  local teamDead, enemyDead = shuffleDeaths()
  local match = currentMatch
  local roundId = match.roundId
  C_Timer.After(SHUFFLE_TIE_WINDOW, function()
    if match ~= currentMatch or match.roundId ~= roundId then return end
    local teamDeadLater, enemyDeadLater = shuffleDeaths()
    teamDead = teamDead or teamDeadLater
    enemyDead = enemyDead or enemyDeadLater

    match.roundOpen = false
    match.roundResolving = false
    -- like the scoreboard, a tie (a death on both teams) counts as neither a win nor a loss, and
    -- neither does a round where no death was seen at all
    if teamDead ~= enemyDead then
      table.insert(match.rounds, { teammates = match.roundTeammates, won = enemyDead })
    end
    shuffleFinished()
  end)
end

local function shuffleMatchStateChanged()
  local state = C_PvP.GetActiveMatchState()
  if state == Enum.PvPMatchState.Engaged then
    startShuffleRound()
  elseif state == Enum.PvPMatchState.PostRound then
    finishShuffleRound()
  elseif state == Enum.PvPMatchState.Complete then
    shuffleFinished()
  end
end

local function tableSize(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end

local function fixInvalidData()
  if arenaDb.matches ~= nil then
    -- Cleanup unused stored match data from v2.0
    arenaDb.matches = nil
    -- Purge data stored with invalid spec map from v2.0
    arenaDb.comps = nil
    arenaDb.maps = nil
  end
end

local function populateSpecIdMap()
  for specId = 1, 999 do
    local _, name, _, _, _, class = GetSpecializationInfoByID(specId)
    if name ~= nil and class ~= nil then
      SPEC_ID_MAP[name .. class] = specId
    end
  end
end

local function setBrackets(key)
  arenaDb[key] = {}
  for _, subKey in ipairs(DB_SUBTABLES[key]) do
    arenaDb[key][subKey] = {}
  end
end

-- Checks if `arenaDb` has `key` (and each of its sub-tables, e.g. one per arena bracket) and
-- adds any that are missing
local function checkAndSetBrackets(key)
  if arenaDb[key] == nil then arenaDb[key] = {} end
  for _, subKey in ipairs(DB_SUBTABLES[key]) do
    if arenaDb[key][subKey] == nil then arenaDb[key][subKey] = {} end
  end
end

-- The "Automatically purge previous season data" options: the config key of each and the
-- `arenaDb` tables it covers
local SEASON_PURGES = {
  { option = "purgeMaps", label = "maps", keys = { "maps" } },
  { option = "purgeComps", label = "comps/specs", keys = { "comps", "opposingComps", "shuffleSpecs" } },
  { option = "purgePlayers", label = "players", keys = { "players" } },
}

-- Calls `fn(records, id, record)` for every record in the `arenaDb` table `key` (every bracket)
local function forEachRecord(key, fn)
  for _, records in pairs(arenaDb[key]) do
    for id, record in pairs(records) do
      if type(record) == "table" then fn(records, id, record) end
    end
  end
end

-- Records from before seasons were tracked can't be dated so they're treated as being from the
-- current season, i.e. they're kept until the next season starts
local function addSeasonToUntrackedRecords(season)
  for key in pairs(DB_SUBTABLES) do
    forEachRecord(key, function(_, _, record)
      if record.season == nil then
        record.season = {
          id = season, w = record.w or 0, l = record.l or 0, lowMmr = record.lowMmr, hiMmr = record.hiMmr
        }
      end
    end)
  end
end

-- Removes everything recorded before `season` from the `arenaDb` tables `keys`, a record that has
-- also been updated this season keeps only this season's data. Returns true if anything was removed
local function purgePreviousSeasons(keys, season)
  local purged = false
  for _, key in ipairs(keys) do
    forEachRecord(key, function(records, id, record)
      local seasonTable = record.season
      -- a record from a later season than `season` (which shouldn't happen) is left alone
      if seasonTable == nil or seasonTable.id < season then
        records[id] = nil -- clearing fields while iterating with pairs() is safe in Lua
        purged = true
      elseif seasonTable.id == season and (record.w ~= seasonTable.w or record.l ~= seasonTable.l) then
        for field, value in pairs(seasonTable) do
          if field ~= "id" then record[field] = value end
        end
        purged = true
      end
    end)
  end
  return purged
end

-- Runs once the current season is known (which may not be until after the addon has loaded),
-- returns false if it isn't known yet. Between seasons (when the season is 0) this never runs so
-- nothing is purged until the next season has started
local function checkSeason()
  local season = currentSeason()
  if season == nil then return false end
  eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
  eventFrame:UnregisterEvent("PVP_RATED_STATS_UPDATE")

  addSeasonToUntrackedRecords(season)

  local purged = {}
  for _, purge in ipairs(SEASON_PURGES) do
    if PvPAuditConfig and PvPAuditConfig[purge.option] and purgePreviousSeasons(purge.keys, season) then
      table.insert(purged, purge.label)
    end
  end
  if #purged > 0 then
    print("PvPAudit: removed previous season arena history (" .. table.concat(purged, ", ") .. ")")
  end
  return true
end

local function addonLoaded()
  if not PvPAuditArenaHistory then
    PvPAuditArenaHistory = {}
  end

  local playerAndRealm = PvPAuditGetPlayerAndRealm()
  if not PvPAuditArenaHistory[playerAndRealm] then
    PvPAuditArenaHistory[playerAndRealm] = {}
  end
  arenaDb = PvPAuditArenaHistory[playerAndRealm]

  if not PvPAuditArenaHistory[NOTES] then
    PvPAuditArenaHistory[NOTES] = {}
  end
  notesDb = PvPAuditArenaHistory[NOTES]

  fixInvalidData()
  checkAndSetBrackets("players")
  checkAndSetBrackets("comps")
  checkAndSetBrackets("opposingComps")
  checkAndSetBrackets("maps")
  checkAndSetBrackets("shuffleSpecs")

  populateSpecIdMap()

  -- if the season isn't known yet this is retried on PLAYER_ENTERING_WORLD/PVP_RATED_STATS_UPDATE
  if not checkSeason() then RequestRatedInfo() end

  PvPAuditLoadHoverModule()
  PvPAuditLoadViewerModule()
end

local function eventHandler(self, event, unit, ...)
  local isArena = IsActiveBattlefieldArena()
  local isShuffle = C_PvP.IsSoloShuffle()
  if event == "UPDATE_BATTLEFIELD_SCORE" and isShuffle then
    shuffleFinished()
  elseif event == "UPDATE_BATTLEFIELD_SCORE" and isArena and GetBattlefieldWinner() ~= nil then
    matchFinished()
  elseif event == "PVP_MATCH_STATE_CHANGED" and isShuffle then
    shuffleMatchStateChanged()
  elseif event == "UPDATE_BATTLEFIELD_STATUS" and (isArena or isShuffle) then
    storeTempMetadata()
  elseif event == "ZONE_CHANGED_NEW_AREA" and not isArena and not isShuffle then
    currentMatch = {}
  elseif event == "ADDON_LOADED" and string.lower(unit) == "pvpaudit" then
    addonLoaded()
  elseif (event == "PLAYER_ENTERING_WORLD" or event == "PVP_RATED_STATS_UPDATE") and arenaDb then
    checkSeason()
  end
end

local function onLoad()
  eventFrame = CreateFrame("Frame", "PvPAuditHistoryEventFrame", UIParent)
  eventFrame:RegisterEvent("ADDON_LOADED")
  eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  eventFrame:RegisterEvent("PVP_RATED_STATS_UPDATE")
  eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
  eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
  eventFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
  eventFrame:SetScript("OnEvent", eventHandler)
end

function PvPArenaHistoryClear(arg)
  if string.match(arg:lower(), ".*players") then
    setBrackets("players")
    print("Player data cleared")
  elseif string.match(arg:lower(), ".*comps") then
    setBrackets("comps")
    setBrackets("opposingComps")
    setBrackets("shuffleSpecs")
    print("Team composition and Solo Shuffle spec data cleared")
  elseif string.match(arg:lower(), ".*maps") then
    setBrackets("maps")
    print("Map data cleared")
  elseif string.match(arg:lower(), ".*all") then
    setBrackets("players")
    setBrackets("comps")
    setBrackets("opposingComps")
    setBrackets("maps")
    setBrackets("shuffleSpecs")
    print("ALL arena history data cleared")
  else
    print("Unknown flag: "..arg)
    print("Run /pvpaudit ? or /pvpaudit help for valid flags")
  end
end

onLoad()