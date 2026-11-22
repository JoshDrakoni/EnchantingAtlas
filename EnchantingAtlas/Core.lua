local addonName = ...
local EA = CreateFrame("Frame")
EA:RegisterEvent("ADDON_LOADED")
EA:RegisterEvent("TRADE_SKILL_SHOW")
EA:RegisterEvent("TRADE_SKILL_UPDATE")
EA:RegisterEvent("TRADE_SKILL_CLOSE")

local function trim(s) return (s or ""):gsub("^%s+", ""):gsub("%s+$", "") end
local function lower(s) return string.lower(s or "") end
local function colorFor(conf)
  if conf == "Published Forever guide" then return "|cff66ccff" end
  if conf == "Verified Forever" then return "|cff33dd66" end
  if conf == "Database recorded" then return "|cff66ccff" end
  if conf == "Classic reference" then return "|cffffcc44" end
  return "|cffff6666"
end
local function ensureDB()
  EnchantingAtlasDB = EnchantingAtlasDB or { known = {}, manual = {}, favorites = {}, version = 1 }
  EnchantingAtlasDB.known = EnchantingAtlasDB.known or {}
  EnchantingAtlasDB.manual = EnchantingAtlasDB.manual or {}
  EnchantingAtlasDB.favorites = EnchantingAtlasDB.favorites or {}
end

local function scanTradeSkill()
  if not GetTradeSkillLine or not GetNumTradeSkills then return end
  local line = GetTradeSkillLine()
  if not line or not string.find(lower(line), "enchant") then return end
  local n = GetNumTradeSkills() or 0
  for i = 1, n do
    local name, skillType = GetTradeSkillInfo(i)
    if name and skillType ~= "header" then
      EnchantingAtlasDB.known[lower(name)] = true
    end
  end
  if EA.Refresh then EA:Refresh() end
end

local function createText(parent, size, text)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "")
  fs:SetText(text or "")
  return fs
end

function EA:BuildUI()
  if self.frame then return end
  local f = CreateFrame("Frame", "EnchantingAtlasFrame", UIParent)
  self.frame = f
  f:SetSize(760, 520)
  f:SetPoint("CENTER")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=32, insets={left=8,right=8,top=8,bottom=8}})
  local title = createText(f, 18, "Enchanting Atlas | WoW Forever")
  title:SetPoint("TOPLEFT", 22, -18)
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)
  local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  search:SetSize(250, 24); search:SetPoint("TOPLEFT", 24, -50); search:SetAutoFocus(false)
  search:SetScript("OnTextChanged", function() EA:Refresh() end)
  self.search = search
  local learned = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  learned:SetPoint("LEFT", search, "RIGHT", 12, 0)
  learned.text:SetText("Show missing only")
  learned:SetScript("OnClick", function() EA.missingOnly = learned:GetChecked(); EA:Refresh() end)
  self.missingOnly = false; self.missingCheck = learned
  local fav = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  fav:SetPoint("LEFT", learned, "RIGHT", 110, 0)
  fav.text:SetText("Favorites")
  fav:SetScript("OnClick", function() EA.favoritesOnly = fav:GetChecked(); EA:Refresh() end)
  self.favoritesOnly = false; self.favCheck = fav
  local listLabel = createText(f, 12, "RECIPES")
  listLabel:SetPoint("TOPLEFT", 28, -88)
  local detailLabel = createText(f, 12, "ACQUISITION DETAILS")
  detailLabel:SetPoint("TOPLEFT", 420, -88)
  local list = CreateFrame("Frame", nil, f)
  list:SetPoint("TOPLEFT", 24, -110); list:SetSize(360, 370)
  list:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background"}); list:SetBackdropColor(0,0,0,0.35)
  self.list = list
  local scroll = CreateFrame("ScrollFrame", "EnchantingAtlasScroll", list, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 4, -4); scroll:SetPoint("BOTTOMRIGHT", -26, 4)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(325, 360); scroll:SetScrollChild(content); self.content = content; self.scroll = scroll
  local detail = CreateFrame("Frame", nil, f)
  detail:SetPoint("TOPLEFT", 405, -110); detail:SetSize(330, 370)
  detail:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background"}); detail:SetBackdropColor(0,0,0,0.35)
  self.detail = detail
  self.detailTitle = createText(detail, 15, "Select a recipe")
  self.detailTitle:SetPoint("TOPLEFT", 14, -16); self.detailTitle:SetWidth(300); self.detailTitle:SetJustifyH("LEFT")
  self.detailText = createText(detail, 12, "Choose a recipe from the list to view its formula, source, confidence, and tracking status.")
  self.detailText:SetPoint("TOPLEFT", 14, -50); self.detailText:SetWidth(300); self.detailText:SetJustifyH("LEFT"); self.detailText:SetJustifyV("TOP")
  self.detailText:SetWordWrap(true)
  local footer = createText(f, 10, "Sources are confidence-labelled. Unknown means no reliable Forever source is recorded; do not treat Classic drop tables as confirmed.")
  footer:SetPoint("BOTTOMLEFT", 24, 18); footer:SetWidth(700); footer:SetJustifyH("LEFT")
  self:Refresh()
end

function EA:ShowDetails(entry)
  self.selected = entry
  local k = lower(entry.name)
  local known = EnchantingAtlasDB.manual[k]
  if known == nil then known = EnchantingAtlasDB.known[k] end
  local fav = EnchantingAtlasDB.favorites[lower(entry.name)]
  self.detailTitle:SetText(entry.name)
  local status = known and "|cff33dd66Known / learned|r" or "|cffff6666Not detected as learned|r"
  local favText = fav and "|cffffd700Favorite|r" or "Not favorited"
  local body = "Formula: " .. (entry.formula or "No separate formula item recorded") .. "\n\n" ..
    "Enchanting skill: " .. tostring(entry.skill or "—") .. "\n" ..
    "Acquisition: " .. tostring(entry.type or "Unknown") .. "\n" ..
    "Zone / vendor area: " .. tostring(entry.zone or "Not recorded") .. "\n\n" ..
    tostring(entry.source or "No source details recorded.") .. "\n\n" ..
    colorFor(entry.confidence) .. "Confidence: " .. tostring(entry.confidence or "Unknown") .. "|r\n\n" ..
    status .. "\n" .. favText
  self.detailText:SetText(body)
  if self.actionButton then self.actionButton:Hide() end
  if self.favoriteButton then self.favoriteButton:Hide() end
  local b = CreateFrame("Button", nil, self.detail, "UIPanelButtonTemplate")
  b:SetSize(132, 24); b:SetPoint("BOTTOMLEFT", 12, 12)
  b:SetText(known and "Mark as missing" or "Mark as learned")
  b:SetScript("OnClick", function()
    local k = lower(entry.name)
    local current = EnchantingAtlasDB.manual[k]
    if current == nil then current = EnchantingAtlasDB.known[k] end
    EnchantingAtlasDB.manual[k] = not current
    EA:ShowDetails(entry); EA:Refresh()
  end)
  local fb = CreateFrame("Button", nil, self.detail, "UIPanelButtonTemplate")
  fb:SetSize(132, 24); fb:SetPoint("LEFT", b, "RIGHT", 8, 0)
  fb:SetText(fav and "Unfavorite" or "Add favorite")
  fb:SetScript("OnClick", function()
    local k = lower(entry.name)
    EnchantingAtlasDB.favorites[k] = not EnchantingAtlasDB.favorites[k] or nil
    EA:ShowDetails(entry); EA:Refresh()
  end)
  self.actionButton = b; self.favoriteButton = fb
end

function EA:Refresh()
  if not self.content then return end
  for _, child in ipairs({self.content:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local query = lower(trim(self.search and self.search:GetText() or ""))
  local y, shown = -4, 0
  for _, entry in ipairs(EnchantingAtlasCatalog or {}) do
    local k = lower(entry.name)
    local known = EnchantingAtlasDB.manual[k]
      if known == nil then known = EnchantingAtlasDB.known[k] end
    local favorite = EnchantingAtlasDB.favorites[k]
    local matches = query == "" or string.find(lower(entry.name), query, 1, true) or string.find(lower(entry.formula or ""), query, 1, true) or string.find(lower(entry.zone or ""), query, 1, true) or string.find(lower(entry.type or ""), query, 1, true)
    if matches and (not self.missingOnly or not known) and (not self.favoritesOnly or favorite) then
      shown = shown + 1
      local btn = CreateFrame("Button", nil, self.content)
      btn:SetSize(325, 25); btn:SetPoint("TOPLEFT", 0, y)
      btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
      local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      txt:SetPoint("LEFT", 5, 0); txt:SetWidth(315); txt:SetJustifyH("LEFT")
      local mark = known and "|cff33dd66[Known]|r " or "|cffff6666[Missing]|r "
      local fav = favorite and "|cffffd700★ |r" or ""
      txt:SetText(fav .. mark .. entry.name .. "  |cffaaaaaa(" .. tostring(entry.skill or "—") .. ")|r")
      btn:SetScript("OnClick", function() EA:ShowDetails(entry) end)
      y = y - 25
    end
  end
  self.content:SetHeight(math.max(360, -y + 10))
  if shown == 0 then
    local empty = createText(self.content, 12, "No matching recipes in the catalog.")
    empty:SetPoint("TOPLEFT", 8, -8)
  end
end

SLASH_ENCHANTINGATLAS1 = "/ea"
SLASH_ENCHANTINGATLAS2 = "/enchantatlas"
SlashCmdList["ENCHANTINGATLAS"] = function()
  EA:BuildUI()
  if EA.frame:IsShown() then EA.frame:Hide() else EA.frame:Show() end
end

EA:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == addonName then
    ensureDB()
  elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" then
    if EnchantingAtlasDB then scanTradeSkill() end
  end
end)
