local defaultConfig = {
  show = true,
  fontSize = 14,
  allFactions = true,
  frame = {
    top = 50,
    center = 0,
  },
}

if not PWB_config then
  PWB_config = defaultConfig
  return
end

for key, defaultValue in pairs(defaultConfig) do
  if PWB_config[key] == nil then
    PWB_config[key] = defaultValue
  end
end