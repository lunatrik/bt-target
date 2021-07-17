local Models = {}
local Zones = {}
local Bones = {}

-- Whitelist events
local Events = {}

local isMouse = false

Citizen.CreateThread(function()
    RegisterKeyMapping("+playerTarget", "Player Targeting", "keyboard", "LMENU") --Removed Bind System and added standalone version
    RegisterCommand('+playerTarget', playerTargetEnable, false)
    RegisterCommand('-playerTarget', playerTargetDisable, false)
    TriggerEvent("chat:removeSuggestion", "/+playerTarget")
    TriggerEvent("chat:removeSuggestion", "/-playerTarget")
end)

if Config.ESX then
    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
			
        PlayerJob = ESX.GetPlayerData().job

        RegisterNetEvent('esx:playerLoaded')
        AddEventHandler('esx:playerLoaded', function()
            PlayerJob = ESX.GetPlayerData().job
        end)
                
        RegisterNetEvent('esx:setJob')
        AddEventHandler('esx:setJob', function(job)
            PlayerJob = job
        end)
    end)
elseif Config.QBCore then
    Citizen.CreateThread(function()
        while QBCore == nil do
            TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
            Citizen.Wait(200)
        end
                
        PlayerJob = QBCore.Functions.GetPlayerData().job
        
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
        AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
            PlayerJob = QBCore.Functions.GetPlayerData().job
        end)			

        RegisterNetEvent('QBCore:Client:OnJobUpdate')
        AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
            PlayerJob = JobInfo
        end)
    end)
else
    PlayerJob = Config.NonFrameworkJob()
end

Citizen.CreateThread(function()
    if next(Config.BoxZones) then
        for k, v in pairs(Config.BoxZones) do
            AddBoxZone(v.name, v.coords, v.length, v.width, {
                name = v.name,
                heading = v.heading,
                debugPoly = v.debugPoly,
                minZ = v.minZ,
                maxZ = v.maxZ
            }, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.CircleZones) then
        for k, v in pairs(Config.CircleZones) do
            AddCircleZone(v.name, v.coords, v.radius, {
                name = v.name,
                debugPoly = v.debugPoly,
            }, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetModels) then
        for k, v in pairs(Config.TargetModels) do
            AddTargetModel(v.objects, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if next(Config.TargetBones) then
        for k, v in pairs(Config.TargetBones) do
            AddTargetBone(v.bones, {
                options = v.options,
                distance = v.distance
            })
        end
    end
end)

function playerTargetEnable()
    if success then return end
    if IsPedArmed(PlayerPedId(), 6) then return end

    targetActive = true

    SendNUIMessage({response = "openTarget"})
	
    DisableControls()
    
    while targetActive do
	local nearestVehicle = GetNearestVehicle()
        local plyCoords = GetEntityCoords(PlayerPedId())
        local hit, coords, entity = RayCastGamePlayCamera(20.0)
        local hit2, coords2, entity2 = RayCastGamePlayCamera2(20.0)

        if hit == 1 then
            if nearestVehicle then
                for _, bone in pairs(Bones) do
                    local boneIndex = GetEntityBoneIndexByName(nearestVehicle, _)
                    local bonePos = GetWorldPositionOfEntityBone(nearestVehicle, boneIndex)
                    local distanceToBone = GetDistanceBetweenCoords(bonePos, plyCoords, 1)

                    if #(bonePos - coords) <= Bones[_]["distance"] then
                        if #(plyCoords - coords) <= Bones[_]["distance"] then
                            NewOptions = {}

                            for _, option in pairs(Bones[_]["options"]) do
                                if option.shouldShow == nil or option.shouldShow() then
                                    for _, job in pairs(option.job) do
                                        if job == "all" or job == PlayerJob.name then
                                            table.insert(NewOptions, option)
                                        end
                                    end
                                end
                            end

                            if NewOptions[1] ~= nil then
                                success = true
                                SendNUIMessage({response = "foundTarget"})
                            end

                            while success and targetActive do
                                local plyCoords = GetEntityCoords(PlayerPedId())
                                local hit, coords, entity = RayCastGamePlayCamera(7.0)
                                local boneI = GetEntityBoneIndexByName(nearestVehicle, _)

                                DisablePlayerFiring(PlayerId(), true)

                                if (IsControlJustReleased(0, 25) or IsDisabledControlJustReleased(0, 25)) then
                                    SetNuiFocus(true, true)
                                    SetCursorLocation(0.5, 0.5)
                                    isMouse = true
                                    SendNUIMessage({response = "validTarget", data = NewOptions})
                                elseif IsControlJustReleased(0, 19) and not isMouse then
                                    SendNUIMessage({response = "closeTarget"})
                                    SetNuiFocus(false, false)
                                    success = false
                                    isMouse = false
                                    targetActive = false
                                end

                                if #(plyCoords - coords) > Bones[_]["distance"] then
                                    SendNUIMessage({response = "leftTarget"})
                                    SetNuiFocus(false, false)
                                    success = false
                                    isMouse = false
                                end

                                Citizen.Wait(1)
                            end
                            SendNUIMessage({response = "leftTarget"})
                            SetNuiFocus(false, false)
                            success = false
                            isMouse = false
                        end
                    end
                end
            end

            for _, zone in pairs(Zones) do
                if Zones[_]:isPointInside(coords) then
                    if #(plyCoords - Zones[_].center) <= zone["targetoptions"]["distance"] then
                        NewOptions = {}
    
                        for _, option in pairs(Zones[_]["targetoptions"]["options"]) do
                            if option.shouldShow == nil or option.shouldShow() then
                                for _, job in pairs(option.job) do
                                    if job == "all" or job == PlayerJob.name then
                                        table.insert(NewOptions, option)
                                    end
                                end
                            end
                        end
    
                        if NewOptions[1] ~= nil then
                            success = true
                            SendNUIMessage({response = "foundTarget"})
                        end
                        while success and targetActive do
                            local plyCoords = GetEntityCoords(PlayerPedId())
                            local hit, coords, entity = RayCastGamePlayCamera(20.0)
    
                            DisablePlayerFiring(PlayerId(), true)
    
                            if (IsControlJustReleased(0, 25) or IsDisabledControlJustReleased(0, 25)) then
                                SetNuiFocus(true, true)
                                SetCursorLocation(0.5, 0.5)
                                isMouse = true
                                SendNUIMessage({response = "validTarget", data = NewOptions})
                            elseif IsControlJustReleased(0, 19) and not isMouse then
                                SendNUIMessage({response = "closeTarget"})
                                SetNuiFocus(false, false)
                                success = false
                                isMouse = false
                                targetActive = false
                            end
    
                            if not Zones[_]:isPointInside(coords) or #(plyCoords - Zones[_].center) > zone.targetoptions.distance then
                                SendNUIMessage({response = "leftTarget"})
                                SetNuiFocus(false, false)
                                success = false
                                isMouse = false
                            end
    
    
                            Citizen.Wait(1)
                        end
                        SendNUIMessage({response = "leftTarget"})
                        SetNuiFocus(false, false)
                        success = false
                        isMouse = false
                    end
                end
            end
        end

        if hit2 == 1 then
            if GetEntityType(entity2) ~= 0 then
                for _, model in pairs(Models) do
                    if _ == GetEntityModel(entity2) then
                       if _ == GetEntityModel(entity2) then
                            if #(plyCoords - coords2) <= Models[_]["distance"] then
                                NewOptions = {}

                                for _, option in pairs(Models[_]["options"]) do
                                    if option.shouldShow == nil or option.shouldShow() then
                                        for _, job in pairs(option.job) do
                                            if job == "all" or job == PlayerJob.name then
                                                table.insert(NewOptions, option)
                                            end
                                        end
                                    end
                                end

                                if NewOptions[1] ~= nil then
                                    success = true
                                    SendNUIMessage({response = "foundTarget"})
                                end

                                while success and targetActive do
                                    local plyCoords = GetEntityCoords(PlayerPedId())
                                    local hit, coords, entity = RayCastGamePlayCamera2(20.0)

                                    DisablePlayerFiring(PlayerId(), true)

                                    if (IsControlJustReleased(0, 25) or IsDisabledControlJustReleased(0, 25)) then
                                        SetNuiFocus(true, true)
                                        SetCursorLocation(0.5, 0.5)
                                        isMouse = true
                                        SendNUIMessage({response = "validTarget", data = NewOptions})
                                    elseif IsControlJustReleased(0, 19) and not isMouse then
                                        SendNUIMessage({response = "closeTarget"})
                                        SetNuiFocus(false, false)
                                        success = false
                                        isMouse = false
                                        targetActive = false
                                    end

                                    if GetEntityType(entity) == 0 or #(plyCoords - coords) > Models[_]["distance"] then
                                        SendNUIMessage({response = "leftTarget"})
                                        SetNuiFocus(false, false)
                                        success = false
                                        isMouse = false
                                    end

                                    Citizen.Wait(1)
                                end
                                SendNUIMessage({response = "leftTarget"})
                                SetNuiFocus(false, false)
                                success = false
                                isMouse = false
                            end
                        end
                    end 
                end
            end
			
            if nearestVehicle then
                for _, bone in pairs(Bones) do
                    local boneIndex = GetEntityBoneIndexByName(nearestVehicle, _)
                    local bonePos = GetWorldPositionOfEntityBone(nearestVehicle, boneIndex)
                    local distanceToBone = GetDistanceBetweenCoords(bonePos, plyCoords, 1)

                    if #(bonePos - coords2) <= Bones[_]["distance"] then
                        if #(plyCoords - coords2) <= Bones[_]["distance"] then
                            NewOptions = {}

                            for _, option in pairs(Bones[_]["options"]) do
                                if option.shouldShow == nil or option.shouldShow() then
                                    for _, job in pairs(option.job) do
                                        if job == "all" or job == PlayerJob.name then
                                            table.insert(NewOptions, option)
                                        end
                                    end
                                end
                            end

                            if NewOptions[1] ~= nil then
                                success = true
                                SendNUIMessage({response = "foundTarget"})
                            end

                            while success and targetActive do
                                local plyCoords = GetEntityCoords(PlayerPedId())
                                local hit, coords, entity = RayCastGamePlayCamera2(7.0)
                                local boneI = GetEntityBoneIndexByName(nearestVehicle, _)

                                DisablePlayerFiring(PlayerId(), true)

                                if (IsControlJustReleased(0, 25) or IsDisabledControlJustReleased(0, 25)) then
                                    SetNuiFocus(true, true)
                                    SetCursorLocation(0.5, 0.5)
                                    isMouse = true
                                    SendNUIMessage({response = "validTarget", data = NewOptions})
                                elseif IsControlJustReleased(0, 19) and not isMouse then
                                    SendNUIMessage({response = "closeTarget"})
                                    SetNuiFocus(false, false)
                                    success = false
                                    isMouse = false
                                    targetActive = false
                                end

                                if #(plyCoords - coords) > Bones[_]["distance"] then
                                    SendNUIMessage({response = "leftTarget"})
                                    SetNuiFocus(false, false)
                                    success = false
                                    isMouse = false
                                end

                                Citizen.Wait(1)
                            end
                            SendNUIMessage({response = "leftTarget"})
                            SetNuiFocus(false, false)
                            success = false
                            isMouse = false
                        end
                    end
                end
            end
        end
        Citizen.Wait(250)
    end
end

function playerTargetDisable()
    if success then return end

    SendNUIMessage({response = "closeTarget"})
    SetNuiFocus(false, false)
    success = false
    isMouse = false
    targetActive = false
end

--NUI CALL BACKS

RegisterNUICallback('selectTarget', function(data, cb)
    -- If the event isn't whitelisted or they're not using bt-target, return
    if Events[data.event] == nil or Events[data.event] == false then
        TriggerServerEvent("bt-target:loginvalidcall", data.event)
        return
    end
    if not targetActive then return end

    SetNuiFocus(false, false)

    success = false
    isMouse = false

    targetActive = false
		
    if data.type ~= nil then
    	if data.type == "client" then
	    TriggerEvent(data.event, data.parameters)
    	elseif data.type == "server" then
	    TriggerServerEvent(data.event, data.parameters)
    	elseif data.type == "function" then
	    _G[data.event](data.parameters)
    	end
    else
	TriggerEvent(data.event, data.parameters)
    end
end)

RegisterNUICallback('closeTarget', function(data, cb)
    SetNuiFocus(false, false)
    success = false
    isMouse = false
    targetActive = false
end)

RegisterNUICallback('leftTarget', function(data, cb)
    SetNuiFocus(false, false)
    success = false
    isMouse = false
end)

--Functions from https://forum.cfx.re/t/get-camera-coordinates/183555/14

function RotationToDirection(rotation)
    local adjustedRotation =
    {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction =
    {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 4))
    return b, c, e
end

function RayCastGamePlayCamera2(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, 30, PlayerPedId(), 4))
    return b, c, e
end

function GetNearestVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    if not (playerCoords and playerPed) then
        return
    end

    local pointB = GetEntityForwardVector(playerPed) * 0.001 + playerCoords

    local shapeTest = StartShapeTestCapsule(playerCoords.x, playerCoords.y, playerCoords.z, pointB.x, pointB.y, pointB.z, 1.0, 10, playerPed, 7)
    local _, hit, _, _, entity = GetShapeTestResult(shapeTest)

    return (hit == 1 and IsEntityAVehicle(entity)) and entity or false
end

--Exports

function AddCircleZone(name, center, radius, options, targetoptions)
    Zones[name] = CircleZone:Create(center, radius, options)
    Zones[name].targetoptions = targetoptions

    for _, option in pairs(targetoptions.options) do
        Events[option.event] = true
    end
end

function AddBoxZone(name, center, length, width, options, targetoptions)
    Zones[name] = BoxZone:Create(center, length, width, options)
    Zones[name].targetoptions = targetoptions

    for _, option in pairs(targetoptions.options) do
        Events[option.event] = true
    end
end

function AddPolyzone(name, points, options, targetoptions)
    Zones[name] = PolyZone:Create(points, options)
    Zones[name].targetoptions = targetoptions

    for _, option in pairs(targetoptions.options) do
        Events[option.event] = true
    end
end

function AddTargetModel(models, parameteres)
    for _, model in pairs(models) do
        Models[model] = parameteres
    end

    for _, option in pairs(parameteres.options) do
        Events[option.event] = true
    end
end

function AddTargetBone(bones, parameteres)
    for _, bone in pairs(bones) do
        Bones[bone] = parameteres
    end

    for _, option in pairs(parameteres.options) do
        Events[option.event] = true
    end
end

function RemoveZone(name)
    if not Zones[name] then return end
    if Zones[name].destroy then
        Zones[name]:destroy()
    end

    for _, option in pairs(Zones[name].targetoptions.options) do
        Events[option.event] = false
    end
    Zones[name] = nil
end

function DisableControls()
    Citizen.CreateThread(function()
        while targetActive do
            Citizen.Wait(0)			
            -- Credit to OfficiallyNoms for finding all the control actions to disable
            DisableControlAction(0, 24, true) -- disable attack
            DisableControlAction(0, 25, true) -- disable aim
            DisableControlAction(0, 47, true) -- disable weapon
            DisableControlAction(0, 58, true) -- disable weapon
            DisableControlAction(0, 263, true) -- disable melee
            DisableControlAction(0, 264, true) -- disable melee
            DisableControlAction(0, 257, true) -- disable melee
            DisableControlAction(0, 140, true) -- disable melee
            DisableControlAction(0, 141, true) -- disable melee
            DisableControlAction(0,142, true) -- disable melee
            DisableControlAction(0, 143, true) -- disable melee
        end
			
        EnableControlAction(0, 24, true) -- disable attack
        EnableControlAction(0, 25, true) -- disable aim
        EnableControlAction(0, 47, true) -- disable weapon
        EnableControlAction(0, 58, true) -- disable weapon
        EnableControlAction(0, 263, true) -- disable melee
        EnableControlAction(0, 264, true) -- disable melee
        EnableControlAction(0, 257, true) -- disable melee
        EnableControlAction(0, 140, true) -- disable melee
        EnableControlAction(0, 141, true) -- disable melee
        EnableControlAction(0,142, true) -- disable melee
        EnableControlAction(0, 143, true) -- disable melee
    end)
end

exports("AddCircleZone", AddCircleZone)

exports("AddBoxZone", AddBoxZone)

exports("AddPolyzone", AddPolyzone)

exports("AddTargetModel", AddTargetModel)

exports("AddTargetBone", AddTargetBone)

exports("RemoveZone", RemoveZone)
