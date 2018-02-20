local GREEN_TEAM = 0
local GOLD_TEAM = 1
local SPEC_ID_MAP = {}

local eventFrame = nil
local arenaDb = nil
local currentMatch = {}

local playerName = GetUnitName("player", false)

function PvPAuditGetPlayerAndRealm()
  return playerName .. "-" .. (GetRealmName():gsub("%s+", ""))
end

local function updateWinLossCount(isWin, wlTable)
  if wlTable.w == nil then wlTable.w = 0 end
  if wlTable.l == nil then wlTable.l = 0 end
  if isWin then
    wlTable.w = wlTable.w + 1
  else
    wlTable.l = wlTable.l + 1
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
    end
  end
end

local function addCurrentMatchToDb()
  arenaDb.matches[time()] = currentMatch
  local isWin = currentMatch.playerTeam == currentMatch.winner
  updateMapWL(isWin)
  updateCompWL(isWin)
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
    local name, _, _, _, _, team, _, class, classToken, damageDone, healingDone, _, _, _, _, specName = GetBattlefieldScore(p)
    local specId = SPEC_ID_MAP[specName]
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
  local opposingTeam = (currentMatch.playerTeam == GREEN_TEAM) and GOLD_TEAM or GREEN_TEAM
  local _, _, _, opposingMmr = GetBattlefieldTeamInfo(opposingTeam)
  currentMatch.opposingMmr = opposingMmr

  local teamSize = (GetNumBattlefieldScores() > 4) and 3 or 2
  currentMatch.bracket = teamSize .. "v" .. teamSize

  currentMatch.winner = GetBattlefieldWinner()
  currentMatch.comp = getComp(teamSpecs)
  currentMatch.opposingComp = getComp(enemySpecs)

  if currentMatch.ranked then
    addCurrentMatchToDb()
  end
end

local function tableSize(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end

-- v2.0 populated the spec ID map incorrectly by using only the spec names
-- as the keys, since spec names are not unique across classes (e.g. resto,
-- holy, frost) all such spec data is invalid and requires correction.
local function fixInvalidData()
  if tableSize(arenaDb.matches) == 0 or tableSize(arenaDb["opposingComps"]["2v2"]) > 0 or tableSize(arenaDb["opposingComps"]["3v3"]) > 0 then
    return
  end

  arenaDb.comps = { ["2v2"]={}, ["3v3"]={} }
  for _, match in pairs(arenaDb.matches) do
    local teamSpecs = {}
    local enemySpecs = {}
    local playerTeam = match["players"][playerName]["team"]
    for _, player in pairs(match.players) do
      local specName = GetSpecializationNameForSpecID(player.specId)
      local specId = SPEC_ID_MAP[specName .. player.class]
      player.specId = specId
      if player.team == playerTeam then
        table.insert(teamSpecs, specId)
      else
        table.insert(enemySpecs, specId)
      end
    end
    match.comp = getComp(teamSpecs)
    match.opposingComp = getComp(enemySpecs)
    local isWin = playerTeam == match.winner
    local bracket = match.bracket
    if arenaDb["comps"][bracket][match.comp] == nil then
      arenaDb["comps"][bracket][match.comp] = {}
    end
    if arenaDb["opposingComps"][bracket][match.opposingComp] == nil then
      arenaDb["opposingComps"][bracket][match.opposingComp] = {}
    end
    updateWinLossCount(isWin, arenaDb["comps"][bracket][match.comp])
    updateWinLossCount(isWin, arenaDb["opposingComps"][bracket][match.opposingComp])
  end

end

local function populateSpecIdMap()
  for specId = 1, 999 do
    local _, name, _, _, _, class = GetSpecializationInfoByID(specId)
    if name ~= nil and class ~= nil then
      SPEC_ID_MAP[name .. class] = specId
    end
  end
  fixInvalidData()
end

-- Checks if `arenaDb` has `key` and if not adds a table for each arena bracket
local function checkAndSetBrackets(key)
  if arenaDb[key] == nil then arenaDb[key] = { ["2v2"]={}, ["3v3"]={} } end
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

  if arenaDb.matches == nil then arenaDb.matches = {} end
  checkAndSetBrackets("players")
  checkAndSetBrackets("comps")
  checkAndSetBrackets("opposingComps")
  checkAndSetBrackets("maps")

  populateSpecIdMap()

  PvPAuditLoadHoverModule()
  PvPAuditLoadViewerModule()
end

local function eventHandler(self, event, unit, ...)
  local isArena = IsActiveBattlefieldArena()
  if event == "UPDATE_BATTLEFIELD_SCORE" and isArena and GetBattlefieldWinner() ~= nil then
    matchFinished()
  elseif event == "UPDATE_BATTLEFIELD_STATUS" and isArena then
    storeTempMetadata()
  elseif event == "ZONE_CHANGED_NEW_AREA" and not isArena then
    currentMatch = {}
  elseif event == "ADDON_LOADED" and unit == "PvPAudit" then
    addonLoaded()
  end
end

local function onLoad()
  eventFrame = CreateFrame("Frame", "PvPAuditHistoryEventFrame", UIParent)
  eventFrame:RegisterEvent("ADDON_LOADED")
  eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
  eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
  eventFrame:SetScript("OnEvent", eventHandler)
end

onLoad()