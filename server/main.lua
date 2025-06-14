local Bridge = require('bridge/loader')
local Framework = Bridge.Load()
local availableJobs = {}
local activeJobs = {}
local menuInUse = false
local menuUsedBy = nil
local usedJobNames = {}
local usedLocations = {}

local function getUniqueJobName()
    local availableNames = {}
    for _, name in ipairs(Config.JobNames) do
        if not usedJobNames[name] then
            table.insert(availableNames, name)
        end
    end
    if #availableNames == 0 then
        usedJobNames = {}
        availableNames = Config.JobNames
    end
    local selectedName = availableNames[math.random(#availableNames)]
    usedJobNames[selectedName] = true
    return selectedName
end

local function getDigitalDenName(den)
    if den.id == 'vinewood' then
        return _L('digital_den_vinewood')
    elseif den.id == 'rockford' then
        return _L('digital_den_rockford')
    else
        return 'Digital Den'
    end
end

local function getAvailableLocation(jobType)
    local locations, prefix
    if jobType == 'prank' then
        locations = Config.PrankLocations
        prefix = 'prank_'
    elseif jobType == 'scam' then
        locations = Config.ScamLocations
        prefix = 'scam_'
    else
        locations = Config.CustomerLocations
        prefix = 'customer_'
    end
    local available = {}
    for i, location in ipairs(locations) do
        local locationKey = prefix .. i
        if not usedLocations[locationKey] then
            table.insert(available, {location = location, key = locationKey})
        end
    end
    if #available > 0 then
        local selected = available[math.random(#available)]
        usedLocations[selected.key] = true
        return selected.location, selected.key
    end
    return nil, nil
end

local function releaseJobResources(job)
    if job then
        if job.jobName and usedJobNames[job.jobName] then
            usedJobNames[job.jobName] = nil
            Framework.Debug('Released job name: ' .. job.jobName, 'info')
        end
        if job.locationKey and usedLocations[job.locationKey] then
            usedLocations[job.locationKey] = nil
            Framework.Debug('Released location: ' .. job.locationKey, 'info')
        end
    end
end

local function generateJob()
    local jobType = 'normal'
    local rand = math.random(100)
    if rand <= Config.JobSettings.scamChance then
        jobType = 'scam'
    elseif rand <= (Config.JobSettings.scamChance + Config.JobSettings.prankChance) then
        jobType = 'prank'
    end
    local location, locationKey = getAvailableLocation(jobType)
    if not location then
        Framework.Debug('No available location for job type: ' .. jobType, 'info')
        return nil
    end
    local customerName = Config.CustomerNames[math.random(#Config.CustomerNames)]
    local jobName = getUniqueJobName()
    local digitalDen = Config.DigitalDens[math.random(#Config.DigitalDens)]
    local customerKnows = math.random(100) > 50
    local reward, issue, issueType, partPrice, fixTime = 0, nil, nil, 0, 10000
    if jobType == 'prank' then
        reward = math.random(Config.Rewards.prank.min, Config.Rewards.prank.max)
        issue = 'windows_installation'
        customerKnows = true
    elseif jobType == 'scam' then
        reward = math.random(Config.Rewards.scam.min, Config.Rewards.scam.max)
        local expensiveHardware = {'gpu', 'cpu', 'motherboard'}
        issue = expensiveHardware[math.random(#expensiveHardware)]
        issueType = 'hardware'
        customerKnows = true
        for _, hw in ipairs(Config.ComputerParts.hardware) do
            if hw.issue == issue then
                partPrice = math.random(hw.price.min, hw.price.max)
                break
            end
        end
    else
        issueType = math.random(100) > 50 and 'hardware' or 'software'
        if issueType == 'hardware' then
            local hw = Config.ComputerParts.hardware[math.random(#Config.ComputerParts.hardware)]
            issue = hw.issue
            partPrice = math.random(hw.price.min, hw.price.max)
            fixTime = hw.fixTime
            reward = math.random(Config.Rewards.hardware.min, Config.Rewards.hardware.max) + partPrice
        else
            local sw = Config.ComputerParts.software[math.random(#Config.ComputerParts.software)]
            issue = sw.issue
            fixTime = sw.fixTime
            reward = math.random(Config.Rewards.software.min, Config.Rewards.software.max)
        end
    end
    local details = ''
    if jobType == 'prank' then
        details = _L('prank_details', reward)
    elseif jobType == 'scam' then
        details = _L('scam_details', _L(issue), reward)
    else
        if customerKnows then
            details = _L('normal_details_known', _L(issue .. '_msg'), reward)
        else
            details = _L('normal_details_unknown', reward)
        end
    end
    return {
        id = 'job_' .. os.time() .. '_' .. math.random(1000, 9999),
        jobName = jobName,
        customerName = customerName,
        customerMsg = customerName .. ' - ' .. jobName,
        details = details,
        reward = reward,
        type = jobType,
        location = location,
        locationKey = locationKey,
        issue = issue,
        issueType = issueType,
        partPrice = partPrice,
        customerKnows = customerKnows,
        fixTime = fixTime,
        digitalDen = digitalDen,
        digitalDenName = getDigitalDenName(digitalDen),
        listingTimeLimit = Config.JobSettings.jobListingExpireTime / 1000,
        playerTimeLimit = Config.JobSettings.playerJobExpireTime / 1000,
        taken = false,
        expired = false,
        createdAt = os.time(),
        robberCount = jobType == 'scam' and location.robbers or 0,
        hasPart = false
    }
end

local function refreshJobListings()
    local currentTime = os.time()
    for i = #availableJobs, 1, -1 do
        local job = availableJobs[i]
        if not job.taken and (currentTime - job.createdAt) > (Config.JobSettings.jobListingExpireTime / 1000) then
            releaseJobResources(job)
            table.remove(availableJobs, i)
            Framework.Debug('Removed expired job: ' .. job.id, 'info')
        end
    end
    local attempts = 0
    while #availableJobs < Config.JobSettings.maxJobsAtOnce and attempts < Config.JobSettings.maxJobsAtOnce * 3 do
        attempts = attempts + 1
        local newJob = generateJob()
        if newJob then
            table.insert(availableJobs, newJob)
            Framework.Debug('Added job: ' .. newJob.id .. ' (' .. newJob.type .. ')', 'info')
        else
            break
        end
    end
end

CreateThread(function()
    Wait(1000)
    refreshJobListings()
    Framework.Debug('IT Service server initialized with ' .. #availableJobs .. ' jobs', 'success')
end)

CreateThread(function()
    while true do
        Wait(Config.JobSettings.jobRefreshTime)
        refreshJobListings()
        Framework.Debug('Jobs refreshed. Count: ' .. #availableJobs, 'info')
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        local currentTime = os.time()
        for playerId, job in pairs(activeJobs) do
            if job.takenAt and (currentTime - job.takenAt) > (Config.JobSettings.playerJobExpireTime / 1000) then
                Framework.Debug('Job expired for player: ' .. playerId, 'warning')
                for _, j in ipairs(availableJobs) do
                    if j.id == job.id then
                        j.taken = false
                        j.takenBy = nil
                        j.takenAt = nil
                        if job.locationKey then
                            usedLocations[job.locationKey] = nil
                        end
                        break
                    end
                end
                activeJobs[playerId] = nil
                lib.callback('anox-itservice:jobExpiredTimeout', playerId, function() end)
            end
        end
    end
end)

lib.callback.register('anox-itservice:getAvailableJobs', function(source)
    if menuInUse and menuUsedBy ~= source then 
        Framework.Notify(source, _L('error'), _L('menu_being_used_by_another_player'), 'error')
        return nil 
    end
    menuInUse = true
    menuUsedBy = source
    SetTimeout(Config.JobSettings.menuCooldown, function()
        menuInUse = false
        menuUsedBy = nil
    end)
    local jobsToSend = {}
    local currentTime = os.time()
    for _, job in ipairs(availableJobs) do
        local jobCopy = {}
        for k, v in pairs(job) do jobCopy[k] = v end
        jobCopy.expired = not jobCopy.taken and (currentTime - jobCopy.createdAt) > (Config.JobSettings.jobListingExpireTime / 1000)
        table.insert(jobsToSend, jobCopy)
    end
    return jobsToSend
end)

lib.callback.register('anox-itservice:releaseMenu', function(source)
    if menuInUse and menuUsedBy == source then
        menuInUse = false
        menuUsedBy = nil
        Framework.Debug('Menu released by player: ' .. source, 'info')
        return true
    end
    return false
end)

lib.callback.register('anox-itservice:takeJob', function(source, jobId)
    local xPlayer = Framework:GetPlayer(source)
    if not xPlayer then return false, nil end
    if activeJobs[source] then
        Framework.Notify(source, _L('error'), _L('already_have_job'), 'error')
        return false, nil
    end
    local job = nil
    for _, j in ipairs(availableJobs) do
        if j.id == jobId then
            job = j
            break
        end
    end
    if not job or job.taken then
        Framework.Notify(source, _L('error'), _L('job_unavailable'), 'error')
        return false, nil
    end
    job.taken = true
    job.takenBy = source
    job.takenAt = os.time()
    local playerJob = {}
    for k, v in pairs(job) do playerJob[k] = v end
    activeJobs[source] = playerJob
    Framework.Debug('Player ' .. source .. ' took job: ' .. jobId, 'success')
    return true, playerJob
end)

lib.callback.register('anox-itservice:buyPart', function(source, jobId, price)
    local xPlayer = Framework:GetPlayer(source)
    local job = activeJobs[source]
    if not xPlayer or not job or job.id ~= jobId then return false end
    if not Framework:HasMoney(source, price, 'cash') then return false end
    Framework:RemoveMoney(source, price, 'cash')
    activeJobs[source].hasPart = true
    Framework.Debug('Player ' .. source .. ' bought part for $' .. price, 'success')
    return true
end)

lib.callback.register('anox-itservice:jobComplete', function(source, jobId, payment)
    local xPlayer = Framework:GetPlayer(source)
    local job = activeJobs[source]
    if not xPlayer or not job or job.id ~= jobId then
        return {success = false}
    end
    local result = {success = true, reward = payment, refund = 0}
    if payment > 0 then
        Framework:AddMoney(source, payment, 'cash')
        if job.hasPart and job.partPrice and job.partPrice > 0 then
            Framework:AddMoney(source, job.partPrice, 'cash')
            result.refund = job.partPrice
        end
    end
    releaseJobResources(job)
    for i, j in ipairs(availableJobs) do
        if j.id == jobId then
            table.remove(availableJobs, i)
            break
        end
    end
    activeJobs[source] = nil
    Framework.Debug('Player ' .. source .. ' completed job: ' .. jobId .. ' ($' .. payment .. ')', 'success')
    return result
end)

lib.callback.register('anox-itservice:jobFailed', function(source, jobId)
    local job = activeJobs[source]
    if not job or job.id ~= jobId then return false end
    for _, j in ipairs(availableJobs) do
        if j.id == jobId then
            j.taken = false
            j.takenBy = nil
            j.takenAt = nil
            if job.locationKey then
                usedLocations[job.locationKey] = nil
            end
            break
        end
    end
    activeJobs[source] = nil
    Framework.Debug('Player ' .. source .. ' failed job: ' .. jobId, 'warning')
    return true
end)

lib.callback.register('anox-itservice:gotRobbed', function(source, jobId)
    local xPlayer = Framework:GetPlayer(source)
    local job = activeJobs[source]
    if not xPlayer or not job or job.id ~= jobId then
        return {success = false, moneyStolen = 0}
    end
    local result = {success = true, moneyStolen = 0}
    if Config.ScamSettings.takePlayerMoney then
        local playerMoney = Framework:GetMoney(source, 'cash')
        if playerMoney > 0 then
            Framework:RemoveMoney(source, playerMoney, 'cash')
            result.moneyStolen = playerMoney
            Framework.Debug('Player ' .. source .. ' lost $' .. playerMoney .. ' in robbery', 'warning')
        end
    end
    releaseJobResources(job)
    for i, j in ipairs(availableJobs) do
        if j.id == jobId then
            table.remove(availableJobs, i)
            break
        end
    end
    activeJobs[source] = nil
    Framework.Debug('Player ' .. source .. ' got robbed on job: ' .. jobId, 'warning')
    return result
end)

AddEventHandler('playerDropped', function()
    local src = source
    if menuInUse and menuUsedBy == src then
        menuInUse = false
        menuUsedBy = nil
        Framework.Debug('Menu released due to player disconnect: ' .. src, 'info')
    end
    if activeJobs[src] then
        local job = activeJobs[src]
        for _, j in ipairs(availableJobs) do
            if j.id == job.id then
                j.taken = false
                j.takenBy = nil
                j.takenAt = nil
                if job.locationKey then
                    usedLocations[job.locationKey] = nil
                end
                break
            end
        end
        activeJobs[src] = nil
        Framework.Debug('Cleaned up job for disconnected player: ' .. src, 'info')
    end
end)