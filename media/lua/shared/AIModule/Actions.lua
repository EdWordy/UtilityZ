local Actions = {}

-- helper methods

function safeGetUsername(character)
    if character and character.getUsername then
        return character:getUsername()
    end
    return "Unknown NPC"
end

-- actions and action methods

local foodCache = {}
local cacheLifetime = 10000 -- How long to keep cached locations (in ticks)

Actions.FindFood = {
    name = "FindFood",
    execute = function(character)
        local username = safeGetUsername(character)
        print(username .. " is searching for food")

        local x, y, z = character:getX(), character:getY(), character:getZ()
        local currentTick = getGameTime():getWorldAgeHours() * 3600

        -- Check cache first
        for loc, data in pairs(foodCache) do
            if currentTick - data.time < cacheLifetime then
                local dx, dy = loc:match("(%d+),(%d+)")
                dx, dy = tonumber(dx), tonumber(dy)
                if math.abs(dx - x) <= 20 and math.abs(dy - y) <= 20 then
                    print(username .. " found cached food at " .. dx .. "," .. dy)
                    character:setX(dx)
                    character:setY(dy)
                    return true
                end
            else
                foodCache[loc] = nil -- Remove outdated cache entry
            end
        end

        -- If not in cache, search for food
        local cell = getCell()
        local range = 15 -- Reduced search range
        for dx = -range, range, 3 do -- Step by 3 to reduce iterations
            for dy = -range, range, 3 do
                local square = cell:getGridSquare(x + dx, y + dy, z)
                if square then
                    local objects = square:getObjects()
                    for i = 0, objects:size() - 1 do
                        local object = objects:get(i)
                        if object:getContainer() then
                            local container = object:getContainer()
                            local items = container:getItems()
                            for j = 0, items:size() - 1 do
                                local item = items:get(j)
                                if item:getCategory() == "Food" then
                                    local loc = (x+dx) .. "," .. (y+dy)
                                    foodCache[loc] = {time = currentTick}
                                    print(username .. " found new food at " .. loc)
                                    character:setX(x + dx)
                                    character:setY(y + dy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end

        print(username .. " couldn't find any food")
        return false
    end
}

Actions.Rest = {
    name = "Rest",
    execute = function(character)
        local username = safeGetUsername(character)
        print(username .. " is resting")
        -- Implement resting logic here
        -- Example:
        character:setAsleep(true)
        character:setFatigue(character:getFatigue() - 0.1)
        return true
    end
}

Actions.Flee = {
    name = "Flee",
    execute = function(character)
        local username = safeGetUsername(character)
        print(username .. " is fleeing from danger")
        -- Implement fleeing logic here
        -- Example:
        local x, y, z = character:getX(), character:getY(), character:getZ()
        local cell = getCell()
        local range = 10 -- Flee range
        local safeSquare = nil
        for dx = -range, range do
            for dy = -range, range do
                local square = cell:getGridSquare(x + dx, y + dy, z)
                if square and not square:isVehicleIntersecting() and square:isFreeOrMidair(false) then
                    local zombies = square:getMovingObjects()
                    if zombies:isEmpty() then
                        safeSquare = square
                        break
                    end
                end
            end
            if safeSquare then break end
        end
        if safeSquare then
            character:setX(safeSquare:getX())
            character:setY(safeSquare:getY())
            character:setZ(safeSquare:getZ())
            print(username .. " fled to " .. safeSquare:getX() .. "," .. safeSquare:getY())
            return true
        else
            print(username .. " couldn't find a safe place to flee")
            return false
        end
    end
}

Actions.SelfDefense = {
    name = "SelfDefense",
    execute = function(character)
        local username = safeGetUsername(character)
        print(username .. " is in self-defense mode")
        
        local x, y, z = character:getX(), character:getY(), character:getZ()
        local cell = getWorld():getCell()
        local range = 5 -- Close range for immediate threats
        local nearestZombie = nil
        local shortestDistance = range * 1.5 -- Slightly larger to ensure we catch zombies at the edge

        -- Use getZombieList for better performance
        local zombieList = cell:getZombieList()
        for i = 0, zombieList:size() - 1 do
            local zombie = zombieList:get(i)
            local distance = IsoUtils.DistanceTo(x, y, zombie:getX(), zombie:getY())
            if distance <= shortestDistance then
                nearestZombie = zombie
                shortestDistance = distance
            end
        end

        if nearestZombie then
            print(username .. " found a zombie at distance " .. shortestDistance)
            character:faceThisObject(nearestZombie)

            -- Check if the character has a weapon
            local weapon = character:getPrimaryHandItem()
            if weapon and instanceof(weapon, "HandWeapon") then
                if weapon:isRanged() and weapon:getAmmo() > 0 then
                    -- Use firearm if available and loaded
                    character:playSound(weapon:getSwingSound())
                    character:DoAttack(0)
                    print(username .. " fired at a zombie with " .. weapon:getName())
                else
                    -- Melee attack
                    character:DoAttack(0)
                    print(username .. " attacked a zombie with " .. weapon:getName())
                end
            else
                -- Unarmed attack
                character:DoAttack(0)
                print(username .. " attempted to push a zombie")
            end

            -- Check if the attack was successful
            if nearestZombie:isDead() then
                print(username .. " killed a zombie")
            end

            return true
        else
            -- If no zombies found, move randomly to search for threats
            local newX = x + ZombRand(-3, 3)
            local newY = y + ZombRand(-3, 3)
            local newSquare = cell:getGridSquare(newX, newY, z)
            if newSquare and newSquare:isFreeOrMidair(false) then
                character:setPath2(newX, newY, z)
                print(username .. " moved to search for threats")
            else
                print(username .. " couldn't move, staying alert")
            end
            return true  -- Always return true to maintain the defensive state
        end
    end,
}

Actions.Idle = {
    name = "Idle",
    execute = function(character)
        local username = safeGetUsername(character)
        print(username .. " is idling")
        
        -- Random idle behaviors
        local idleBehaviors = {
            function() 
                character:faceThisObject(nil) 
                print(username .. " is looking around")
            end,
            function() 
                character:setVariable("sitstatic", "Idle")
                print(username .. " is standing still")
            end,
            function()
                local x, y, z = character:getX(), character:getY(), character:getZ()
                local square = getCell():getGridSquare(x + ZombRand(-1, 1), y + ZombRand(-1, 1), z)
                if square and square:isFreeOrMidair(false) then
                    character:pathToLocation(square:getX(), square:getY(), square:getZ())
                    print(username .. " is wandering nearby")
                end
            end
        }
        
        -- Choose a random idle behavior
        local randomBehavior = idleBehaviors[ZombRand(1, #idleBehaviors + 1)]
        randomBehavior()
        
        -- Idle for a short time
        character:setVariable("IsIdling", true)
        Events.OnTick.Add(function()
            character:setVariable("IsIdling", false)
        end)
        
        return true
    end
}

Actions.Die = {
    name = "Die",
    execute = function(character)
        local username = safeGetUsername(character)
        print(username .. " has died")
        character:setHealth(0)
        character:setZombieKills(0)  -- Reset zombie kills to avoid inflating stats
        character:die()
        return true
    end
}

-- action weights

Actions.FindFood.weights = {Hunger = 1.0, Tiredness = 0.2, Safety = 0.5, Danger = 0.3, Boredom = 0.1, Health = 0.1}
Actions.Rest.weights = {Hunger = 0.2, Tiredness = 1.0, Safety = 0.8, Danger = 0.2, Boredom = 0.1, Health = 0.1}
Actions.Flee.weights = {Hunger = 0.1, Tiredness = 0.3, Safety = 0.9, Danger = 0.8, Boredom = 0.0, Health = 0.5}
Actions.SelfDefense.weights = {Hunger = 0.1, Tiredness = 0.2, Safety = 1.0, Danger = 1.0, Boredom = 0.0, Health = 0.5}
Actions.Idle.weights = {Hunger = 0.1, Tiredness = 0.1, Safety = 0.3, Danger = 0.1, Boredom = 1.0, Health = 0.1}
Actions.Die.weights = {Health = 10.0}

-- return the complete object

return Actions
