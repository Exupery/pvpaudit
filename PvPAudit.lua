SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"

local function colorPrint(msg)
  print("|cffb2b2b2" .. msg)
end

local function errorPrint(err)
  print("|cffff0000" .. err)
end

local function eventHandler(self, event, unit, ...)
  if event == "INSPECTACHIEVEMENTREADY" then
    -- TODO
    print("INSPECTACHIEVEMENTREADY")  -- TODO DELME
  end
end

local function onLoad()
  local eventFrame = CreateFrame("Frame", "PvPAuditEventFrame", UIParent)
  eventFrame:RegisterEvent("INSPECTACHIEVEMENTREADY")
  eventFrame:SetScript("OnEvent", eventHandler)

  print("PvPAudit loaded, to audit the current target type /pvpaudit")
end

local function printHelp()
	colorPrint("PvPAudit commands:")
  print("/pvpaudit - audit the current target")
  print("/pvpaudit audit PLAYERNAME - audit player named PLAYERNAME")
  print("/pvpaudit ? or /pvpaudit help - Print this list")
end

SlashCmdList["PVPAUDIT"] = function(arg)
	if arg == "?" or arg == "help" then
		printHelp()
  elseif arg ~= nil and string.match(arg, "%w+") then
    print("ARG: " .. arg)  -- TODO DELME
    if arg == "audit" or string.match(arg, "audit%s+$") then
    	-- TODO AUDIT TARGET
    	print("AUDIT TARGET")  -- TODO DELME
  	elseif string.match(arg, "audit%s+%w+") then
  		local name = string.match(arg, "audit%s+(.+)")
    	-- TODO AUDIT NAME
    	print("AUDIT: " .. name)  -- TODO DELME
    else
    	errorPrint("PvPAudit Command '" .. arg .. "' Not Found")
    	printHelp()
    end
  else
    -- TODO AUDIT TARGET
    print("NO ARG")  -- TODO DELME
  end
end

onLoad()
