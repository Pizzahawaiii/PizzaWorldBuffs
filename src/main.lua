PWB = CreateFrame('Frame', nil, UIParent)
PWB.name = 'PizzaWorldBuffs'

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
  ONY = 'Onyxia',
  NEF = 'Nefarian',
}

function PWB:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(PWB.Colors.pizzaPurple .. 'Pizza' .. PWB.Colors.darkgrey .. 'WorldBuffs:|r ' .. msg)
end

PWB:RegisterEvent('CHAT_MSG_ADDON')
PWB:RegisterEvent('CHAT_MSG_CHANNEL')
PWB:RegisterEvent('PLAYER_ENTERING_WORLD')
PWB:RegisterEvent('CHAT_MSG_MONSTER_YELL')
PWB:SetScript('OnEvent', function ()
  if event == 'PLAYER_ENTERING_WORLD' then
    -- Store player's faction for future use ('A' or 'H')
    PWB.playerFaction = string.sub(UnitFactionGroup("player"), 1, 1)

    if not PWB.core.hasTimers() then
      -- If we don't have any timers, initialize them
      PWB.core.clearTimers()
    end

    PWB.core.resetPublishDelay()

    -- Trigger delayed joining of the PWB chat channel
    PWB.channelJoinDelay:Show()
  end

  if event == 'CHAT_MSG_MONSTER_YELL' then
    PWB:Print('Received monster yell message: ' .. arg1)
    local boss, faction = PWB.core.parseMonsterYell(arg1)
    if boss and faction then
      PWB:Print('--> BUFF DROPPING: ' .. boss .. ' (' .. faction .. ')')
      PWB_timers[PWB.playerFaction][boss] = {
        faction = faction,
        boss = boss,
        deadline = PWB.utils.hoursFromNow(2),
        fromWitness = false,
        witnessedMyself = true,
      }
    end
  end

  if event == 'CHAT_MSG_CHANNEL' and arg2 ~= UnitName('player') then
    local _, _, source = string.find(arg4, '(%d+)%.')
    local channelName

		if source then
			_, channelName = GetChannelName(source)
		end

    if channelName == PWB.name then
			local addonName, msg = PWB.utils.strSplit(arg1, ':')
			if addonName == PWB.name then
        PWB.core.resetPublishDelay()

        local timerStrs = { PWB.utils.strSplit(msg, ';') }
        for _, timerStr in next, timerStrs do
          local timer = PWB.core.decode(timerStr)
          if not timer or not timer.faction or not timer.boss or not timer.deadline or timer.fromWitness == nil then return end
          timer.witnessedMyself = false

          if PWB.core.shouldUpdateTimer(timer) then
            PWB_timers[timer.faction][timer.boss] = {
              faction = timer.faction,
              boss = timer.boss,
              deadline = timer.deadline,
              fromWitness = timer.fromWitness,
              witnessedMyself = false,
            }
          end
        end
      end
		end
  end
end)

PWB:SetScript('OnUpdate', function ()
  if PWB.core.shouldPublishTimers() then
    PWB.core.publishTimers()
  end
end)