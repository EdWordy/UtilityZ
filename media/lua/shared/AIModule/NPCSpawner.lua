local AIBehavior = require "AIModule/AIBehavior"

local NPCSpawner = {}

-- Function to add and wear a clothing item
local function addClothingItem(npcIsoPlayer, clothingID)
    local clothingItem = instanceItem(clothingID)
    if clothingItem ~= nil then
        npcIsoPlayer:getInventory():AddItem(clothingItem)
        local bodyPartLocation = clothingItem:getBodyLocation()
        if bodyPartLocation ~= nil and bodyPartLocation ~= '' then
            npcIsoPlayer:setWornItem(bodyPartLocation, clothingItem)
        end
    end
end

-- npc spawner

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
    survivor:setNoClip(false)
    survivor:setBlockMovement(true)
    survivor:setNPC(true)

    -- Adjust stats as needed
    survivor:getStats():setHunger(0)
    survivor:getStats():setThirst(0)
    survivor:getStats():setFatigue(0)

    -- Add clothing to the NPC
    local clothingItems = {
        "Base.Tshirt_White",
        "Base.Trousers_Denim",
        "Base.Shoes_Black",
        "Base.Socks_Ankle"
    }
    for _, clothingID in ipairs(clothingItems) do
        addClothingItem(survivor, clothingID)
    end

    -- Add a weapon to the NPC's inventory
    local weaponTypes = {"Base.BaseballBat", "Base.Axe", "Base.Crowbar", "Base.Machete"}
    local randomWeapon = weaponTypes[ZombRand(1, #weaponTypes + 1)]
    survivor:getInventory():AddItem(randomWeapon)
    
    -- Equip the weapon
    local weapon = survivor:getInventory():getFirstTypeRecurse(randomWeapon)
    if weapon then
        survivor:setPrimaryHandItem(weapon)
        survivor:setSecondaryHandItem(weapon)
    end

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