local GREEN_TEAM = 0
local GOLD_TEAM = 1

local SPEC_ID_MAP = {}

local eventFrame = nil
local arenaDb = nil
local currentMatch = {}

local playerName = GetUnitName("player", false)

local function updateWL(isWin, arenaDbKey, currentMatchKey)
  local currentBracket = arenaDb[arenaDbKey][currentMatch.bracket]
  local bracketKey = currentMatch[currentMatchKey]
  if currentBracket[bracketKey] == nil then
    currentBracket[bracketKey] = { w=0, l=0 }
  end

  local wlTable = currentBracket[bracketKey]
  if isWin then
    wlTable.w = wlTable.w + 1
  else
    wlTable.l = wlTable.l + 1
  end
end

local function updateMapWL(isWin)
  updateWL(isWin, "maps", "mapName")
end

local function updateCompWL(isWin)
  updateWL(isWin, "comps", "comp")
end

local function addCurrentMatchToDb()
  print("addCurrentMatchToDb")  -- TODO DELME
  arenaDb.matches[time()] = currentMatch
  local isWin = currentMatch.playerTeam == currentMatch.winner
  updateMapWL(isWin)
  -- TODO arenaDb.players
  updateCompWL(isWin)
end

local function storeTempMetadata()
  print("storeTempMetadata") -- TODO DELME
  for b = 1, GetMaxBattlefieldID() do
    local status, mapName, _, _, rankedMatch, queueType = GetBattlefieldStatus(b)
    if status == "active" then
      currentMatch.mapName = mapName
      currentMatch.ranked = rankedMatch -- TODO CONFIRM
      currentMatch.season = GetCurrentArenaSeason()
      currentMatch.playerTeam = GetBattlefieldArenaFaction()
      print(GetCurrentArenaSeason()) -- TODO DELME
      print(GetBattlefieldArenaFaction()) -- TODO DELME
      print(mapName) -- TODO DELME
      print(rankedMatch) -- TODO DELME
      print(queueType) -- TODO DELME
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
  print("matchFinished") -- TODO DELME
  if currentMatch.players ~= nil then return end
  local teamSpecs = {}
  local enemySpecs = {}
  currentMatch.players = {}
  for p = 1, GetNumBattlefieldScores() do
    local name, _, _, _, _, team, _, class, classToken, damageDone, healingDone, rating, _, _, _, specName = GetBattlefieldScore(p)
    local specId = SPEC_ID_MAP[specName]
    currentMatch.players[name] = {}
    currentMatch.players[name].class = classToken
    currentMatch.players[name].specId = specId
    currentMatch.players[name].damage = damageDone
    currentMatch.players[name].healing = healingDone
    currentMatch.players[name].team = team
    currentMatch.players[name].rating = rating

    if team == currentMatch.playerTeam then
      table.insert(teamSpecs, specId)
    else
      table.insert(enemySpecs, specId)
    end
    print(name) -- TODO DELME
    print(classToken .. " " .. specName .. " " .. specId) -- TODO DELME
    print(rating) -- TODO DELME
  end

  for t = 0, 1 do
    local _, oldTeamRating, newTeamRating, teamRating = GetBattlefieldTeamInfo(t)
    if teamRating > 0 then
      print(oldTeamRating) -- TODO DELME
      print(newTeamRating) -- TODO DELME
      print(teamRating) -- TODO DELME
    end
  end

  local teamSize = (GetNumBattlefieldScores() > 4) and 3 or 2
  currentMatch.bracket = teamSize .. "v" .. teamSize
  currentMatch.winner = GetBattlefieldWinner()
  currentMatch.comp = getComp(teamSpecs)
  currentMatch.opposingComp = getComp(enemySpecs)

  if true then  -- TODO CHECK IF RATED
    addCurrentMatchToDb()
  end
end

local function populateSpecIdMap()
  for specId = 1, 999 do
    local name = GetSpecializationNameForSpecID(specId)
    if name ~= nil then
      SPEC_ID_MAP[name] = specId
    end
  end
end

-- Checks if `arenaDb` has `key` and if not adds a table for each arena bracket
local function checkAndSetBrackets(key)
  if arenaDb[key] == nil then arenaDb[key] = { ["2v2"]={}, ["3v3"]={} } end
end

local function addonLoaded()
  if not PvPAuditArenaHistory then
    PvPAuditArenaHistory = {}
  end

  local playerAndRealm = playerName .. "-" .. (GetRealmName():gsub("%s+", ""))
  if not PvPAuditArenaHistory[playerAndRealm] then
    PvPAuditArenaHistory[playerAndRealm] = {}
  end

  arenaDb = PvPAuditArenaHistory[playerAndRealm]

  if arenaDb.matches == nil then arenaDb.matches = {} end
  checkAndSetBrackets("players")
  checkAndSetBrackets("comps")
  checkAndSetBrackets("maps")

  populateSpecIdMap()
end

local function eventHandler(self, event, unit, ...)
  local isArena = IsActiveBattlefieldArena()
  if event == "UPDATE_BATTLEFIELD_SCORE" and isArena and GetBattlefieldWinner() ~= nil then
    print("UPDATE_BATTLEFIELD_SCORE") -- TODO DELME
    matchFinished()
  elseif event == "UPDATE_BATTLEFIELD_STATUS" and isArena then
    print("UPDATE_BATTLEFIELD_STATUS") -- TODO DELME
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