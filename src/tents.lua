local PWB = PizzaWorldBuffs
PWB.tents = {}

setfenv(1, PWB:GetEnv())

--
-- Tent radius: 1.5 with buffer (coords)
-- /LFT character limit: 255 (probably?)
--

local scheduledTentAlerts = {}

local frame = CreateFrame('Frame', 'PizzaWorldBuffsTents', UIParent)
frame:ClearAllPoints()
frame:SetPoint('TOP', 0, -250)
frame:SetFrameStrata('LOW')
frame.text = frame:CreateFontString('PizzaWorldBuffsTentsText', 'DIALOG', 'GameFontWhite')
frame.text:SetFont(STANDARD_TEXT_FONT, 16, 'OUTLINE')
frame.text:SetJustifyH('CENTER')
frame.text:SetPoint('TOP', 0, 0)
frame:SetWidth(frame.text:GetWidth())
frame:SetHeight(frame.text:GetHeight())
frame:Show()

function length(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function cutHead(t)
  for i, v in ipairs(t) do
    if i > 1 then
      t[i - 1] = t[i]
    end
  end
  table.remove(t, length(t))
end

local secondsToProbe = 10
local probes = secondsToProbe * 10
local lastRestedGains = {}
local lastTentSavedAt = 0
local wasMapOpen = false
frame:SetScript('OnUpdate', function ()
  local now = GetTime()

  if (this.tick or .1) > now then return else this.tick = now + .1 end

  if WorldMapFrame:IsVisible() and not wasMapOpen then
    PWB.tents.updatePins()
    wasMapOpen = true
  elseif not WorldMapFrame:IsVisible() and wasMapOpen then
    wasMapOpen = false
  end

  local rested = GetXPExhaustion() or 0

  if length(lastRestedGains) >= probes then
    cutHead(lastRestedGains)
  end

  table.insert(lastRestedGains, rested)

  if length(lastRestedGains) == probes then
    local diff = lastRestedGains[probes] - lastRestedGains[1]
    local diffAvg = diff / secondsToProbe
    local rate = diffAvg / UnitXPMax('player') * 100
    local tent = rate >= .13
    local stack = math.floor(rate / .13)
    local now = time()

    if tent and (now - lastTentSavedAt > 5) and not WorldMapFrame:IsShown() then
      SetMapToCurrentZone()
      local zone = GetZoneText()
      local x, y = GetPlayerMapPosition("player")
      PWB.tents.save(zone, x, y, stack, now, now, true)
      lastTentSavedAt = now
    end
  end

  if (this.mediumTick or 1) > now then return else this.mediumTick = now + 1 end

  PWB.tents.processScheduledAlerts()

  if (this.longTick or 5) > now then return else this.longTick = now + 5 end

  PWB.tents.clearExpiredTents()
end)

function PWB.tents.save(zone, x, y, stack, firstSeen, lastSeen, imTheWitness)
  if not zone or not x or not y or not stack or not firstSeen or not lastSeen then
    return
  end

  if not PWB_tents then
    _G.PWB_tents = {}
  end

  if not PWB_tents[zone] then
    _G.PWB_tents[zone] = {}
  end

  -- See if we already have a tent stored around that location and if
  -- we have to update it.
  local tentsUpdated = false
  local existingTent, idx = PWB.tents.findTent(zone, x, y)
  if existingTent then
    if lastSeen > existingTent.lastSeen then
      _G.PWB_tents[zone][idx].stack = stack
      _G.PWB_tents[zone][idx].lastSeen = lastSeen
      tentsUpdated = true
    end
  else
    local newTent = {
      x = x,
      y = y,
      zone = zone,
      stack = stack,
      firstSeen = firstSeen,
      lastSeen = lastSeen,
    }
    newTent.id = PWB.utils.getId(newTent)
    table.insert(_G.PWB_tents[zone], newTent)
    tentsUpdated = true

    -- Always immediately publish new tents when I discover them.
    if imTheWitness then
      PWB.tents.publish(newTent)
    end

    if PWB_config.tents and not imTheWitness then
      if PWB_config.tentAlert == 2 then
        PWB.tents.scheduleAlert(newTent)
      elseif PWB_config.tentAlert == 1 and not WorldMapFrame:IsShown() then
        SetMapToCurrentZone()
        if zone == PWB.utils.getCurrentMapZoneName() then
          PWB.tents.scheduleAlert(newTent)
        end
      end
    end
  end

  if tentsUpdated and WorldMapFrame:IsVisible() then
    PWB.tents.updatePins()
  end
end

function PWB.tents.scheduleAlert(tent)
  if not tent.id then return end

  local alertDelay = 10
  scheduledTentAlerts[tent.id] = time() + alertDelay
end

function PWB.tents.processScheduledAlerts()
  for id, alertAt in pairs(scheduledTentAlerts) do
    if time() >= alertAt then
      local tent = PWB.tents.findTentById(id)
      if tent then
        local lastSeenAgoStr, lastSeenAgoColor = PWB.tents.getSeenAgoStr(time() - tent.lastSeen)
        local tentAlertMessage = 'Tent detected in ' .. PWB.Colors.primary .. tent.zone .. PWB.Colors.grey .. ' (' .. lastSeenAgoColor .. lastSeenAgoStr .. PWB.Colors.grey .. ' ago)'
        PWB:Print(tentAlertMessage)
        scheduledTentAlerts[id] = nil
      else
        scheduledTentAlerts[id] = nil
      end
    end
  end
end

function PWB.tents.findTentById(id)
  for _, tents in pairs(PWB_tents) do
    for _, tent in ipairs(tents) do
      if tent.id then
        if tent.id == id then return tent end
      end
    end
  end
end

function PWB.tents.findTent(zone, x, y)
  if not PWB_tents or not PWB_tents[zone] then
    return
  end

  for idx, tent in ipairs(PWB_tents[zone]) do
    if PWB.tents.distance(x, y, tent.x, tent.y) < 1.5 then
      return tent, idx
    end
  end
end

function PWB.tents.distance(x1, y1, x2, y2)
  return sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2));
end

local zone, lastZone
frame:RegisterEvent('ZONE_CHANGED')
frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
frame:RegisterEvent('MINIMAP_ZONE_CHANGED')
frame:RegisterEvent('WORLD_MAP_UPDATE')
frame:RegisterEvent('CHAT_MSG_CHANNEL')
frame:SetScript('OnEvent', function() 
  if event == 'CHAT_MSG_CHANNEL' then
    if arg2 ~= PWB.me then
      local _, _, source = string.find(arg4, '(%d+)%.')
      local channelName

      if source then
        _, channelName = GetChannelName(source)
      end

      if string.lower(channelName) == string.lower(PWB.channelName) then
        local _, _, addonName, remoteVersion, encodedTents = string.find(arg1, '(.*)%:(.*)%:(.*)')
        if addonName == PWB.abbrevTents then
          PWB.tents.decodeAndSaveAll(encodedTents)

          if tonumber(remoteVersion) > PWB.utils.getVersionNumber() and not PWB.updateNotified then
            PWB:Print(T['New version available! https://github.com/Pizzahawaiii/PizzaWorldBuffs'])
            PWB.updateNotified = true
          end
        end
      end
    end
  else
    -- save current zone
    zone = GetCurrentMapZone()

    if event == "ZONE_CHANGED" or event == "MINIMAP_ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
      if not WorldMapFrame:IsShown() then
        SetMapToCurrentZone()
      end
    end

    -- update nodes on world map changes
    if event == "WORLD_MAP_UPDATE" and lastZone ~= zone then
      PWB.tents.updatePins()
      lastZone = zone
    end
  end
end)

function PWB.tents.isExpired(tent)
  local tentDuration = 15 * 60
  local tenMinutes = 10 * 60
  local fiveMinutes = 5 * 60
  local firstSeenAgo = time() - tent.firstSeen
  local lastSeenAgo = time() - tent.lastSeen

  if lastSeenAgo > tentDuration then
    return true
  end

  if firstSeenAgo > tenMinutes and lastSeenAgo > fiveMinutes then
    return true
  end

  return false
end

function PWB.tents.clearExpiredTents()
  if not PWB_tents then
    return
  end

  local tentsUpdated = false
  for zone, tents in pairs(PWB_tents) do
    for idx, tent in ipairs(tents) do
      if PWB.tents.isExpired(tent) then
        _G.PWB_tents[zone][idx] = nil
        if length(PWB_tents[zone]) == 0 then
          _G.PWB_tents[zone] = nil
        end
        tentsUpdated = true
      end
    end
  end

  if tentsUpdated and WorldMapFrame:IsVisible() then
    PWB.tents.updatePins()
  end
end

function PWB.tents.valid(tent)
  return tent and tent.x and tent.y and tent.zone and tent.stack and tent.firstSeen and tent.lastSeen
end

function PWB.tents.hasTents()
  if not PWB_tents then
    return false
  end

  for _, tents in pairs(PWB_tents) do
    if length(tents) > 0 then
      return true
    end
  end
  return false
end

function PWB.tents.getZoneIds(zoneName)
  local continents = { GetMapContinents() }
  for cid, _ in pairs(continents) do
    local zones = { GetMapZones(cid) }
    for zid, zone in pairs(zones) do
      if zone == zoneName then
        return cid, zid
      end
    end
  end
end

local zonesCache = {
  [1] = {},
  [2] = {},
}
local function populateZonesCache(cid, ...)
  for i = 1, arg.n, 1 do
    zonesCache[cid][i] = arg[i]
  end
end

function PWB.tents.getZoneName(cid, zid)
  if not zonesCache[cid] or not zonesCache[cid][zid] then
    populateZonesCache(cid, GetMapZones(cid))
  end

  local res = zonesCache[cid][zid]
  return res
end

function PWB.tents.printAll()
  local knownTents = {}

  if not PWB_tents then
    PWB:Print('No known tent locations')
    return
  end

  for zone, tents in pairs(PWB_tents) do
    local lastSeen = 0
    local lastSeenAgoStr, lastSeenAgoColor
    for _, tent in ipairs(tents) do
      if tent.lastSeen > lastSeen then
        lastSeen = tent.lastSeen
      end
    end

    table.insert(knownTents, { zone = zone, lastSeen = lastSeen })
  end

  table.sort(knownTents, function (a, b)
    return a.lastSeen > b.lastSeen
  end)

  if length(knownTents) == 0 then
    PWB:Print('No known tent locations')
    return
  end

  PWB:Print('Known tent locations:')
  for _, knownTent in ipairs(knownTents) do
    local lastSeenAgoStr, lastSeenAgoColor = PWB.tents.getSeenAgoStr(time() - knownTent.lastSeen)
    PWB:PrintClean(PWB.Colors.secondary .. '  ' .. knownTent.zone .. PWB.Colors.grey .. ' (' .. lastSeenAgoColor .. lastSeenAgoStr .. PWB.Colors.grey .. ' ago)')
  end
end

function PWB.tents.encode(tent)
  if not PWB.tents.valid(tent) then
    return
  end

  local cid, mid = PWB.tents.getZoneIds(tent.zone)
  local now = time()
  local firstSeenAgo = now - tent.firstSeen
  local lastSeenAgo = now - tent.lastSeen

  if not cid or not mid or not firstSeenAgo or not lastSeenAgo then
    return
  end

  return string.format('%d-%d-%.1f-%.1f-%d-%d-%d', cid, mid, tent.x * 100, tent.y * 100, tent.stack, firstSeenAgo, lastSeenAgo)
end

function PWB.tents.encodeAll(tents)
  local encodedTents
  for _, tent in pairs(tents) do
    local encTent = PWB.tents.encode(tent)
    if encTent then
      encodedTents = (encodedTents and encodedTents .. ';' or '') .. encTent
    end
  end
  return encodedTents
end

function PWB.tents.decode(tentStr)
  local _, _, cid, zid, x, y, stack, firstSeenAgoStr, lastSeenAgoStr = string.find(tentStr, '(.*)%-(.*)%-(.*)%-(.*)%-(.*)%-(.*)%-(.*)%;')

  if not cid or not zid or not x or not y or not stack or not firstSeenAgoStr or not lastSeenAgoStr then
    return
  end

  local firstSeenAgo = tonumber(firstSeenAgoStr)
  local lastSeenAgo = tonumber(lastSeenAgoStr)

  if not firstSeenAgo or not lastSeenAgo then
    return
  end

  local zone = PWB.tents.getZoneName(tonumber(cid), tonumber(zid))
  local now = time()
  local firstSeen = now - firstSeenAgo
  local lastSeen = now - lastSeenAgo

  return zone, tonumber(x) / 100, tonumber(y) / 100, tonumber(stack), firstSeen, lastSeen
end

local encodedTents = {}
function PWB.tents.decodeAndSaveAll(tentsStr)
  -- Clear table first
  for k in pairs(encodedTents) do
    encodedTents[k] = nil
  end

  local _, delimCount = string.gsub(tentsStr, ';', ';')
  local pattern = '(.*)'
  for i = 1, delimCount - 1, 1 do
    pattern = pattern .. '%;(.*)'
  end
  encodedTents[1], encodedTents[2], encodedTents[3], encodedTents[4], encodedTents[5], encodedTents[6], encodedTents[7], encodedTents[8], encodedTents[9] = string.find(tentsStr, pattern)

  for _, encodedTent in next, encodedTents do
    if encodedTent then
      PWB.tents.save(PWB.tents.decode(encodedTent))
    end
  end
end

local tentsToPublish = {}
function PWB.tents.getTentsToPublish()
  -- Clear table first
  for k in pairs(tentsToPublish) do
    tentsToPublish[k] = nil
  end

  for zone, tents in pairs(PWB_tents) do
    for _, tent in ipairs(tents) do
      table.insert(tentsToPublish, tent)
    end
  end

  local len = length(tentsToPublish)
  if len > 9 then
    local toRemove = len - 9
    for i = 1, toRemove do
      local idx = math.random(1, length(tentsToPublish))
      table.remove(tentsToPublish, idx)
    end
  end

  return tentsToPublish
end

-- Format:            PWB_T:VERSION:CID-ZID-X-Y-STACK-FIRSTSEEN-LASTSEEN;CID-ZID-X-Y-STACK-FIRSTSEEN-LASTSEEN;...
-- Example:           PWB_T:10400:2-25-74.5-92.9-1-7331-1337;1-13-52.1-29.8-2-14-5;...
-- Prefix Length:     12
-- Max Tent Length:   27
-- Message Limit:     255 (probably)
-- Tents Limit:       243
-- # of Tents Limit:  9
function PWB.tents.publish(tent)
  if not PWB.tents.hasTents() or UnitLevel('player') < 5 then
    return
  end

  local pwbChannel = GetChannelName(PWB.channelName)
  if pwbChannel ~= 0 then
    local encodedTentsToPub

    if tent then
      -- Publish only the specified tent.
      encodedTentsToPub = PWB.tents.encode(tent)
    else
      -- Publish (a random selection of) all tents we know.
      local tentsToPub = PWB.tents.getTentsToPublish()
      encodedTentsToPub = PWB.tents.encodeAll(tentsToPub)
    end

    if encodedTentsToPub then
      local msg = PWB.abbrevTents .. ':' .. PWB.utils.getVersionNumber() .. ':' .. encodedTentsToPub
      SendChatMessage(msg, 'CHANNEL', nil, pwbChannel)
    end
  end
end

local pins = {}
function PWB.tents.clearPins()
  for i, pin in ipairs(pins) do
    pin:Hide()
  end
  pins = {}
end

function PWB.tents.getSeenAgoStr(seenAgoSeconds, isFirstSeen)
  local thresholdOrange = isFirstSeen and 300 or 60
  local thresholdRed = isFirstSeen and 600 or 180

  local color = PWB.Colors.green
  if seenAgoSeconds > thresholdOrange then
    color = PWB.Colors.orange
  end
  if seenAgoSeconds > thresholdRed then
    color = PWB.Colors.red
  end
  return PWB.utils.toRoughTimeString(seenAgoSeconds), color
end

function PWB.tents.updatePins()
  if not pins then
    pins = {}
  end

  PWB.tents.clearPins()

  local zone = PWB.utils.getCurrentMapZoneName()
  if not zone or not PWB_tents or not PWB_tents[zone] or length(PWB_tents[zone]) == 0 then
    return
  end

  for i, tent in ipairs(PWB_tents[zone]) do
    local f = CreateFrame('Button', 'PizzaTentPin' .. i, WorldMapButton)
    local pinSize = PWB_config.tentStyle == 1337 and 20 or 18
    f.tent = tent
    f:ClearAllPoints()
    f:SetFrameStrata('FULLSCREEN')
    f:SetFrameLevel(4)
    f:SetWidth(pinSize)
    f:SetHeight(pinSize)
    local mapWidth = WorldMapButton:GetWidth()
    local mapHeight = WorldMapButton:GetHeight()
    local tentX = tent.x * mapWidth
    local tentY = tent.y * mapHeight
    f:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', tentX, -tentY)
    f.tex = f:CreateTexture(nil, 'MEDIUM')
    f.tex:SetAllPoints(f)
    f.tex:SetTexture('Interface\\AddOns\\PizzaWorldBuffs\\img\\tent' .. PWB_config.tentStyle)

    if PWB_config.tents then
      f:Show()
    else
      f:Hide()
    end

    f:SetScript('OnEnter', function()
      GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
      local title = f.tent.stack > 1 and 'Tent Stack ' .. PWB.Colors.grey .. '(' .. f.tent.stack .. 'x)' or 'Tent'
      GameTooltip:SetText(PWB.Colors.primary .. title)
      local firstSeenAgoStr, firstSeenAgoColor = PWB.tents.getSeenAgoStr(time() - f.tent.firstSeen, true)
      GameTooltip:AddLine(PWB.Colors.secondary .. 'First seen ' .. firstSeenAgoColor .. firstSeenAgoStr .. PWB.Colors.secondary .. ' ago.')
      local lastSeenAgoStr, lastSeenAgoColor = PWB.tents.getSeenAgoStr(time() - f.tent.lastSeen)
      GameTooltip:AddLine(PWB.Colors.secondary .. 'Last seen ' .. lastSeenAgoColor .. lastSeenAgoStr .. PWB.Colors.secondary .. ' ago.')
      GameTooltip:Show()
    end)

    f:SetScript('OnLeave', function()
      GameTooltip:Hide()
    end)

    pins[i] = f
  end
end
