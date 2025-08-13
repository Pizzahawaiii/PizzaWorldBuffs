local PWB = PizzaWorldBuffs

PWB.channelName = 'LFT'

-- Frame to delay joining PWB channel
PWB.channelJoinDelay = CreateFrame('Frame', 'PizzaWorldBuffsChannelJoinDelay', UIParent)
PWB.channelJoinDelay:Hide()

PWB.channelJoinDelay:SetScript('OnShow', function ()
  this.startTime = GetTime()
end)

PWB.channelJoinDelay:SetScript('OnHide', function ()
  local isInChannel = false
  local channels = { GetChannelList() }

  for _, channel in next, channels do
    if string.lower(channel) == string.lower(PWB.channelName) then
      isInChannel = true
      break
    end
  end

  if not isInChannel then
    JoinChannelByName(PWB.channelName)
  end
end)

PWB.channelJoinDelay:SetScript('OnUpdate', function ()
  local delay = 15
  local gt = GetTime() * 1000
  local st = (this.startTime + delay) * 1000
  if gt >= st then
    PWB.channelJoinDelay:Hide()
  end
end)
