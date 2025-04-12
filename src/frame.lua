-- frame.lua
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
      if arg1 ~= 'LeftButton' and arg1 ~= 'RightButton' and arg1 ~= 'MiddleButton' and arg1 ~= 'Button4' then return end
      if f.timer then
        PWB.share.share(arg1, 'timer', f.timer)
      elseif f.name == 'PizzaWorldBuffsDmf' then 
        PWB.share.share(arg1, 'dmf')
      else
        PWB.share.share(arg1, 'link')
      end
    else
      if not PWB_config.lock then
        PWB.frame:StartMoving()
      end
    end
  end)
  f.frame:SetScript('OnMouseUp', function ()
    PWB.frame:StopMovingOrSizing()
  end)

  if f.name == 'PizzaWorldBuffsDmf' then
    f.frame:SetScript('OnEnter', function ()
      local location
      local lastSeen
      if PWB_dmf and PWB.DmfLocations[PWB_dmf.location] then
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
      shouldShow = function() 
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
      shouldShow = function() 
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
    else
      PWB.frame:Hide()
    end
  end
end)

function PWB.frame.updateFrames()
  local spacing = 10 -- Space between frames in horizontal mode
  local xOffset = 0
  local yOffset = 0
  local maxWidth = 0
  local totalHeight = 0

  for i, frame in ipairs(PWB.frames) do
    frame.frame.text:SetFont(STANDARD_TEXT_FONT, PWB_config.fontSize, 'OUTLINE')

    -- Update text content
    if frame.timer then
      local timer = PWB_timers and PWB_timers[frame.timer.faction] and PWB_timers[frame.timer.faction][frame.timer.boss]
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
        local shortLoc = PWB.utils.strSplit(PWB.DmfLocations[PWB_dmf.location], ' ')
        if shortLoc then
          local color = PWB_dmf.location == 'E' and PWB.Colors.alliance or PWB.Colors.horde
          location = color .. shortLoc
        end
      end
      frame.frame.text:SetText(PWB.Colors.primary .. 'DMF: ' .. location)
    end

    -- Handle visibility for optional frames
    if frame.shouldShow then
      if frame.shouldShow() then
        frame.frame:Show()
      else
        frame.frame:Hide()
      end
    end

    -- Position frames based on orientation
    frame.frame:ClearAllPoints()
    local point = PWB_config.orientation == 'horizontal' and 'TOPLEFT' or (PWB_config.align == 'left' and 'TOPLEFT' or PWB_config.align == 'right' and 'TOPRIGHT' or 'TOP')

    if PWB_config.orientation == 'horizontal' then
      if frame.frame:IsShown() then
        frame.frame:SetPoint(point, PWB.frame, point, xOffset, 0)
        xOffset = xOffset + frame.frame.text:GetWidth() + spacing
        totalHeight = math.max(totalHeight, frame.frame.text:GetHeight())
      end
    else -- vertical (default)
      if frame.frame:IsShown() then
        frame.frame:SetPoint(point, PWB.frame, point, 0, yOffset)
        yOffset = yOffset - frame.frame.text:GetHeight()
        maxWidth = math.max(maxWidth, frame.frame.text:GetWidth())
        totalHeight = totalHeight + frame.frame.text:GetHeight()
      end
    end

    frame.frame:SetWidth(frame.frame.text:GetWidth())
    frame.frame:SetHeight(frame.frame.text:GetHeight())
  end

  -- Set parent frame size
  if PWB_config.orientation == 'horizontal' then
    PWB.frame:SetWidth(xOffset - spacing) -- Subtract last spacing
    PWB.frame:SetHeight(totalHeight)
  else
    PWB.frame:SetWidth(maxWidth)
    PWB.frame:SetHeight(totalHeight)
  end
end

-- Update
PWB.frame:SetScript('OnUpdate', function ()
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
  PWB.frame.updateFrames()
end)