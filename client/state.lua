AZH = AZH or {}

AZH.C = {
  ready = false,
  houses = {},       -- [id] = house
  doors = {},        -- array
  garages = {},      -- array
  rentals = {},      -- [house_id] = rental
  interiors = {},    -- config pass-through
  forcedUnlockUntil = {}, -- [house_id]=unix

  currentHouseId = nil,
  currentBucket = 0,
  outside = nil,

  blips = {},
  zones = { doors = {}, garages = {}, interiorExit = nil },
}

function AZH.C.resetZones()
  -- ox_target zones are removed by name; we store names.
  if not exports or not exports.ox_target then return end

  for _, name in ipairs(AZH.C.zones.doors) do
    pcall(function() exports.ox_target:removeZone(name) end)
  end
  for _, name in ipairs(AZH.C.zones.garages) do
    pcall(function() exports.ox_target:removeZone(name) end)
  end
  if AZH.C.zones.interiorExit then
    pcall(function() exports.ox_target:removeZone(AZH.C.zones.interiorExit) end)
  end

  AZH.C.zones.doors = {}
  AZH.C.zones.garages = {}
  AZH.C.zones.interiorExit = nil
end

function AZH.C.clearBlips()
  for _, b in ipairs(AZH.C.blips) do
    if DoesBlipExist(b) then RemoveBlip(b) end
  end
  AZH.C.blips = {}
end
