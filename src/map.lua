local PWB = PizzaWorldBuffs
PWB.map = {}

setfenv(1, PWB:GetEnv())

local frame = CreateFrame('Frame', 'PizzaWorldBuffsMap', UIParent)

--        SW            OG
-- Ony:   67.3, 84.4    51.9, 78.8
-- Nef:   70.6, 80.4    52.8, 78.7
local pins = {
  A = {
    O = {
      frame = CreateFrame('Button', 'PizzaHeadPinAllyOny', WorldMapButton),
      x = .673,
      y = .844,
    },
    N = {
      frame = CreateFrame('Button', 'PizzaHeadPinAllyNef', WorldMapButton),
      x = .706,
      y = .804,
    },
  },
  H = {
    O = {
      frame = CreateFrame('Button', 'PizzaHeadPinHordeOny', WorldMapButton),
      x = .514,
      y = .788,
    },
    N = {
      frame = CreateFrame('Button', 'PizzaHeadPinHordeNef', WorldMapButton),
      x = .533,
      y = .787,
    },
  },
}

function PWB.map.updatePins()
  local pinSize = 18

  for faction, factionPins in pairs(pins) do
    for boss, pin in pairs(factionPins) do
      pin.frame.faction = faction
      pin.frame.boss = boss

      if not PWB_config.mapHeads or not PWB.utils.hasTimer(faction, boss) then
        pin.frame:Hide()
      else
        pin.frame:ClearAllPoints()
        pin.frame:SetFrameStrata('FULLSCREEN')
        pin.frame:SetFrameLevel(4)
        pin.frame:SetWidth(pinSize)
        pin.frame:SetHeight(pinSize)
        pin.frame:EnableMouse(true)

        local mapWidth = WorldMapButton:GetWidth()
        local mapHeight = WorldMapButton:GetHeight()
        local pinX = pin.x * mapWidth
        local pinY = pin.y * mapHeight

        pin.frame:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', pinX, -pinY)
        if not pin.frame.tex then
          pin.frame.tex = pin.frame:CreateTexture(pin.frame:GetName() .. 'Tex', 'BACKGROUND')
          pin.frame.tex:SetAllPoints(pin.frame)
        end

        local timer = PWB_timers[faction][boss]
        local confidence = PWB.utils.getTimerConfidence(timer.witness, timer.receivedFrom)
        pin.frame.tex:SetTexture('Interface\\AddOns\\PizzaWorldBuffs\\img\\' .. boss .. confidence)
        pin.frame.tex:Hide()
        pin.frame.tex:Show()

        pin.frame:SetScript('OnEnter', function()
          GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
          local titleColor = this.faction == 'A' and PWB.Colors.alliance or PWB.Colors.horde
          GameTooltip:SetText(titleColor .. PWB.Bosses[this.boss] .. ' Head')
          local timerColor = PWB.utils.getTimerColor(timer.witness, timer.receivedFrom)
          local h, m = PWB.core.getTimeLeft(timer.h, timer.m)
          GameTooltip:AddLine(PWB.Colors.secondary .. 'Time left: ' .. timerColor .. PWB.utils.toString(h, m))
          local witness = timer.witness == PWB.me and 'YOU' or timer.witness
          GameTooltip:AddLine(PWB.Colors.secondary .. 'Witness: ' .. PWB.Colors.primary .. witness)
          GameTooltip:Show()
        end)

        pin.frame:SetScript('OnLeave', function()
          GameTooltip:Hide()
        end)

        pin.frame:SetScript('OnMouseDown', function ()
          if IsShiftKeyDown() then
            if arg1 ~= 'LeftButton' and arg1 ~= 'RightButton' and arg1 ~= 'MiddleButton' and arg1 ~= 'Button4' then return end
            PWB.share.share(arg1, 'timer', PWB_timers[this.faction][this.boss])
          end
        end)
      end
    end
  end
end

function PWB.map.showPins(zone)
  if not PWB_config.mapHeads then return end
  if zone ~= 'Stormwind City' and zone ~= T['SWC'] and zone ~= 'Orgrimmar' and zone ~= T['OG'] then return end

  local faction = (zone == 'Stormwind City' or zone == T['SWC']) and 'A' or 'H'
  for boss, pin in pairs(pins[string.sub(faction, 1, 1)]) do
    if PWB.utils.hasTimer(faction, boss) then
      pin.frame:Show()
    end
  end
end

function PWB.map.hidePins()
  for faction, factionPins in pairs(pins) do
    for boss, pin in pairs(factionPins) do
      pin.frame:Hide()
    end
  end
end

frame:SetScript('OnUpdate', function ()
  local now = GetTime()

  if (this.tick or 1) > now then return else this.tick = now + 1 end

  PWB.map.updatePins()
end)

frame:RegisterEvent('WORLD_MAP_UPDATE')
frame:SetScript('OnEvent', function() 
  if event == 'WORLD_MAP_UPDATE' then
    PWB.map.hidePins()
    PWB.map.showPins(PWB.utils.getCurrentMapZoneName())
  end
end)
