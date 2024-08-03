local UtilityAI = {}

function UtilityAI.new(actions, considerations)
    local self = {}
    self.actions = actions
    self.considerations = considerations

    function self:calculateUtility(character, action)
        local utility = 0
        local totalWeight = 0
    
        for considerationName, weight in pairs(action.weights) do
            local consideration = self.considerations[considerationName]
            if consideration and consideration.evaluate then
                local value = consideration.evaluate(character)
                utility = utility + (value * weight)
                totalWeight = totalWeight + weight
            else
                print("Warning: Invalid consideration or missing evaluate function for " .. considerationName)
            end
        end
    
        print(string.format("Utility for %s: %.2f", action.name, utility))
    
        return utility
    end

    function self:chooseBestAction(character)
        local bestAction = nil
        local bestScore = -1

        for _, action in pairs(self.actions) do
            local score = self:calculateUtility(character, action)
            if score > bestScore then
                bestScore = score
                bestAction = action
            end
        end

        return bestAction
    end

    return self
end

return UtilityAI
