local PWB = PizzaWorldBuffs

-- Main container frame
PWB.frame = CreateFrame('Frame', 'PizzaWorldBuffsFrame', UIParent)
PWB.frame:ClearAllPoints()
PWB.frame:SetPoint('TOP', 0, -50)
PWB.frame:SetFrameStrata('LOW')
PWB.frame:SetWidth(1)
PWB.frame:SetHeight(1)

-- Initialize a single frame
local function initFrame(f, anchor)
  f.frame = CreateFrame('Frame', f.name, PWB.frame)
  f.anchor = anchor
  f.frame:EnableMouse(true)
  f.frame:SetScript('OnMouseDown', function ()
    if IsShiftKeyDown() then
      if arg1 ~= 'LeftButton' and arg1 ~= 'RightButton' and arg1 ~= 'MiddleButton' then return end

      local text
      if f.timer then
        local city = f.timer.faction == 'A' and 'SW' or 'OG'
        local timer = PWB_timers[f.timer.faction][f.timer.boss]
        local suffix = ' head has no timer, it\'s probably despawned'

        if timer then
          local h, m = PWB.core.getTimeLeft(timer.h, timer.m)
          local timeLeft = h == 0 and m == 0 and ' NOW!' or ' in ' .. PWB.utils.toString(h, m)
          suffix = ' head will despawn ' .. timeLeft
        end

        text = '(' .. city .. ') ' .. PWB.Bosses[f.timer.boss] .. suffix
      else
        local prefix = 'I\'m using PizzaWorldBuffs. Get it at'
        if math.random(1, 20) == 1 then
          prefix = 'I <3 pineapple on pizza!'
        end
        text = prefix .. ' https://github.com/Pizzahawaiii/PizzaWorldBuffs'
      end

      if text then
        local editBox = DEFAULT_CHAT_FRAME.editBox
        local targetEditBox = WIM_EditBoxInFocus or editBox:IsVisible() and editBox or nil
        if targetEditBox then
          targetEditBox:SetText(text)
        else
          local sendTo
          if arg1 == 'LeftButton' then sendTo = 'SAY' end
          if arg1 == 'RightButton' then sendTo = 'GUILD' end
          if arg1 == 'MiddleButton' then sendTo = 'HARDCORE' end

          if sendTo then
            SendChatMessage(text, sendTo)
          end
        end
      end
    else
      PWB.frame:StartMoving()
    end
  end)
  f.frame:SetScript('OnMouseUp', function ()
    PWB.frame:StopMovingOrSizing()
  end)

  f.frame.text = f.frame:CreateFontString(f.name .. 'Text', 'DIALOG', 'GameFontWhite')
  f.frame.text:SetFont(STANDARD_TEXT_FONT, PWB_config.fontSize, 'OUTLINE')
  f.frame.text:SetJustifyH('LEFT')
  local point = PWB_config.align == 'left' and 'TOPLEFT' or PWB_config.align == 'right' and 'TOPRIGHT' or 'TOP'
  f.frame.text:SetPoint(point, 0, 0)
  f.frame.text:SetText(f.text)
end

-- Initialize all frames
local function initFrames()
  if PWB.frames then return end

  local otherFaction = PWB.myFaction == 'A' and 'H' or 'A'

  PWB.frames = {
    {
      name = 'PizzaWorldBuffsHeader',
      text = PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs',
    },
    {
      name = 'PizzaWorldBuffsTimer1',
      timer = {
        faction = PWB.myFaction,
        boss = 'O',
      },
    },
    {
      name = 'PizzaWorldBuffsTimer2',
      timer = {
        faction = PWB.myFaction,
        boss = 'N',
      },
    },
    {
      name = 'PizzaWorldBuffsTimer3',
      timer = {
        faction = otherFaction,
        boss = 'O',
      },
    },
    {
      name = 'PizzaWorldBuffsTimer4',
      timer = {
        faction = otherFaction,
        boss = 'N',
      },
    },
  }

  local previous
  for _, frame in ipairs(PWB.frames) do
    initFrame(frame, previous)
    previous = frame
  end
end

-- Mouse Drag
PWB.frame:SetMovable(true)

-- Apply saved variables
PWB.frame:RegisterEvent('PLAYER_ENTERING_WORLD')
PWB.frame:SetScript('OnEvent', function ()
  if event == 'PLAYER_ENTERING_WORLD' then
    initFrames()

    if PWB_config.show then
      PWB.frame:Show()
    end
  end
end)

function PWB.frame.updateFrames()
  for i, frame in ipairs(PWB.frames) do
    frame.frame.text:SetFont(STANDARD_TEXT_FONT, PWB_config.fontSize, 'OUTLINE')

    if frame.timer then
      local timer = PWB_timers[frame.timer.faction][frame.timer.boss]
      local timeStr = PWB.Colors.grey .. 'N/A'

      if timer then
        local h, m = PWB.core.getTimeLeft(timer.h, timer.m)
        timeStr = PWB.utils.getTimerColor(timer.witness, timer.receivedFrom) .. PWB.utils.toString(h, m)
      end

      local bossColor = frame.timer.faction == 'A' and PWB.Colors.alliance or PWB.Colors.horde
      frame.frame.text:SetText(bossColor .. PWB.Bosses[frame.timer.boss] .. ': ' .. timeStr)

      if not PWB_config.allFactions and frame.timer.faction ~= PWB.myFaction then
        frame.frame:Hide()
      else
        frame.frame:Show()
      end
    end

    frame.frame:ClearAllPoints()
    local y = frame.anchor and (-frame.anchor.frame.text:GetHeight()) or 0
    local point = PWB_config.align == 'left' and 'TOPLEFT' or PWB_config.align == 'right' and 'TOPRIGHT' or 'TOP'
    frame.frame:SetPoint(point, 0, (i - 1) * y)
    frame.frame:SetWidth(frame.frame.text:GetWidth())
    frame.frame:SetHeight(frame.frame.text:GetHeight())
  end
end

function PWB.frame.updatePizzaWorldBuffsHeader()  
  for i, frame in ipairs(PWB.frames) do
    if frame.name == 'PizzaWorldBuffsHeader' then
      frame.text = PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs' .. PWB.Colors.grey .. (PWB_config.autoLogout and (PWB_config.setQuit and ' (AutoQuit)' or ' (AutoLogout)') or '')
      frame.frame.text:SetText(frame.text)
    end
  end
end

-- Update
PWB.frame:SetScript('OnUpdate', function ()
  -- Throttle this function so it doesn't run on every frame render
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  PWB.frame.updateFrames()
end)