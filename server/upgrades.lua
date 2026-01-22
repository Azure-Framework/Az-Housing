// File: no-comments-pasted.lua

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
  if sl == '0' or sl == 'null' or sl == 'none' or sl == 'false' or sl == 'nil' or sl == 'n/a' or sl == 'na' or sl == 'undefined' then
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

local function canAccessHouse(src, houseId)
  houseId = tonumber(houseId)
  if not houseId then return false end
  local st = S()
  local ident = identOf(src)
  local h = st.Houses and st.Houses[houseId] or nil
  if not h or not ident then return false end

  if AZH.isAdmin(src) then return true end

  local owner = normIdent(h.owner_identifier)
  if owner and owner == ident then return true end

  if st.Keys and st.Keys[houseId] and st.Keys[houseId][ident] then return true end

  local r = st.Rentals and st.Rentals[houseId] or nil
  local tenant = r and normIdent(r.tenant_identifier) or nil
  if tenant and tenant == ident then return true end

  return false
end

local function canManageUpgrades(src, houseId)
  houseId = tonumber(houseId)
  if not houseId then return false end
  if AZH.isAdmin(src) then return true end
  local st = S()
  local h = st.Houses and st.Houses[houseId] or nil
  if not h then return false end
  local ident = identOf(src)
  local owner = normIdent(h.owner_identifier)
  return (owner and ident and owner == ident) or false
end

local function clampLevel(typeName, level)
  local cfg = Config and Config.Upgrades and Config.Upgrades.Levels and Config.Upgrades.Levels[typeName]
  if not cfg then return 0 end
  level = tonumber(level) or 0
  if level < 0 then level = 0 end
  if level > (#cfg - 1) then level = (#cfg - 1) end
  return level
end

function AZH.getHouseUpgrades(houseId)
  local u = AZH.Storage.getUpgrades(houseId) or {}
  u.house_id = tonumber(houseId)
  u.mailbox_level = clampLevel('mailbox', u.mailbox_level)
  u.decor_level = clampLevel('decor', u.decor_level)
  u.storage_level = clampLevel('storage', u.storage_level)
  return u
end

function AZH.getHouseLimits(houseId)
  local u = AZH.getHouseUpgrades(houseId)

  local mailboxCap = (Config.Mailbox and Config.Mailbox.BaseCapacity) or 15
  local mbCfg = Config and Config.Upgrades and Config.Upgrades.Levels and Config.Upgrades.Levels.mailbox
  if mbCfg and mbCfg[u.mailbox_level + 1] and mbCfg[u.mailbox_level + 1].capacityBonus then
    mailboxCap = mailboxCap + tonumber(mbCfg[u.mailbox_level + 1].capacityBonus)
  else

    mailboxCap = mailboxCap + (tonumber(Config.Mailbox and Config.Mailbox.CapacityPerLevel) or 10) * (u.mailbox_level or 0)
  end

  local decorCfg = Config and Config.Upgrades and Config.Upgrades.Levels and Config.Upgrades.Levels.decor
  local furnLimit = 25
  if decorCfg and decorCfg[u.decor_level + 1] and decorCfg[u.decor_level + 1].furnitureLimit then
    furnLimit = tonumber(decorCfg[u.decor_level + 1].furnitureLimit)
  end

  local storageCfg = Config and Config.Upgrades and Config.Upgrades.Levels and Config.Upgrades.Levels.storage
  local stashSlots, stashWeight = 20, 20000
  if storageCfg and storageCfg[u.storage_level + 1] then
    stashSlots = tonumber(storageCfg[u.storage_level + 1].stashSlots) or stashSlots
    stashWeight = tonumber(storageCfg[u.storage_level + 1].stashWeight) or stashWeight
  end

  return {
    mailboxCap = mailboxCap,
    furnitureLimit = furnLimit,
    stashSlots = stashSlots,
    stashWeight = stashWeight,
  }
end

lib.callback.register('az_housing:cb:getUpgrades', function(src, houseId)
  if not canAccessHouse(src, houseId) then
    return { ok = false, error = 'No access' }
  end
  local u = AZH.getHouseUpgrades(houseId)
  local limits = AZH.getHouseLimits(houseId)
  return { ok = true, upgrades = u, limits = limits, canManage = canManageUpgrades(src, houseId) }
end)

RegisterNetEvent('az_housing:server:buyUpgrade', function(houseId, upType)
  local src = source
  houseId = tonumber(houseId)
  upType = tostring(upType or '')
  if not houseId or upType == '' then return end

  if not canManageUpgrades(src, houseId) then
    AZH.notify(src, 'error', 'Upgrades', 'You do not own this property.')
    return
  end

  local cfg = Config and Config.Upgrades and Config.Upgrades.Levels and Config.Upgrades.Levels[upType]
  if not cfg then
    AZH.notify(src, 'error', 'Upgrades', 'Invalid upgrade type.')
    return
  end

  local u = AZH.getHouseUpgrades(houseId)
  local cur = tonumber(u[upType .. '_level'] or 0) or 0
  local nextLevel = cur + 1

  if nextLevel > (#cfg - 1) then
    AZH.notify(src, 'inform', 'Upgrades', 'Already at max level.')
    return
  end

  local nextCfg = cfg[nextLevel + 1]
  local price = tonumber(nextCfg and nextCfg.price) or 0

  if price > 0 then
    local ok = AZH.moneyTake(src, price, ('housing:%s_upgrade'):format(upType))
    if not ok then
      AZH.notify(src, 'error', 'Upgrades', 'Not enough money.')
      return
    end
  end

  u[upType .. '_level'] = nextLevel
  AZH.Storage.setUpgradeLevels(houseId, u.mailbox_level, u.decor_level, u.storage_level)

  TriggerClientEvent('az_housing:client:notify', src, 'success', 'Upgrades', ('Purchased %s upgrade (Level %d).'):format(upType, nextLevel))
  TriggerClientEvent('az_housing:client:upgradesChanged', -1, houseId)
end)