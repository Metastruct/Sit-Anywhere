if SERVER then
    AddCSLuaFile("sitanywhere/client/sit.lua")
    include("sitanywhere/server/sit.lua")
else
    include("sitanywhere/client/sit.lua")
end