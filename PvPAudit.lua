SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"
BINDING_HEADER_PVPAUDIT = "PvPAudit"
BINDING_NAME_PVPAUDIT1 = "Audit the current target"

local eventFrame = nil

local TARGET = "target"
local BRACKETS = { "2v2", "3v3", "5v5", "RBG" }
local MAX_ATTEMPTS = 2
local MAX_CACHE_AGE = 2592000 -- 30 DAYS

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

local auditTarget = TARGET
local targetCurrentRatings = {}

local attempts = 0

local printTo = nil

local auditBracket = nil
local groupAuditTargets = {}
local groupAuditsCompleted = 0
local groupAuditTime = 0

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
  local auditDesc = auditBracket == nil and "PvPAudit" or auditBracket .. " audit"
  local str = string.format("%s for %s %s", auditDesc, name, realm)

  if printTo == nil then
    classColorPrint(str, PvPAuditPlayerCache[playerSlug]["localeIndependentClass"])
  else
    output(str)
  end
end

-- Print player's ratings for a single bracket
local function printRating(playerSlug, bracket)
  local highest = PvPAuditPlayerCache[playerSlug][bracket]["highest"]
  local cr = PvPAuditPlayerCache[playerSlug][bracket]["cr"]

  local str = auditBracket and "" or (bracket .. "   ")
  str = str .. highest .. " EXP "
  if printTo == nil then str = str .. "|cffb2b2b2" end
  str = str .. "[" .. cr .. " CR]"

  output(str)
end

-- Print player's ratings for ALL brackets
local function printRatings(playerSlug)
  for _, bracket in pairs(BRACKETS) do
    printRating(playerSlug, bracket)
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

-- Prints ratings for ALL brackets and achievements
local function printAll(playerSlug)
  printRatings(playerSlug)
  printAchievements(playerSlug)
end

-- Prints ratings for specified bracket only
local function printBracket(playerSlug, bracket)
  printRating(playerSlug, bracket)
end

local function printAuditResults(playerSlug)
  printPlayerInfo(playerSlug)
  if auditBracket == nil then
    printAll(playerSlug)
  else
    printBracket(playerSlug, auditBracket)
  end
end

local function init()
  ClearAchievementComparisonUnit()
  ClearInspectPlayer()
end

local function cleanup(auditFunction)
  attempts = 0
  groupAuditsCompleted = groupAuditsCompleted + 1
  local nextTarget = groupAuditTargets[groupAuditsCompleted]
  if nextTarget ~= nil then
    auditFunction(nextTarget)
  else
    printTo = nil
    auditTarget = TARGET
    groupAuditTime = 0
    groupAuditsCompleted = 0
    groupAuditTargets = {}
    eventFrame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
    eventFrame:UnregisterEvent("INSPECT_HONOR_UPDATE")
    eventFrame:UnregisterEvent("INSPECT_READY")
  end
end

local function getNameRealmSlug()
  local name, realm = UnitName(auditTarget)
  if realm == nil then realm = "" end
  local slug = name .. realm

  return  name, realm, slug
end

local function audit(target)
  auditTarget = target
  init()

  local reset = true
  local canInspect = CanInspect(auditTarget, false)

  if canInspect then
    local name = UnitName(auditTarget)
    local inRange = UnitIsVisible(auditTarget) or CheckInteractDistance(auditTarget, 1)
    if inRange then
      reset = false
      eventFrame:RegisterEvent("INSPECT_READY")
      NotifyInspect(auditTarget)
    else
      local _, _, slug = getNameRealmSlug()
      if PvPAuditPlayerCache[slug] ~= nil then
        local elapsed = SecondsToTime(time() - PvPAuditPlayerCache[slug]["cachedAt"])
        output(name .. " out of range, using cached data from " .. elapsed .. " ago")
        printAuditResults(slug)
      else
        errorPrint(name .. " out of range")
      end
    end
  else
    errorPrint("Unable to audit")
  end

  if reset then cleanup(audit) end
end

local function auditGroup()
  local groupSize = GetNumGroupMembers()
  if not IsInRaid() then groupSize = groupSize - 1 end
  local group = IsInRaid() and "raid" or "party"
  for i = 1, groupSize do
    groupAuditTargets[i] = group .. i
  end

  if IsInRaid() then
    groupAuditsCompleted = 1
    audit(groupAuditTargets[1])
  else
    audit("player")
  end
end

local function cachePlayerInfo(name, realm)
  local playerSlug = name .. realm
  local _, localeIndependentClass = UnitClass(auditTarget)

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
  if attempts >= MAX_ATTEMPTS then
    return false
  end

  for _, r in pairs(targetCurrentRatings) do
    if r > 0 then return false end
  end

  return true
end

local function onUpdate(self, elapsed)
  if auditTarget ~= TARGET and groupAuditsCompleted < GetNumGroupMembers() then
    groupAuditTime = groupAuditTime + elapsed
    if groupAuditTime >= 1 then
      attempts = 0
      groupAuditTime = 0
      audit(auditTarget)
    end
  end
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

  if shouldRescan() then
    audit(auditTarget)
  else
    eventFrame:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
    SetAchievementComparisonUnit(auditTarget)
  end
end

local function onAchievementInspectReady()
  local name, realm, slug = getNameRealmSlug()

  cacheAll(name, realm, slug)
  printAuditResults(slug)
  cleanup(audit)
end

local function tidyCache()
  for slug, data in pairs(PvPAuditPlayerCache) do
    local age = time() - (data["cachedAt"] ~= nil and data["cachedAt"] or 0)
    if age > MAX_CACHE_AGE then
      PvPAuditPlayerCache[slug] = nil
    end
  end
end

local function addonLoaded()
  if not PvPAuditPlayerCache then
    PvPAuditPlayerCache = {}
  else
    tidyCache()
  end

  print("PvPAudit loaded, to audit the current target type /pvpaudit")
end

local function eventHandler(self, event, unit, ...)
  if event == "INSPECT_HONOR_UPDATE" then
    onHonorInspectReady()
  elseif event == "INSPECT_ACHIEVEMENT_READY" then
    onAchievementInspectReady()
  elseif event == "INSPECT_READY" then
    onInspectReady()
  elseif event == "ADDON_LOADED" and unit == "PvPAudit" then
    addonLoaded()
  end
end

local function onLoad()
  eventFrame = CreateFrame("Frame", "PvPAuditEventFrame", UIParent)
  eventFrame:RegisterEvent("ADDON_LOADED")
  eventFrame:SetScript("OnEvent", eventHandler)
  eventFrame:SetScript("OnUpdate", onUpdate)
end

local function printHelp()
  colorPrint("PvPAudit commands:")
  print("/pvpaudit - audit the current target")
  print("/pvpaudit i or /pvpaudit instance - audit the current target and output to /instance")
  print("/pvpaudit p or /pvpaudit party - audit the current target and output to /party")
  print("/pvpaudit r or /pvpaudit raid - audit the current target and output to /raid")
  print("To audit ALL current group members and output a specific bracket append the bracket after any of the above commands.")
  print("Arena brackets can be provided by either single (e.g. '3') or three character identifiers (e.g. '3v3')")
  print("Examples: /pvpaudit 3v3, /pvpaudit i 2, /pvpaudit raid rbg")
  print("/pvpaudit ? or /pvpaudit help - Print this list")
end

-- global function for keybinding audit current target
function pvpaudit()
  auditBracket = nil
  audit(TARGET)
end

SlashCmdList["PVPAUDIT"] = function(arg)
  if arg == "?" or arg == "help" then
    printHelp()
  elseif string.match(arg, "h.*") then
    PvPAuditHistoryCmd(arg)
  else
    if string.match(arg, "i.*") then
      printTo = "INSTANCE_CHAT"
    elseif string.match(arg, "p.*") then
      printTo = "PARTY"
    elseif string.match(arg, "r.*") and arg:lower() ~= "rbg" then
      printTo = "RAID"
    else
      printTo = nil
    end

    if string.match(arg, ".*2.*") then
      auditBracket = BRACKETS[1]
    elseif string.match(arg, ".*3.*") then
      auditBracket = BRACKETS[2]
    elseif string.match(arg, ".*5.*") then
      auditBracket = BRACKETS[3]
    elseif string.match(arg:lower(), ".*rbg.*") then
      auditBracket = BRACKETS[4]
    else
      auditBracket = nil
    end

    if auditBracket == nil then
      audit(TARGET)
    else
      auditGroup()
    end
  end
end

onLoad()
