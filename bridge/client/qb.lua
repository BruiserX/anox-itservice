local QBBridge = {}
QBBridge.__index = QBBridge
local QBCore = nil

function QBBridge:Init()
    QBCore = exports['qb-core']:GetCoreObject()
    if not QBCore then
        return false
    end
    return true
end

function QBBridge:GetPlayerData()
    return QBCore.Functions.GetPlayerData()
end

function QBBridge:HasJob(jobName)
    local playerData = self:GetPlayerData()
    return playerData.job and playerData.job.name == jobName
end

function QBBridge:GetJob()
    local playerData = self:GetPlayerData()
    return playerData.job
end

function QBBridge:GetPlayerIdentifier()
    local playerData = self:GetPlayerData()
    return playerData.citizenid
end

function QBBridge:GetPlayerLicense()
    local playerData = self:GetPlayerData()
    return playerData.license
end

function QBBridge:GetMoney(moneyType)
    local playerData = self:GetPlayerData()
    moneyType = moneyType or 'cash'
    return playerData.money and playerData.money[moneyType] or 0
end

function QBBridge:HasMoney(amount, moneyType)
    return self:GetMoney(moneyType) >= amount
end

function QBBridge:GetPlayerName()
    local playerData = self:GetPlayerData()
    if playerData.charinfo then
        return playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname
    end
    return "Unknown"
end

function QBBridge:HasItem(item, amount, cb)
    amount = amount or 1
    QBCore.Functions.TriggerCallback('QBCore:HasItem', cb, item, amount)
end

function QBBridge:GetFramework()
    return QBCore
end

return QBBridge