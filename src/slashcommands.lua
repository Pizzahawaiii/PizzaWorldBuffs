local PWB = PizzaWorldBuffs

SLASH_PIZZAWORLDBUFFS1, SLASH_PIZZAWORLDBUFFS2, SLASH_PIZZAWORLDBUFFS3 = '/wb', '/pwb', '/pizzawb'

setfenv(1, PWB:GetEnv())

SlashCmdList['PIZZAWORLDBUFFS'] = function (args, editbox)
  local cmd, msg = PWB.utils.strSplit(args, ' ')
  local command = cmd and string.lower(cmd)

  if command == 'show' then
    PWB_config.show = true
    PWB.frame:Show()
    return
  end

  if command == 'hide' then
    PWB_config.show = false
    PWB.frame:Hide()
    return
  end

  if command == 'reset' then
    PWB.frame:ClearAllPoints()
    PWB.frame:SetPoint('TOP', 0, -50)
    PWB.logoutFrame:ClearAllPoints()
    PWB.logoutFrame:SetPoint('TOP', 0, -200)
    PWB:Print(T['Reset PizzaWorldBuffs frames to their default position'])
    return
  end

  if command == 'fontsize' then
    local fontSize = tonumber(msg)
    if not fontSize then
      PWB:Print(T['Invalid option. Only numbers allowed!'])
      return
    end

    PWB_config.fontSize = fontSize
    PWB.frame.updateFrames()
    PWB:Print(T['Changed font size to'] .. ' ' .. PWB_config.fontSize)
    return
  end

  if command == 'align' then
    local align = string.lower(msg)
    if align ~= 'left' and align ~= 'center' and align ~= 'right' then
      PWB:Print(T['Invalid option. Valid options are: left, center, right'])
      return
    end

    PWB_config.align = align
    PWB.frame.updateFrames()
    PWB:Print(T['Changed text alignment to'] .. ' ' .. PWB_config.align)
    return
  end

  if command == 'header' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.header = number == 1
    PWB.frame.updateFrames()
    local message
    if PWB_config.header then
      message = T['Showing PizzaWorldBuffs header']
    else
      message = T['Hiding PizzaWorldBuffs header']
    end
    PWB:Print(message)
    return
  end

  if command == 'all' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.allFactions = number == 1
    local message
    if PWB_config.allFactions then
      message = T['Showing both factions\' world buff timers']
    else
      message = T['Showing only your factions\' world buff timers']
    end
    PWB:Print(message)
    return
  end

  if command == 'sharing' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.sharingEnabled = number == 1

    -- If sharing was disabled, clear all timers we didn't witness ourselves
    if not PWB_config.sharingEnabled then
      PWB.utils.forEachTimer(function (timer)
        if timer.witness ~= PWB.me then
          PWB.core.clearTimer(timer)
        end
      end)
    end

    local message
    if PWB_config.sharingEnabled then
      message = T['Timer sharing between you and other players enabled. You will see other peoples\' timers too.']
    else
      message = T['Timer sharing between you and other players disabled. You will only see your own timers.']
    end
    PWB:Print(message)

    return
  end

  if command == 'logout' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.autoLogout = number == 1

    local message
    if PWB_config.autoLogout then
      message = T['Auto-logout after receiving next buff enabled. This will be disabled again the next time you relog or reload your UI.']
      if PWB_config.autoExit then
        PWB_config.autoExit = false
        PWB:Print(T['Auto-exit after receiving next buff disabled.'])
      end
    else
      message = T['Auto-logout after receiving next buff disabled.']
    end

    PWB.logoutFrame.update()
    PWB:Print(message)

    return
  end

  if command == 'exit' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.autoExit = number == 1

    local message
    if PWB_config.autoExit then
      message = T['Auto-exit after receiving next buff enabled. This will be disabled again the next time you relog or reload your UI.']
      if PWB_config.autoLogout then
        PWB_config.autoLogout = false
        PWB:Print(T['Auto-logout after receiving next buff disabled.'])
      end
    else
      message = T['Auto-exit after receiving next buff disabled.']
    end

    PWB.logoutFrame.update()
    PWB:Print(message)

    return
  end

  if command == 'version' then
    PWB:Print(T['Version'] .. ' ' .. PWB.utils.getVersion())
    return
  end

  PWB:PrintClean(PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs|r ' .. T['commands'] .. ':')
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r show ' .. PWB.Colors.grey .. '- ' .. T['Show the addon'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r hide ' .. PWB.Colors.grey .. '- ' .. T['Hide the addon'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r header ' .. (PWB_config.header and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Show PizzaWorldBuffs header'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r all ' .. (PWB_config.allFactions and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Show both factions\' world buff timers'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r sharing ' .. (PWB_config.sharingEnabled and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Enable timer sharing between you and other players'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r logout ' .. (PWB_config.autoLogout and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Log out automatically after receiving next buff'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r exit ' .. (PWB_config.autoExit and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Exit game automatically after receiving next buff'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r reset ' .. PWB.Colors.grey .. '- ' .. T['Reset PizzaWorldBuffs frames to their default positions'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r fontSize ' .. PWB_config.fontSize .. PWB.Colors.grey .. ' - ' .. T['Set font size'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r align ' .. PWB_config.align .. PWB.Colors.grey .. ' - ' .. T['Align text left/center/right'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r version ' .. PWB.Colors.grey .. '- ' .. T['Show current version'])
end
