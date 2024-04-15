PWB.core = {}

local BUFF_CD_HOURS = 2

function PWB.core.encode (timer)
  if not timer or not timer.faction or not timer.boss or not timer.deadline or timer.witnessedMyself == nil then return end
  return string.format('%s-%s-%.2d-%.2d-%d', timer.faction, timer.boss, timer.deadline.h, timer.deadline.m, timer.witnessedMyself and 1 or 0)
end

function PWB.core.encodeAll ()
  local timersStr
  for faction, timers in pairs(PWB_timers) do
    for boss, timer in pairs(timers) do
      timersStr = (timersStr and timersStr .. ';' or '') .. PWB.core.encode(timer)
    end
  end
  return timersStr
end

function PWB.core.decode (timerStr, myOwn)
  local faction, boss, hStr, mStr, fromWitnessStr = PWB.utils.strSplit(timerStr, '-')
  local deadline = {
    h = tonumber(hStr),
    m = tonumber(mStr),
  }
  local fromWitness = not myOwn and fromWitnessStr == '1'
  local witnessedMyself = myOwn and fromWitnessStr == '1'

  return {
    faction = faction,
    boss = boss,
    deadline = deadline,
    fromWitness = fromWitness,
    witnessedMyself = witnessedMyself,
  }
end

function PWB.core.getTimeLeft (timer)
  local deadline = { h = timer.deadline.h, m = timer.deadline.m }
  local now = PWB.utils.getServerTime()

  if now.h > deadline.h and deadline.h < BUFF_CD_HOURS then
    -- now is before and deadline is after midnight. Let's just fix the diff
    -- calculation by adding 24 hours to the deadline time.
    deadline.h = deadline.h + 24
  end

  local diff = PWB.utils.toMinutes(deadline) - PWB.utils.toMinutes(now)

  local isExpired = diff < 0
  local isInvalid = diff > BUFF_CD_HOURS * 60
  if isExpired or isInvalid then return end

  return PWB.utils.toTime(diff)
end

function PWB.core.isValid (timer)
  return PWB.core.getTimeLeft(timer) ~= nil
end

local yellTriggers = {
  A = {
    ONY = 'The dread lady, Onyxia, hangs from the arches!',
    NEF = 'Citizens of the Alliance, the Lord of Blackrock is slain! Nefarian has been subdued',
  },
  H = {
    ONY = 'The brood mother, Onyxia, has been slain!',
    NEF = 'NEFARIAN IS SLAIN! People of Orgrimmar, bow down before the might of',
  },
}
function PWB.core.parseMonsterYell (yellMsg)
  for faction, bossTriggers in pairs(yellTriggers) do
    for boss, yellTrigger in pairs(bossTriggers) do
      local found = string.find(yellMsg, yellTrigger)
      if found then
        return boss, faction
      end
    end
  end
end

function PWB.core.getTimer (faction, boss)
  return PWB_timers[faction][boss]
end

function PWB.core.setTimer (timer)
  PWB_timers[timer.faction][timer.boss] = timer
end

function PWB.core.clearTimer (faction, boss)
  PWB_timers[faction][boss] = nil
end

function PWB.core.clearExpiredTimers ()
  if not PWB_timers then return end

  for faction, timers in pairs(PWB_timers) do
    for boss, timer in pairs(timers) do
      if not PWB.core.isValid(timer) then
        PWB.core.clearTimer(faction, boss)
      end
    end
  end
end

function PWB.core.clearAllTimers ()
  PWB_timers = {
    A = {
      ONY = nil,
      NEF = nil,
    },
    H = {
      ONY = nil,
      NEF = nil,
    },
  }
end

function PWB.core.shouldUpdateTimer (newTimer)
  local currentTimer = PWB.core.getTimer(newTimer.faction, newTimer.boss)

  -- Always update if we currently don't have a timer for this buff
  if not currentTimer then return true end

  -- Always accept new timers that we witnessed ourselves
  if newTimer.witnessedMyself then return true end

  -- Never update if we currently have a timer that we witnessed ourselves
  if currentTimer.witnessedMyself then return false end

  -- Otherwise, only update if the new timer came from a direct witness and our current one didn't
  return newTimer.fromWitness and not currentTimer.fromWitness
end

function PWB.core.hasTimers ()
  if not PWB_timers then return false end

  for _, timers in pairs(PWB_timers) do
    for _, timer in pairs(timers) do
      if timer then return true end
    end
  end

  return false
end

function PWB.core.resetPublishDelay ()
  -- (Re)set our own publishAll delay to a random number of seconds
  -- TODO: Tweak this so we don't spam the channel too much once more people use the addon
  -- TODO: Ideally, think of a better solution
  PWB.publishAt = GetTime() + math.random(5, 30)
end

function PWB.core.shouldPublishTimers ()
  return PWB.publishAt and GetTime() > PWB.publishAt
end

function PWB.core.publishTimers ()
  PWB.core.resetPublishDelay()

  if UnitLevel('player') < 5 or not PWB.core.hasTimers() then
    return
  end

  local pwbChannel = GetChannelName(PWB.name)
  if pwbChannel ~= 0 then
    SendChatMessage(PWB.name .. ':' .. PWB.core.encodeAll(), 'CHANNEL', nil, pwbChannel)
  end
end