local QBXBridge = {}
QBXBridge.__index = QBXBridge
local QBX = nil

function QBXBridge:Init()
    QBX = exports['qb-core']:GetCoreObject()
    if not QBX then
        return false
    end
    return true
end

function QBXBridge:GetPlayerData()
    return QBX.Functions.GetPlayerData()
end

function QBXBridge:HasJob(jobName)
    local playerData = self:GetPlayerData()
    return playerData.job and playerData.job.name == jobName
end

function QBXBridge:GetJob()
    local playerData = self:GetPlayerData()
    return playerData.job
end

function QBXBridge:GetPlayerIdentifier()
    local playerData = self:GetPlayerData()
    return playerData.citizenid
end

function QBXBridge:GetPlayerLicense()
    local playerData = self:GetPlayerData()
    return playerData.license
end

function QBXBridge:GetMoney(moneyType)
    local playerData = self:GetPlayerData()
    moneyType = moneyType or 'cash'
    return playerData.money and playerData.money[moneyType] or 0
end

function QBXBridge:HasMoney(amount, moneyType)
    return self:GetMoney(moneyType) >= amount
end

function QBXBridge:GetPlayerName()
    local playerData = self:GetPlayerData()
    if playerData.charinfo then
        return playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname
    end
    return "Unknown"
end

function QBXBridge:HasItem(item, amount, cb)
    amount = amount or 1
    QBX.Functions.TriggerCallback('QBCore:HasItem', cb, item, amount)
end

function QBXBridge:GetFramework()
    return QBX
end

return QBXBridge