local PWB = PizzaWorldBuffs

setfenv(1, PWB:GetEnv())

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
        local city = f.timer.faction == 'A' and T['SW'] or T['OG']
        local timer = PWB_timers[f.timer.faction][f.timer.boss]
        local suffix = T['head has no timer, it\'s probably despawned']

        if timer then
          local h, m = PWB.core.getTimeLeft(timer.h, timer.m)
          local isNow = h == 0 and m == 0
          suffix = isNow and T['head will despawn NOW!'] or T['head will despawn in'] .. ' ' .. PWB.utils.toString(h, m)
        end

        text = '(' .. city .. ') ' .. T[PWB.Bosses[f.timer.boss]] .. ' ' .. suffix
      elseif f.name == 'PizzaWorldBuffsDmf' then
        text = 'Darkmoon Faire location is currently unknown. Try "/w Tents dmf?"'

        if PWB.utils.hasDmf() then
          local location = PWB.DmfLocations[PWB_dmf.location]
          local secondsAgo = time() - PWB_dmf.seenAt
          local timeAgo = PWB.utils.toRoughTimeString(secondsAgo)
          text = 'Darkmoon Faire was last seen in ' .. location .. ' ' .. timeAgo .. ' ago.'
        end
      else
        local prefix = T['I\'m using PizzaWorldBuffs. Get it at']
        if math.random(1, 20) == 1 then
          prefix = T['I <3 pineapple on pizza! Get some at']
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

  if f.name == 'PizzaWorldBuffsDmf' then
    f.frame:SetScript('OnEnter', function ()
      local location
      local lastSeen

      if PWB_dmf then
        local locationColor = PWB_dmf.location == 'E' and PWB.Colors.alliance or PWB.Colors.horde
        location = locationColor .. PWB.DmfLocations[PWB_dmf.location]

        local lastSeenSeconds = time() - PWB_dmf.seenAt
        local lastSeenColor = PWB.Colors.green
        if lastSeenSeconds > (60 * 60) then lastSeenColor = PWB.Colors.orange end
        if lastSeenSeconds > (60 * 60 * 12) then lastSeenColor = PWB.Colors.red end
        lastSeen = lastSeenColor .. PWB.utils.toRoughTimeString(lastSeenSeconds)
      end

      GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
      GameTooltip:SetText(PWB.Colors.primary .. 'Darkmoon Faire')
      if location and lastSeen then
        GameTooltip:AddLine(PWB.Colors.secondary .. '\nLast seen ' .. lastSeen .. PWB.Colors.secondary .. ' ago in ' .. location .. PWB.Colors.secondary .. '.')
      else
        GameTooltip:AddLine(PWB.Colors.secondary .. '\nLocation currently unknown')
      end
      GameTooltip:AddLine(PWB.Colors.grey .. '\nThe Faire shuts down on Wednesdays and\nmoves between Elwynn Forest and Mulgore\nevery Sunday at midnight (server time).')
      GameTooltip:AddLine(PWB.Colors.primary .. '\n/wb dmfbuffs' .. PWB.Colors.grey .. ' shows all available buffs.')
      GameTooltip:AddLine(PWB.Colors.primary .. '\n/wb dmf 0' .. PWB.Colors.grey .. ' hides DMF location.')
      GameTooltip:Show()
    end)
    f.frame:SetScript('OnLeave', function ()
      GameTooltip:Hide()
    end)
  end

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
      shouldShow =  function() 
        return PWB_config.header == true
      end,
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
    {
      name = 'PizzaWorldBuffsDmf',
      shouldShow =  function() 
        return PWB_config.dmf == true
      end,
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
      local timeStr = PWB.Colors.grey .. T['N/A']

      if timer then
        local h, m = PWB.core.getTimeLeft(timer.h, timer.m)
        timeStr = PWB.utils.getTimerColor(timer.witness, timer.receivedFrom) .. PWB.utils.toString(h, m)
      end

      local bossColor = frame.timer.faction == 'A' and PWB.Colors.alliance or PWB.Colors.horde
      frame.frame.text:SetText(bossColor .. T[PWB.Bosses[frame.timer.boss]] .. ': ' .. timeStr)

      if not PWB_config.allFactions and frame.timer.faction ~= PWB.myFaction then
        frame.frame:Hide()
      else
        frame.frame:Show()
      end
    elseif frame.name == 'PizzaWorldBuffsDmf' then
      local location = PWB.Colors.grey .. 'N/A'

      if PWB_dmf then
        local color = PWB_dmf.location == 'E' and PWB.Colors.alliance or PWB.Colors.horde
        location = color .. PWB.utils.strSplit(PWB.DmfLocations[PWB_dmf.location], ' ')
      end

      frame.frame.text:SetText(PWB.Colors.primary .. 'DMF: ' .. location)
    end

    frame.frame:ClearAllPoints()
    local y = frame.anchor and (-frame.anchor.frame.text:GetHeight()) or 0
    local point = PWB_config.align == 'left' and 'TOPLEFT' or PWB_config.align == 'right' and 'TOPRIGHT' or 'TOP'

    local idx = i - 1
    -- Anchor DMF frame correctly if only own faction timers are shown.
    if frame.name == 'PizzaWorldBuffsDmf' and not PWB_config.allFactions then
      idx = i - 3
    end
    frame.frame:SetPoint(point, 0, idx * y)
    frame.frame:SetWidth(frame.frame.text:GetWidth())
    frame.frame:SetHeight(frame.frame.text:GetHeight())

    if frame.shouldShow then
      if frame.shouldShow() then
        frame.frame:Show()
      else
        frame.frame:SetHeight(0)
        frame.frame:Hide()
      end
    end
  end
end

-- Update
PWB.frame:SetScript('OnUpdate', function ()
  -- Throttle this function so it doesn't run on every frame render
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  PWB.frame.updateFrames()
end)
