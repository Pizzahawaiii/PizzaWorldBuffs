local PWB = PizzaWorldBuffs

setfenv(1, PWB:GetEnv())

PWB.logoutFrame = CreateFrame('Frame', 'PizzaWorldBuffsLogoutFrame', UIParent)
PWB.logoutFrame:ClearAllPoints()
PWB.logoutFrame:SetPoint('TOP', 0, -200)
PWB.logoutFrame:SetFrameStrata('LOW')
PWB.logoutFrame:SetWidth(1)
PWB.logoutFrame:SetHeight(1)

PWB.logoutFrame.text = PWB.logoutFrame:CreateFontString('PizzaWorldBuffsLogoutFrameText', 'DIALOG', 'GameFontWhite')
PWB.logoutFrame.text:SetFont(STANDARD_TEXT_FONT, 16, 'OUTLINE')
PWB.logoutFrame.text:SetJustifyH('CENTER')
PWB.logoutFrame.text:SetPoint('TOP', 0, 0)
local prefix = PWB.Colors.primary .. 'Pizza' .. PWB.Colors.secondary .. 'WorldBuffs'

PWB.logoutFrame:SetWidth(PWB.logoutFrame.text:GetWidth())
PWB.logoutFrame:SetHeight(PWB.logoutFrame.text:GetHeight())

PWB.logoutFrame:Show()

function PWB.logoutFrame.update()
  if PWB_config.autoLogout or PWB_config.autoExit then
    local command = PWB_config.autoExit and '/wb exit 0' or '/wb logout 0'
    local suffix = T['To disable this, type'] .. PWB.Colors.primary .. ' ' .. command .. '|r'

    local now = time()
    if PWB.logoutAt and now < PWB.logoutAt then
      local diff = PWB.logoutAt - now
      local msg = PWB_config.autoExit and T['Received buff. Exiting game in'] or T['Received buff. Logging out in']
      local message = PWB.Colors.red .. msg .. '|r ' .. diff .. ' ' .. PWB.Colors.red .. T['seconds'] .. '...|r'
      PWB.logoutFrame.text:SetText(prefix .. '\n\n' .. message .. '\n' .. suffix)
    else
      local message = PWB_config.autoExit and T['Auto-exit enabled!'] or T['Auto-logout enabled!']
      PWB.logoutFrame.text:SetText(prefix .. '\n\n' .. PWB.Colors.orange .. message .. '|r\n' .. suffix)
    end

    PWB.logoutFrame.text:Show()
  else
    PWB.logoutFrame.text:Hide()
  end
end

PWB.logoutFrame:SetScript('OnUpdate', function ()
  -- Throttle this function so it doesn't run on every frame render
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end

  PWB.logoutFrame.update()
end)
