local PWB = PizzaWorldBuffs

PWB.config = {}

local defaultConfig = {
  show = true,
  fontSize = 14,
  align = 'center',
  allFactions = true,
  sharingEnabled = true,
  autoLogout = false,
  setQuit = false,
  frame = {
    top = 50,
    center = 0,
  },
}

function PWB.config.init()
  if not PWB_config then
    PWB_config = defaultConfig
    return
  end

  for key, defaultValue in pairs(defaultConfig) do
    if PWB_config[key] == nil then
      PWB_config[key] = defaultValue
    end
  end
end
