local BRACKETS = { "2v2", "3v3" }

local arenaDb = nil
local eventFrame = nil

local viewer = CreateFrame("Frame", "PvPAuditHistoryViewer", UIParent, "BasicFrameTemplateWithInset")
viewer:SetClampedToScreen(true)
viewer:SetMovable(true)
viewer:EnableMouse(true)
viewer:SetAlpha(0.8)

local bracketTabs = CreateFrame("Frame", "PvPAuditBracketTabs", viewer)

local function showViewer()
  viewer:Show()
end

local function eventHandler(self, event, unit, ...)
end

local function selectBracket(tab)
  PanelTemplates_SetTab(bracketTabs, tab:GetID())
end

local function drawBracketTabs()
  local xOffset = 0
  for i, bracket in pairs(BRACKETS) do
    local tab = CreateFrame("Button", bracketTabs:GetName().."Tab"..i, bracketTabs, "CharacterFrameTabButtonTemplate")
    tab:SetID(i)
    tab:SetText(bracket)
    tab:SetPoint("TOPLEFT", viewer, "BOTTOMLEFT", xOffset, 0)
    tab:SetScript("OnClick", selectBracket)
    xOffset = tab:GetWidth() - 15
  end
  PanelTemplates_SetNumTabs(bracketTabs, table.getn(BRACKETS))
  PanelTemplates_SetTab(bracketTabs, 1)
end

local function drawMainFrame()
  if viewer:GetHeight() ~= 0 then return end

  viewer:SetWidth(512)
  viewer:SetHeight(256)
  viewer:SetResizable(false)

  viewer:RegisterForDrag("LeftButton", "RightButton")
  viewer:SetScript("OnDragStart", viewer.StartMoving)
  viewer:SetScript("OnDragStop", viewer.StopMovingOrSizing)
  viewer:SetPoint("CENTER")

  drawBracketTabs()

  viewer:Hide()
end

function PvPAuditLoadViewerModule()
  eventFrame = CreateFrame("Frame", "PvPAuditViewerEventFrame", UIParent)
  eventFrame:SetScript("OnEvent", eventHandler)

  local playerAndRealm = PvPAuditGetPlayerAndRealm()
  arenaDb = PvPAuditArenaHistory[playerAndRealm]

  drawMainFrame()
end

function PvPAuditHistoryCmd(arg)
  showViewer()
end