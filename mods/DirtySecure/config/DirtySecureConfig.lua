local Config = {}
Config.author = 'Dirtyredz'
Config.name = 'DirtySecure'
Config.homepage = "https://github.com/dirtyredz/DirtySecure"
Config.version = {
    major=1, minor=5, patch = 0,
    string = function()
        return  Config.version.major .. '.' ..
                Config.version.minor .. '.' ..
                Config.version.patch
    end
}

Config.DistanceFromCore = 120 --0 = entire galaxy, for pvp damage inside the core use 120
Config.DisableNeutralZones = true -- if true will remove the nuetralzone script from that sector and re enable pvp damage for that sector.
Config.OfflineProtection = true -- if true will give offline protection to the players current ship, if they logged off inside the DistanceFromCore setting.
Config.StationProtection = true -- if true will give invincibility to all stations
Config.PirateStationProtection = false -- if false will ensure pirate stations do not have protection

function Config.print(...)
  local args = table.pack(...)
  table.insert(args,1,"[" .. Config.name .. "][" .. Config.version.string() .. "]")
  print(table.unpack(args))
end

return Config
