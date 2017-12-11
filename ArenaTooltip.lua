local eventFrame = nil
local arenaDb = nil

local BRACKETS = { "2v2", "3v3" }

local function tooltipUnitUpdate(tooltip)
  local _, unit = tooltip:GetUnit()  -- TODO HANDLE LFG TOOL
  if tooltip:IsUnit("player") or not unit then return end

  local name = GetUnitName(unit, true)
  for _, bracket in pairs(BRACKETS) do
    local target = arenaDb["players"][bracket][name]
    if target then
      local mmrRange = target.lowMmr .. "-" .. target.hiMmr
      local str = string.format("%s W: %d L: %d MMR: %s", bracket, target.w, target.l, mmrRange)
      tooltip:AddLine(str, 1, 1, 1)
      tooltip:Show()
    end
  end
end

local function eventHandler(self, event, unit, ...)
end

function PvPAuditLoadHoverModule()
  eventFrame = CreateFrame("Frame", "PvPAuditHoverEventFrame", UIParent)
  eventFrame:SetScript("OnEvent", eventHandler)

  GameTooltip:SetScript("OnTooltipSetUnit", tooltipUnitUpdate)

  local playerAndRealm = PvPAuditGetPlayerAndRealm()
  arenaDb = PvPAuditArenaHistory[playerAndRealm]
end