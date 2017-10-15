local DirtySecure = {}

function DirtySecure.onPlayerLogIn(playerIndex)
  -- Adding script to player when they log in
  local player = Player(playerIndex)
  player:addScriptOnce("mods/DirtySecure/scripts/player/DirtySecure.lua")
end

return DirtySecure
