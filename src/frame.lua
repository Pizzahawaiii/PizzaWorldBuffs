local PWB = PizzaWorldBuffs

-- Frame
PWB.frame = CreateFrame("Frame", "PizzaWorldBuffFrame", UIParent)
PWB.frame:ClearAllPoints()
PWB.frame:SetPoint("TOP", 0, -50)
PWB.frame:SetFrameStrata('LOW')
PWB.frame:SetWidth(200)
PWB.frame:SetHeight(1)

-- Mouse Drag
PWB.frame:SetMovable(true)
PWB.frame:EnableMouse(true)
PWB.frame:RegisterForDrag('leftButton')
PWB.frame:SetScript('OnDragStart', function ()
  PWB.frame:StartMoving()
end)
PWB.frame:SetScript('OnDragStop', function ()
  PWB.frame:StopMovingOrSizing()
end)

if PWB_config.show then
  PWB.frame:Show()
end

-- Text
PWB.frame.text = PWB.frame:CreateFontString('PizzaWorldBuffText', 'DIALOG', 'GameFontWhite')
PWB.frame.text:SetJustifyH('CENTER')
PWB.frame.text:SetFont(STANDARD_TEXT_FONT, PWB_config.fontSize, 'OUTLINE')
PWB.frame.text:SetPoint('CENTER', 0, 0)

-- Apply saved variables
PWB.frame:RegisterEvent('ADDON_LOADED')
PWB.frame:SetScript('OnEvent', function ()
  if event == 'ADDON_LOADED' then
    PWB.frame.text:SetFont(STANDARD_TEXT_FONT, PWB_config.fontSize, 'OUTLINE')
  end
end)

function PWB.frame.appendTimerText (timer)
  if PWB_config.allFactions or timer.faction == PWB.myFaction then
    local h, m = PWB.core.getTimeLeft(timer.h, timer.m)
    if h and m then
      local bossColor = timer.faction == 'A' and PWB.Colors.alliance or PWB.Colors.horde
      local timerText = bossColor .. PWB.Bosses[timer.boss] .. ':|r ' .. PWB.utils.getTimerColor(timer.witness, timer.receivedFrom) .. PWB.utils.toString(h, m) .. '|r'
      PWB.frame.content = PWB.frame.content and PWB.frame.content .. '\n' .. timerText or timerText
    end
  end
end

-- Update
PWB.frame:SetScript('OnUpdate', function ()
  -- Throttle this function so it doesn't run on every frame render
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + .1 end

  PWB.frame.content = nil
  PWB.utils.forEachTimer(PWB.frame.appendTimerText)

  if not PWB.frame.content then
    PWB.frame.content = PWB.Colors.grey .. 'No known world buff timers'
  end

  PWB.frame.text:SetText(PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs|r\n' .. PWB.frame.content)
  PWB.frame:SetHeight(PWB.frame.text:GetHeight() + 10)
end)

-- Backdrop
local backdrop = {
  bgFile = "Interface\\BUTTONS\\WHITE8X8",
  tile = false,
  tileSize = 0,
  edgeFile = "Interface\\BUTTONS\\WHITE8X8",
  edgeSize = 4,
  insets = {left = 0, right = 0, top = 0, bottom = 0},
}
PWB.frame.backdrop = CreateFrame("Frame", nil, PWB.frame)
level = PWB.frame:GetFrameLevel()
if level < 1 then
  PWB.frame.backdrop:SetFrameLevel(level)
else
  PWB.frame.backdrop:SetFrameLevel(level - 1)
end
PWB.frame.backdrop:SetPoint("TOPLEFT", PWB.frame, "TOPLEFT", 0, 0)
PWB.frame.backdrop:SetPoint("BOTTOMRIGHT", PWB.frame, "BOTTOMRIGHT", 0, 0)
PWB.frame.backdrop:SetBackdrop(backdrop)
PWB.frame.backdrop:SetBackdropColor(0, 0, 0, 0)
PWB.frame.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
PWB.frame.backdrop:Show()