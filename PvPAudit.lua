SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"
BINDING_HEADER_PVPAUDIT = "PvPAudit"
BINDING_NAME_PVPAUDIT1 = "Audit the current target"

local eventFrame = nil

local TARGET = "target"
local BRACKETS = { "2v2", "3v3", "5v5", "RBG" }
local MAX_ATTEMPTS = 3

local achievements = {
  [1174] = "Arena Master",
  [2091] = "Gladiator",
  [6941] = "Hero of the Horde",
  [6942] = "Hero of the Alliance"
}

local statistics = {
  [BRACKETS[1]] = 370,
  [BRACKETS[2]] = 595,
  [BRACKETS[3]] = 596,
  [BRACKETS[4]] = nil
}

local rbgRatings = {
  [1100] = {5330, 5345},
  [1200] = {5331, 5346},
  [1300] = {5332, 5347},
  [1400] = {5333, 5348},
  [1500] = {5334, 5349},
  [1600] = {5335, 5350},
  [1700] = {5336, 5351},
  [1800] = {5337, 5352},
  [1900] = {5359, 5338},
  [2000] = {5339, 5353},
  [2100] = {5340, 5354},
  [2200] = {5341, 5355},
  [2300] = {5357, 5342},
  [2400] = {5343, 5356}
}

local targetCurrentRatings = {}

local attempts = 0

local printTo = nil

local function colorPrint(msg)
  print("|cffb2b2b2" .. msg)
end

local function classColorPrint(msg, class)
  local color = string.format("|c%s", RAID_CLASS_COLORS[class]["colorStr"])
  print(color .. msg)
end

local function errorPrint(err)
  print("|cffff0000" .. err)
end

local function output(msg)
  if printTo == nil then
    print(msg)
  else
    SendChatMessage(msg, printTo)
  end

end

local function printPlayerInfo(playerSlug)
  local name = PvPAuditPlayerCache[playerSlug]["name"]
  local realm = PvPAuditPlayerCache[playerSlug]["realm"]
  local str = string.format("PvPAudit for %s %s", name, realm)

  if printTo == nil then
    classColorPrint(str, PvPAuditPlayerCache[playerSlug]["localeIndependentClass"])
  else
    output(str)
  end
end

local function printRatings(playerSlug)
  for _, b in pairs(BRACKETS) do
    local highest = PvPAuditPlayerCache[playerSlug][b]["highest"]
    local cr = PvPAuditPlayerCache[playerSlug][b]["cr"]

    local str = b .. "   " .. highest .. " EXP "
    if printTo == nil then str = str .. "|cffb2b2b2" end
    str = str .. "[" .. cr .. " CR]"

    output(str)
  end
end

local function printAchievements(playerSlug)
  local playerAchievements = PvPAuditPlayerCache[playerSlug]["achievements"]

  if next(playerAchievements) ~= nil then
    output("Notable Achievements [account-wide]")
    for k, _ in pairs(playerAchievements) do
      output(k)
    end
  end

end

local function printAll(playerSlug)
  printPlayerInfo(playerSlug)
  printRatings(playerSlug)
  printAchievements(playerSlug)
end

local function init()
  ClearAchievementComparisonUnit()
  ClearInspectPlayer()
end

local function cleanup()
  eventFrame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
  eventFrame:UnregisterEvent("INSPECT_HONOR_UPDATE")
  eventFrame:UnregisterEvent("INSPECT_READY")
  attempts = 0
  printTo = nil
end

local function getNameRealmSlug()
  local name, realm = UnitName(TARGET)
  if realm == nil then realm = "" end
  local slug = name .. realm

  return  name, realm, slug
end

local function audit()
  init()

  local reset = true
  local canInspect = CanInspect(TARGET, false)

  if canInspect then
    local inRange = UnitIsVisible(TARGET) or CheckInteractDistance(TARGET, 1)
    if inRange then
      reset = false
      eventFrame:RegisterEvent("INSPECT_READY")
      NotifyInspect(TARGET)
    else
      local _, _, slug = getNameRealmSlug()
      if PvPAuditPlayerCache[slug] ~= nil then
        local elapsed = SecondsToTime(time() - PvPAuditPlayerCache[slug]["cachedAt"])
        output("Target out of range, using cached data from " .. elapsed .. " ago")
        printAll(slug)
      else
        errorPrint("Out of range")
      end
    end
  else
    errorPrint("Unable to audit")
  end

  if reset then cleanup() end
end

local function cachePlayerInfo(name, realm)
  local playerSlug = name .. realm
  local _, localeIndependentClass = UnitClass(TARGET)

  PvPAuditPlayerCache[playerSlug]["name"] = name
  PvPAuditPlayerCache[playerSlug]["realm"] = realm
  PvPAuditPlayerCache[playerSlug]["localeIndependentClass"] = localeIndependentClass
  PvPAuditPlayerCache[playerSlug]["cachedAt"] = time()
end

local function getCurrentRatings()
  targetCurrentRatings = {}

  for i, b in pairs(BRACKETS) do
    local cr = GetInspectArenaData(i)
    targetCurrentRatings[b] = cr
  end
end

local function getRbgHighest()
  local highest = 0
  for rating, ids in pairs(rbgRatings) do
    local completed = GetAchievementComparisonInfo(ids[1]) or GetAchievementComparisonInfo(ids[2])
    if completed and rating > highest then highest = rating end
  end

  if highest == 0 then
    return "--"
  else
    return highest .. "+"
  end
end

-- INSPECT_HONOR_UPDATE may fire before CR data is actually available
-- if CRs for all brackets are zero then rescan up to MAX_ATTEMPTS
local function shouldRescan()
  attempts = attempts + 1
  if attempts > MAX_ATTEMPTS then
    return false
  end

  for _, r in pairs(targetCurrentRatings) do
    if r > 0 then return false end
  end

  return true
end

local function cacheRatings(playerSlug)
  for _, b in pairs(BRACKETS) do
    local highest
    if b ~= "RBG" then
      highest = GetComparisonStatistic(statistics[b])
      if tonumber(highest) == 1500 then highest = "< 1500" end
    else
      highest = getRbgHighest()
    end

    local cr = targetCurrentRatings[b]

    PvPAuditPlayerCache[playerSlug][b] = {}
    PvPAuditPlayerCache[playerSlug][b]["highest"] = highest
    PvPAuditPlayerCache[playerSlug][b]["cr"] = cr
  end
end

local function cacheAchievements(playerSlug)
  PvPAuditPlayerCache[playerSlug]["achievements"] = {}

  for k, v in pairs(achievements) do
    local completed = GetAchievementComparisonInfo(k)
    if completed then
      PvPAuditPlayerCache[playerSlug]["achievements"][v] = true
    end
  end
end

local function cacheAll(name, realm, slug)
  PvPAuditPlayerCache[slug] = {}

  cachePlayerInfo(name, realm)
  cacheRatings(slug)
  cacheAchievements(slug)
end

local function onInspectReady()
  eventFrame:RegisterEvent("INSPECT_HONOR_UPDATE")
  RequestInspectHonorData()
end

local function onHonorInspectReady()
  getCurrentRatings()

  eventFrame:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
  SetAchievementComparisonUnit(TARGET)
end

local function onAchievementInspectReady()
  if shouldRescan() then
    audit()
  else
    local name, realm, slug = getNameRealmSlug()

    cacheAll(name, realm, slug)
    printAll(slug)
    cleanup()
  end
end

local function eventHandler(self, event, unit, ...)
  if event == "INSPECT_HONOR_UPDATE" then
    onHonorInspectReady()
  elseif event == "INSPECT_ACHIEVEMENT_READY" then
    onAchievementInspectReady()
  elseif event == "INSPECT_READY" then
    onInspectReady()
  end
end

local function onLoad()
  eventFrame = CreateFrame("Frame", "PvPAuditEventFrame", UIParent)
  eventFrame:SetScript("OnEvent", eventHandler)

  if not PvPAuditPlayerCache then
    PvPAuditPlayerCache = {}
  end

  print("PvPAudit loaded, to audit the current target type /pvpaudit")
end

local function printHelp()
  colorPrint("PvPAudit commands:")
  print("/pvpaudit - audit the current target")
  print("/pvpaudit i or /pvpaudit instance - audit the current target and output to /instance")
  print("/pvpaudit p or /pvpaudit party - audit the current target and output to /party")
  print("/pvpaudit r or /pvpaudit raid - audit the current target and output to /raid")
  print("/pvpaudit ? or /pvpaudit help - Print this list")
end

-- global function for keybinding
function pvpaudit()
  audit()
end

SlashCmdList["PVPAUDIT"] = function(arg)
  if arg == "?" or arg == "help" then
    printHelp()
  else
    if arg == "i" or arg == "instance" then
      printTo = "INSTANCE_CHAT"
    elseif arg == "p" or arg == "party" then
      printTo = "PARTY"
    elseif arg == "r" or arg == "raid" then
      printTo = "RAID"
    else
      printTo = nil
    end

    audit()
  end
end

onLoad()
