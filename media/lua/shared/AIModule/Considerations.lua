local Considerations = {}

-- helper methods

function normalize(value, min, max)
    return (value - min) / (max - min)
end

-- considerations

Considerations.Hunger = {
    name = "Hunger",
    evaluate = function(character)
        local hunger = character:getStats():getHunger()
        return normalize((hunger / 100), 0, 1)  -- Normalize to 0-1
    end
}

Considerations.Tiredness = {
    name = "Tiredness",
    evaluate = function(character)
        local fatigue = character:getStats():getFatigue()
        return normalize((fatigue / 100), 0, 1)  -- Normalize to 0-1
    end
}

Considerations.Safety = {
    name = "Safety",
    evaluate = function(character)
        local zombiesNearby = character:getCell():getZombieList():size()
        return 1 - normalize((1 - (zombiesNearby / 3)), 0, 1)  -- Inverse and normalize
    end
}

Considerations.Danger = {
    name = "Danger",
    evaluate = function(character)
        local x, y, z = character:getX(), character:getY(), character:getZ()
        local cell = getCell()
        local range = 10
        local zombieCount = 0

        for dx = -range, range do
            for dy = -range, range do
                local square = cell:getGridSquare(x + dx, y + dy, z)
                if square then
                    local movingObjects = square:getMovingObjects()
                    for i = 0, movingObjects:size() - 1 do
                        local obj = movingObjects:get(i)
                        if instanceof(obj, "IsoZombie") then
                            zombieCount = zombieCount + 1
                        end
                    end
                end
            end
        end

        return normalize((zombieCount / 1), 0, 1)  -- Normalize to 0-1
    end
}

Considerations.Boredom = {
    name = "Boredom",
    evaluate = function(character)
        local timeSinceLastAction = character:getModData().timeSinceLastAction or 0
        return normalize((timeSinceLastAction / 1000), 0, 1)  -- Normalize to 0-1
    end
}

Considerations.Health = {
    name = "Health",
    evaluate = function(character)
        local health = character:getHealth()
        return 1 - normalize(health, 0, 1)  -- Invert so that lower health gives higher utility
    end
}


return Considerations