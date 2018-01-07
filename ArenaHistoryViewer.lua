local BRACKETS = { "2v2", "3v3" }
local CATEGORIES = { "Maps", "Comps", "Players" }

local arenaDb = nil
local eventFrame = nil

local viewer = CreateFrame("Frame", "PvPAuditHistoryViewer", UIParent, "BasicFrameTemplateWithInset")
viewer:SetClampedToScreen(true)
viewer:SetMovable(true)
viewer:EnableMouse(true)
viewer:SetAlpha(0.8)

local bracketTabs = CreateFrame("Frame", "PvPAuditBracketTabs", viewer)
local categoryTabs = CreateFrame("Frame", "PvPAuditCategoryTabs", viewer)
local tableFrame = CreateFrame("Frame", "PvPAuditViewerTable", viewer)
local identifierHeading = nil

local function showViewer()
  viewer:Show()
end

local function eventHandler(self, event, unit, ...)
end

local function selectBracket(tab)
  PanelTemplates_SetTab(bracketTabs, tab:GetID())
end

local function selectCategory(tab)
  PanelTemplates_SetTab(categoryTabs, tab:GetID())
  local cat = CATEGORIES[tab:GetID()]
  identifierHeading:SetText(string.sub(cat, 1, cat:len() - 1))
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

local function drawCategoryTabs()
  local xOffset = 0
  local anchor = viewer
  local anchorPoint = "BOTTOMRIGHT"
  for i, cat in pairs(CATEGORIES) do
    local tab = CreateFrame("Button", categoryTabs:GetName().."Tab"..i, categoryTabs, "CharacterFrameTabButtonTemplate")
    tab:SetID(i)
    tab:SetText(cat)
    tab:SetPoint("TOPRIGHT", anchor, anchorPoint, xOffset, 0)
    tab:SetScript("OnClick", selectCategory)
    anchor = tab
    anchorPoint = "TOPLEFT"
    xOffset = 15
  end
  PanelTemplates_SetNumTabs(categoryTabs, table.getn(CATEGORIES))
  PanelTemplates_SetTab(categoryTabs, table.getn(CATEGORIES)) -- these tabs get drawn right to left
end

local function createColumnHeader(text, anchor, anchorPoint, widthPercent)
  local header = tableFrame:CreateFontString(tableFrame:GetName()..text, "ARTWORK", "GameFontNormal")
  header:SetPoint("TOPLEFT", anchor, anchorPoint, 0, 0)
  header:SetWidth(tableFrame:GetWidth() * widthPercent)
  header:SetJustifyH("CENTER")
  header:SetText(text)
  header:Show()
  return header
end

local function drawTable()
  tableFrame:SetPoint("BOTTOMLEFT", viewer, "BOTTOMLEFT", 10, 5)
  tableFrame:SetWidth(viewer:GetWidth() - 15)
  tableFrame:SetHeight(viewer:GetHeight() - 35)

  identifierHeading = createColumnHeader("Identifier", tableFrame, "TOPLEFT", 0.45)
  local wins = createColumnHeader("Wins", identifierHeading, "TOPRIGHT", 0.15)
  local losses = createColumnHeader("Losses", wins, "TOPRIGHT", 0.15)
  local ratio = createColumnHeader("Ratio", losses, "TOPRIGHT", 0.25)
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
  drawCategoryTabs()
  drawTable()

  selectCategory(_G[categoryTabs:GetName().."Tab"..table.getn(CATEGORIES)])
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