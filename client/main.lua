local Bridge = require('bridge/loader')
local Framework = Bridge.Load()
local activeJob = nil
local jobNPC = nil
local customerNPC = nil
local jobBlips = {}
local menuOpen = false
local timeLeft = 0
local timerActive = false
local computerProp = nil

CreateThread(function()
    local npcData = Config.JobNPC
    RequestModel(npcData.model)
    while not HasModelLoaded(npcData.model) do
        Wait(100)
    end
    jobNPC = CreatePed(4, npcData.model, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w, false, true)
    SetEntityHeading(jobNPC, npcData.coords.w)
    FreezeEntityPosition(jobNPC, true)
    SetEntityInvincible(jobNPC, true)
    SetBlockingOfNonTemporaryEvents(jobNPC, true)
    if npcData.blipEnabled then
        local blip = AddBlipForCoord(npcData.coords.x, npcData.coords.y, npcData.coords.z)
        SetBlipSprite(blip, npcData.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, npcData.blip.scale)
        SetBlipColour(blip, npcData.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(_L('npc_blip'))
        EndTextCommandSetBlipName(blip)
    end
    Framework.Target.AddLocalEntity(jobNPC, {
        {
            name = 'it_service_menu',
            label = _L('view_jobs'),
            icon = 'fas fa-laptop',
            distance = 2.5,
            canInteract = function()
                return not menuOpen and not activeJob
            end,
            onSelect = function()
                openJobMenu()
            end
        }
    })
    Framework.Debug('IT Service script initialized', 'info')
end)

CreateThread(function()
    while true do
        if timerActive and timeLeft > 0 then
            timeLeft = timeLeft - 1
            if timeLeft <= 0 then
                timerActive = false
                if activeJob then
                    local jobId = activeJob.id
                    Framework.Notify(nil, _L('job_failed'), _L('job_failed'), 'error')
                    lib.callback('anox-itservice:jobFailed', false, function() end, jobId)
                    cleanupJob()
                end
            end
        end
        Wait(1000)
    end
end)

function openJobMenu()
    if menuOpen then
        Framework.Notify(nil, _L('error'), _L('menu_in_use'), 'error')
        return
    end
    menuOpen = true
    lib.callback('anox-itservice:getAvailableJobs', false, function(jobs)
        if not jobs then
            menuOpen = false
            return
        end
        if #jobs == 0 then
            Framework.Notify(nil, _L('error'), _L('no_jobs_available'), 'error')
            menuOpen = false
            return
        end
        local options = {}
        for _, job in ipairs(jobs) do
            local disabled = job.taken or job.expired
            local description = job.customerMsg
            if job.expired then
                description = description .. ' ' .. _L('expired')
            elseif job.taken then
                description = description .. ' ' .. _L('taken')
            end
            table.insert(options, {
                title = job.jobName .. ' - $' .. job.reward,
                description = description,
                disabled = disabled,
                icon = disabled and 'ban' or 'laptop',
                iconColor = disabled and '#C53030' or '#6CFF7F',
                metadata = {
                    {label = _L('customer'), value = job.customerName},
                    {label = _L('reward'), value = '$' .. job.reward}
                },
                onSelect = function()
                    selectJob(job)
                end
            })
        end
        Framework.RegisterContext({
            id = 'it_service_jobs',
            title = _L('it_service_jobs'),
            options = options,
            onExit = function()
                menuOpen = false
                lib.callback('anox-itservice:releaseMenu', false, function() end)
            end
        })
        Framework.ShowContext('it_service_jobs')
    end)
end

function selectJob(job)
    local alert = Framework.AlertDialog({
        header = job.jobName,
        content = job.details,
        centered = true,
        cancel = true,
        labels = {
            confirm = _L('accept_job'),
            cancel = _L('go_back')
        }
    })
    if alert == 'confirm' then
        lib.callback('anox-itservice:takeJob', false, function(success, jobData)
            if success then
                startJob(jobData)
            else
                menuOpen = false
                lib.callback('anox-itservice:releaseMenu', false, function() end)
            end
        end, job.id)
    else
        menuOpen = false
        lib.callback('anox-itservice:releaseMenu', false, function() end)
    end
end

function startJob(job)
    activeJob = job
    menuOpen = false
    Framework.Notify(nil, _L('job_accepted'), _L('job_taken'), 'success')
    timeLeft = job.playerTimeLimit
    timerActive = true

    -- Start job timer + TextUI thread (runs only when job is active)
    CreateThread(function()
        local lastTime = -1
        while timerActive and activeJob and timeLeft > 0 do
            if timeLeft ~= lastTime then
                lastTime = timeLeft
                local timeFormatted = string.format('%02d:%02d', math.floor(timeLeft / 60), timeLeft % 60)
                Framework.ShowTextUI(_L('time_left', timeFormatted), {
                    style = 'timer',
                    icon = 'clock',
                    iconAnimation = 'pulse'
                })
            end
            Wait(1000)
            timeLeft -= 1
        end

        -- Hide TextUI after timer ends or job is canceled
        Framework.HideTextUI()

        if timeLeft <= 0 and activeJob then
            Framework.Notify(nil, _L('job_failed'), _L('job_failed'), 'error')
            lib.callback('anox-itservice:jobFailed', false, function() end, activeJob.id)
            cleanupJob()
        end
    end)

    -- Blip and target logic (unchanged)
    if job.type == 'prank' then
        createJobBlip(job.location, _L('customer_location'))
        createDoorTarget(job.location, job)
    elseif job.type == 'scam' then
        local blipLabel = job.digitalDenName .. ' - ' .. _L('buy_part', _L(job.issue), job.partPrice)
        createJobBlip(job.digitalDen.coords, blipLabel)
        createDigitalDenTarget(job)
    else
        if job.customerKnows and job.issueType == 'hardware' then
            local blipLabel = job.digitalDenName .. ' - ' .. _L('buy_part', _L(job.issue), job.partPrice)
            createJobBlip(job.digitalDen.coords, blipLabel)
            createDigitalDenTarget(job)
        else
            createJobBlip(job.location.door, _L('customer_location'))
            createDoorTarget(job.location.door, job)
        end
    end

    Framework.Debug('Started job: ' .. job.id .. ' (' .. job.jobName .. ') Type: ' .. job.type, 'info')
end

function createJobBlip(coords, label)
    removeJobBlips()
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 3)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    table.insert(jobBlips, blip)
end

function createDigitalDenTarget(job)
    Framework.Target.AddSphereZone({
        coords = job.digitalDen.coords,
        radius = 2.5,
        debug = Config.Debug,
        name = 'digital_den_' .. job.id,
        options = {
            {
                label = _L('buy_part', _L(job.issue), job.partPrice),
                icon = 'fas fa-shopping-cart',
                distance = 2.5,
                onSelect = function()
                    buyPart(job)
                end
            }
        }
    })
end

function buyPart(job)
    Framework.Target.RemoveZone('digital_den_' .. job.id)
    local partItem = nil
    for _, hw in ipairs(Config.ComputerParts.hardware) do
        if hw.issue == job.issue then
            partItem = hw.item
            break
        end
    end
    local success = Framework.ProgressCircle({
        duration = Config.Animations.purchase.duration,
        label = _L('purchasing_part', _L(job.issue), job.digitalDenName),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = Config.Animations.purchase.dict,
            clip = Config.Animations.purchase.anim,
            flag = Config.Animations.purchase.flag
        },
        prop = {
            model = Config.Animations.purchase.prop,
            bone = Config.Animations.purchase.bone,
            pos = Config.Animations.purchase.pos,
            rot = Config.Animations.purchase.rot
        }
    })
    if success then
        lib.callback('anox-itservice:buyPart', false, function(purchased)
            if purchased then
                Framework.Notify(nil, _L('purchase_complete'), _L('item_purchased', _L(activeJob.issue), activeJob.partPrice), 'success')
                activeJob.hasPart = true
                if activeJob.type == 'scam' then
                    createJobBlip(activeJob.location.door, _L('customer_location'))
                    createScamTarget(activeJob.location.door, activeJob)
                else
                    createJobBlip(activeJob.location.door, _L('customer_location'))
                    createDoorTarget(activeJob.location.door, activeJob)
                end
            else
                Framework.Notify(nil, _L('insufficient_funds'), _L('not_enough_money'), 'error')
                Wait(500)
                createDigitalDenTarget(activeJob)
            end
        end, job.id, job.partPrice)
    end
end

function createDoorTarget(coords, job)
    local targetCoords = coords
    if job.type == 'prank' then
        targetCoords = coords
    else
        targetCoords = coords
    end
    Framework.Target.AddSphereZone({
        coords = targetCoords,
        radius = 2.5,
        debug = Config.Debug,
        name = 'customer_door_' .. job.id,
        options = {
            {
                label = _L('knock_door'),
                icon = 'fas fa-door-open',
                distance = 2.5,
                onSelect = function()
                    knockOnDoor(job)
                end
            }
        }
    })
end

function createScamTarget(coords, job)
    Framework.Target.AddSphereZone({
        coords = coords,
        radius = 2.5,
        debug = Config.Debug,
        name = 'scam_door_' .. job.id,
        options = {
            {
                label = _L('deliver_part', _L(job.issue)),
                icon = 'fas fa-box',
                distance = 2.5,
                onSelect = function()
                    triggerScam(job)
                end
            }
        }
    })
end

function knockOnDoor(job)
    Framework.Target.RemoveZone('customer_door_' .. job.id)
    local success = Framework.ProgressBar({
        duration = Config.Animations.knock.duration,
        label = _L('knocking_door'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = Config.Animations.knock.dict,
            clip = Config.Animations.knock.anim
        }
    })
    if success then
        if job.type == 'prank' then
            Framework.Notify(nil, _L('job_pranked'), _L('pranked'), 'error')
            cleanupJob()
            lib.callback('anox-itservice:jobComplete', false, function() end, job.id, 0)
        else
            enterCustomerHouse(job)
        end
    end
end

function enterCustomerHouse(job)
    DoScreenFadeOut(500)
    Wait(500)
    if customerNPC and DoesEntityExist(customerNPC) then
        DeleteEntity(customerNPC)
        customerNPC = nil
    end
    SetEntityCoords(PlayerPedId(), job.location.computer.x, job.location.computer.y, job.location.computer.z)
    local npcModel = Config.NPCModels[math.random(#Config.NPCModels)]
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end
    customerNPC = CreatePed(4, npcModel, job.location.npc.x, job.location.npc.y, job.location.npc.z - 1.0, job.location.npc.w, false, true)
    SetEntityHeading(customerNPC, job.location.npc.w)
    FreezeEntityPosition(customerNPC, true)
    SetEntityInvincible(customerNPC, true)
    SetBlockingOfNonTemporaryEvents(customerNPC, true)
    PlaceObjectOnGroundProperly(customerNPC)
    DoScreenFadeIn(500)
    startWorriedNPCBehavior()
    createComputerTarget(job)
end

function startWorriedNPCBehavior()
    CreateThread(function()
        while customerNPC and DoesEntityExist(customerNPC) and activeJob do
            local worriedAnims = {
                {dict = "amb@world_human_bum_standing@depressed@base", anim = "base"},
                {dict = "amb@world_human_stand_impatient@male@no_hat@base", anim = "base"},
                {dict = "anim@amb@casino@hangout@ped_male@stand@02b@base", anim = "base"},
                {dict = "amb@world_human_hang_out_street@male_c@base", anim = "base"}
            }
            local selectedAnim = worriedAnims[math.random(#worriedAnims)]
            RequestAnimDict(selectedAnim.dict)
            while not HasAnimDictLoaded(selectedAnim.dict) do
                Wait(100)
            end
            ClearPedTasks(customerNPC)
            FreezeEntityPosition(customerNPC, false)
            SetEntityCollision(customerNPC, true, true)
            PlaceObjectOnGroundProperly(customerNPC)
            FreezeEntityPosition(customerNPC, true)
            TaskPlayAnim(customerNPC, selectedAnim.dict, selectedAnim.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
            local randomAction = math.random(1, 4)
            if randomAction == 1 then
                Wait(3000)
                ClearPedTasks(customerNPC)
                RequestAnimDict("gestures@m@standing@casual")
                while not HasAnimDictLoaded("gestures@m@standing@casual") do
                    Wait(100)
                end
                TaskPlayAnim(customerNPC, "gestures@m@standing@casual", "gesture_hand_down", 8.0, -8.0, 2000, 0, 0, false, false, false)
                Wait(2000)
            elseif randomAction == 2 then
                Wait(5000)
            elseif randomAction == 3 then
                Wait(2000)
                ClearPedTasks(customerNPC)
                RequestAnimDict("mp_player_int_upperscratch_head")
                while not HasAnimDictLoaded("mp_player_int_upperscratch_head") do
                    Wait(100)
                end
                TaskPlayAnim(customerNPC, "mp_player_int_upperscratch_head", "mp_player_int_scratch_head", 8.0, -8.0, 3000, 0, 0, false, false, false)
                Wait(3000)
            else
                Wait(4000)
            end
            Wait(math.random(5000, 10000))
        end
    end)
end

function createComputerTarget(job)
    Framework.Target.AddSphereZone({
        coords = job.location.computer,
        radius = 2.5,
        debug = Config.Debug,
        name = 'computer_' .. job.id,
        options = {
            {
                label = _L('diagnose_computer'),
                icon = 'fas fa-search',
                distance = 2.5,
                canInteract = function()
                    return not job.diagnosed and not job.customerKnows
                end,
                onSelect = function()
                    diagnoseComputer(job)
                end
            },
            {
                label = _L('fix_computer'),
                icon = 'fas fa-wrench',
                distance = 2.5,
                canInteract = function()
                    return (job.diagnosed or job.customerKnows) and (job.issueType == 'software' or activeJob.hasPart)
                end,
                onSelect = function()
                    fixComputer(job)
                end
            }
        }
    })
end

function diagnoseComputer(job)
    local success = Framework.ProgressBar({
        duration = Config.Animations.diagnose.duration,
        label = _L('diagnosing'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = Config.Animations.diagnose.dict,
            clip = Config.Animations.diagnose.anim
        }
    })
    if success then
        local skillSuccess = Framework.SkillCheck(Config.SkillCheck.diagnose.difficulty, Config.SkillCheck.diagnose.inputs)
        if skillSuccess then
            activeJob.diagnosed = true
            Framework.Notify(nil, _L('diagnosis_complete'), _L('issue_found', _L(job.issue)), 'info')
            if job.issueType == 'hardware' and not activeJob.hasPart then
                Framework.Notify(nil, _L('hardware_required'), _L('need_to_buy', _L(job.issue), job.digitalDenName), 'warning')
                Framework.Target.RemoveZone('computer_' .. job.id)
                exitCustomerHouse(true)
                local blipLabel = job.digitalDenName .. ' - ' .. _L('buy_part', _L(job.issue), job.partPrice)
                createJobBlip(job.digitalDen.coords, blipLabel)
                createDigitalDenTarget(job)
            end
        else
            Framework.Notify(nil, _L('diagnosis_failed'), _L('failed_diagnose'), 'error')
        end
    end
end

function fixComputer(job)
    local success = Framework.ProgressBar({
        duration = job.fixTime or Config.Animations.fix.duration,
        label = _L('fixing'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = Config.Animations.fix.dict,
            clip = Config.Animations.fix.anim
        }
    })
    if success then
        local skillSuccess = Framework.SkillCheck(Config.SkillCheck.fix.difficulty, Config.SkillCheck.fix.inputs)
        if skillSuccess then
            Framework.Notify(nil, _L('fix_complete'), _L('computer_fixed'), 'success')
            Framework.Target.RemoveZone('computer_' .. job.id)
            createPaymentTarget(job)
        else
            Framework.Notify(nil, _L('fix_failed'), _L('failed_fix'), 'error')
        end
    end
end

function createPaymentTarget(job)
    Framework.Target.AddLocalEntity(customerNPC, {
        {
            name = 'get_payment_' .. job.id,
            label = _L('get_payment'),
            icon = 'fas fa-dollar-sign',
            distance = 2.5,
            onSelect = function()
                getPayment(job)
            end
        }
    })
end

function getPayment(job)
    Framework.Target.RemoveLocalEntity(customerNPC, 'get_payment_' .. job.id)
    ClearPedTasks(customerNPC)
    RequestAnimDict("friends@frj@ig_1")
    while not HasAnimDictLoaded("friends@frj@ig_1") do
        Wait(100)
    end
    TaskPlayAnim(customerNPC, "friends@frj@ig_1", "wave_a", 8.0, -8.0, 3000, 0, 0, false, false, false)
    Wait(1000)
    lib.callback('anox-itservice:jobComplete', false, function(result)
        if result.success then
            Framework.Notify(nil, _L('job_completed'), _L('job_complete', result.reward), 'success')
            if result.refund and result.refund > 0 then
                Wait(1000)
                Framework.Notify(nil, _L('part_refunded'), _L('part_refund_msg', result.refund), 'success')
            end
        end
        exitCustomerHouse(false)
    end, job.id, job.reward)
end

function exitCustomerHouse(comingBack)
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(PlayerPedId(), activeJob.location.door.x, activeJob.location.door.y, activeJob.location.door.z)
    if customerNPC and DoesEntityExist(customerNPC) then
        DeleteEntity(customerNPC)
        customerNPC = nil
    end
    DoScreenFadeIn(500)
    if not comingBack then
        cleanupJob()
    end
end

function triggerScam(job)
    Framework.Target.RemoveZone('scam_door_' .. job.id)
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(PlayerPedId(), job.location.robbery.x, job.location.robbery.y, job.location.robbery.z)
    local robbers = {}
    for i = 1, job.robberCount do
        RequestModel(Config.JobSettings.robberModel)
        while not HasModelLoaded(Config.JobSettings.robberModel) do
            Wait(100)
        end
        local offsetX = math.random(-2, 2)
        local offsetY = math.random(-2, 2)
        local robber = CreatePed(4, Config.JobSettings.robberModel, 
            job.location.robbery.x + offsetX, 
            job.location.robbery.y + offsetY, 
            job.location.robbery.z - 1.0, 
            0.0, false, true)
        PlaceObjectOnGroundProperly(robber)
        GiveWeaponToPed(robber, GetHashKey('WEAPON_PISTOL'), 100, false, true)
        TaskAimGunAtEntity(robber, PlayerPedId(), -1, true)
        table.insert(robbers, robber)
    end
    DoScreenFadeIn(500)
    RequestAnimDict("random@arrests@busted")
    while not HasAnimDictLoaded("random@arrests@busted") do
        Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), "random@arrests@busted", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
    Framework.Notify(nil, _L('job_robbed'), _L('robbed'), 'error')
    Wait(3000)
    ClearPedTasks(PlayerPedId())
    lib.callback('anox-itservice:gotRobbed', false, function(result)
        if result.moneyStolen and result.moneyStolen > 0 then
            Wait(500)
            Framework.Notify(nil, _L('money_stolen'), _L('money_stolen_amount', result.moneyStolen), 'error')
        end
        SetTimeout(2000, function()
            for _, robber in ipairs(robbers) do
                if DoesEntityExist(robber) then
                    DeleteEntity(robber)
                end
            end
            cleanupJob()
        end)
    end, job.id)
end

lib.callback.register('anox-itservice:jobExpiredTimeout', function()
    Framework.Notify(nil, _L('job_failed'), _L('job_expired_timeout'), 'error')
    cleanupJob()
    return true
end)

function cleanupJob()
    removeJobBlips()
    if activeJob then
        Framework.Target.RemoveZone('digital_den_' .. activeJob.id)
        Framework.Target.RemoveZone('customer_door_' .. activeJob.id)
        Framework.Target.RemoveZone('scam_door_' .. activeJob.id)
        Framework.Target.RemoveZone('computer_' .. activeJob.id)
        if customerNPC then
            Framework.Target.RemoveLocalEntity(customerNPC, 'get_payment_' .. activeJob.id)
        end
    end
    if customerNPC and DoesEntityExist(customerNPC) then
        DeleteEntity(customerNPC)
        customerNPC = nil
    end
    if computerProp and DoesEntityExist(computerProp) then
        DeleteEntity(computerProp)
        computerProp = nil
    end
    activeJob = nil
    timerActive = false
    timeLeft = 0
    Framework.HideTextUI()
    Framework.Debug('Job cleaned up', 'info')
end

function removeJobBlips()
    for _, blip in ipairs(jobBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    jobBlips = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    cleanupJob()
    if DoesEntityExist(jobNPC) then
        Framework.Target.RemoveLocalEntity(jobNPC, 'it_service_menu')
        DeleteEntity(jobNPC)
    end
    if DoesEntityExist(customerNPC) then
        DeleteEntity(customerNPC)
    end
    if DoesEntityExist(computerProp) then
        DeleteEntity(computerProp)
    end
end)
