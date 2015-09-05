SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"
BINDING_HEADER_PVPAUDIT = "PvPAudit"
BINDING_NAME_PVPAUDIT1 = "Audit the current target"

local eventFrame = nil

local TARGET = "target"
local BRACKETS = { "2v2", "3v3", "5v5", "RBG" }

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

local targetRatings = {}

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

local function audit()
	local canInspect = CanInspect(TARGET, false)

	if canInspect then
		NotifyInspect(TARGET)
		eventFrame:RegisterEvent("INSPECT_HONOR_UPDATE")
		RequestInspectHonorData()
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

local function getRatings()
	for i, b in pairs(BRACKETS) do
	  local cr = GetInspectArenaData(i)
	  targetRatings[b] = cr
	end
end

local function getRbgHighest()
	return 0 -- TODO
end

local function printRatings()
	for _, b in pairs(BRACKETS) do
	  local highest
	  if b ~= "RBG" then
	  	highest = GetComparisonStatistic(statistics[b])
  	else
  		highest = getRbgHighest()
  	end

	  print(b .. "   " .. highest .. " EXP |cffb2b2b2[" .. targetRatings[b] .. " CR]")
	end
end

local function printAchievements()
	for k, v in pairs(achievements) do
	  local completed = GetAchievementComparisonInfo(k)
	  if completed then print(v) end
	end
end

local function onHonorInspectReady()
	getRatings()

	eventFrame:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
	SetAchievementComparisonUnit(TARGET)
end

local function onAchievementInspectReady()
	printHeader()
	printRatings()
	printAchievements()

	eventFrame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
	eventFrame:UnregisterEvent("INSPECT_HONOR_UPDATE")
	ClearAchievementComparisonUnit()
	ClearInspectPlayer()
end

local function eventHandler(self, event, unit, ...)
	if event == "INSPECT_HONOR_UPDATE" then
		onHonorInspectReady()
  elseif event == "INSPECT_ACHIEVEMENT_READY" then
  	onAchievementInspectReady()
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
