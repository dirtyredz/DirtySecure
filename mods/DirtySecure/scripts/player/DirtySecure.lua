-- David McClain | Dirtyredz

-- Dirty Secure
-- A script for providing galaxy wide pvp protection

-- this is so the script won't crash when executed in a context where there's no onServer() or onClient() function available -
-- naturally those functions should return false then
if not onServer then onServer = function() return false end end
if not onClient then onClient = function() return false end end
if onClient() then return end

if onServer() then

--Custom logging
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"
local logLevels = require("PrintLog")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace DirtySecure
DirtySecure = {}

--For EXTERNAL configuration files
local modConfigExsist, modConfig = pcall(require, 'mods.DirtySecure.config.DirtySecureConfig')

--Local variables
local ship = nil  --Need to keep the current ships id, so that we can protect it on log off
local player = nil

function DirtySecure.initialize()
  if not modConfigExsist then print(modConfig); terminate(); return end
  modConfig.print('DirtySecure initialize', logLevels.trace)

  Player = Player()
  local x, y = Sector():getCoordinates()
  local playerIndex = Player.index
  ship = Player.craft --store the craft entity the player logged in on

  Player:registerCallback("onSectorEntered", "DirtySecure_onSectorEntered")
  Player:registerCallback("onShipChanged", "DirtySecure_onShipChanged")
  Server():registerCallback("onPlayerLogOff", "DirtySecure_onPlayerLogOff")

  if ship and valid(ship) then
    local faction = Faction(ship.factionIndex)
    if faction.isAlliance then
      ship:setValue('LastShipDriver',playerIndex)
      DirtySecure.ProtectionSetting(ship,false,x,y)
    end
  end

  --Disable offline protection
  DirtySecure.ProtectionSetting(ship,false,x,y)
  --Run Sector check incase player logged in on a sector that hasnt been set to PVP or PVE yet
  DirtySecure.CheckSector(playerIndex, x, y)
end

function DirtySecure.ProtectionSetting(Entity,invincible_bool,x,y,silent)
  local xy = '()'
  if x and y then xy = "("..x..", "..y..")" end

  if Entity and valid(Entity) then

    local EntiyName = 'Fighter'
    if not Entity.isFighter then
      EntiyName = Entity.name
    end

    Entity.invincible = invincible_bool
    if invincible_bool then
      Entity:setValue('Invincible','DirtySecure')
      --Entity:addScriptOnce('DirtySecureNotifier.lua')
      if not silent then
        modConfig.print('Setting protection to: True, for entity: ' .. EntiyName .. ', ' .. xy, logLevels.info)
      end
    else
      Entity:setValue('Invincible',nil)
      if not silent then
        modConfig.print('Setting protection to: False, for entity: ' .. EntiyName .. ', ' .. xy, logLevels.info)
      end
    end
  else
    modConfig.print('Cannot set protection, ship is nil', logLevels.info)
  end
end

function DirtySecure.DirtySecure_onPlayerLogOff(playerIndex)
  if Player.index ~= playerIndex then return end  --WTF, why is this function run against every player?

  modConfig.print('DirtySecure DirtySecure_onPlayerLogOff', logLevels.trace)
  local x, y = Sector():getCoordinates()

  modConfig.print('(' .. playerIndex .. '), has logged off', logLevels.debug)

  --Enable player log off protection
  if modConfig.OfflineProtection then
    DirtySecure.ProtectionSetting(ship,true,x,y)
  end
end

function DirtySecure.DirtySecure_onSectorEntered(playerIndex, x, y)
  if Player.index ~= playerIndex then return end  --WTF, why is this function run against every player?
  modConfig.print('DirtySecure DirtySecure_onSectorEntered', logLevels.trace)

  DirtySecure.CheckSector(playerIndex, x, y)
end

function DirtySecure.DirtySecure_onShipChanged(playerIndex, craftIndex)
  if Player.index ~= playerIndex then return end  --WTF, why is this function run against every player?
  modConfig.print('(' .. playerIndex .. ') has changed ships.', logLevels.debug)
  ship = Entity(craftIndex) --assign the ship entity so we can protect it later
  local x, y = Sector():getCoordinates()
  local faction = Faction(ship.factionIndex)
  if faction.isAlliance then
    ship:setValue('LastShipDriver',playerIndex)
    DirtySecure.ProtectionSetting(ship,false,x,y)
  end
end

function DirtySecure.ProtectStations(x,y)
  modConfig.print('DirtySecure ProtectStations', logLevels.trace)

  --Get all the stations
  local stations = {Sector():getEntitiesByType(EntityType.Station)}
  local faction = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))
  for _, entity in pairs(stations) do
    --Keep it dynamic is StationProtection is disabled in the future we can remove all the invincibility
    if modConfig.StationProtection and not entity.invincible then
      --Dont Protect Pirate stations.
      if not modConfig.PirateStationProtection and entity.factionIndex == faction.index then
        DirtySecure.ProtectionSetting(entity,false,x,y,false) --Enable, no print out
      else
        DirtySecure.ProtectionSetting(entity,true,x,y,true) --Enable, no print out
      end
    elseif not modConfig.StationProtection then
      DirtySecure.ProtectionSetting(entity,false,x,y,true) --Disable, no print out
    end
  end
end

function DirtySecure.ProtectOfflineShips(x,y)
  modConfig.print('DirtySecure ProtectOfflineShips', logLevels.trace)

  --Get all the ships
  local ships = {Sector():getEntitiesByType(EntityType.Ship)}

  --Get Online players
  local OnlinePlayers = {Server():getOnlinePlayers()}

  for _, entity in pairs(ships) do
    local faction = Faction(entity.factionIndex) --Use faction so we can also protect alliance ships
    local LastShipDriver = entity:getValue('LastShipDriver')
    local ShipOwnerIndex

    if faction.isPlayer then
      modConfig.print('Entity:' .. entity.name .. ' is an player ship',logLevels.debug)
      ShipOwnerIndex = faction.index
    elseif faction.isAlliance then
      modConfig.print('Entity:' .. entity.name .. ' is an alliance ship',logLevels.debug)
      if LastShipDriver then
        modConfig.print('Ship had a last driver',logLevels.debug)
        modConfig.print('Entity:' .. entity.name .. ', Ships last driver: ' .. LastShipDriver,logLevels.debug)
        ShipOwnerIndex = LastShipDriver
      else
        modConfig.print('Entity:' .. entity.name .. ', Ship had no last driver, Removing protection.',logLevels.debug)
        DirtySecure.ProtectionSetting(entity,false,x,y)
      end
    end

    --If its owned by a PLAYER or has a LASTSHIPDRIVER value
    if ShipOwnerIndex then
      if modConfig.OfflineProtection then
        --if Offline Protection is enabled
        for _,player in pairs(OnlinePlayers) do
          if ShipOwnerIndex == player.index then
            modConfig.print('('..player.index..') is Online, Removing any protection, just in case',logLevels.info)
            DirtySecure.ProtectionSetting(entity,false,x,y)
            goto continue
          end
        end--End OnlinePlayers
        modConfig.print('('..ShipOwnerIndex..') is Offline, Enabling protection, incase it was missed',logLevels.info)
        DirtySecure.ProtectionSetting(entity,true,x,y)
      else
        --if Offline protection is disabled, remove all protection from player owned ships
        DirtySecure.ProtectionSetting(entity,false,x,y)
      end -- Offline Protection

    end -- ShipOwnerIndex
    ::continue::
  end--eND SHIPS
end

function DirtySecure.ProtectOfflineFighters(x,y)
  modConfig.print('DirtySecure ProtectOfflineFighters', logLevels.trace)

  --Get all the ships
  local fighters= {Sector():getEntitiesByType(EntityType.Fighter)}

  --Get Online players
  local OnlinePlayers = {Server():getOnlinePlayers()}

  for _, entity in pairs(fighters) do
    local faction = Faction(entity.factionIndex) --Use faction so we can also protect alliance ships
    local ShipOwnerIndex = faction.index
    local EntiyName = 'Fighter'

    if faction.isPlayer then
      modConfig.print('Entity:' .. EntiyName .. ' is a players fighter',logLevels.debug)
      if modConfig.OfflineProtection then
        --if Offline Protection is enabled
        for _,player in pairs(OnlinePlayers) do
          if ShipOwnerIndex == player.index then
            modConfig.print('('..player.index..') is Online, Removing any protection, just in case',logLevels.info)
            DirtySecure.ProtectionSetting(entity,false,x,y)
            goto continue
          end
        end--End OnlinePlayers
        modConfig.print('('..ShipOwnerIndex..') is Offline, Enabling protection, incase it was missed',logLevels.info)
        DirtySecure.ProtectionSetting(entity,true,x,y)
      else
        --if Offline protection is disabled, remove all protection from player owned ships
        DirtySecure.ProtectionSetting(entity,false,x,y)
      end -- Offline Protection
    elseif faction.isAlliance then
      modConfig.print('Entity:' .. EntiyName .. ' is an alliance fighter, Disabling protection',logLevels.debug)
      DirtySecure.ProtectionSetting(entity,false,x,y)
    end
    ::continue::
  end--END FIGHTERS
end

function DirtySecure.CheckSector(playerIndex, x, y)
  if Player.index ~= playerIndex then return end  --WTF, why is this function run against every player?
  modConfig.print('DirtySecure CheckSector', logLevels.trace)

  DirtySecure.ProtectStations(x,y)
  DirtySecure.ProtectOfflineShips(x,y)
  DirtySecure.ProtectOfflineFighters(x,y)

  local xy = "("..x..", "..y..")"
  local Sector = Sector()
  local distanceFromCenter = length(vec2(x,y))

  if distanceFromCenter > modConfig.DistanceFromCore then
    --PVE
    Sector.pvpDamage = 0
    modConfig.print('Setting ' .. xy .. ' to no PVP damage.', logLevels.debug)
    Sector:setValue('DirtySecure','PVE') -- Tie in for a future command to check for pvp status of the sector

  else
    --PVP
    local isNeutralSector = Sector:hasScript("neutralzone.lua")

    if isNeutralSector then
      --Neutral Sector
      if  modConfig.DisableNeutralZones then
        --Remove Neutral zone
        Sector:setValue("neutral_zone", 0)
        modConfig.print('Neutral Sector: ' .. xy .. ' , inside PVP Zone. DisableNeutralZones is turned on, removing...', logLevels.info)
        --Sector:unregisterCallback("onPlayerEntered", "onPlayerEntered")
        Sector:removeScript("data/scripts/sector/neutralzone.lua")

      else
        --Ignore neutral zone
        modConfig.print('Neutral Sector: ' .. xy .. ' , inside PVP Zone. DisableNeutralZones is turned off, ignoring...', logLevels.debug)
        return
      end

    end

    -- make this sector PVP enabled
    Sector.pvpDamage = 1
    if Sector.pvpDamage == 1 then
      Sector:setValue('DirtySecure','PVP') -- Tie in for a future command to check for pvp status of the sector
      Player():sendChatMessage('Server', 2, 'You have entered a PVP Sector, be carefull.')
      modConfig.print('(' .. playerIndex .. ') has entered a PVP Sector: ' .. xy, logLevels.info)
    else
      modConfig.print('You have configured this sector to be PVP, yet you have PlayerToPlayerDamage set to false in your server.ini', logLevels.warning)
    end
  end
end

end
