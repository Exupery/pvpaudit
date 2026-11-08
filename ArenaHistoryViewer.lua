local BRACKETS = { "2v2", "3v3", "Shuffle" }
local CATEGORIES = { "Maps", "Comps", "Players" }

local SHUFFLE = "Shuffle"
local SHUFFLE_COMPS_LABEL = "Specs"
local SHUFFLE_PLAYERS_NOTE = "Individual player tracking not available for solo shuffle"
local SHUFFLE_SPEC_SECTIONS = {
  { title = "With Healers", group = "with", healers = true },
  { title = "With DPS", group = "with", healers = false },
  { title = "Against Healers", group = "against", healers = true },
  { title = "Against DPS", group = "against", healers = false },
}
local SECTION_COLOR = { 1, 0.82, 0 }
local MUTED_COLOR = { 0.5, 0.5, 0.5 }
local SPEC_INDENT = 10

local IDENTIFIER = "Identifier"

local arenaDb = nil
local eventFrame = nil

local viewer = CreateFrame("Frame", "PvPAuditHistoryViewer", UIParent, "BasicFrameTemplateWithInset")
viewer:SetClampedToScreen(true)
viewer:SetMovable(true)
viewer:EnableMouse(true)
viewer:SetAlpha(0.8)
table.insert(UISpecialFrames, viewer:GetName()) -- close with ESC

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

local function createCell(row, colHeader, text, anchor, anchorPoint, font)
  local key = tableDataFrame:GetName()..row..colHeader
  local cell = cells[key]

  if cell == nil then
    cell = tableDataFrame:CreateFontString(key, "ARTWORK", "GameTooltipTextSmall")
    cell:SetPoint("TOPLEFT", anchor, anchorPoint, 0, 0)
    cell:SetWidth(_G[tableFrame:GetName()..colHeader]:GetWidth() - 1)
    cell:SetHeight(_G[tableFrame:GetName()..IDENTIFIER]:GetHeight())
    if colHeader == IDENTIFIER then
      cell:SetJustifyH("LEFT")
    else
      cell:SetJustifyH("RIGHT")
    end
    cells[key] = cell
  end

  cell:SetFont(font, _G[tableFrame:GetName()..IDENTIFIER]:GetHeight())
  cell:SetText(text)
  cell:Show()
  return cell
end

local function specTexture(frame, specId)
  local size = _G[tableFrame:GetName()..IDENTIFIER]:GetHeight() * 0.8
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

local function rowHeight()
  return _G[tableFrame:GetName()..IDENTIFIER]:GetHeight()
end

local function rowOffset(row)
  return -(row - 1) * rowHeight()
end

local function createWinLossCells(row, t, idCell, font)
  local ratio = t.w / (t.w + t.l) * 100
  if ratio < 1 then ratio = 0 end

  local wCell = createCell(row, "Wins", t.w, idCell, "TOPRIGHT", font)
  local lCell = createCell(row, "Losses", t.l, wCell, "TOPRIGHT", font)
  createCell(row, "Ratio", string.format("%.0f", ratio).."%     ", lCell, "TOPRIGHT", font)
end

-- A row with only text in the identifier column (e.g. a section heading)
local function createTextRow(row, text, color, indent, font)
  local key = tableDataFrame:GetName()..row.."Text"
  local cell = cells[key]

  if cell == nil then
    cell = tableDataFrame:CreateFontString(key, "ARTWORK", "GameTooltipTextSmall")
    cell:SetHeight(rowHeight())
    cell:SetJustifyH("LEFT")
    cells[key] = cell
  end

  cell:ClearAllPoints()
  cell:SetPoint("TOPLEFT", tableDataFrame, "TOPLEFT", indent, rowOffset(row))
  cell:SetWidth(_G[tableFrame:GetName()..IDENTIFIER]:GetWidth() - 1 - indent)
  cell:SetFont(font, rowHeight())
  cell:SetTextColor(unpack(color))
  cell:SetText(text)
  cell:Show()
  return cell
end

local function createSpecCell(row, text, icon, font)
  local key = tableDataFrame:GetName()..row.."Spec"
  local cell = cells[key]
  local height = rowHeight()

  if cell == nil then
    cell = CreateFrame("Frame", key, tableDataFrame)
    cell:SetSize(_G[tableFrame:GetName()..IDENTIFIER]:GetWidth() - 1, height)
    cell:SetPoint("TOPLEFT", tableDataFrame, "TOPLEFT", 0, rowOffset(row))
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetSize(height * 0.8, height * 0.8)
    cell.icon:SetPoint("LEFT", cell, "LEFT", SPEC_INDENT, 0)
    cell.text = cell:CreateFontString(nil, "ARTWORK", "GameTooltipTextSmall")
    cell.text:SetPoint("LEFT", cell.icon, "RIGHT", 4, 0)
    cell.text:SetPoint("RIGHT", cell, "RIGHT", 0, 0)
    cell.text:SetHeight(height)
    cell.text:SetJustifyH("LEFT")
    cells[key] = cell
  end

  cell.icon:SetTexture(icon)
  cell.text:SetFont(font, height)
  cell.text:SetText(text)
  cell:Show()
  return cell
end

-- Returns the display name and icon for `specId` and whether it's a healer spec (tank specs
-- are grouped with DPS)
local function specInfo(specId)
  local _, specName, _, icon, role, _, className = GetSpecializationInfoByID(specId)
  if not specName then return nil end
  return specName.." "..className, icon, role == "HEALER"
end

local function populateShuffleSpecs(font)
  local row = 1
  for _, section in ipairs(SHUFFLE_SPEC_SECTIONS) do
    createTextRow(row, section.title, SECTION_COLOR, 0, font)
    row = row + 1

    local entries = {}
    for specId, t in pairs(arenaDb.shuffleSpecs[section.group]) do
      local name, icon, isHealer = specInfo(specId)
      if name and isHealer == section.healers then
        table.insert(entries, { name = name, icon = icon, t = t })
      end
    end
    table.sort(entries, function(a, b) return a.name < b.name end)

    if #entries == 0 then
      createTextRow(row, "None", MUTED_COLOR, SPEC_INDENT, font)
      row = row + 1
    end
    for _, entry in ipairs(entries) do
      local cell = createSpecCell(row, entry.name, entry.icon, font)
      createWinLossCells(row, entry.t, cell, font)
      row = row + 1
    end
  end
  return row - 1
end

local function showShufflePlayersNote(font)
  local key = tableDataFrame:GetName().."ShufflePlayersNote"
  local note = cells[key]

  if note == nil then
    note = tableDataFrame:CreateFontString(key, "ARTWORK", "GameTooltipTextSmall")
    note:SetPoint("TOP", tableScrollFrame, "TOP", 0, -rowHeight())
    note:SetWidth(tableScrollFrame:GetWidth() - 20)
    note:SetJustifyH("CENTER")
    note:SetTextColor(unpack(MUTED_COLOR))
    cells[key] = note
  end

  note:SetFont(font, rowHeight() * 0.8)
  note:SetText(SHUFFLE_PLAYERS_NOTE)
  note:Show()
end

local function populateBracketTable(data, cat, font)
  if not data then return 0 end

  local row = 1
  local idCellAnchor = tableDataFrame
  local idCellAnchorPoint = "TOPLEFT"
  local sorted = sortTableKeys(data)
  for _, k in ipairs(sorted) do
    local idCell = nil
    if cat == "comps" then
      idCell = createCompCell(row, k, idCellAnchor, idCellAnchorPoint)
    else
      idCell = createCell(row, IDENTIFIER, k, idCellAnchor, idCellAnchorPoint, font)
    end
    createWinLossCells(row, data[k], idCell, font)
    row = row + 1
    idCellAnchor = idCell
    idCellAnchorPoint = "BOTTOMLEFT"
  end
  return row - 1
end

local function populateTable()
  clearTable()
  tableScrollFrame:SetVerticalScroll(0)
  local bracketId = PanelTemplates_GetSelectedTab(bracketTabs)
  local catId = PanelTemplates_GetSelectedTab(categoryTabs)
  if not bracketId or not catId then return end

  local bracket = BRACKETS[bracketId]
  local cat = CATEGORIES[catId]:lower()
  local font = PVPAUDIT_FONTS[PvPAuditConfig["fontstyle"]]

  local rows = 0
  if bracket == SHUFFLE and cat == "players" then
    showShufflePlayersNote(font)
  elseif bracket == SHUFFLE and cat == "comps" then
    rows = populateShuffleSpecs(font)
  else
    rows = populateBracketTable(arenaDb[cat][bracket], cat, font)
  end

  -- size the scroll child to fit every row so tables taller than the window can be scrolled
  tableScrollChild:SetHeight(math.max(tableScrollFrame:GetHeight(), rows * rowHeight() + 12))
end

-- Solo Shuffle tracks W/L with/against specs in place of comps
local function categoryLabel(catId)
  local bracket = BRACKETS[PanelTemplates_GetSelectedTab(bracketTabs)]
  if CATEGORIES[catId] == "Comps" and bracket == SHUFFLE then
    return SHUFFLE_COMPS_LABEL
  end
  return CATEGORIES[catId]
end

local function updateLabels()
  for i = 1, table.getn(CATEGORIES) do
    local tab = _G[categoryTabs:GetName().."Tab"..i]
    local label = categoryLabel(i)
    if tab:GetText() ~= label then
      tab:SetText(label)
      PanelTemplates_TabResize(tab)
    end
  end

  local label = categoryLabel(PanelTemplates_GetSelectedTab(categoryTabs))
  identifierHeading:SetText(string.sub(label, 1, label:len() - 1))
end

local function selectBracket(tab)
  PanelTemplates_SetTab(bracketTabs, tab:GetID())
  updateLabels()
  populateTable()
end

local function selectCategory(tab)
  PanelTemplates_SetTab(categoryTabs, tab:GetID())
  updateLabels()
  populateTable()
end

local function drawBracketTabs()
  local xOffset = 10
  for i, bracket in pairs(BRACKETS) do
    local tab = CreateFrame("Button", bracketTabs:GetName().."Tab"..i, bracketTabs, "CharacterFrameTabTemplate")
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
  local xOffset = -165
  local anchor = viewer
  local anchorPoint = "BOTTOMRIGHT"
  for i, cat in pairs(CATEGORIES) do
    local tab = CreateFrame("Button", categoryTabs:GetName().."Tab"..i, categoryTabs, "CharacterFrameTabTemplate")
    tab:SetID(i)
    tab:SetText(cat)
    tab:SetPoint("TOPRIGHT", anchor, anchorPoint, xOffset, 0)
    tab:SetScript("OnClick", selectCategory)
    anchor = tab
    anchorPoint = "TOPLEFT"
    xOffset = 155
  end
  PanelTemplates_SetNumTabs(categoryTabs, table.getn(CATEGORIES))
  PanelTemplates_SetTab(categoryTabs, table.getn(CATEGORIES)) -- these tabs get drawn right to left
end

local function createColumnHeader(text, anchor, anchorPoint, widthPercent)
  local header = tableFrame:CreateFontString(tableFrame:GetName()..text, "ARTWORK", "GameFontNormal")
  header:SetPoint("TOPLEFT", anchor, anchorPoint, 0, 0)
  header:SetHeight(19)
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
  local wins = createColumnHeader("Wins", identifierHeading, "TOPRIGHT", 0.12)
  local losses = createColumnHeader("Losses", wins, "TOPRIGHT", 0.12)
  local ratio = createColumnHeader("Ratio", losses, "TOPRIGHT", 0.25)

  dataBorderFrame:SetPoint("BOTTOMLEFT", tableFrame, "BOTTOMLEFT", -4, -2)
  dataBorderFrame:SetWidth(tableFrame:GetWidth() + 1)
  dataBorderFrame:SetHeight(tableFrame:GetHeight() - identifierHeading:GetHeight() - 1)

  tableScrollFrame:SetPoint("BOTTOMLEFT", dataBorderFrame, "BOTTOMLEFT", -4, 4)
  tableScrollFrame:SetWidth(dataBorderFrame:GetWidth() - 22)
  tableScrollFrame:SetHeight(dataBorderFrame:GetHeight() - 10)

  tableScrollChild:SetHeight(tableScrollFrame:GetHeight())
  tableScrollChild:SetWidth(tableScrollFrame:GetWidth())

  tableDataFrame:SetPoint("TOPLEFT", tableScrollChild, "TOPLEFT", 11, 0)
  tableDataFrame:SetWidth(tableScrollFrame:GetWidth())
  tableDataFrame:SetHeight(tableScrollFrame:GetHeight() - 12)
end

local function drawMainFrame()
  if viewer:GetHeight() ~= 0 then return end

  viewer:SetWidth(585)
  viewer:SetHeight(480)
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
