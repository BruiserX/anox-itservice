local ESXBridge = {}
ESXBridge.__index = ESXBridge
local ESX = nil

function ESXBridge:Init()
    ESX = exports['es_extended']:getSharedObject()
    if not ESX then
        return false
    end
    return true
end

function ESXBridge:GetPlayerData()
    return ESX.GetPlayerData()
end

function ESXBridge:HasJob(jobName)
    local playerData = self:GetPlayerData()
    return playerData.job and playerData.job.name == jobName
end

function ESXBridge:GetJob()
    local playerData = self:GetPlayerData()
    return playerData.job
end

function ESXBridge:GetPlayerIdentifier()
    local playerData = self:GetPlayerData()
    return playerData.identifier
end

function ESXBridge:GetFramework()
    return ESX
end

return ESXBridge