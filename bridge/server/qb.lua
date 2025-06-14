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

function QBBridge:GetPlayer(playerId)
    return QBCore.Functions.GetPlayer(playerId)
end

function QBBridge:GetPlayerFromIdentifier(identifier)
    return QBCore.Functions.GetPlayerByCitizenId(identifier)
end

function QBBridge:AddMoney(playerId, amount, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    Player.Functions.AddMoney(moneyType, amount)
    return true
end

function QBBridge:RemoveMoney(playerId, amount, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    Player.Functions.RemoveMoney(moneyType, amount)
    return true
end

function QBBridge:GetMoney(playerId, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return 0 end
    moneyType = moneyType or 'cash'
    return Player.PlayerData.money[moneyType] or 0
end

function QBBridge:HasMoney(playerId, amount, moneyType)
    return self:GetMoney(playerId, moneyType) >= amount
end

function QBBridge:GetPlayerJob(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.job
end

function QBBridge:GetPlayerIdentifier(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

function QBBridge:GetPlayerName(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return "Unknown" end
    return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
end

function QBBridge:GetPlayerLicense(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.license
end

function QBBridge:AddItem(playerId, item, amount, info)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    amount = amount or 1
    info = info or {}
    return Player.Functions.AddItem(item, amount, false, info)
end

function QBBridge:RemoveItem(playerId, item, amount)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    amount = amount or 1
    return Player.Functions.RemoveItem(item, amount)
end

function QBBridge:HasItem(playerId, item, amount)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    amount = amount or 1
    local hasItem = Player.Functions.GetItemByName(item)
    return hasItem and hasItem.amount >= amount
end

function QBBridge:GetItemCount(playerId, item)
    local Player = self:GetPlayer(playerId)
    if not Player then return 0 end
    local hasItem = Player.Functions.GetItemByName(item)
    return hasItem and hasItem.amount or 0
end

function QBBridge:GetFramework()
    return QBCore
end

return QBBridge