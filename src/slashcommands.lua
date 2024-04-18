SLASH_PIZZAWORLDBUFFS1, SLASH_PIZZAWORLDBUFFS2 = '/pwb', '/wb'
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

  if command == 'clear' then
    PWB.core.clearAllTimers()
    return
  end

  if command == 'fontsize' then
    local fontSize = tonumber(msg)
    if not fontSize then
      PWB:Print('Invalid option. Only numbers allowed!')
      return
    end

    local fontName, _, fontStyle = PWB.frame.text:GetFont()
    PWB.frame.text:SetFont(fontName, fontSize, fontStyle)
    PWB_config.fontSize = fontSize
    PWB:Print(PWB.Colors.grey .. 'Changed font size to ' .. PWB_config.fontSize)
    return
  end

  if command == 'all' then
    local number = tonumber(msg)
    if not number or (number ~= 0 and number ~= 1) then
      PWB:Print('Valid options are 0 and 1')
      return
    end

    PWB_config.allFactions = number == 1
    local message = PWB_config.allFactions and 'Showing both factions\' world buff timers' or 'Only showing your faction\'s world buff timers'
    PWB:Print(PWB.Colors.grey .. message)
    return
  end

  if command == 'version' then
    PWB:Print('Version ' .. PWB.utils.getVersion())
    return
  end

  PWB:PrintClean(PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs|r commands:')
  PWB:PrintClean(PWB.Colors.primary .. '  /wb|r show ' .. PWB.Colors.grey .. '- Show the addon')
  PWB:PrintClean(PWB.Colors.primary .. '  /wb|r hide ' .. PWB.Colors.grey .. '- Hide the addon')
  PWB:PrintClean(PWB.Colors.primary .. '  /wb|r clear ' .. PWB.Colors.grey .. '- Clear all world buff timers')
  PWB:PrintClean(PWB.Colors.primary .. '  /wb|r fontSize ' .. PWB_config.fontSize .. PWB.Colors.grey .. ' - Set font size')
  PWB:PrintClean(PWB.Colors.primary .. '  /wb|r all ' .. (PWB_config.allFactions and 1 or 0) .. PWB.Colors.grey .. ' - Show both factions\' world buff timers')
  PWB:PrintClean(PWB.Colors.primary .. '  /wb|r version ' .. PWB.Colors.grey .. '- Show current version')
end