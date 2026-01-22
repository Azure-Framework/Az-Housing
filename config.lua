Config = Config or {}

-- ============================================================
-- Core toggles
-- ============================================================
Config.Debug = (Config.Debug == true)
Config.UseOxLib = (Config.UseOxLib ~= false)         -- if ox_lib exists, we use it for zones + notify
Config.UseOxTarget = (Config.UseOxTarget ~= false)   -- if ox_target exists, we use it for interactions
Config.UseDatabase = (Config.UseDatabase ~= false)   -- if oxmysql exists, we persist to DB; else JSON fallback

-- ============================================================
-- Identifiers
-- ============================================================
-- We store ownership/keys by a stable identifier.
-- This resource is configured for Az-Framework character ownership:
--   owner_identifier / key identifiers will be:  char:<charId>
--
-- Fallback priority (only used if no active character is found):
Config.IdentifierPriority = { 'license', 'discord', 'fivem', 'steam' }

-- ============================================================
-- Commands
-- ============================================================
Config.Commands = {
  Portal = 'housing',         -- opens housing portal UI
  Placement = 'housingedit',  -- toggles placement mode (admins)
}

-- ============================================================
-- Interaction ranges
-- ============================================================
Config.Interact = {
  DoorDistance = 2.0,
  KnockDistance = 2.5,
  GarageDistance = 4.0,
  MarkerDistance = 25.0,
}

-- ============================================================
-- Routing buckets
-- ============================================================
Config.Buckets = {
  Base = 500000,      -- avoid conflicts with other scripts
  UsePerHouse = true, -- if false, uses one shared interior bucket
}

-- ============================================================
-- Police breach
-- ============================================================
Config.Police = {
  Jobs = { 'police', 'sheriff', 'state', 'lspd', 'bcso' },
  BreachCooldownSec = 30,
  BreachUnlockSeconds = 120,    -- door remains forced-unlocked for this long
  BreachBlipSeconds = 180,      -- police dispatch blip duration
  RequireItem = false,
  BreachItem = 'ram',
}

-- ============================================================
-- Blips
-- ============================================================
Config.Blips = {
  Enabled = true,
  Sprite = 40,
  Color = 2,
  Scale = 0.65,
  ShortRange = true,
  ShowOnlyIfDiscovered = false,
}

-- ============================================================
-- Default pricing
-- ============================================================
Config.Defaults = {
  SalePrice = 75000,
  RentPerWeek = 2500,
  Deposit = 2500,
}

-- ============================================================
-- Money adapter
-- ============================================================
-- Set Mode to integrate with your framework/economy.
-- 'none': no money checks (always allow). Great for dev/testing.
-- 'qb': QBCore (Player.Functions.RemoveMoney)
-- 'esx': ESX (xPlayer.removeAccountMoney)
-- 'az-econ': exports['az-econ'] adapter
-- 'custom': edit shared/money.lua
Config.Money = {
  -- Cash-only purchases using Az-Framework exports (fw:deductMoney / fw:addMoney)
  Mode = 'azfw',
  -- Account is ignored for azfw mode.
  Account = 'cash', -- qb/esx account name
}

-- ============================================================
-- Permissions (Discord Role IDs)
-- ============================================================
-- If your server syncs Discord roles into player state, you can gate admin/agent
-- features by role IDs.
--
-- Supported state shapes:
--   Player(src).state.discordRoles = {"123","456"}
--   Player(src).state.roles       = {"123","456"}
--   Player(src).state.discord_roles = {"123","456"}
--
-- If these lists are empty, we fall back to ACE/job checks.
Config.Perms = {
  AdminRoleIds = { },
  AgentRoleIds = { "1437877826706604115"},
}

-- ============================================================
-- Mailbox
-- ============================================================
Config.Mailbox = {
  Enabled = true,
  BaseCapacity = 15,
  CapacityPerLevel = 10,
}

-- ============================================================
-- House upgrades
-- ============================================================
Config.Upgrades = {
  Levels = {
    -- Level 0 = base. Prices are paid on purchase.
    mailbox = {
      { price = 0,   capacityBonus = 0 },
      { price = 2500, capacityBonus = 10 },
      { price = 5000, capacityBonus = 20 },
      { price = 9000, capacityBonus = 35 },
    },
    decor = {
      { price = 0,    furnitureLimit = 25 },
      { price = 7500, furnitureLimit = 50 },
      { price = 15000, furnitureLimit = 85 },
      { price = 25000, furnitureLimit = 130 },
    },
    storage = {
      { price = 0,    stashSlots = 20, stashWeight = 20000 },
      { price = 12500, stashSlots = 40, stashWeight = 40000 },
      { price = 25000, stashSlots = 60, stashWeight = 70000 },
    },
  }
}

-- ============================================================
-- Furniture placement
-- ============================================================
Config.Furniture = {
  Enabled = true,
  -- A small, safe starter catalog (add your own props here)
  Catalog = {
    { label = 'Sofa (Modern)', model = 'v_res_mp_sofa' },
    { label = 'Coffee Table', model = 'v_res_fh_coftableb' },
    { label = 'TV Stand', model = 'v_res_tre_tvstand' },
    { label = 'Flat TV', model = 'prop_tv_flat_01' },
    { label = 'Bed (Simple)', model = 'v_res_msonbed' },
    { label = 'Lamp', model = 'v_res_d_lampa' },
    { label = 'Plant', model = 'prop_plant_int_02a' },
    { label = 'Rug', model = 'v_res_m_rugrug' },
  },
  AllowCustomModelForAdmins = true,
}

-- ============================================================
-- Access Control
-- ============================================================
Config.Ace = {
  Admin = 'azhousing.admin', -- add_ace group.admin azhousing.admin allow
}

Config.Agent = {
  Jobs = { 'realestate', 'realtor' },
}

-- ============================================================
-- Interior templates (vanilla GTA interiors)
-- ============================================================
-- NOTE: These coordinates are inside existing GTA interiors. No extra assets required.
-- You can add more templates or point to your MLOs.
Config.Interiors = {
  apt_basic = {
    label = 'Basic Apartment',
    entry = vector4(266.0388, -1007.5456, -101.0085, 355.15),
    exit  = vector4(266.0388, -1007.5456, -101.0085, 175.15),
    stash = vector3(265.90, -999.50, -99.00),
    wardrobe = vector3(259.70, -1004.00, -99.00),
  },

  apt_mid = {
    label = 'Mid Apartment',
    entry = vector4(346.5221, -1012.7787, -99.1962, 0.0),
    exit  = vector4(346.5221, -1012.7787, -99.1962, 180.0),
    stash = vector3(350.80, -993.70, -99.20),
    wardrobe = vector3(349.20, -994.90, -99.20),
  },

  apt_highend = {
    label = 'High-End Apartment',
    entry = vector4(-786.8663, 315.7642, 217.6385, 268.0),
    exit  = vector4(-786.8663, 315.7642, 217.6385, 88.0),
    stash = vector3(-796.20, 331.10, 217.04),
    wardrobe = vector3(-796.40, 327.70, 217.04),
  }
}

-- ============================================================
-- Garage
-- ============================================================
Config.Garage = {
  SpawnClearance = 3.0,
  DefaultRadius = 2.2,
}

-- ============================================================
-- Markers
-- ============================================================
Config.Markers = {
  Enabled = true,
  DoorType = 2,
  GarageType = 36,
  Scale = vec3(0.25, 0.25, 0.25),
}
