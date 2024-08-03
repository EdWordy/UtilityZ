local NPCSpawner = require "AIModule/NPCSpawner"
local AIBehavior = require "AIModule/AIBehavior"

local NPCManager = {}

NPCManager.npcs = {}
NPCManager.config = {
    maxNPCs = 10,
    spawnDistance = 25,
    despawnDistance = 200,
    chunkSize = 50,
}

function NPCManager.init()
    print("NPCManager initialized")
    Events.OnTick.Add(NPCManager.update)
    Events.OnCharacterDeath.Add(NPCManager.onAnyCharacterDeath)
end

local updateCounter = 0
local updateFrequency = 300 -- Update every X ticks (adjust as needed)

function NPCManager.update()
    updateCounter = updateCounter + 1
    if updateCounter >= updateFrequency then
        updateCounter = 0
        NPCManager.manageNPCs(NPCManager.getPlayers())
    end
end

function NPCManager.getPlayers()
    local players = {}
    if isClient() then
        -- Multiplayer
        local onlinePlayers = getOnlinePlayers()
        for i = 0, onlinePlayers:size() - 1 do
            table.insert(players, onlinePlayers:get(i))
        end
    else
        -- Single-player
        local player = getSpecificPlayer(0)
        if player then
            table.insert(players, player)
        end
    end
    return players
end

function NPCManager.getActiveChunks(players)
    local activeChunks = {}
    for _, player in ipairs(players) do
        local playerX, playerY = player:getX(), player:getY()
        local chunkX, chunkY = NPCManager.getChunk(playerX, playerY)
        print("Debug: Player at " .. playerX .. ", " .. playerY .. " is in chunk " .. chunkX .. "," .. chunkY)
        
        for dx = -1, 1 do
            for dy = -1, 1 do
                local neighborChunkX = chunkX + dx
                local neighborChunkY = chunkY + dy
                table.insert(activeChunks, {x = neighborChunkX, y = neighborChunkY})
            end
        end
    end
    return activeChunks
end

function NPCManager.getChunk(x, y)
    local chunkX = math.floor(x / NPCManager.config.chunkSize)
    local chunkY = math.floor(y / NPCManager.config.chunkSize)
    return chunkX, chunkY
end

function NPCManager.manageNPCs(players)
    print("Managing NPCs. Current count: " .. #NPCManager.npcs)
    local activeChunks = NPCManager.getActiveChunks(players)
    
    for _, chunk in ipairs(activeChunks) do
        if #NPCManager.npcs < NPCManager.config.maxNPCs then
            NPCManager.spawnNPCInChunk(chunk.x, chunk.y)
        end
    end
    
    for i = #NPCManager.npcs, 1, -1 do
        local npc = NPCManager.npcs[i]
        if NPCManager.shouldDespawnNPC(npc, players) then
            NPCManager.despawnNPC(i)
        else
            local isAlive = AIBehavior.update(npc)
            if not isAlive then
                print("NPC " .. npc:getUsername() .. " has died, removing from manager")
                NPCManager.removeNPC(i)
            end
        end
    end
end

function NPCManager.spawnNPCInChunk(chunkX, chunkY)
    print("Debug: Attempting to spawn NPC in chunk: " .. tostring(chunkX) .. "," .. tostring(chunkY))

    local chunkStartX = chunkX * NPCManager.config.chunkSize
    local chunkStartY = chunkY * NPCManager.config.chunkSize

    -- Iterate through positions in the chunk
    for xOffset = 0, NPCManager.config.chunkSize - 1 do
        for yOffset = 0, NPCManager.config.chunkSize - 1 do
            local x = chunkStartX + xOffset
            local y = chunkStartY + yOffset
            local z = 0  -- Start at ground level

            print(string.format("Debug: Trying position: (%d, %d)", x, y))

            local square = getCell():getGridSquare(x, y, z)
            if square and not square:isVehicleIntersecting() and square:isFreeOrMidair(false) then
                local NPCSpawner = require("AIModule/NPCSpawner")
                if NPCSpawner and NPCSpawner.spawnNPC then
                    local npc = NPCSpawner.spawnNPC("NPC_" .. (#NPCManager.npcs + 1), square)
                    if npc then
                        table.insert(NPCManager.npcs, npc)
                        print("NPC spawned successfully at " .. x .. ", " .. y .. ", " .. z)
                        return true
                    else
                        print("Failed to spawn NPC at " .. x .. ", " .. y .. ", " .. z)
                    end
                else
                    print("Error: NPCSpawner or spawnNPC function not available")
                    return false
                end
            else
                print("Debug: Invalid or occupied square at " .. x .. ", " .. y .. ", " .. z)
            end
        end
    end

    print("Failed to spawn NPC in chunk " .. chunkX .. "," .. chunkY .. " after checking all positions")
    return false
end

function NPCManager.onAnyCharacterDeath(deadCharacter)
    for i, npc in ipairs(NPCManager.npcs) do
        if npc == deadCharacter then
            print("NPC " .. npc:getUsername() .. " has died")
            NPCManager.removeNPC(i)
            break
        end
    end
end

function NPCManager.removeNPC(index)
    local npc = NPCManager.npcs[index]
    print("Removing NPC " .. npc:getUsername() .. " at index " .. index)
    table.remove(NPCManager.npcs, index)
    print("NPC " .. npc:getUsername() .. " removed from manager")
end

function NPCManager.shouldDespawnNPC(npc, players)
    for _, player in ipairs(players) do
        local distance = NPCManager.getDistance(npc, player)
        if distance <= NPCManager.config.despawnDistance then
            return false
        end
    end
    return true
end

function NPCManager.despawnNPC(index)
    local npc = NPCManager.npcs[index]
    npc:removeFromWorld()
    NPCManager.removeNPC(index)
    print("NPC " .. npc:getUsername() .. " despawned")
end

function NPCManager.getDistance(entity1, entity2)
    local dx = entity1:getX() - entity2:getX()
    local dy = entity1:getY() - entity2:getY()
    return math.sqrt(dx * dx + dy * dy)
end

return NPCManager