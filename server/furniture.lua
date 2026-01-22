AZH = AZH or {}

local function S()
  return AZH.State or {}
end

local function normIdent(v)
  if v == nil then return nil end
  local s = tostring(v)
  s = s:gsub('^%s+', ''):gsub('%s+$', '')
  if s == '' then return nil end
  local sl = string.lower(s)
  if sl == '0' or sl == 'null' or sl == 'none' or sl == 'false' or sl == 'nil'
    or sl == 'n/a' or sl == 'na' or sl == 'undefined' then
    return nil
  end
  if string.sub(s, 1, 5) == 'char:' then
    s = 'charid:' .. string.sub(s, 6)
  end
  return s
end

local function identOf(src)
  return normIdent(AZH.getIdentifier(src))
end

local function expectedBucket(houseId)

  local base = (Config and Config.Buckets and Config.Buckets.Base) or 500000
  return base + (tonumber(houseId) or 0)
end

local function ensureInside(src, houseId)
  local buck = GetPlayerRoutingBucket(src)
  return tonumber(buck) == tonumber(expectedBucket(houseId))
end

local function canDecorate(src, houseId)
  houseId = tonumber(houseId)
  if not houseId then return false end

  local st = S()
  local h = st.Houses and st.Houses[houseId] or nil
  if not h then return false end

  if AZH.isAdmin(src) then return true end

  local ident = identOf(src)
  if not ident then return false end

  local owner = normIdent(h.owner_identifier)
  if owner and owner == ident then return true end

  if st.Keys and st.Keys[houseId] and st.Keys[houseId][ident] then return true end

  local r = st.Rentals and st.Rentals[houseId] or nil
  local tenant = r and normIdent(r.tenant_identifier) or nil
  if tenant and tenant == ident then return true end

  return false
end

lib.callback.register('az_housing:cb:getFurniture', function(src, houseId)
  if not (Config and Config.Furniture and Config.Furniture.Enabled) then
    return { ok = false, error = 'Furniture disabled' }
  end

  houseId = tonumber(houseId)
  if not houseId then
    return { ok = false, error = 'Invalid house' }
  end

  if not canDecorate(src, houseId) then
    return { ok = false, error = 'No access' }
  end

  local list = AZH.Storage.listFurniture(houseId) or {}
  local limits = AZH.getHouseLimits(houseId)
  return { ok = true, furniture = list, limit = (limits and limits.furnitureLimit) or 25 }
end)

RegisterNetEvent('az_housing:server:addFurniture', function(houseId, model, coords, heading, rot, meta)
  local src = source
  houseId = tonumber(houseId)
  model = tostring(model or '')
  coords = coords or {}
  rot = rot or {}
  meta = meta or {}

  if not houseId or model == '' then return end
  if not (Config and Config.Furniture and Config.Furniture.Enabled) then return end

  if not canDecorate(src, houseId) then
    AZH.notify(src, 'error', 'Furniture', 'No access.')
    return
  end

  if not ensureInside(src, houseId) then
    AZH.notify(src, 'error', 'Furniture', 'You must be inside the property to place furniture.')
    return
  end

  local limits = AZH.getHouseLimits(houseId)
  local max = (limits and limits.furnitureLimit) or 25
  local current = AZH.Storage.listFurniture(houseId) or {}
  if #current >= max then
    AZH.notify(src, 'error', 'Furniture', 'Furniture limit reached. Upgrade Decor to place more.')
    return
  end

  local c = {
    x = tonumber(coords.x) or 0.0,
    y = tonumber(coords.y) or 0.0,
    z = tonumber(coords.z) or 0.0,
  }
  local r = {
    x = tonumber(rot.x) or 0.0,
    y = tonumber(rot.y) or 0.0,
    z = tonumber(rot.z) or 0.0
  }

  local ident = identOf(src) or AZH.getIdentifier(src)
  local id = AZH.Storage.addFurniture(houseId, ident, model, c, tonumber(heading) or 0.0, r, meta)
  if not id then
    AZH.notify(src, 'error', 'Furniture', 'Failed to save.')
    return
  end

  AZH.notify(src, 'success', 'Furniture', 'Placed.')
  TriggerClientEvent('az_housing:client:furnitureChanged', -1, houseId)
end)

RegisterNetEvent('az_housing:server:removeFurniture', function(houseId, furnId)
  local src = source
  houseId = tonumber(houseId)
  furnId = tonumber(furnId)

  if not houseId or not furnId then return end
  if not (Config and Config.Furniture and Config.Furniture.Enabled) then return end

  if not canDecorate(src, houseId) then
    AZH.notify(src, 'error', 'Furniture', 'No access.')
    return
  end

  if not ensureInside(src, houseId) then
    AZH.notify(src, 'error', 'Furniture', 'You must be inside the property to remove furniture.')
    return
  end

  if AZH.Storage.driver == 'oxmysql' then
    local rows = AZH.Storage.exec('SELECT house_id FROM az_house_furniture WHERE id=? LIMIT 1', { furnId }) or {}
    if not rows[1] or tonumber(rows[1].house_id) ~= houseId then
      AZH.notify(src, 'error', 'Furniture', 'Invalid furniture.')
      return
    end
  else
    local list = AZH.Storage.listFurniture(houseId) or {}
    local ok = false
    for _, f in ipairs(list) do
      if tonumber(f.id) == furnId then ok = true break end
    end
    if not ok then
      AZH.notify(src, 'error', 'Furniture', 'Invalid furniture.')
      return
    end
  end

  AZH.Storage.deleteFurniture(furnId)
  AZH.notify(src, 'success', 'Furniture', 'Removed.')
  TriggerClientEvent('az_housing:client:furnitureChanged', -1, houseId)
end)
