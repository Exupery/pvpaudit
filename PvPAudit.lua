SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"

local eventFrame = nil

local function colorPrint(msg)
  print("|cffb2b2b2" .. msg)
end

local function errorPrint(err)
  print("|cffff0000" .. err)
end

local function audit()
	local success = SetAchievementComparisonUnit("target")
	local canInspect = CanInspect("target", false)

	if success and canInspect then
		eventFrame:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
	else
		errorPrint("Unable to audit")
	end
end

local function onInspectReady()
	print("INSPECT_ACHIEVEMENT_READY")  -- TODO DELME
  local completed, month, day, year = GetAchievementComparisonInfo(401)
  print(completed)  -- TODO DELME
  print(year)  -- TODO DELME
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
