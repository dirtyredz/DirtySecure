if onServer() then
  function execute(sender, commandName, one, ...)
      local args = {...}
      local Server = Server()
      local Player = Player(sender)
      local script = Player:hasScript("mods/DirtySecure/scripts/player/DirtySecure.lua")
      if script == true then
        Player:removeScript("mods/DirtySecure/scripts/player/DirtySecure.lua")
      end
      Player:addScript("mods/DirtySecure/scripts/player/DirtySecure.lua")
      Player:sendChatMessage('DirtySecure', 0, "Dirty Secure Added")

      return 0, "", ""
  end

  function getDescription()
      return ""
  end

  function getHelp()
      return ""
  end
end
