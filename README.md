# DirtySecure

A mod designed to allow custom pvp sectors based on distance from the core.
The mod also has the capabilities of protecting stations, and offline players ships

## INSTALLATION
___

Step 1.
Unzip the zip file and drag/drop the contents into the avorion directory.

Step 2.
Navigate to:

    data/scripts/server/server.lua

and place these 2 lines of code at the bottom of the file:

    local s, b = pcall(require, 'mods/DirtySecure/scripts/server/server')
    if s then if b.onPlayerLogIn then local a = onPlayerLogIn; onPlayerLogIn = function(c) a(c); b.onPlayerLogIn(c); end end else print(b); end
