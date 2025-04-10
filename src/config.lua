-- config.lua
local PWB = PizzaWorldBuffs
PWB.config = {}

local defaultConfig = {
  show = true,
  lock = false,
  fontSize = 14,
  align = 'left', -- This controls text justification within each frame
  header = true,
  allFactions = true,
  autoLogout = false,
  autoExit = false,
  frame = {
    top = 50,
    center = 0,
  },
  dmf = true,
  mapHeads = true,
  tents = true,
  tentStyle = 1,
  tentAlert = 1,
  orientation = 'vertical', -- New option: 'vertical' or 'horizontal'
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