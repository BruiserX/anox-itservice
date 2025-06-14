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

function QBXBridge:GetPlayer(playerId)
    return QBX.Functions.GetPlayer(playerId)
end

function QBXBridge:GetPlayerFromIdentifier(identifier)
    return QBX.Functions.GetPlayerByCitizenId(identifier)
end

function QBXBridge:AddMoney(playerId, amount, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    Player.Functions.AddMoney(moneyType, amount)
    return true
end

function QBXBridge:RemoveMoney(playerId, amount, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    Player.Functions.RemoveMoney(moneyType, amount)
    return true
end

function QBXBridge:GetMoney(playerId, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return 0 end
    moneyType = moneyType or 'cash'
    return Player.PlayerData.money[moneyType] or 0
end

function QBXBridge:HasMoney(playerId, amount, moneyType)
    return self:GetMoney(playerId, moneyType) >= amount
end

function QBXBridge:GetPlayerJob(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.job
end

function QBXBridge:GetPlayerIdentifier(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

function QBXBridge:GetPlayerName(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return "Unknown" end
    return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
end

function QBXBridge:GetPlayerLicense(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.license
end

function QBXBridge:AddItem(playerId, item, amount, info)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    amount = amount or 1
    info = info or {}
    return Player.Functions.AddItem(item, amount, false, info)
end

function QBXBridge:RemoveItem(playerId, item, amount)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    amount = amount or 1
    return Player.Functions.RemoveItem(item, amount)
end

function QBXBridge:HasItem(playerId, item, amount)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    amount = amount or 1
    local hasItem = Player.Functions.GetItemByName(item)
    return hasItem and hasItem.amount >= amount
end

function QBXBridge:GetItemCount(playerId, item)
    local Player = self:GetPlayer(playerId)
    if not Player then return 0 end
    local hasItem = Player.Functions.GetItemByName(item)
    return hasItem and hasItem.amount or 0
end

function QBXBridge:GetFramework()
    return QBX
end

return QBXBridge