// File: no-comments-pasted.lua

AZH = AZH or {}

local function getState()
  return AZH.State or {}
end

local function toBool(v)
  if v == true then return true end
  if v == false then return false end
  local n = tonumber(v)
  if n then return n == 1 end
  local s = tostring(v or ''):lower():gsub('%s+','')
  return s == 'true' or s == 'yes' or s == 'y' or s == 'on'
end

local function isListed(r)
  if not r then return false end
  if r.is_listed ~= nil then return toBool(r.is_listed) end
  local st = tostring(r.status or ''):lower()
  if st == 'listed' or st == 'available' or st == 'open' or st == 'active' then return true end
  return false
end

local function getAgentHouseSet(src)
  local st = getState()
  local ident = AZH.getIdentifier(src)
  local set = {}
  if not ident then return set, ident, st end

  for _, h in pairs(st.Houses or {}) do
    local hid = tonumber(h.id)
    if hid and h.owner_identifier == ident then
      local r = st.Rentals and st.Rentals[hid] or nil
      if isListed(r) then
        set[hid] = true
      end
    end
  end

  return set, ident, st
end

lib.callback.register('az_housing:cb:isAdmin', function(src)
  return AZH.isAdmin(src)
end)

lib.callback.register('az_housing:cb:getPortalData', function(src)
  local st = getState()
  local ident = AZH.getIdentifier(src)

  local owned, keyMap, myRentals = {}, {}, {}

  for _, h in pairs(st.Houses or {}) do
    if h.owner_identifier and h.owner_identifier == ident then
      owned[tonumber(h.id)] = true
    end
  end

  for houseId, map in pairs(st.Keys or {}) do
    if map[ident] then
      keyMap[tonumber(houseId)] = map[ident]
    end
  end

  for _, r in pairs(st.Rentals or {}) do
    if r.tenant_identifier == ident then
      myRentals[tonumber(r.house_id)] = r
    end
  end

  return {
    me = ident,
    isAdmin = AZH.isAdmin(src),
    isPolice = AZH.isPolice(src),
    isAgent = (AZH.isAgent(src) or next(getAgentHouseSet(src)) ~= nil),
    owned = owned,
    keys = keyMap,
    rentals = myRentals,
  }
end)

lib.callback.register('az_housing:cb:getAgentApps', function(src)
  local isAdmin = AZH.isAdmin(src)
  local roleAgent = AZH.isAgent(src)
  local agentSet, ident, st = getAgentHouseSet(src)

  if not (isAdmin or roleAgent or next(agentSet) ~= nil) then
    return { ok = false, error = 'Not authorized' }
  end

  local all = AZH.Storage.loadAll()
  local apps = all.apps or {}

  if not (isAdmin or roleAgent) then
    local filtered = {}
    for _, a in ipairs(apps) do
      local hid = tonumber(a.house_id)
      if hid and agentSet[hid] then
        table.insert(filtered, a)
      end
    end
    apps = filtered
  end

  local nameById = {}
  for _, h in pairs(st.Houses or {}) do
    nameById[tonumber(h.id)] = h.name
  end
  for _, a in ipairs(apps) do
    local hid = tonumber(a.house_id)
    a.house_name = a.house_name or (hid and nameById[hid])
  end

  return { ok = true, apps = apps }
end)