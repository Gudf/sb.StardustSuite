require "/lib/stardust/itemutil.lua"
require "/lib/stardust/power.lua"

--[[
parameters.batteryStats {
  energy
  capacity
  ioRate
}
]]

function power.setItemTooltipFields(item)
  if true then return nil end -- just an early-out until actual tooltip finished
  
  local cfg = itemutil.getCachedConfig(item)
  local capacity = (item.parameters.batteryStats or {}).capacity or (cfg.batteryStats or {}).capacity
  local energy = (item.parameters.batteryStats or {}).energy or 0
  
  -- TODO: actually set up tooltipFields
  if not item.tooltipFields then item.tooltipFields = {} end
  item.tooltipFields.batteryStatsLabel = table.concat({energy, "/", capacity, "FP"})
end

function power.fillItemEnergy(item, amount, testOnly)
  if not item.count then return 0 end -- no item here!
  local cfg = itemutil.getCachedConfig(item)
  if not cfg.batteryStats and not item.parameters.batteryStats then return 0 end -- no internal battery
  
  -- assemble actual battery stats
  local bs = copy(cfg.batteryStats or {})
  for k,v in pairs(item.parameters.batteryStats or {}) do bs[k] = v end
  
  -- calculate how much can actually be added
  local r = math.min(amount, bs.ioRate or amount)
  r = math.min(r, (bs.capacity - bs.energy) or 0)
  
  if not testOnly then -- actually fill
    if not item.parameters.batteryStats then item.parameters.batteryStats = {} end
    item.parameters.batteryStats.energy = bs.energy + r
    
    -- and rebuild tooltip
    power.setItemTooltipFields(item)
  end
  
  return r
end

function power.drawItemEnergy(item, amount, testOnly)
  if not item.count then return 0 end -- no item here!
  local cfg = itemutil.getCachedConfig(item)
  if not cfg.batteryStats and not item.parameters.batteryStats then return 0 end -- no internal battery
  
  -- assemble actual battery stats
  local bs = copy(cfg.batteryStats or {})
  for k,v in pairs(item.parameters.batteryStats or {}) do bs[k] = v end
  
  -- calculate how much can actually be taken
  local r = math.min(amount, bs.ioRate or amount)
  r = math.min(r, bs.energy or 0)
  
  if not testOnly then -- actually remove
    if not item.parameters.batteryStats then item.parameters.batteryStats = {} end
    item.parameters.batteryStats.energy = bs.energy - r
    
    -- and rebuild tooltip
    power.setItemTooltipFields(item)
  end
  
  return r
end

function power.fillEquipEnergy(amount, testOnly)
  if not player then return 0 end -- abort if player table is unavailable
  local acc = 0
  
  local slots = {
    "back",
    "chest",
    "legs",
    "head"
  }
  
  for k,slot in pairs(slots) do
    -- check each slot
    local item = player.equippedItem(slot)
    local amt = power.fillItemEnergy(item, amount - acc, testOnly) -- try to fill equipped item
    acc = acc + amt -- accumulate...
    if amt > 0 and not testOnly then player.setEquippedItem(slot, item) end -- update item if capacity changed
    if acc >= amount then return acc end -- early out when quota reached
  end
  
  return acc
end

function power.drawEquipEnergy(amount, testOnly)
  if not player then return 0 end -- abort if player table is unavailable
  local acc = 0
  
  local slots = {
    "back",
    "chest",
    "legs",
    "head"
  }
  
  for k,slot in pairs(slots) do
    -- check each slot
    local item = player.equippedItem(slot)
    local amt = power.drawItemEnergy(item, amount - acc, testOnly) -- try to draw from equipped item
    --sb.logInfo("slot " .. slot .. ": drew " .. amt .. "FP")
    acc = acc + amt -- accumulate...
    if amt > 0 and not testOnly then player.setEquippedItem(slot, item) end -- update item if capacity changed
    if acc >= amount then return acc end -- early out when quota reached
  end
  
  --sb.logInfo("drew " .. acc .. " total")
  return acc
end









--