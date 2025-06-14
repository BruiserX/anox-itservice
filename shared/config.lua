--[[------------------------>FOR ASSISTANCE,SCRIPTS AND MORE JOIN OUR DISCORD<-------------------------------------
 ________   ________    ________      ___    ___      ________   _________   ___  ___   ________   ___   ________     
|\   __  \ |\   ___  \ |\   __  \    |\  \  /  /|  ||  |\   ____\ |\___   ___\|\  \|\  \ |\   ___ \ |\  \ |\   __  \    
\ \  \|\  \\ \  \\ \  \\ \  \|\  \   \ \  \/  / /  ||  \ \  \___|_\|___ \  \_|\ \  \\\  \\ \  \_|\ \\ \  \\ \  \|\  \   
 \ \   __  \\ \  \\ \  \\ \  \\\  \   \ \    / /   ||   \ \_____  \    \ \  \  \ \  \\\  \\ \  \ \\ \\ \  \\ \  \\\  \  
  \ \  \ \  \\ \  \\ \  \\ \  \\\  \   /     \/    ||    \|____|\  \    \ \  \  \ \  \\\  \\ \  \_\\ \\ \  \\ \  \\\  \ 
   \ \__\ \__\\ \__\\ \__\\ \_______\ /  /\   \    ||      ____\_\  \    \ \__\  \ \_______\\ \_______\\ \__\\ \_______\
    \|__|\|__| \|__| \|__| \|_______|/__/ /\ __\   ||     |\_________\    \|__|   \|_______| \|_______| \|__| \|_______|
                                     |__|/ \|__|   ||     \|_________|                                                 
------------------------------------->(https://discord.gg/gbJ5SyBJBv)---------------------------------------------------]]
Config = {}
Config.Debug = false -- Enable debug logs
Config.Framework = 'auto' -- 'esx', 'qb', 'qbx','auto'
Config.Language = 'en' -- 'en'
Config.Target = 'ox' -- 'ox', 'qb'

Config.UISystem = {
    Notify = 'ox',           -- 'ox'
    TextUI = 'ox',           -- 'ox'
    ProgressBar = 'ox',      -- 'ox'
    AlertDialog = 'ox',      -- 'ox'
    SkillCheck = 'ox',       -- 'ox'
    ContextMenu = 'ox',      -- 'ox'
    InputDialog = 'ox',      -- 'ox'
}
Config.JobSettings = {
    maxJobsAtOnce = 5,              -- Maximum jobs shown in menu
    jobRefreshTime = 900000,        -- Time in ms to refresh job list (15 minutes)
    prankChance = 15,               -- % chance for prank job
    scamChance = 10,                -- % chance for scam job
    jobListingExpireTime = 600000,  -- Time before job expires from listing (10 minutes)
    playerJobExpireTime = 300000,  -- Time for player to complete active job (5 minutes)
    menuCooldown = 3000,            -- Cooldown between menu opens (3 seconds)
    robberModel = 'g_m_y_mexgang_01' -- Model for scam robbers
}
Config.Rewards = {
    software = {min = 100, max = 250},
    hardware = {min = 150, max = 350},
    prank = {min = 300, max = 500}, -- Higher to bait players
    scam = {min = 500, max = 800}   -- Even higher to bait players
}
Config.ScamSettings = {
    takePlayerMoney = true  -- Whether robbers take player's money during scam
}
Config.JobNPC = {
    coords = vector4(1275.53, -1710.45, 54.77, 117.78),
    model = 'a_m_y_business_01',
    blipEnabled = true,
    blip = {
        sprite = 521,
        color = 3,
        scale = 0.8
    }
}
Config.DigitalDens = {
    {
        coords = vector3(392.59, -831.85, 29.29),
        id = 'vinewood',
        blipEnabled = false,
        blip = {
            sprite = 606,
            color = 2,
            scale = 0.8
        }
    },
    {
        coords = vector3(-658.53, -854.70, 24.51),
        id = 'rockford',
        blipEnabled = false,
        blip = {
            sprite = 606,
            color = 2,
            scale = 0.8
        }
    }
}
Config.SkillCheck = {
    diagnose = {
        difficulty = {'easy', 'easy', 'medium'},
        inputs = {'w', 'a', 's', 'd'}
    },
    fix = {
        difficulty = {'easy', 'medium', 'medium'},
        inputs = {'w', 'a', 's', 'd'}
    }
}
Config.ComputerParts = {
    hardware = {
        {
            issue = 'gpu',
            price = {min = 700, max = 1000},
            item = 'graphics_card',
            fixTime = 15000
        },
        {
            issue = 'ram',
            price = {min = 40, max = 80},
            item = 'ram_stick',
            fixTime = 10000
        },
        {
            issue = 'cpu',
            price = {min = 400, max = 800},
            item = 'processor',
            fixTime = 20000
        },
        {
            issue = 'psu',
            price = {min = 100, max = 200},
            item = 'power_supply',
            fixTime = 12000
        },
        {
            issue = 'motherboard',
            price = {min = 300, max = 600},
            item = 'motherboard',
            fixTime = 25000
        },
        {
            issue = 'cooling',
            price = {min = 30, max = 60},
            item = 'thermal_paste',
            fixTime = 8000
        }
    },
    software = {
        {
            issue = 'windows',
            fixTime = 20000
        },
        {
            issue = 'virus',
            fixTime = 15000
        },
        {
            issue = 'bios',
            fixTime = 18000
        },
        {
            issue = 'drivers',
            fixTime = 12000
        },
        {
            issue = 'registry',
            fixTime = 10000
        },
        {
            issue = 'network',
            fixTime = 8000
        }
    }
}
Config.CustomerLocations = {
    {
        door = vector3(-816.96, 178.07, 72.23),
        computer = vector3(-806.59, 167.47, 76.74),
        npc = vector4(-806.86, 173.32, 76.74, 108.85)
    },
    {
        door = vector3(-1150.08, -1521.95, 10.63),
        computer = vector3(-1156.69, -1517.34, 10.63),
        npc = vector4(-1150.37, -1521.19, 10.63, 32.83)
    },
    {
        door = vector3(119.44, 563.99, 183.96),
        computer = vector3(114.13, 567.14, 176.70),
        npc = vector4(116.29, 565.00, 176.70, 16.04)
    },
    {
        door = vector3(718.04, -975.90, 24.91),
        computer =  vector3(706.53, -966.87, 30.41),
        npc = vector4(707.14, -962.83, 30.40, 182.06)
    },
    {
        door = vector3(-95.38, -806.59, 44.04),
        computer = vector3(-81.01, -802.21, 243.40),
        npc = vector4(-81.73, -803.83, 243.39, 331.20)
    }
}
Config.PrankLocations = {
    vector3(1209.14, -455.01, 66.86),
    vector3(6.02, 108.94, 79.02),
    vector3(-17.03, 6303.32, 31.50),
    vector3(-3251.26, 1027.27, 11.76) 
}
Config.ScamLocations = {
    {
        door = vector3(46.04, -1864.18, 23.28),
        robbery = vector3(44.28, -1865.73, 22.83),
        robbers = 3 -- Number of robbers
    },
    {
        door = vector3(1592.32, 3606.41, 35.43),
        robbery = vector3(1594.99, 3607.84, 35.39),
        robbers = 2
    },
    {
        door = vector3(-120.29, 6326.91, 31.58),
        robbery = vector3(-117.73, 6324.44, 31.49),
        robbers = 4
    }
}
Config.JobNames = {
    'TechFix Pro',
    'QuickBytes Repair',
    'Digital Doctor',
    'PC Medic Service',
    'CyberCare Solutions',
    'ByteWise Support',
    'TechRescue Team',
    'CompuCare Express',
    'DigitalAid Services',
    'TechSaver Support',
    'PC Guardian',
    'ByteHeal Technicians',
    'CyberFix Masters',
    'TechWizard Solutions',
    'DigitalCure Services'
}
Config.CustomerNames = {
    'James Wilson', 'Mary Johnson', 'John Smith', 'Patricia Brown', 'Robert Davis', 'Jennifer Miller', 'Michael Garcia', 'Linda Rodriguez',
    'William Martinez', 'Elizabeth Anderson', 'David Taylor', 'Barbara Thomas', 'Richard Jackson', 'Susan White', 'Joseph Harris', 'Jessica Martin',
    'Thomas Thompson', 'Sarah Lewis', 'Charles Walker', 'Karen Hall', 'Christopher Allen', 'Nancy Young', 'Daniel King', 'Lisa Wright',
    'Matthew Lopez', 'Betty Scott', 'Anthony Green', 'Helen Adams', 'Mark Baker', 'Sandra Gonzalez', 'Donald Nelson', 'Donna Carter',
    'Steven Mitchell', 'Carol Perez', 'Paul Roberts', 'Ruth Turner', 'Andrew Phillips', 'Sharon Campbell', 'Joshua Parker', 'Michelle Evans'
}
Config.Animations = {
    knock = {
        dict = 'timetable@jimmy@doorknock@',
        anim = 'knockdoor_idle',
        duration = 3000
    },
    diagnose = {
        dict = 'anim@heists@prison_heiststation@cop_reactions',
        anim = 'cop_b_idle',
        duration = 5000
    },
    fix = {
        dict = 'mini@repair',
        anim = 'fixing_a_ped',
        duration = 8000
    },
    pickup = {
        dict = 'pickup_object',
        anim = 'pickup_low',
        duration = 1500
    },
    purchase = {
        dict = 'mp_common',
        anim = 'givetake1_a',
        duration = 3000,
        flag = 49,
        prop = 'prop_cs_cardbox_01',
        bone = 57005,
        pos = {x = 0.33, y = 0.0, z = 0.0},
        rot = {x = 0.0, y = 0.0, z = 0.0}
    }
}
Config.NPCModels = {
    'a_m_y_business_02',
    'a_f_y_business_01',
    'a_m_m_business_01',
    'a_f_y_business_04',
    'a_m_y_smartcaspat_01',
    'a_f_y_scdressy_01',
    'a_m_m_soucent_03',
    'a_f_m_downtown_01',
    'a_m_y_epsilon_01',
    'a_f_y_hipster_01'
}