SLASH_PIZZAWORLDBUFFS1, SLASH_PIZZAWORLDBUFFS2 = '/pwb', '/wb'
SlashCmdList['PIZZAWORLDBUFFS'] = function (args, editbox)
  local cmd, msg = PWB.utils.strSplit(args, ' ')
  local command = cmd and string.lower(cmd)

  if not command then
    PWB:Print('/wb clear ' .. PWB.Colors.grey .. '- Clear all world buff timers')
    PWB:Print('/wb fontSize ' .. PWB_config.fontSize .. PWB.Colors.grey .. ' - Set font size')
    PWB:Print('/wb all ' .. (PWB_config.allFactions and 1 or 0) .. PWB.Colors.grey .. ' - Show both factions\' world buff timers')
  end

  if command == 'clear' then
    PWB.core.clearTimers()
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

  -- Message format:
  --
  --   PizzaWorldBuffs:FACTION-BOSS-HH-MM-WITNESS;FACTION-BOSS-HH-MM-WITNESS;...
  --
  --   FACTION    'A' or 'H'
  --   BOSS       'ONY' or 'NEF'
  --   TIME       The server time at which the head will go down again, in HH-MM format
  --   WITNESS    0 if the sender got the time from someone else, 1 if they witnessed the buff themselves
  --
  -- Example:
  --   PizzaWorldBuffs:A-ONY-16-37-1;H-NEF-17-03-0
  if command == 'test' then
    local timerStrs = { PWB.utils.strSplit(msg, ';') }
    for _, timerStr in next, timerStrs do
      local timer = PWB.core.decode(timerStr, true)
      if PWB.core.shouldUpdateTimer(timer) then
        PWB_timers[timer.faction][timer.boss] = {
          faction = timer.faction,
          boss = timer.boss,
          deadline = timer.deadline,
          fromWitness = timer.fromWitness,
          witnessedMyself = timer.witnessedMyself,
        }
      end
    end
  end
end