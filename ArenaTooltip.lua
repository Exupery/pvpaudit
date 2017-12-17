local eventFrame = nil
local arenaDb = nil

local BRACKETS = { "2v2", "3v3" }

-- adds W/L data to tooltip if DB has data for `name`
local function addToTooltip(tooltip, name)
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

local function tooltipOnShow(tooltip)
  if tooltip:NumLines() > 0 then
    local line = _G[tooltip:GetName() .. "TextLeft1"]
    local txt = line:GetText()

    local _, results = C_LFGList.GetSearchResults()
    for _, r in pairs(results) do
      local id, _, name, desc, voice, _, _, _, _, _, _, _, leader = C_LFGList.GetSearchResultInfo(r)
      if txt and txt:match(name) then
        addToTooltip(tooltip, leader)
      end
    end

    -- TODO HANDLE PLAYER IS IN GROUP LFM
  end
end

local function tooltipUnitUpdate(tooltip)
  local _, unit = tooltip:GetUnit()
  if tooltip:IsUnit("player") or not unit then return end

  local name = GetUnitName(unit, true)
  addToTooltip(tooltip, name)
end

local function eventHandler(self, event, unit, ...)
end

function PvPAuditLoadHoverModule()
  eventFrame = CreateFrame("Frame", "PvPAuditHoverEventFrame", UIParent)
  eventFrame:SetScript("OnEvent", eventHandler)

  GameTooltip:SetScript("OnTooltipSetUnit", tooltipUnitUpdate)
  GameTooltip:SetScript("OnShow", tooltipOnShow)

  local playerAndRealm = PvPAuditGetPlayerAndRealm()
  arenaDb = PvPAuditArenaHistory[playerAndRealm]
end