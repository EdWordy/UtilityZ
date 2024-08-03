local AIBehavior = require "AIModule/AIBehavior"

local NPCSpawner = {}

function NPCSpawner.spawnNPC(name, square)
    if not square then
        print("Error: Invalid square for NPC spawn")
        return nil
    end

    local cell = getCell()
    if not cell then
        print("Error: Unable to get game cell")
        return nil
    end

    -- Create a survivor description
    local survivorDesc = SurvivorFactory.CreateSurvivor()
    if not survivorDesc then
        print("Error: Failed to create SurvivorDesc")
        return nil
    end

    -- Create the actual IsoPlayer from the description
    local survivor = IsoPlayer.new(cell, survivorDesc, square:getX(), square:getY(), square:getZ())
    if not survivor then
        print("Error: Failed to create IsoPlayer from SurvivorDesc")
        return nil
    end

    -- Set NPC-specific properties
    survivor:setUsername(name)
    survivor:setForname(name)
    survivor:setSurname("")
    survivor:setGhostMode(false)
    survivor:setInvincible(false)
    survivor:setGodMod(false)
    survivor:setSceneCulled(false)
    survivor:setNPC(true)

    -- Adjust stats as needed
    survivor:getStats():setHunger(0)
    survivor:getStats():setThirst(0)
    survivor:getStats():setFatigue(0)

    -- Initialize AI for the NPC
    AIBehavior.initForNPC(survivor)

    -- Verify that the survivor was added successfully
    if survivor:getCell() ~= nil then
        print("Spawned NPC: " .. name .. " at " .. square:getX() .. "," .. square:getY() .. "," .. square:getZ())
        return survivor
    else
        print("Error: Failed to add NPC to world")
        return nil
    end
end

return NPCSpawner