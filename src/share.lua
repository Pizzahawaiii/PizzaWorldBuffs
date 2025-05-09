local PWB = PizzaWorldBuffs
PWB.share = {}

setfenv(1, PWB:GetEnv())

function PWB.share.getText(type, t)
  local text

  if type == 'timer' then
    if not t then return end

    local city = t.faction == 'A' and T['SW'] or T['OG']
    local timer = PWB_timers[t.faction][t.boss]
    local suffix = T['head has no timer, it\'s probably despawned']

    if timer then
      local h, m = PWB.core.getTimeLeft(timer.h, timer.m)
      local isNow = h == 0 and m == 0
      suffix = isNow and T['head will despawn NOW!'] or T['head will despawn in'] .. ' ' .. PWB.utils.toString(h, m)
    end

    text = '(' .. city .. ') ' .. T[PWB.Bosses[t.boss]] .. ' ' .. suffix
  elseif type == 'dmf' then
    text = 'Darkmoon Faire location is currently unknown. Try "/w Tents dmf?"'

    if PWB.utils.hasDmf() then
      local location = PWB.DmfLocations[PWB_dmf.location]
      local secondsAgo = time() - PWB_dmf.seenAt
      local timeAgo = PWB.utils.toRoughTimeString(secondsAgo)
      text = 'Darkmoon Faire was last seen in ' .. location .. ' ' .. timeAgo .. ' ago.'
    end
  elseif type == 'link' then
    local prefix = T['I\'m using PizzaWorldBuffs. Get it at']
    if math.random(1, 20) == 1 then
      prefix = T['I <3 pineapple on pizza! Get some at']
    elseif PWB.utils.isTipsie() and math.random(1, 10) == 1 then
      prefix = T['I\'m a BIG nab :( But using PizzaWorldBuffs really helped me! Get it at']
    end
    text = prefix .. ' https://github.com/Pizzahawaiii/PizzaWorldBuffs'
  end

  return text
end

function PWB.share.share(mouseButton, type, t)
  if type == 'timer' and not t then return end
  if mouseButton ~= 'LeftButton' and mouseButton ~= 'RightButton' and mouseButton ~= 'MiddleButton' and mouseButton ~= 'Button4' then return end

  local text = PWB.share.getText(type, t)
  if text then
    local editBox = DEFAULT_CHAT_FRAME.editBox
    local targetEditBox = WIM_EditBoxInFocus or editBox:IsVisible() and editBox or nil
    if targetEditBox then
      targetEditBox:SetText(text)
    elseif arg1 == 'Button4' then
      local worldChannelId = PWB.utils.getChannelId('world')
      if worldChannelId then
        SendChatMessage(text, 'CHANNEL', nil, worldChannelId)
      end
    else
      local sendTo
      if arg1 == 'LeftButton' then sendTo = 'SAY' end
      if arg1 == 'RightButton' then sendTo = 'GUILD' end
      if arg1 == 'MiddleButton' then sendTo = 'HARDCORE' end

      if sendTo then
        SendChatMessage(text, sendTo)
      end
    end
  end
end
