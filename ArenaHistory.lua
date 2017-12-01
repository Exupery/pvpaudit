local GREEN_TEAM = 0
local GOLD_TEAM = 1

local SPEC_ID_MAP = {}

local eventFrame = nil
local arenaDb = PvPAuditArenaHistory
local currentMatch = {}

local playerName = GetUnitName("player", false)

local function storeTempMetadata()
  print("storeTempMetadata") -- TODO DELME
  for b = 1, GetMaxBattlefieldID() do
    local status, mapName, _, _, _, teamSize, rankedMatch = GetBattlefieldStatus(b)
    if status == "active" then
      currentMatch.mapName = mapName
      currentMatch.bracket = teamSize
      currentMatch.ranked = rankedMatch -- TODO MAKE BOOLEAN
      currentMatch.season = GetCurrentArenaSeason()
      currentMatch.playerTeam = GetBattlefieldArenaFaction()
      print(GetCurrentArenaSeason()) -- TODO DELME
      print(GetBattlefieldArenaFaction()) -- TODO DELME
      print(mapName) -- TODO DELME
      print(teamSize) -- TODO DELME
      print(rankedMatch) -- TODO DELME
      return
    end
  end
end

local function matchFinished()
  print("matchFinished") -- TODO DELME
  if currentMatch.players ~= nil then return end
  print("NO PLAYERS YET") -- TODO DELME
  currentMatch.players = {}
  for p = 1, GetNumBattlefieldScores() do
    local name, _, _, deaths, _, team, _, class, classToken, damageDone, healingDone, rating, _, _, _, talentSpec = GetBattlefieldScore(p)
    currentMatch.players[name] = {}
    currentMatch.players[name].class = classToken
    currentMatch.players[name].specId = SPEC_ID_MAP[talentSpec]
    currentMatch.players[name].damage = damageDone
    currentMatch.players[name].healing = healingDone
    currentMatch.players[name].died = deaths > 0
    currentMatch.players[name].team = team
    currentMatch.players[name].rating = rating
    print(name) -- TODO DELME
    print(classToken) -- TODO DELME
    print(talentSpec) -- TODO DELME
    print(currentMatch.players[name].specId) -- TODO DELME
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

  currentMatch.winner = GetBattlefieldWinner()
  print(GetBattlefieldWinner()) -- TODO DELME
end

local function populateSpecIdMap()
  for specId = 1, 999 do
    local name = GetSpecializationNameForSpecID(specId)
    if name ~= nil then
      SPEC_ID_MAP[name] = specId
    end
  end
end

local function addonLoaded()
  if not PvPAuditArenaHistory then
    PvPAuditArenaHistory = {}
    arenaDb = PvPAuditArenaHistory
  end

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
  elseif event == "ADDON_LOADED" and unit == "PvPAudit" then
    addonLoaded()
  end
end

local function onLoad()
  eventFrame = CreateFrame("Frame", "PvPAuditHistoryEventFrame", UIParent)
  eventFrame:RegisterEvent("ADDON_LOADED")
  eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
  eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
  eventFrame:SetScript("OnEvent", eventHandler)
end

onLoad()