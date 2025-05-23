SLASH_PVPAUDIT1 = "/pvpaudit"
SLASH_PVPAUDIT2 = "/pa"
BINDING_HEADER_PVPAUDIT = "PvPAudit"
BINDING_NAME_PVPAUDIT1 = "Audit the current target"

local TARGET = "target"
local BRACKET_ORDER = { 7, 1, 2, 3, 9, 4 }
local BRACKETS = {
  [1] = "2v2",
  [2] = "3v3",
  [3] = "5v5",
  [4] = "RBG",
  [7] = "Shuffle",
  [9] = "Blitz"
}
local MAX_CACHE_AGE = 2592000 -- 30 DAYS

local DEFAULT_FONT = "Arial"

PVPAUDIT_FONTS = {
  Arial = "Fonts\\ARIALN.TTF",
  FritzQuad = "Fonts\\FRIZQT__.TTF",
  Morpheus = "Fonts\\MORPHEUS.ttf",
  Skurri = "Fonts\\skurri.ttf",
  Emblem = "Interface\\Addons\\PvPAudit\\Fonts\\Emblem.ttf",
  SfDiegoSans = "Interface\\Addons\\PvPAudit\\Fonts\\SF Diego Sans.ttf",
  koKR = "Fonts\\2002.ttf",
  ruRU = "Fonts\\ARIALN.TTF",
  zhCN = "Fonts\\ARKai_T.ttf",
  zhTW = "Fonts\\bkAI00M.ttf",
}

local eventFrame = nil
local optionsFrame = nil
local config = {}
local tempConfig = {}

local achievements = {
  [1174] = "Arena Master",
  [2091] = "Gladiator",
  [6941] = "Hero of the Horde",
  [6942] = "Hero of the Alliance"
}

local rankOneAchievements = {
  -- TBC
  [418] = "Merciless Gladiator: Season 2",
  [419] = "Vengeful Gladiator: Season 3",
  [420] = "Brutal Gladiator: Season 4",
  -- WotLK
  [3336] = "Deadly Gladiator: Season 5",
  [3436] = "Furious Gladiator: Season 6",
  [3758] = "Relentless Gladiator: Season 7",
  [4599] = "Wrathful Gladiator: Season 8",
  -- Cata
  [6002] = "Vicious Gladiator: Season 9",
  [6124] = "Ruthless Gladiator: Season 10",
  [6938] = "Cataclysmic Gladiator: Season 11",
  -- MoP
  [8214] = "Malevolent Gladiator: Season 12",
  [8791] = "Tyrannical Gladiator: Season 13",
  [8643] = "Grievous Gladiator: Season 14",
  [8666] = "Prideful Gladiator: Season 15",
  -- WoD
  [9232] = "Primal Gladiator: Warlords Season 1",
  [10096] = "Wild Gladiator: Warlords Season 2",
  [10097] = "Warmongering Gladiator: Warlords Season 3",
  --Legion
  [11012] = "Vindictive Gladiator: Legion Season 1",
  [11014] = "Fearless Gladiator: Legion Season 2",
  [11037] = "Cruel Gladiator: Legion Season 3",
  [11062] = "Ferocious Gladiator: Legion Season 4",
  [12010] = "Fierce Gladiator: Legion Season 5",
  [12134] = "Dominant Gladiator: Legion Season 6",
  [12185] = "Demonic Gladiator: Legion Season 7",
  -- BfA
  [12945] = "Dread Gladiator: Battle for Azeroth Season 1",
  [13200] = "Sinister Gladiator: Battle for Azeroth Season 2",
  [13630] = "Notorious Gladiator: Battle for Azeroth Season 3",
  [13957] = "Corrupted Gladiator: Battle for Azeroth Season 4",
  -- SL
  [14690] = "Sinful Gladiator: Shadowlands Season 1",
  [14973] = "Unchained Gladiator: Shadowlands Season 2",
  [15353] = "Cosmic Gladiator: Shadowlands Season 3",
  [15606] = "Eternal Gladiator: Shadowlands Season 4",
  -- DF
  [15951] = "Crimson Gladiator: Dragonflight Season 1",
  [16734] = "Crimson Legend: Dragonflight Season 1",
  [17764] = "Obsidian Gladiator: Dragonflight Season 2",
  [17767] = "Obsidian Legend: Dragonflight Season 2",
  [19132] = "Verdant Gladiator: Dragonflight Season 3",
  [19131] = "Verdant Legend: Dragonflight Season 3",
  [19454] = "Draconic Gladiator: Dragonflight Season 4",
  [19453] = "Draconic Legend: Dragonflight Season 4",
  -- TWW
  [40380] = "Forged Gladiator: The War Within Season 1",
  [40381] = "Forged Legend: The War Within Season 1",
  [41354] = "Prized Gladiator: The War Within Season 2",
  [41355] = "Prized Legend: The War Within Season 2"
}

local statistics = {
  [BRACKETS[1]] = 370,
  [BRACKETS[2]] = 595,
  [BRACKETS[3]] = 596,
  [BRACKETS[4]] = nil
}

local rbgRatings = {
  [1100] = {5330, 5345},
  [1200] = {5331, 5346},
  [1300] = {5332, 5347},
  [1400] = {5333, 5348},
  [1500] = {5334, 5349},
  [1600] = {5335, 5350},
  [1700] = {5336, 5351},
  [1800] = {5337, 5352},
  [1900] = {5359, 5338},
  [2000] = {5339, 5353},
  [2100] = {5340, 5354},
  [2200] = {5341, 5355},
  [2300] = {5357, 5342},
  [2400] = {5343, 5356}
}

local auditTarget = TARGET
local targetCurrentRatings = {}

local printTo = nil

local auditBracket = nil
local groupAuditTargets = {}
local groupAuditsCompleted = 0
local groupAuditTime = 0

local function colorPrint(msg)
  print("|cffebff00" .. msg)
end

local function classColorPrint(msg, class)
  local color = string.format("|c%s", RAID_CLASS_COLORS[class]["colorStr"])
  print(color .. msg)
end

local function errorPrint(err)
  print("|cffff0000" .. err)
end

local function output(msg)
  if printTo == nil then
    print(msg)
  else
    SendChatMessage(msg, printTo)
  end
end

local function sortedKeys(tbl)
  local sorted = {}
  for i, _ in pairs(tbl) do
    table.insert(sorted, i)
  end
  table.sort(sorted)

  return sorted
end

local function printPlayerInfo(playerSlug)
  local name = PvPAuditPlayerCache[playerSlug]["name"]
  local realm = PvPAuditPlayerCache[playerSlug]["realm"]
  local auditDesc = auditBracket == nil and "PvPAudit" or auditBracket .. " audit"
  local str = string.format("%s for %s %s", auditDesc, name, realm)

  if printTo == nil then
    classColorPrint(str, PvPAuditPlayerCache[playerSlug]["localeIndependentClass"])
  else
    output(str)
  end
end

-- Print player's ratings for a single bracket
local function printRating(playerSlug, bracket)
  if bracket == "5v5" and not PvPAuditConfig["show5v5"] then
    return
  end
  local highest = PvPAuditPlayerCache[playerSlug][bracket]["highest"]
  local cr = PvPAuditPlayerCache[playerSlug][bracket]["cr"]

  local str = auditBracket and "" or (bracket .. "    ")
  str = str .. cr .. " CR "
  if printTo == nil then str = str .. "|cffb2b2b2" end
  if highest ~= nil then
    str = str .. "[" .. highest .. " EXP]"
  end

  output(str)
end

-- Print player's ratings for ALL brackets
local function printRatings(playerSlug)
  for _, i in pairs(BRACKET_ORDER) do
    bracket = BRACKETS[i]
    printRating(playerSlug, bracket)
  end
end

local function printAchievements(playerSlug)
  local playerAchievements = PvPAuditPlayerCache[playerSlug]["achievements"]

  if next(playerAchievements) ~= nil then
    output("Notable Achievements [account-wide]")
    for k, _ in pairs(playerAchievements) do
      output(k)
    end
  end

end

-- Prints ratings for ALL brackets and achievements
local function printAll(playerSlug)
  printRatings(playerSlug)
  printAchievements(playerSlug)
end

-- Prints ratings for specified bracket only
local function printBracket(playerSlug, bracket)
  printRating(playerSlug, bracket)
end

local function printAuditResults(playerSlug)
  printPlayerInfo(playerSlug)
  if auditBracket == nil then
    printAll(playerSlug)
  else
    printBracket(playerSlug, auditBracket)
  end
end

local function init()
  ClearAchievementComparisonUnit()
  ClearInspectPlayer()
end

local function cleanup(auditFunction)
  groupAuditsCompleted = groupAuditsCompleted + 1
  local nextTarget = groupAuditTargets[groupAuditsCompleted]
  if nextTarget ~= nil then
    auditFunction(nextTarget)
  else
    printTo = nil
    auditTarget = TARGET
    groupAuditTime = 0
    groupAuditsCompleted = 0
    groupAuditTargets = {}
    eventFrame:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
    eventFrame:UnregisterEvent("INSPECT_READY")
  end
end

local function getNameRealmSlug()
  local name, realm = UnitName(auditTarget)
  if realm == nil then realm = "" end
  local slug = name
  if realm ~= "" then
    slug = name .. "-" .. realm
  end

  return  name, realm, slug
end

local function audit(target)
  auditTarget = target
  init()

  local reset = true
  local canInspect = CanInspect(auditTarget, false)

  if canInspect then
    local name = UnitName(auditTarget)
    local inRange = UnitIsVisible(auditTarget) or CheckInteractDistance(auditTarget, 1)
    if inRange then
      reset = false
      eventFrame:RegisterEvent("INSPECT_READY")
      NotifyInspect(auditTarget)
    else
      local _, _, slug = getNameRealmSlug()
      if PvPAuditPlayerCache[slug] ~= nil then
        local elapsed = SecondsToTime(time() - PvPAuditPlayerCache[slug]["cachedAt"])
        output(name .. " out of range, using cached data from " .. elapsed .. " ago")
        printAuditResults(slug)
      else
        errorPrint(name .. " out of range")
      end
    end
  else
    errorPrint("Unable to audit")
  end

  if reset then cleanup(audit) end
end

local function auditGroup()
  local groupSize = GetNumGroupMembers()
  if not IsInRaid() then groupSize = groupSize - 1 end
  local group = IsInRaid() and "raid" or "party"
  for i = 1, groupSize do
    groupAuditTargets[i] = group .. i
  end

  if IsInRaid() then
    groupAuditsCompleted = 1
    audit(groupAuditTargets[1])
  else
    audit("player")
  end
end

local function cachePlayerInfo(name, realm, playerSlug)
  local _, localeIndependentClass = UnitClass(auditTarget)

  PvPAuditPlayerCache[playerSlug]["name"] = name
  PvPAuditPlayerCache[playerSlug]["realm"] = realm
  PvPAuditPlayerCache[playerSlug]["localeIndependentClass"] = localeIndependentClass
  PvPAuditPlayerCache[playerSlug]["cachedAt"] = time()
end

local function getCurrentRatings()
  targetCurrentRatings = {}

  for _, i in pairs(BRACKET_ORDER) do
    local b = BRACKETS[i]
    local cr = GetInspectArenaData(i)
    targetCurrentRatings[b] = cr
  end
end

local function getRbgHighest()
  local highest = 0
  for rating, ids in pairs(rbgRatings) do
    local completed = GetAchievementComparisonInfo(ids[1]) or GetAchievementComparisonInfo(ids[2])
    if completed and rating > highest then highest = rating end
  end

  if highest == 0 then
    return "--"
  else
    return highest .. "+"
  end
end

local function onUpdate(self, elapsed)
  if auditTarget ~= TARGET and groupAuditsCompleted < GetNumGroupMembers() then
    groupAuditTime = groupAuditTime + elapsed
    if groupAuditTime >= 1 then
      groupAuditTime = 0
      audit(auditTarget)
    end
  end
end

local function cacheRatings(playerSlug)
  for _, b in pairs(BRACKETS) do
    local highest
    if b == "RBG" then
      highest = getRbgHighest()
    elseif statistics[b] ~= nil then
      highest = GetComparisonStatistic(statistics[b])
      if tonumber(highest) == 1500 then highest = "< 1500" end
    end

    local cr = targetCurrentRatings[b]

    PvPAuditPlayerCache[playerSlug][b] = {}
    PvPAuditPlayerCache[playerSlug][b]["highest"] = highest
    PvPAuditPlayerCache[playerSlug][b]["cr"] = cr
  end
end

local function cacheAchievementsFromTable(playerAchievementsCache, achievementTable)
  for k, v in pairs(achievementTable) do
    local completed = GetAchievementComparisonInfo(k)
    if completed then
      playerAchievementsCache[v] = true
    end
  end
end

local function cacheAchievements(playerSlug)
  PvPAuditPlayerCache[playerSlug]["achievements"] = {}

  cacheAchievementsFromTable(PvPAuditPlayerCache[playerSlug]["achievements"], achievements)
  if PvPAuditConfig["showR1"] then
    cacheAchievementsFromTable(PvPAuditPlayerCache[playerSlug]["achievements"], rankOneAchievements)
  end
end

local function cacheAll(name, realm, slug)
  PvPAuditPlayerCache[slug] = {}

  cachePlayerInfo(name, realm, slug)
  cacheRatings(slug)
  cacheAchievements(slug)
end

local function onInspectReady()
  getCurrentRatings()
  eventFrame:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
  SetAchievementComparisonUnit(auditTarget)
end

local function onAchievementInspectReady()
  local name, realm, slug = getNameRealmSlug()

  cacheAll(name, realm, slug)
  printAuditResults(slug)
  cleanup(audit)
end

local function tidyCache()
  for slug, data in pairs(PvPAuditPlayerCache) do
    local age = time() - (data["cachedAt"] ~= nil and data["cachedAt"] or 0)
    if age > MAX_CACHE_AGE then
      PvPAuditPlayerCache[slug] = nil
    end
  end
end

local function updateConfig(key, value)
  PvPAuditConfig[key] = value
  local updated = PvPAuditConfig[key] == value
  if updated then
    config = PvPAuditConfig
  end
  return updated
end

local function createLabel(text, parent, xOffset, yOffset)
  local label = parent:CreateFontString("PvPAudit"..text.."Label", "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", xOffset, yOffset)
  label:SetText(text)
  return label
end

local function createDropDown(name, parent, callback, tableValues, selectedValue)
  local SelectBox = LibStub:GetLibrary("SelectBox")
  local dropdown = SelectBox:Create(name, parent, 120, callback, function() return tableValues end, selectedValue)
  dropdown:ClearAllPoints()
  dropdown:UpdateValue()
  return dropdown
end

local function setFontStyle(style)
  local font = PVPAUDIT_FONTS[style]
  if not font then return end
  config.fontstyle = style
end

local function fontStyleSelected(self)
  setFontStyle(self.value)
  updateConfig("fontstyle", self.value)
end

local function drawFontStyleOptions(parent, xOffset, yOffset)
  local label = createLabel("Font", parent, xOffset, yOffset)

  local fonts = sortedKeys(PVPAUDIT_FONTS)
  local selectedFont = config.fontstyle
  parent.fontstyle = createDropDown("PvPAuditFontStyle", parent, fontStyleSelected, fonts, selectedFont)
  parent.fontstyle:SetPoint("LEFT", label, "RIGHT", 0, 0)
end

local function drawConfigCheckOption(parent, xOffset, yOffset, title, description,
    uiOptionName, frameName, checked)
  local label = createLabel(title, parent, xOffset, yOffset)
  local callback = function (self, button, down)
    PvPAuditConfig[uiOptionName] = parent[uiOptionName]:GetChecked()
  end

  parent[uiOptionName] = CreateFrame("CheckButton", frameName, parent, "ChatConfigCheckButtonTemplate")
  parent[uiOptionName]:SetPoint("LEFT", label, "RIGHT", 0, 0)
  parent[uiOptionName].tooltip = description
  parent[uiOptionName]:SetChecked(checked)
  parent[uiOptionName]:SetScript("PostClick", callback)
  parent[uiOptionName]:Show()
end

local function drawHistoryTooltipOption(parent, xOffset, yOffset)
  drawConfigCheckOption(parent, xOffset, yOffset,
    "Show arena player history in tooltip",
    "If enabled arena W/L with player will appear in tooltips",
    "showHistory", "PvPAuditShowHistoryCheckBox", PvPAuditConfig["showHistory"])
end

local function drawAuditTooltipOption(parent, xOffset, yOffset)
  drawConfigCheckOption(parent, xOffset, yOffset,
    "Show arena audit results in tooltip",
    "If enabled the arena EXP/CR of previously audited players will appear in tooltips",
    "showAudit", "PvPAuditShowAuditCheckBox", PvPAuditConfig["showAudit"])
end

local function drawAuditOutputOptions(parent, xOffset, yOffset)
  drawConfigCheckOption(parent, xOffset, yOffset,
    "Include 5v5 in audit output",
    "If enabled audit output will include 5v5 EXP/CR",
    "show5v5", "PvPAuditShow5v5CheckBox", PvPAuditConfig["show5v5"])

  drawConfigCheckOption(parent, xOffset, yOffset - 40,
    "Include Rank One titles in audit output",
    "If enabled audit output will include any/all Rank 1 titles obtained",
    "showR1", "PvPAuditShowR1CheckBox", PvPAuditConfig["showR1"])
end

local function defaultConfig()
  return {
    fontstyle = DEFAULT_FONT,
    showHistory = true,
    showAudit = false,
    show5v5 = false,
    showR1 = true
  }
end

local function createDropdown(configKey, defaultValue, name, tooltip, options, getValue, setValue)
  local setting = Settings.RegisterProxySetting(optionsFrame, configKey, PvPAuditConfig, "string", name, defaultValue, getValue, setValue, setValue)
  Settings.CreateDropDown(optionsFrame, setting, options, tooltip)
end

local function createCheckBox(configKey, defaultValue, name, tooltip)
  local setting = Settings.RegisterProxySetting(optionsFrame, configKey, PvPAuditConfig, "boolean", name, defaultValue)
  Settings.CreateCheckBox(optionsFrame, setting, tooltip)
end

local function createFontDropdown()
  local function getOptions()
    local fonts = sortedKeys(PVPAUDIT_FONTS)
    local container = Settings.CreateControlTextContainer()
    for i, fontName in pairs(fonts) do
      container:Add(fontName, fontName)
    end
    return container:GetData()
  end

  local function getValue()
    return PvPAuditConfig["fontstyle"]
  end

  local function setValue(fontName)
    return PVPAUDIT_FONTS[fontName]
  end

  createDropdown("fontstyle", DEFAULT_FONT, "Font", "The font used in the arena partner history viewer", getOptions, getValue, setValue)
end

local function createOptionsPanel()
  config = PvPAuditConfig

  local xOffset = 20
  optionsFrame = CreateFrame("Frame", "PvPAuditOptions", UIParent)
  optionsFrame.name = "PvPAudit"
  local category, _ = Settings.RegisterCanvasLayoutCategory(optionsFrame, optionsFrame.name, optionsFrame.name)
  category.ID = optionsFrame.name
  Settings.RegisterAddOnCategory(category)

  optionsFrame.title = optionsFrame:CreateFontString("PvPAuditOptionsTitle", "OVERLAY", "GameFontNormalLarge")
  optionsFrame.title:SetPoint("TOPLEFT", xOffset, -20)
  optionsFrame.title:SetText("PvPAudit Options")

  drawFontStyleOptions(optionsFrame, xOffset, -60)
  drawHistoryTooltipOption(optionsFrame, xOffset, -100)
  drawAuditTooltipOption(optionsFrame, xOffset, -140)
  drawAuditOutputOptions(optionsFrame, xOffset, -180)

  optionsFrame.fontstyle:SetText(config.fontstyle)
end

local function createOptionsPanelNew()
  config = PvPAuditConfig
  optionsFrame = Settings.RegisterVerticalLayoutCategory("PvPAudit")

  createFontDropdown()

  createCheckBox("showHistory", true, "Show arena player history in tooltip",
    "If enabled arena W/L with player will appear in tooltips")
  createCheckBox("showAudit", false, "Show arena audit results in tooltip",
    "If enabled the arena EXP/CR of previously audited players will appear in tooltips")
  createCheckBox("show5v5", false, "Include 5v5 in audit output",
    "If enabled audit output will include 5v5 EXP/CR")
  createCheckBox("showR1", true, "Include Rank One titles in audit output",
    "If enabled audit output will include any/all Rank 1 titles obtained")

  Settings.RegisterAddOnCategory(optionsFrame)
end

local function addonLoaded()
  local firstLoad = false

  if not PvPAuditPlayerCache then
    PvPAuditPlayerCache = {}
  else
    tidyCache()
  end

  if not PvPAuditConfig then
    firstLoad = true
    PvPAuditConfig = defaultConfig()
  end
  for i, v in pairs(defaultConfig()) do
    if PvPAuditConfig[i] == nil then PvPAuditConfig[i] = v end
  end

  createOptionsPanel()

  if firstLoad then
    print("PvPAudit loaded, to audit the current target type /pvpaudit")
  end
end

local function eventHandler(self, event, unit, ...)
  if event == "INSPECT_ACHIEVEMENT_READY" then
    onAchievementInspectReady()
  elseif event == "INSPECT_READY" then
    onInspectReady()
  elseif event == "ADDON_LOADED" and string.lower(unit) == "pvpaudit" then
    addonLoaded()
  end
end

local function onLoad()
  eventFrame = CreateFrame("Frame", "PvPAuditEventFrame", UIParent)
  eventFrame:RegisterEvent("ADDON_LOADED")
  eventFrame:SetScript("OnEvent", eventHandler)
  eventFrame:SetScript("OnUpdate", onUpdate)
end

local function printHelp()
  colorPrint("PvPAudit player audit commands:")
  print("/pvpaudit - audit the current target")
  print("/pvpaudit instance - audit the current target and output to /instance")
  print("/pvpaudit party - audit the current target and output to /party")
  print("/pvpaudit raid - audit the current target and output to /raid")
  print("/pvpaudit officer - audit the current target and output to guild officer chat")
  colorPrint("PvPAudit arena history commands:")
  print("/pvpaudit h or /pvpaudit history - open arena history window")
  print("/pvpaudit clear players - removes all players from arena history")
  print("/pvpaudit clear comps - removes all team compositions from arena history")
  print("/pvpaudit clear maps - removes all maps from arena history")
  print("/pvpaudit clear all - removes ALL data from arena history")
  colorPrint("Other PvPAudit commands:")
  print("/pvpaudit config - open the configuration panel")
  print("/pvpaudit ? or /pvpaudit help - Print this list")
end

-- global function for keybinding audit current target
function pvpaudit()
  auditBracket = nil
  audit(TARGET)
end

SlashCmdList["PVPAUDIT"] = function(arg)
  if arg == "?" or arg == "help" then
    printHelp()
  elseif string.match(arg, "h.*") then
    PvPAuditHistoryCmd(arg)
  elseif string.match(arg, "config") then
    Settings.OpenToCategory("PvPAudit")
  elseif string.match(arg, "clear.*") then
    PvPArenaHistoryClear(arg)
  else
    if string.match(arg, "i.*") then
      printTo = "INSTANCE_CHAT"
    elseif string.match(arg, "p.*") then
      printTo = "PARTY"
    elseif string.match(arg, "o.*") then
      printTo = "OFFICER"
    elseif string.match(arg, "r.*") and arg:lower() ~= "rbg" then
      printTo = "RAID"
    else
      printTo = nil
    end

    if string.match(arg, ".*2.*") then
      auditBracket = BRACKETS[1]
    elseif string.match(arg, ".*3.*") then
      auditBracket = BRACKETS[2]
    elseif string.match(arg, ".*5.*") then
      auditBracket = BRACKETS[3]
    elseif string.match(arg:lower(), ".*rbg.*") then
      auditBracket = BRACKETS[4]
    elseif string.match(arg:lower(), ".*shuffle.*") then
      auditBracket = BRACKETS[7]
    elseif string.match(arg:lower(), ".*blitz.*") then
      auditBracket = BRACKETS[9]
    else
      auditBracket = nil
    end

    if auditBracket == nil then
      audit(TARGET)
    else
      auditGroup()
    end
  end
end

onLoad()
