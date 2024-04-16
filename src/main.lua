PWB = CreateFrame('Frame', nil, UIParent)
PWB.name = 'PizzaWorldBuffs'
PWB.abbrev = 'PWB'

PWB.Colors = {
  pizzaPurple = '|cffa050ff',
  alliance = '|cff0070dd',
  horde = '|cffc41e3a',
  grey = '|cffaaaaaa',
  darkgrey = '|cff777777',
  green = '|cff00ff98',
  orange = '|cffff7c0a',
  red = '|cffc41e3a',
}

PWB.Bosses = {
  O = 'Onyxia',
  N = 'Nefarian',
}

function PWB:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(PWB.Colors.pizzaPurple .. 'Pizza' .. PWB.Colors.darkgrey .. 'WorldBuffs:|r ' .. msg)
end

PWB:RegisterEvent('PLAYER_ENTERING_WORLD')
PWB:RegisterEvent('CHAT_MSG_ADDON')
PWB:RegisterEvent('CHAT_MSG_CHANNEL')
PWB:RegisterEvent('CHAT_MSG_MONSTER_YELL')
PWB:SetScript('OnEvent', function ()
  if event == 'PLAYER_ENTERING_WORLD' then
    -- Store player's name & faction ('A' or 'H') for future use
    PWB.me = UnitName('player')
    PWB.myFaction = string.sub(UnitFactionGroup('player'), 1, 1)

    if not PWB.core.hasTimers() then
      -- If we don't have any timers, initialize them
      PWB.core.clearAllTimers()
    end

    PWB.core.resetPublishDelay()

    -- Trigger delayed joining of the PWB chat channel
    PWB.channelJoinDelay:Show()
  end

  if event == 'CHAT_MSG_MONSTER_YELL' then
    local boss, faction = PWB.core.parseMonsterYell(arg1)
    if boss and faction then
      PWB.core.setTimer({
        faction = faction,
        boss = boss,
        deadline = PWB.utils.hoursFromNow(2),
        witness = PWB.me,
        receivedFrom = PWB.me,
      })
    end
  end

  if event == 'CHAT_MSG_CHANNEL' and arg2 ~= UnitName('player') then
    local _, _, source = string.find(arg4, '(%d+)%.')
    local channelName

		if source then
			_, channelName = GetChannelName(source)
		end

    if channelName == PWB.name then
			local addonName, version, msg = PWB.utils.strSplit(arg1, ':')
			if addonName == PWB.abbrev then
        PWB.core.resetPublishDelay()

        local timerStrs = { PWB.utils.strSplit(msg, ';') }
        for _, timerStr in next, timerStrs do
          local timer = PWB.core.decode(timerStr)
          if not timer or not timer.faction or not timer.boss or not timer.deadline or not timer.witness then return end

          timer.receivedFrom = arg2
          if PWB.core.shouldAcceptNewTimer(timer) then
            PWB.core.setTimer(timer)
          end
        end
      end
		end
  end
end)

PWB:SetScript('OnUpdate', function ()
  PWB.core.clearExpiredTimers()
  if PWB.core.shouldPublishTimers() then
    PWB.core.publishTimers()
  end
end)