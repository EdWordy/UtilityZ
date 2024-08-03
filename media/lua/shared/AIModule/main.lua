print("Loading main.lua")

local NPCManager

local function initMod()
    print("Initializing mod")
    NPCManager = require "AIModule/NPCManager"
    if NPCManager then
        print("NPCManager loaded successfully")
        if NPCManager.init then
            print("Calling NPCManager.init()")
            NPCManager.init()
        else
            print("Error: NPCManager.init function is not available")
        end
    else
        print("Error: Failed to load NPCManager")
    end
end

Events.OnGameStart.Add(initMod)
print("Added initMod to OnGameStart event")