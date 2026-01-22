// File: no-comments-pasted.lua



AZH = AZH or {}
AZH.Framework = AZH.Framework or {}

local RESOURCE = GetCurrentResourceName()

local function log(...)
  print(('^3[%s:framework]^7'):format(RESOURCE), ...)
end

local function truthy(v)
  if v == nil then return false end
  if type(v) == 'boolean' then return v == true end
  if type(v) == 'number' then return v ~= 0 end
  if type(v) == 'string' then
    local s = string.lower(v:gsub('^%s+', ''):gsub('%s+$', ''))
    return (s == 'true' or s == '1' or s == 'yes' or s == 'y' or s == 'on')
  end
  return false
end

local function getFw()
  local ok, exp = pcall(function() return exports['Az-Framework'] end)
  if ok and exp then return exp end
  return nil
end

local function inList(val, list)
  if not val or type(list) ~= 'table' then return false end
  local needle = tostring(val):lower()
  for _, v in ipairs(list) do
    if tostring(v):lower() == needle then return true end
  end
  return false
end

function AZH.Framework.getJob(src)
  src = tonumber(src)
  if not src then return nil end

  local fw = getFw()
  if not fw then
    log('getJob: no Az-Framework export')
    return nil
  end

  if type(fw.getPlayerJob) == 'function' then
    local ok, res = pcall(function() return fw:getPlayerJob(src) end)
    if ok and type(res) == 'string' and res ~= '' then
      return tostring(res):lower()
    end

    ok, res = pcall(function() return fw.getPlayerJob(src) end)
    if ok and type(res) == 'string' and res ~= '' then
      return tostring(res):lower()
    end
  end

  if type(fw.getJob) == 'function' then
    local ok, res = pcall(function() return fw:getJob(src) end)
    if ok and type(res) == 'string' and res ~= '' then return tostring(res):lower() end
    ok, res = pcall(function() return fw.getJob(src) end)
    if ok and type(res) == 'string' and res ~= '' then return tostring(res):lower() end
  end

  return nil
end

function AZH.Framework.isAdmin(src)
  src = tonumber(src)
  if not src then return false end

  local fw = getFw()
  if not fw or type(fw.isAdmin) ~= 'function' then
    log('isAdmin: no Az-Framework export or isAdmin missing')
    return false
  end

  local ok, res = pcall(function() return fw:isAdmin(src) end)
  log('isAdmin:syncCheck', 'ok=', ok, 'res=', tostring(res), 'type=', type(res))
  if ok then
    return truthy(res)
  end

  ok, res = pcall(function() return fw.isAdmin(src) end)
  log('isAdmin:syncCheck2', 'ok=', ok, 'res=', tostring(res), 'type=', type(res))
  if ok then
    return truthy(res)
  end

  local p = promise.new()
  local done = false

  local okAsync = pcall(function()
    fw:isAdmin(src, function(v)
      if done then return end
      done = true
      p:resolve(v == true)
    end)
  end)

  if not okAsync then
    log('isAdmin:asyncInvokeFailed')
    return false
  end

  SetTimeout(1500, function()
    if done then return end
    done = true
    log('isAdmin:asyncTimeout', 'src=', src)
    p:resolve(false)
  end)

  return Citizen.Await(p) == true
end

CreateThread(function()
  Wait(0)

  if GetResourceState('ox_lib') ~= 'started' or not lib or not lib.callback or not lib.callback.register then
    log('ox_lib not ready; callbacks will not be registered')
    return
  end

  lib.callback.register('az_housing:cb:getJob', function(src)
    return AZH.Framework.getJob(src)
  end)

  lib.callback.register('az_housing:cb:isPolice', function(src)
    local job = AZH.Framework.getJob(src)
    local okPolice = inList(job, (Config and Config.Police and Config.Police.Jobs) or {})
    return okPolice == true, job
  end)

  lib.callback.register('az_housing:cb:isAdmin', function(src)
    return AZH.Framework.isAdmin(src) == true
  end)

  log('Registered callback az_housing:cb:getJob')
  log('Registered callback az_housing:cb:isPolice')
  log('Registered callback az_housing:cb:isAdmin')
end)

RegisterNetEvent('az_housing:server:getJobReq', function(reqId)
  local src = source
  local job = AZH.Framework.getJob(src)
  TriggerClientEvent('az_housing:client:getJobRes', src, reqId, job)
end)

RegisterNetEvent('az_housing:server:isPoliceReq', function(reqId)
  local src = source
  local job = AZH.Framework.getJob(src)
  local okPolice = inList(job, (Config and Config.Police and Config.Police.Jobs) or {})
  TriggerClientEvent('az_housing:client:isPoliceRes', src, reqId, okPolice == true, job)
end)

RegisterNetEvent('az_housing:server:isAdminReq', function(reqId)
  local src = source
  local okAdmin = AZH.Framework.isAdmin(src) == true
  TriggerClientEvent('az_housing:client:isAdminRes', src, reqId, okAdmin == true)
end)