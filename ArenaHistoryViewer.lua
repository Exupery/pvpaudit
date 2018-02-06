local BRACKETS = { "2v2", "3v3" }
local CATEGORIES = { "Maps", "Comps", "Players" }

local IDENTIFIER = "Identifier"
local FONT = "Fonts\\FRIZQT__.TTF"

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
local dataBorderFrame = CreateFrame("Frame", "PvPAuditViewerTableDataBorder", tableFrame, "InsetFrameTemplate2")
local tableScrollFrame = CreateFrame("ScrollFrame", "PvPAuditViewerScroll", dataBorderFrame, "UIPanelScrollFrameTemplate")
local tableScrollChild = CreateFrame("Frame", "PvPAuditViewerScrollChild", tableScrollFrame)
local tableDataFrame = CreateFrame("Frame", "PvPAuditViewerTableData", tableScrollChild)
tableScrollFrame:SetScrollChild(tableScrollChild)

local cells = {}
local identifierHeading = nil

local function sortTableKeys(tbl)
  local sorted = {}
  for k, v in pairs(tbl) do
    table.insert(sorted, k)
  end
  table.sort(sorted)
  return sorted
end

local function createCell(row, colHeader, text, anchor, anchorPoint)
  local key = tableDataFrame:GetName()..row..colHeader
  local cell = cells[key]

  if cell == nil then
    cell = tableDataFrame:CreateFontString(key, "ARTWORK", "GameTooltipTextSmall")
    cell:SetPoint("TOPLEFT", anchor, anchorPoint, 0, 0)
    cell:SetWidth(_G[tableFrame:GetName()..colHeader]:GetWidth() - 3)
    if colHeader == IDENTIFIER then
      cell:SetJustifyH("LEFT")
    else
      cell:SetJustifyH("RIGHT")
    end
    cell:SetFont(FONT, _G[tableFrame:GetName()..IDENTIFIER]:GetHeight() * 0.75)
    cells[key] = cell
  end

  cell:SetText(text)
  cell:Show()
  return cell
end

local function specTexture(frame, specId)
  local size = _G[tableFrame:GetName()..IDENTIFIER]:GetHeight()
  local texture = frame:CreateTexture(nil, "ARTWORK")
  local _, _, _, icon = GetSpecializationInfoByID(specId)
  texture:SetTexture(icon)
  texture:SetSize(size, size)
  return texture
end

local function getSpecsFromComp(comp)
  local specs = {}
  local startIdx = 1
  local endIdx = nil
  for s = 1, 3 do
    local endIdx = comp:find("_", startIdx, true)
    if endIdx == nil then
      endIdx = comp:len()
    else
      endIdx = endIdx - 1
    end
    local spec = comp:sub(startIdx, endIdx)
    if spec and spec:len() > 0 then
      table.insert(specs, spec)
    end
    startIdx = endIdx + 2
  end
  return specs
end

local function createCompCell(row, comp, anchor, anchorPoint)
  local key = tableDataFrame:GetName()..row.."Comp"
  local cell = cells[key]

  if cell == nil then
    cell = CreateFrame("Frame", key, anchor)
    local width = _G[tableFrame:GetName()..IDENTIFIER]:GetWidth() - 3
    local height = _G[tableFrame:GetName()..IDENTIFIER]:GetHeight()
    cell:SetSize(width, height)
    cell:SetPoint("TOPLEFT", anchor, anchorPoint, 0, 0)
    cells[key] = cell
  end

  local specAnchor = cell
  local specAnchorPoint = "CENTER"
  local xOffset = -28
  for _, specId in pairs(getSpecsFromComp(comp)) do
    local spec = specTexture(cell, specId)
    spec:SetPoint("LEFT", specAnchor, specAnchorPoint, xOffset, 0)
    spec:Show()
    specAnchor = spec
    specAnchorPoint = "RIGHT"
    xOffset = 2
    cells[key..specId] = spec
  end

  cell:Show()
  return cell
end

local function clearTable()
  for _, cell in pairs(cells) do
    cell:Hide()
  end
end

local function populateTable()
  clearTable()
  local bracketId = PanelTemplates_GetSelectedTab(bracketTabs)
  local catId = PanelTemplates_GetSelectedTab(categoryTabs)
  if not bracketId or not catId then return end

  local bracket = BRACKETS[bracketId]
  local cat = CATEGORIES[catId]:lower()
  local data = arenaDb[cat][bracket]
  if not data then return end
  local row = 1
  local idCellAnchor = tableDataFrame
  local idCellAnchorPoint = "TOPLEFT"
  local sorted = sortTableKeys(data)
  for _, k in ipairs(sorted) do
    local t = data[k]
    local ratio = t.w / (t.w + t.l) * 100

    local idCell = nil
    if cat == "comps" then
      idCell = createCompCell(row, k, idCellAnchor, idCellAnchorPoint)
    else
      idCell = createCell(row, IDENTIFIER, k, idCellAnchor, idCellAnchorPoint)
    end
    local wCell = createCell(row, "Wins", t.w, idCell, "TOPRIGHT")
    local lCell = createCell(row, "Losses", t.l, wCell, "TOPRIGHT")
    local rCell = createCell(row, "Ratio", string.format("%.1f", ratio).."%     ", lCell, "TOPRIGHT")
    row = row + 1
    idCellAnchor = idCell
    idCellAnchorPoint = "BOTTOMLEFT"
  end
end

local function selectBracket(tab)
  PanelTemplates_SetTab(bracketTabs, tab:GetID())
  populateTable()
end

local function selectCategory(tab)
  PanelTemplates_SetTab(categoryTabs, tab:GetID())
  local cat = CATEGORIES[tab:GetID()]
  identifierHeading:SetText(string.sub(cat, 1, cat:len() - 1))
  populateTable()
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
  header:SetHeight(18)
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

  identifierHeading = createColumnHeader(IDENTIFIER, tableFrame, "TOPLEFT", 0.5)
  local wins = createColumnHeader("Wins", identifierHeading, "TOPRIGHT", 0.15)
  local losses = createColumnHeader("Losses", wins, "TOPRIGHT", 0.15)
  local ratio = createColumnHeader("Ratio", losses, "TOPRIGHT", 0.2)

  dataBorderFrame:SetPoint("BOTTOMLEFT", tableFrame, "BOTTOMLEFT", -4, -2)
  dataBorderFrame:SetWidth(tableFrame:GetWidth() + 1)
  dataBorderFrame:SetHeight(tableFrame:GetHeight() - identifierHeading:GetHeight() - 1)

  tableScrollFrame:SetPoint("BOTTOMLEFT", dataBorderFrame, "BOTTOMLEFT", -4, 4)
  tableScrollFrame:SetWidth(dataBorderFrame:GetWidth() - 22)
  tableScrollFrame:SetHeight(dataBorderFrame:GetHeight() - 10)

  tableScrollChild:SetHeight(tableScrollFrame:GetHeight())
  tableScrollChild:SetWidth(tableScrollFrame:GetWidth())

  tableDataFrame:SetPoint("BOTTOMLEFT", tableScrollChild, "BOTTOMLEFT", 11, 12)
  tableDataFrame:SetWidth(tableScrollFrame:GetWidth())
  tableDataFrame:SetHeight(tableScrollFrame:GetHeight() - 12)
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

local function showViewer()
  populateTable()
  viewer:Show()
end

local function eventHandler(self, event, unit, ...)
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