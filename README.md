# Az-Housing 

A **routing-bucket** housing/apartment system for FiveM with a modern **NUI Housing Portal**, **door/garage interactions**, **rentals + applications (agent workflow)**, **police breach**, **mailbox**, **upgrades**, and **persistent furniture placement**.

> **Built for Az-Framework** (job/admin/character ownership), with optional money adapters for `azfw`, `az-econ`, `qb`, `esx`, or `none`.

---

## What this resource does

### Core gameplay
- **Instanced interiors via routing buckets**
  - Everyone uses the same interior coordinates, but each house can have its **own bucket** (`Config.Buckets.UsePerHouse`).
- **Doors**
  - **Enter**, **Knock**, **Lock/Unlock**
  - **Police Breach** (temporary forced unlock + entry)
- **Garages**
  - Store the current vehicle
  - Retrieve stored vehicles (per-house, per-owner) using `ox_lib` vehicle properties

### Housing Portal (NUI)
Open via **target** option at doors/garages or the `/housing` command (configurable).

Portal includes:
- **Browse properties** (purchase / rental listings)
- **My Properties**
- **My Rentals / Lease info**
- **Agent tools** (approve/deny applications for houses you have listed for rent)
- **Property Manager** (per house):
  - **Mailbox**
  - **Upgrades**
  - **Furniture** (place / remove)

### Persistence (DB or JSON fallback)
- Uses **oxmysql** when available (`Config.UseDatabase = true`)
- Falls back to JSON files in `data/` when DB is disabled/unavailable

---

## Dependencies

### Required
- **ox_lib** (used for callbacks, UI helpers, menus, textUI, vehicle props)

### Recommended
- **oxmysql** (persistence)
- **ox_target** (clean interactions at doors/garages; the script can run without it, but interactions will be limited)

### Framework/Economy
- **Az-Framework** recommended (jobs/admin + stable character identifier `char:<id>`)
- Economy adapter configured in `Config.Money.Mode`:
  - `azfw` (Az-Framework cash exports)
  - `az-econ`
  - `qb`
  - `esx`
  - `none` (dev/testing)

---

## Installation

### 1) Add to your server
Place the folder as `resources/[yourfolder]/Az-Housing` (resource name: `Az-Housing` in `fxmanifest.lua`).

### 2) Database (recommended)
This resource can auto-create its tables on start, but you can also import SQL.

- Import: `sql/install.sql` *(note: some installs are older—auto-ensure will still add missing columns/tables)*

### 3) Ensure order
```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure Az-Housing
```

### 4) Configure
Open `config.lua` and adjust:
- `Config.Commands.Portal` (default: `housing`)
- `Config.Commands.Placement` (default: `housingedit`)
- `Config.Money.Mode` (default in this build: `azfw`)
- `Config.Police.Jobs`
- `Config.Agent.Jobs`
- `Config.Interiors` (add/edit interior templates)

---

## Quick start (Admin)

### Give yourself admin permission
The resource checks admin using **Az-Framework** and can also use ACE:

```cfg
add_ace group.admin azhousing.admin allow
```

Default ACE string:
- `Config.Ace.Admin = "azhousing.admin"`

### Create houses / doors / garages
Use:
- `/housingedit`

This opens the **Housing Editor** menu:
- **Create House** (name, optional label, price, interior template)
- **Place Door Entrance** *(stand where the door should be)*
- **Place Garage Entrance** *(stand at the garage entry; can use your vehicle position as the spawn)*
- **Delete House**
- **Reload** (rebuild server caches + re-bootstrap clients)

---

## Player guide

### Entering a property
Walk to a placed **door** and use the target options:
- **Enter** (if you’re the owner / have keys / are authorized)
- **Knock** (notifies inside occupants)
- **Lock / Unlock** (owner/keys)
- **Breach (Police)** (police jobs only)

### Using the Housing Portal
- Use the door/garage target option **Housing Portal**, or run:
  - `/housing`

From the portal you can:
- Buy a listed house
- Apply to rent a listed house
- Manage your owned properties
- Manage mailbox / upgrades / furniture (for properties you can manage)

### Furniture placement controls
When placing furniture (Property Manager → Furniture → Start Placement):
- **E**: confirm
- **Backspace**: cancel
- **Mouse wheel**: rotate
- **Arrow Up/Down**: raise/lower
- **Hold Shift**: fine adjustment

---

## Rentals + Agent workflow (how it works)

1) **Owner lists** their house for rent (set rent + deposit, toggle listed).
2) Players **apply** with a message.
3) The **agent/owner** reviews applications in the **Agent Portal** tab.
4) Approve/deny:
   - Approval assigns a tenant and activates the lease in `az_house_rentals`.

> “Agent” is defined as: **a player who owns a house and has it listed for rent** (admins also count as agents). Job/role gates can be enabled via `Config.Agent.Jobs` and/or `Config.Perms.AgentRoleIds`.

---

## Police breach

- Accessible at the door target option **Breach (Police)**.
- Police jobs controlled by:
  - `Config.Police.Jobs`
- Options:
  - `Config.Police.RequireItem` + `Config.Police.BreachItem`
- Effects:
  - Temporarily forces door unlocked for `Config.Police.BreachUnlockSeconds`
  - Optional dispatch blip duration: `Config.Police.BreachBlipSeconds`

---

## Images (house cover + gallery)

This build includes a lightweight image system stored on `az_houses`:
- `Config.Images.Enabled` (default true)
- `Config.Images.MaxPerHouse` (default 8)
- `Config.Images.MaxBytes` (default 2MB)

Images are stored in `az_houses.image_url` (cover) and `az_houses.image_data` (JSON). The NUI uses these for listing/portal visuals.

---

## Database tables (auto-created when using oxmysql)

- `az_houses` (houses + owner + interior + image data)
- `az_house_doors`
- `az_house_garages`
- `az_house_keys`
- `az_house_rentals`
- `az_house_apps` (rental applications)
- `az_house_vehicles` (stored vehicles)
- `az_house_upgrades`
- `az_house_mail` (mailbox messages)
- `az_house_furniture`

---

## Troubleshooting

- **No target options at doors/garages**
  - Ensure `ox_target` is started *before* `Az-Housing`
  - Confirm `Config.UseOxTarget = true`
  - Run `/azhousing_reload` (admin) or restart the resource

- **Portal won’t open**
  - Ensure `ox_lib` is running
  - Try `/housing` (or your configured command)

- **Can’t enter / can’t manage**
  - Ownership/keys are stored by identifier (prefers `char:<id>` via Az-Framework)
  - Ensure your character system returns a stable character id

- **DB tables missing**
  - Ensure `oxmysql` is running
  - Check your connection string and that the database user has CREATE/ALTER permissions
  - The script will attempt to `CREATE TABLE IF NOT EXISTS` on start

---

## Commands

Player:
- `/housing` — open portal (configurable: `Config.Commands.Portal`)

Admin:
- `/housingedit` — housing editor (configurable: `Config.Commands.Placement`)
- `/azhousing_reload` — reload server caches + re-bootstrap clients
- `/azhousing_sell <houseId> <playerId> <price>` — sell a house directly to a player (admin tool)
- `/house_sell` — legacy alias for selling (see server/main.lua)

---

## Notes for developers

This resource is primarily event/callback driven (ox_lib callbacks + net events).
Key server events include:
- `Az-Housing:server:enter`, `:leave`, `:toggleLock`, `:knock`, `:breach`
- `Az-Housing:server:buy`
- `Az-Housing:server:listForRent`, `:unlistRent`, `:applyRent`, `:agentDecide`
- `Az-Housing:server:garageStore`, `:garageTakeOut`
- `Az-Housing:server:saveFurniture`
- Admin: `Az-Housing:server:adminCreateHouse`, `:adminAddDoor`, `:adminAddGarage`, `:adminDeleteHouse`

ox_lib callbacks (used by NUI/client):
- `Az-Housing:cb:getPortalData`
- `Az-Housing:cb:getAgentApps`
- `Az-Housing:cb:getMailbox`
- `Az-Housing:cb:getUpgrades`
- `Az-Housing:cb:getFurniture`
- `Az-Housing:cb:listVehicles`

---

## Credits
- Azure (Az-Framework ecosystem)
- ox_lib / ox_target / oxmysql communities
