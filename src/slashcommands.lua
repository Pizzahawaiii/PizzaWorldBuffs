SLASH_PIZZAWORLDBUFFS1, SLASH_PIZZAWORLDBUFFS2 = '/pwb', '/wb'
SlashCmdList['PIZZAWORLDBUFFS'] = function (args, editbox)
  local cmd, msg = PWB.utils.strSplit(args, ' ')
  local command = cmd and string.lower(cmd)

  if not command then
    PWB:Print('/wb show ' .. PWB.Colors.grey .. '- Show the addon')
    PWB:Print('/wb hide ' .. PWB.Colors.grey .. '- Hide the addon')
    PWB:Print('/wb clear ' .. PWB.Colors.grey .. '- Clear all world buff timers')
    PWB:Print('/wb fontSize ' .. PWB_config.fontSize .. PWB.Colors.grey .. ' - Set font size')
    PWB:Print('/wb all ' .. (PWB_config.allFactions and 1 or 0) .. PWB.Colors.grey .. ' - Show both factions\' world buff timers')
  end

  if command == 'show' then
    PWB_config.show = true
    PWB.frame:Show()
  end

  if command == 'hide' then
    PWB_config.show = false
    PWB.frame:Hide()
  end

  if command == 'clear' then
    PWB.core.clearAllTimers()
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
  end
end