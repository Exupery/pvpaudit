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
		print("INSPECTACHIEVEMENTREADY")	-- TODO DELME
	end
end

local function onLoad()
	local eventFrame = CreateFrame("Frame", "PvPAuditEventFrame", UIParent)
	eventFrame:RegisterEvent("INSPECTACHIEVEMENTREADY")
	eventFrame:SetScript("OnEvent", eventHandler)

	print("PvPAudit loaded, to audit the current target type /pvpaudit")
end

SlashCmdList["PVPAUDIT"] = function(arg)
	if arg == "?" or arg == "help" then
		colorPrint("PvPAudit commands:")
		print("/pvpaudit - audit the current player")
		print("/pvpaudit PLAYERNAME - audit player named PLAYERNAME")
		print("/pvpaudit ? or /pvpaudit help - Prints this list")
	elseif arg ~= nil and string.match(arg, "%w+") then
		-- TODO
		print("ARG: " .. arg)	-- TODO DELME
	else
		-- TODO
		print("NO ARG")	-- TODO DELME
	end
end

onLoad()
