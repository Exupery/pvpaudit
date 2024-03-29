local eventFrame = nil
local arenaDb = nil
local notesDb = nil

local BRACKETS = { "2v2", "3v3" }

-- adds W/L data to tooltip if DB has data for `name`
local function addToTooltip(tooltip, name)
  if not name then return end

  if PvPAuditConfig["showHistory"] then
    for _, bracket in pairs(BRACKETS) do
      local target = arenaDb["players"][bracket][name]
      if target then
        local mmrRange = target.lowMmr .. "-" .. target.hiMmr
        local str = string.format("%s W: %d L: %d MMR: %s", bracket, target.w, target.l, mmrRange)
        tooltip:AddLine(str)
        tooltip:Show()
      end
    end
  end

  if PvPAuditConfig["showAudit"] and PvPAuditPlayerCache[name] ~= nil then
    for _, bracket in pairs(BRACKETS) do
      local exp = PvPAuditPlayerCache[name][bracket]["highest"]
      local cr = PvPAuditPlayerCache[name][bracket]["cr"]
      local str = string.format("%s %d EXP [%d CR]", bracket, exp, cr)
      tooltip:AddLine(str)
      tooltip:Show()
    end
  end

  if notesDb[name] ~= nil then
    tooltip:AddLine(notesDb[name])
    tooltip:Show()
  end
end

local function tooltipOnShow(tooltip)
  if tooltip:NumLines() > 0 then
    local line = _G[tooltip:GetName() .. "TextLeft1"]
    local txt = line:GetText()

    local _, results = C_LFGList.GetSearchResults()
    for _, r in pairs(results) do
      local searchResultInfo = C_LFGList.GetSearchResultInfo(r);
      local leader = searchResultInfo.leaderName
      local groupName = searchResultInfo.name
      if txt == groupName then
        addToTooltip(tooltip, leader)
      end
    end

    local applicants = C_LFGList.GetApplicants()
    if not applicants then return end
    for _, a in pairs(applicants) do
      local name = C_LFGList.GetApplicantMemberInfo(a, 1)
      if txt == name then
        addToTooltip(tooltip, name)
      end
    end
  end
end

local function tooltipUnitUpdate(tooltip)
  if tooltip == nil then return end
  local _, unit = tooltip:GetUnit()
  if not unit then return end

  local name = GetUnitName(unit, true)
  addToTooltip(tooltip, name)
end

local function eventHandler(self, event, unit, ...)
end

function PvPAuditLoadHoverModule()
  eventFrame = CreateFrame("Frame", "PvPAuditHoverEventFrame", UIParent)
  eventFrame:SetScript("OnEvent", eventHandler)

  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, tooltipUnitUpdate)
  GameTooltip:HookScript("OnShow", tooltipOnShow)

  local playerAndRealm = PvPAuditGetPlayerAndRealm()
  arenaDb = PvPAuditArenaHistory[playerAndRealm]
  notesDb = PvPAuditArenaHistory["notes"]
end