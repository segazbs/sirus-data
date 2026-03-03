-- Sirus Mythic Tooltip

local SHOW_LADDER_RANK = true

-- Иконка Mythic+
local MPLUS_ICON = "Interface\\Icons\\INV_Relics_Hourglass"
local ICON_SIZE = 14

---------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
---------------------------------------------------

local function addPair(tt, left, right)
  if right and right ~= "" then
    tt:AddDoubleLine(left, right, 1, 0.82, 0, 1, 1, 1)
  end
end

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

-- ВАЖНО: %02x принимает целые числа
local function toByte01(x)
  x = clamp(x, 0, 1)
  return math.floor(x * 255 + 0.5)
end

local function rgbToHex(r, g, b)
  return ("|cff%02x%02x%02x"):format(toByte01(r), toByte01(g), toByte01(b))
end

---------------------------------------------------
-- ЦВЕТ КЛЮЧА
---------------------------------------------------

local function keyColor(level)
  level = tonumber(level or 0) or 0
  if level >= 15 then
    return "|cffffd100" -- золото
  elseif level >= 10 then
    return "|cffa335ee" -- фиолет
  else
    return "|cff0070dd" -- синий
  end
end

local function fmtKey(level, dungeon)
  if not level then return nil end
  level = tonumber(level)
  if not level then return nil end

  local c = keyColor(level)
  local reset = "|r"

  if not dungeon or dungeon == "" then
    return (c .. "+%d" .. reset):format(level)
  end

  dungeon = tostring(dungeon):gsub("%s*%(%d+%)%s*$", "")
  return (c .. "+%d" .. reset .. "  %s"):format(level, dungeon)
end

---------------------------------------------------
-- ГРАДИЕНТ РЕЙТИНГА
---------------------------------------------------

local SCORE_MIN = 0
local SCORE_MAX = 2500

local SCORE_STOPS = {
  {0.00, 0.12, 0.80, 0.20}, -- зелёный
  {0.35, 0.00, 0.44, 0.87}, -- синий
  {0.65, 0.64, 0.21, 0.93}, -- фиолет
  {1.00, 1.00, 0.50, 0.00}, -- оранжевый
}

local function scoreColor(score)
  score = tonumber(score or 0) or 0

  local t = 0
  if SCORE_MAX > SCORE_MIN then
    t = (score - SCORE_MIN) / (SCORE_MAX - SCORE_MIN)
  end

  t = clamp(t, 0, 1)

  local prev = SCORE_STOPS[1]
  for i = 2, #SCORE_STOPS do
    local cur = SCORE_STOPS[i]
    if t <= cur[1] then
      local span = cur[1] - prev[1]
      local lt = (span > 0) and ((t - prev[1]) / span) or 0

      local r = lerp(prev[2], cur[2], lt)
      local g = lerp(prev[3], cur[3], lt)
      local b = lerp(prev[4], cur[4], lt)

      return rgbToHex(r, g, b)
    end
    prev = cur
  end

  local last = SCORE_STOPS[#SCORE_STOPS]
  return rgbToHex(last[2], last[3], last[4])
end

---------------------------------------------------
-- ФОРМАТ РАНГА (топ 20 / топ 100 / топ 1000)
---------------------------------------------------

local function formatRank(rank)
  rank = tonumber(rank)
  if not rank then return nil end

  if rank <= 20 then
    return "|cffffd100" .. rank .. "|r"   -- золото
  elseif rank <= 100 then
    return "|cffff8000" .. rank .. "|r"   -- оранжевый
  elseif rank <= 1000 then
    return "|cffa335ee" .. rank .. "|r"   -- фиолет
  else
    return tostring(rank)                 -- обычный
  end
end

---------------------------------------------------
-- ВЫБОР МАКС КЛЮЧА (overall)
---------------------------------------------------

local function pickOverallMax(info)
  if not info then return nil, nil end
  local lvl = tonumber(info.bestOverallLevel)
      or tonumber(info.bestLevel)
      or tonumber(info.bestTimedLevel)

  local dung = info.bestOverallDungeon
      or info.bestDungeon
      or info.bestTimedDungeon

  return lvl, dung
end

---------------------------------------------------
-- TOOLTIP
---------------------------------------------------

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
  local ok = pcall(function()

    local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local name = UnitName(unit)
    if not name then return end

    if not SIRUS_MPLUS_LADDER then return end
    local info = SIRUS_MPLUS_LADDER[name]
    if not info then return end

    self:AddLine(" ")

    local icon = ("|T%s:%d:%d:0:0|t "):format(MPLUS_ICON, ICON_SIZE, ICON_SIZE)
    self:AddLine(icon .. "|cff00ff00Mythic+|r", 1, 1, 1)

    -- Рейтинг
    if info.score then
      local s = math.floor(tonumber(info.score) or 0)
      addPair(self, "Рейтинг M+", scoreColor(s) .. tostring(s) .. "|r")
    end

    -- Ранг
    if SHOW_LADDER_RANK and info.rank then
      addPair(self, "Место в ладдере", formatRank(info.rank) or tostring(info.rank))
    end

    -- Макс ключ
    local maxLvl, maxDung = pickOverallMax(info)
    addPair(self, "Макс. ключ", fmtKey(maxLvl, maxDung) or "—")

    -- Забеги
    if info.timed or info.total then
      addPair(self, "Забеги (в таймер/всего)",
        tostring(info.timed or "—") .. "/" .. tostring(info.total or "—"))
    end

  end)

  if not ok then
    self:AddLine("|cffff0000SirusMythicTooltip error|r")
  end
end)
-- test123