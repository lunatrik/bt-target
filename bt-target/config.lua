Config = {}

Config.ESX = false
Config.QBCore = true
Config.DropPlayer = false -- Drop player if they attempt to trigger an invalid event

-- Return an object in the format
-- {
--     name = job name
-- }

Config.NonEsxJob = function()
    local PlayerJob = {}

    return PlayerJob
end

Config.BoxZones = {
    ["PoliceDuty"] = {
        name = "PoliceDuty",
        coords = vector3(441.83, -982.06, 30.69),
        length = 0.5,
        width = 0.4,
        heading = 12,
        debugPoly = false,
        minZ = 30.79,
        maxZ = 31.04,
        options = {
            {
                event = "toggleduty",
                icon = "fas fa-clipboard",
                label = "Toggle Duty",
                job = {"police"},
            },
        },
        distance = 1.5
    }
}

Config.CircleZones = {
    ["PoliceDuty"] = {
        name = "PoliceDuty2",
        coords = vector3(441.83, -982.06, 30.69),
        radius = 1.4,
        debugPoly = false,
        options = {
            {
                event = "toggleduty",
                icon = "far fa-clipboard",
                label = "Sign On",
                job = {"police"},
            },
        },
        distance = 1.5
    }
}

Config.TargetModels = {
    ["atms"] = {
        objects = {
            `prop_atm_01`,
            `prop_atm_02`,
            `prop_atm_03`,
            `prop_fleeca_atm`
        },
        options = {
            {
                event = "dumpster:search",
                icon = "fas fa-credit-card",
                label = "Use atm",
                job = {"all"}
            },
        },
        distance = 2.5
    }
}

Config.TargetBones = {
    ["lock"] = {
        bones = {
            "door_dside_f",
            "door_dside_r",
            "door_pside_f",
            "door_pside_r"
        },
        options = {
            {
                event = "door",
                icon = "fas fa-door-open",
                label = "Toggle Door",
                job = {"all"},
            },
            {
                event = "unlock",
                icon = "fas fa-door-open",
                label = "Unlock Door",
                job = {"all"},
            },
        },
        distance = 1.5
    }
}
