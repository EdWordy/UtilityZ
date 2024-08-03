local UtilityAI = require "AIModule/UtilityAI"
local Considerations = require "AIModule/Considerations"
local Actions = require "AIModule/Actions"

local AIBehavior = {}
local aiInstances = {}
local npcStates = {}

function AIBehavior.initForNPC(npc)
    local considerations = Considerations
    local actions = Actions
    aiInstances[npc:getUsername()] = UtilityAI.new(actions, considerations)
    npcStates[npc:getUsername()] = {inSelfDefense = false}
end

function AIBehavior.update(npc)
    local ai = aiInstances[npc:getUsername()]
    local state = npcStates[npc:getUsername()]
    if ai then
        local bestAction = ai:chooseBestAction(npc)
        if bestAction then
            if bestAction.name == "Die" then
                bestAction.execute(npc)
                return false  -- Indicate that the NPC has died
            elseif bestAction.name == "SelfDefense" then
                state.inSelfDefense = true
                bestAction.execute(npc)
            elseif state.inSelfDefense then
                -- If in self-defense state, continue self-defense regardless of best action
                Actions.SelfDefense.execute(npc)
            else
                state.inSelfDefense = false
                bestAction.execute(npc)
            end
        end
    end
    return true  -- Indicate that the NPC is still alive
end

return AIBehavior