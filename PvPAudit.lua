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
      errorPrint("Out of range")
    end
  else
    errorPrint("Unable to audit")
  end

  if reset then cleanup() end
end

local function printHeader(name, realm)
  local _, localeIndependentClass = UnitClass(TARGET)
  local str = string.format("PvPAudit for %s %s", name, realm)

  PvPAuditPlayerCache[name .. realm]["name"] = name
  PvPAuditPlayerCache[name .. realm]["realm"] = realm
  PvPAuditPlayerCache[name .. realm]["localeIndependentClass"] = localeIndependentClass

  if printTo == nil then
    classColorPrint(str, localeIndependentClass)
  else
    output(str)
  end
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

local function printRatings()
  for _, b in pairs(BRACKETS) do
    local highest
    if b ~= "RBG" then
      highest = GetComparisonStatistic(statistics[b])
      if tonumber(highest) == 1500 then highest = "< 1500" end
    else
      highest = getRbgHighest()
    end

    local str = b .. "   " .. highest .. " EXP "
    if printTo == nil then str = str .. "|cffb2b2b2" end
    str = str .. "[" .. targetCurrentRatings[b] .. " CR]"

    output(str)
  end
end

local function printAchievements()
  for k, v in pairs(achievements) do
    local completed = GetAchievementComparisonInfo(k)
    if completed then output(v) end
  end
end

local function printAll()
  local name, realm = UnitName(TARGET)
  if realm == nil then realm = "" end

  PvPAuditPlayerCache[name .. realm] = {}

  printHeader(name, realm)
  printRatings()
  printAchievements()
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
    printAll()
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
