SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"
BINDING_HEADER_PVPAUDIT = "PvPAudit"
BINDING_NAME_PVPAUDIT1 = "Audit the current target"

local eventFrame = nil

local TARGET = "target"
local BRACKETS = { "2v2", "3v3", "5v5", "RBG" }
local DELAY = 0.25

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

local elapsed = 0
local honorInspectCalled = false

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

local function init()
  elapsed = 0
  honorInspectCalled = false
  ClearAchievementComparisonUnit()
  ClearInspectPlayer()
end

local function audit()
  init()

  local canInspect = CanInspect(TARGET, false)

  if canInspect then
    local inRange = UnitIsVisible(TARGET) or CheckInteractDistance(TARGET, 1)
    if inRange then
      eventFrame:RegisterEvent("INSPECT_READY")
      NotifyInspect(TARGET)
    else
      errorPrint("Out of range")
    end
  else
    errorPrint("Unable to audit")
  end
end

local function printHeader()
  local name, realm = UnitName(TARGET)
  if realm == nil then realm = "" end
  local _, localeIndependentClass = UnitClass(TARGET)
  local str = string.format("PvPAudit for %s %s", name, realm)

  classColorPrint(str, localeIndependentClass)
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

local function printRatings()
  for _, b in pairs(BRACKETS) do
    local highest
    if b ~= "RBG" then
      highest = GetComparisonStatistic(statistics[b])
    else
      highest = getRbgHighest()
    end

    print(b .. "   " .. highest .. " EXP |cffb2b2b2[" .. targetCurrentRatings[b] .. " CR]")
  end
end

local function printAchievements()
  for k, v in pairs(achievements) do
    local completed = GetAchievementComparisonInfo(k)
    if completed then print(v) end
  end
end

local function printAll()
  printHeader()
  printRatings()
  printAchievements()
end

local function cleanup()
  honorInspectCalled = false
  eventFrame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
  eventFrame:UnregisterEvent("INSPECT_HONOR_UPDATE")
  eventFrame:UnregisterEvent("INSPECT_READY")
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
  printAll()
  cleanup()
end

-- use a delay because INSPECT_HONOR_UPDATE lies
local function updateHandler(self, sinceLast)
  elapsed = elapsed + sinceLast
  if elapsed > DELAY then
    honorInspectCalled = true
    elapsed = 0
    eventFrame:SetScript("OnUpdate", nil)
    onHonorInspectReady()
  end
end

local function eventHandler(self, event, unit, ...)
  if event == "INSPECT_HONOR_UPDATE" and not honorInspectCalled then
    eventFrame:SetScript("OnUpdate", updateHandler)
  elseif event == "INSPECT_ACHIEVEMENT_READY" then
    onAchievementInspectReady()
  elseif event == "INSPECT_READY" then
    onInspectReady()
  end
end

local function onLoad()
  eventFrame = CreateFrame("Frame", "PvPAuditEventFrame", UIParent)
  eventFrame:SetScript("OnEvent", eventHandler)

  print("PvPAudit loaded, to audit the current target type /pvpaudit")
end

local function printHelp()
  colorPrint("PvPAudit commands:")
  print("/pvpaudit - audit the current target")
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
    audit()
  end
end

onLoad()
