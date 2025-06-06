-- slashcommands.lua
local PWB = PizzaWorldBuffs

SLASH_PIZZAWORLDBUFFS1, SLASH_PIZZAWORLDBUFFS2, SLASH_PIZZAWORLDBUFFS3 = '/wb', '/pwb', '/pizzawb'

setfenv(1, PWB:GetEnv())

SlashCmdList['PIZZAWORLDBUFFS'] = function (args, editbox)
  local cmd, msg = PWB.utils.strSplit(args, ' ')
  local command = cmd and string.lower(cmd)

  if command == 'show' then
    PWB_config.show = true
    PWB.frame:Show()
    PWB:Print(T['Showing main frame'])
    return
  end

  if command == 'hide' then
    PWB_config.show = false
    PWB.frame:Hide()
    PWB:Print(T['Hiding main frame'])
    return
  end

  if command == 'toggle' then
    PWB_config.show = not PWB_config.show
    if PWB_config.show then PWB.frame:Show() else PWB.frame:Hide() end
    PWB:Print(PWB_config.show and T['Showing main frame'] or T['Hiding main frame'])
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

  if command == 'lock' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.lock = number == 1
    PWB:Print(T['Frame ' .. (PWB_config.lock and 'locked' or 'unlocked')])
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

  if command == 'dmf' then
    local number = tonumber(msg)
    if not number or (number ~=0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.dmf = number == 1
    PWB.frame.updateFrames()
    local message
    if PWB_config.dmf then
      message = T['Showing Darkmoon Faire location']
    else
      message = T['Hiding Darkmoon Faire location']
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
    PWB.frame.updateFrames()
    local message
    if PWB_config.allFactions then
      message = T['Showing both factions\' world buff timers']
    else
      message = T['Showing only your factions\' world buff timers']
    end
    PWB:Print(message)
    return
  end

  if command == 'mapheads' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.mapHeads = number == 1
    PWB.map.updatePins()
    local message
    if PWB_config.mapHeads then
      message = T['Showing Ony/Nef head timers on the SW/OG map']
    else
      message = T['Hiding Ony/Nef head timers from the SW/OG map']
    end
    PWB:Print(message)
    return
  end

  if command == 'tents' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print(T['Valid options are 0 and 1'])
      return
    end

    PWB_config.tents = number == 1
    PWB.tents.updatePins()
    local message
    if PWB_config.tents then
      message = T['Showing tents on the world map']
    else
      message = T['Hiding tents from the world map']
    end
    PWB:Print(message)
    return
  end

  local tentStyles = { 1, 2, 3, 4, 5, 6, 7, 1337}
  if command == 'tentstyle' then
    local number = tonumber(msg)
    if not number or not PWB.utils.contains(tentStyles, number) then
      local options
      for idx, style in ipairs(tentStyles) do
        options = options and (options .. ', ' .. style) or style
      end
      PWB:Print(T['Valid options are:'] .. ' ' .. options)
      return
    end

    PWB_config.tentStyle = number
    PWB:Print(T['Switched to tent style'] .. ' ' .. number .. '. ')
    return
  end

  if command == 'tentalert' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1 and number ~= 2) then
      PWB:Print(T['Valid options are 0, 1 and 2'])
      return
    end

    PWB_config.tentAlert = number
    local message
    if PWB_config.tentAlert == 0 then
      message = T['Tent alert disabled']
    elseif PWB_config.tentAlert == 1 then
      message = T['Tent alert enabled (current zone)']
    else
      message = T['Tent alert enabled (global)']
    end
    PWB:Print(message)
    return
  end

  if command == 'wheretents' or command == 'wheretent' or command == 'where' or command == 'wt' then
    PWB.tents.printAll()
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

  if command == 'dmfbuffs' then
    PWB:PrintClean(PWB.Colors.primary .. 'Darkmoon Faire|r Buffs:')
    PWB:PrintClean('   (1-1)  +10% Damage')
    PWB:PrintClean('   (1-2)  +25 All Resistances')
    PWB:PrintClean('   (1-3)  +10% Armor')
    PWB:PrintClean('   (2-1)  +10% Spirit')
    PWB:PrintClean('   (2-2)  +10% Intelligence')
    PWB:PrintClean('   (2-3)  +25 All Resistances')
    PWB:PrintClean('   (3-1)  +10% Stamina')
    PWB:PrintClean('   (3-2)  +10% Strength')
    PWB:PrintClean('   (3-3)  +10% Agility')
    PWB:PrintClean('   (4-1)  +10% Intelligence')
    PWB:PrintClean('   (4-2)  +10% Spirit')
    PWB:PrintClean('   (4-3)  +10% Armor')
    return
  end

  if command == 'version' then
    PWB:Print(T['Version'] .. ' ' .. PWB.utils.getVersion())
    return
  end

  -- Add new commands HERE, just before the help text
  if command == 'horizontal' then
    PWB_config.orientation = 'horizontal'
    PWB.frame.updateFrames()
    PWB:Print(T['Text orientation set to horizontal'])
    return
  end

  if command == 'vertical' then
    PWB_config.orientation = 'vertical'
    PWB.frame.updateFrames()
    PWB:Print(T['Text orientation set to vertical'])
    return
  end

  -- Help text (default case when no command matches)
  PWB:PrintClean(PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs|r ' .. T['commands'] .. ':')
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r show ' .. PWB.Colors.grey .. '- ' .. T['Show the addon'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r hide ' .. PWB.Colors.grey .. '- ' .. T['Hide the addon'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r toggle ' .. PWB.Colors.grey .. '- ' .. T['Toggle show/hide the addon'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r lock ' .. (PWB_config.lock and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Lock PizzaWorldBuffs frame'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r header ' .. (PWB_config.header and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Show PizzaWorldBuffs header'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r dmf ' .. (PWB_config.dmf and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Show Darkmoon Faire location'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r all ' .. (PWB_config.allFactions and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Show both factions\' world buff timers'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r mapHeads ' .. (PWB_config.mapHeads and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Show Ony/Nef head timers on the SW/OG map'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r tents ' .. (PWB_config.tents and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Show tent locations on the world map'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r tentStyle ' .. PWB_config.tentStyle .. PWB.Colors.grey .. ' - ' .. T['Choose between tent styles 1, 2, 3, 4, 5, 6, 7 and 1337'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r tentAlert ' .. PWB_config.tentAlert .. PWB.Colors.grey .. ' - ' .. T['Alert about new tents in your zone (1) or anywhere (2)'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r whereTents ' .. PWB.Colors.grey .. '- ' .. T['List all currently known tent locations'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r logout ' .. (PWB_config.autoLogout and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Log out automatically after receiving next buff'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r exit ' .. (PWB_config.autoExit and 1 or 0) .. PWB.Colors.grey .. ' - ' .. T['Exit game automatically after receiving next buff'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r reset ' .. PWB.Colors.grey .. '- ' .. T['Reset PizzaWorldBuffs frames to their default positions'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r fontSize ' .. PWB_config.fontSize .. PWB.Colors.grey .. ' - ' .. T['Set font size'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r align ' .. PWB_config.align .. PWB.Colors.grey .. ' - ' .. T['Align text left/center/right'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r horizontal ' .. PWB.Colors.grey .. '- ' .. T['Set text orientation to horizontal']) -- New
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r vertical ' .. PWB.Colors.grey .. '- ' .. T['Set text orientation to vertical']) -- New
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r dmfbuffs ' .. PWB.Colors.grey .. '- ' .. T['Show list of Darkmoon Faire buffs'])
  PWB:PrintClean(PWB.Colors.primary .. '   /wb|r version ' .. PWB.Colors.grey .. '- ' .. T['Show current version'])
end
