PizzaWorldBuffs = CreateFrame('Frame', 'PizzaWorldBuffs', UIParent)
local PWB = PizzaWorldBuffs
PWB.abbrev = 'PWB'
PWB.abbrevDmf = 'PWB_DMF'
PWB.abbrevTents = 'PWB_T'

-- If many players are using the addon and we're unlucky, we mayb never be able to publish our timers, because
-- someone else will publish theirs before us every time. To combat this and allow everyone to publish their
-- timers eventually, we use a publish interval upper limit. If this runs out, we just blindly publish our 
-- timers regardless, even if someone else publishes theirs before us again.
PWB.maxPublishIntervalMinutes = 3

PWB.Colors = {
  primary = '|cffa050ff',
  secondary = '|cffffffff',

  alliance = '|cff0070dd',
  horde = '|cffc41e3a',
  white = '|cffffffff',
  grey = '|cffaaaaaa',
  green = '|cff00ff98',
  orange = '|cffff7c0a',
  red = '|cffc41e3a',
}

local dmfNpcNames = {
  'Flik',
  'Sayge',
  'Burth',
  'Lhara',
  'Morja',
  'Jubjub',
  'Chronos',
  'Felinni',
  'Rinling',
  'Sylannia',
  'Hornsley',
  'Kerri Hicks',
  'Flik\'s Frog',
  'Yebb Neblegear',
  'Silas Darkmoon',
  'Selina Dourman',
  'Khaz Modan Ram',
  'Pygmy Cockatrice',
  'Gelvas Grimegate',
  'Stamp Thunderhorn',
  'Maxima Blastenheimer',
  'Professor Thaddeus Paleo',
}

PWB.env = {}
setmetatable(PWB.env, { __index = function (self, key)
  if key == 'T' then return end
  return getfenv(0)[key]
end})
function PWB:GetEnv()
  if not PWB.env.T then
    local locale = GetLocale() or 'enUS'
    PWB.env.T = setmetatable((PWB_translations or {})[locale] or {}, {
      __index = function(tbl, key)
        local value = tostring(key)
        rawset(tbl, key, value)
        return value
      end
    })
  end
  PWB.env._G = getfenv(0)
  return PWB.env
end
setfenv(1, PWB:GetEnv())

PWB.Bosses = {
  O = T['Onyxia'] or 'Onyxia',
  N = T['Nefarian'] or 'Nefarian',
}

PWB.DmfLocations = {
  E = T['Elwynn Forest'] or 'Elwynn Forest',
  M = T['Mulgore'] or 'Mulgore',
}

function PWB:Print(msg, withPrefix)
  local prefix = withPrefix == false and '' or PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs:|r '
  DEFAULT_CHAT_FRAME:AddMessage(prefix .. msg)
end

function PWB:PrintClean(msg)
  PWB:Print(msg, false)
end

local timerStrs = {}
PWB:RegisterEvent('ADDON_LOADED')
PWB:RegisterEvent('PLAYER_ENTERING_WORLD')
PWB:RegisterEvent('CHAT_MSG_ADDON')
PWB:RegisterEvent('CHAT_MSG_CHANNEL')
PWB:RegisterEvent('CHAT_MSG_MONSTER_YELL')
PWB:RegisterEvent('CHAT_MSG_WHISPER')
PWB:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
PWB:SetScript('OnEvent', function ()
  if event == 'ADDON_LOADED' and arg1 == 'PizzaWorldBuffs' then
    -- Initialize config with default values if necessary
    PWB.config.init()

    if PWB_config.autoLogout then
      PWB_config.autoLogout = false
      PWB:Print(T['Auto-logout disabled automatically. To enable it again, use /wb logout 1'])
    end

    if PWB_config.autoExit then
      PWB_config.autoExit = false
      PWB:Print(T['Auto-exit disabled automatically. To enable it again, use /wb exit 1'])
    end
  end

  if event == 'PLAYER_ENTERING_WORLD' then
    -- PWB:Print(T['Just a test LOL'])

    -- Store player's name & faction ('A' or 'H') for future use
    PWB.me = UnitName('player')
    PWB.myFaction = string.sub(UnitFactionGroup('player'), 1, 1)
    -- Workaround for Turtle WoW's Spanish localization
    if PWB.myFaction ~= "A" and PWB.myFaction ~= "H" then
        local _, raceEn = UnitRace('player')
        local hordeRaces = {
            Orc = true,
            Scourge = true,
            Troll = true,
            Tauren = true,
            Goblin = true,
        }
        PWB.myFaction = hordeRaces[raceEn] and "H" or "A"
    end
    PWB.isOnKalimdor = GetCurrentMapContinent() == 1

    -- If we don't have any timers or we still have timers in a deprecated format, clear/initialize them first.
    if not PWB.utils.hasTimers() or PWB.utils.hasDeprecatedTimerFormat() then
      PWB.core.clearAllTimers()
    end

    -- Publish everything once whenever we log in
    PWB.core.publishAll()

    -- Trigger delayed joining of the PWB chat channel
    PWB.channelJoinDelay:Show()
  end

  if event == 'CHAT_MSG_MONSTER_YELL' then
    local boss, faction = PWB.core.parseMonsterYell(arg1)
    if boss and faction then
      local h, m = PWB.utils.hoursFromNow(2)
      PWB.core.setTimer(faction, boss, h, m, PWB.me, PWB.me)

      if PWB_config.autoLogout or PWB_config.autoExit then
        local message = PWB_config.autoExit and T['About to receive buff and auto-exit is enabled. Will exit game in 1 minute.'] or T['About to receive buff and auto-logout is enabled. Will log out in 1 minute.']
        PWB:Print(message)
        PWB.logoutAt = time() + 60
      end
    end
  end

  if event == 'CHAT_MSG_CHANNEL' and arg2 ~= UnitName('player') then
    local _, _, source = string.find(arg4, '(%d+)%.')
    local channelName

    if source then
      _, channelName = GetChannelName(source)
    end

    if channelName == PWB.channelName then
      local _, _, addonName, remoteVersion, msg = string.find(arg1, '(.*)%:(.*)%:(.*)')
      if addonName == PWB.abbrev then
        -- Ignore timers from players with pre-1.1.4 versions that contain a bug where it sometimes
        -- shares invalid/expired timers with everyone.
        if tonumber(remoteVersion) < 10104 then
          return
        end

        PWB.core.resetPublishDelay()

        timerStrs[1], timerStrs[2], timerStrs[3], timerStrs[4] = PWB.utils.strSplit(msg, ';')
        for _, timerStr in next, timerStrs do
          local faction, boss, h, m, witness = PWB.core.decode(timerStr)
          if not faction or not boss or not h or not m or not witness then return end

          local receivedFrom = arg2
          if PWB.core.shouldAcceptNewTimer(faction, boss, h, m, witness, receivedFrom) then
            PWB.core.setTimer(faction, boss, h, m, witness, receivedFrom)
          end
        end

        if tonumber(remoteVersion) > PWB.utils.getVersionNumber() and not PWB.updateNotified then
          PWB:Print(T['New version available! https://github.com/Pizzahawaiii/PizzaWorldBuffs'])
          PWB.updateNotified = true
        end
      elseif addonName == PWB.abbrevDmf then
        PWB.core.resetPublishDelay()
        local location, seenAt, witness = PWB.core.decodeDmf(msg)
        if PWB.core.shouldAcceptDmfLocation(seenAt, tonumber(remoteVersion)) then
          PWB.core.setDmfLocation(location, seenAt, witness)
        end
      end
    end
  end

  if event == 'CHAT_MSG_WHISPER' and string.find(UnitName('player'), 'Pizza') then
    local msg, from = string.lower(string.gsub(arg1, '?', '')), arg2
    if msg == 'ony when' or msg == 'nef when' or msg == 'buff when' or msg == 'buf when' or msg == 'head when' then
      local aOnyText = PWB.share.getText('timer', { faction = 'A', boss = 'O' })
      local aNefText = PWB.share.getText('timer', { faction = 'A', boss = 'N' })
      local hOnyText = PWB.share.getText('timer', { faction = 'H', boss = 'O' })
      local hNefText = PWB.share.getText('timer', { faction = 'H', boss = 'N' })
      SendChatMessage(aOnyText, 'WHISPER', nil, from)
      SendChatMessage(aNefText, 'WHISPER', nil, from)
      SendChatMessage(hOnyText, 'WHISPER', nil, from)
      SendChatMessage(hNefText, 'WHISPER', nil, from)
    elseif msg == 'dmf where' or msg == 'dmf' or msg == 'dmf loc' or msg == 'dmf location' then
      local dmfText = PWB.share.getText('dmf')
      SendChatMessage(dmfText, 'WHISPER', nil, from)
    end
  end

  if event == 'UPDATE_MOUSEOVER_UNIT' and not UnitIsPlayer('mouseover') and PWB.utils.contains(dmfNpcNames, UnitName('mouseover')) then
    local zone = GetZoneText()
    if zone == 'Elwynn Forest' or zone == T['Elwynn Forest'] or zone == 'Mulgore' or zone == T['Mulgore'] then
      PWB.core.setDmfLocation(string.sub(zone, 1, 1), time(), PWB.me)
    end
  end
end)

PWB:SetScript('OnUpdate', function ()
  -- Throttle this function so it doesn't run on every frame render
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end

  PWB.core.clearExpiredTimers()

  if (PWB_config.autoLogout or PWB_config.autoExit) and PWB.logoutAt and time() >= PWB.logoutAt then
    PWB.logoutAt = nil
    PWB.core.publishAll()
    if PWB_config.autoLogout then
      PWB:Print(T['Logging out...'])
      Logout()
    else
      PWB:Print(T['Exiting game...'])
      Quit()
    end
  elseif PWB.core.shouldPublish() then
    PWB.core.publishAll()
  end
end)
