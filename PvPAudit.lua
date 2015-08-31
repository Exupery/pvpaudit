SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"

local eventFrame = nil

local TARGET = "target"

local achievements = {
	[1174] = "Arena Master",
	[2091] = "Gladiator",
	[6941] = "Hero of the Horde",
	[6942] = "Hero of the Alliance"
}

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
	local success = SetAchievementComparisonUnit(TARGET)
	local canInspect = CanInspect(TARGET, false)

	if success and canInspect then
		eventFrame:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
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

local function printAchievements()
	for k, v in pairs(achievements) do
	  local completed = GetAchievementComparisonInfo(k)
	  if completed then print(v) end
	end
end

local function onInspectReady()
	printHeader()
	-- TODO PRINT CR
	printAchievements()

	eventFrame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
	ClearAchievementComparisonUnit()
end

local function eventHandler(self, event, unit, ...)
  if event == "INSPECT_ACHIEVEMENT_READY" then
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

SlashCmdList["PVPAUDIT"] = function(arg)
	if arg == "?" or arg == "help" then
		printHelp()
  else
    audit()
  end
end

onLoad()
