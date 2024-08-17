local open = false
local sent = false
local closing = false

local unpack = function (...)
    local a = {...}
    local t = {}

    for _, value in pairs(a) do
        t[#t+1] = value
    end
    return table.unpack(t)
end

local Event = function (data, custom_arg)
    if not data or not data.table then
        local t = data

        data = {}
        data.table = t
    end

    if not custom_arg then
        custom_arg = {}
    end

    if data.table['server_event'] and data.table['event'] then
        TriggerServerEvent(data.table['event'], unpack(table.unpack(custom_arg)))
    elseif data.table['event'] then
        TriggerEvent(data.table['event'], unpack(table.unpack(custom_arg)))
    end
end

RegisterNUICallback('zone_event', function (data)
    if sent then return end
    
    sent = true
    Event(data, (data.table['custom_arg'] or {}))
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    Wait(1000) -- Wait 1 sec

    sent = false
    TriggerEvent('renzu_popui:closeui')
end)

RegisterNuiCallback('close', function (data)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    local count = 0

    while open and not sent and count < 20 do
        if not closing then
            closing = true
        end
        count = count + 1
        Wait(100)
    end

    Wait(250)

    if open then
        open = false
    end

    SendNUIMessage({
        type = 'reset', 
        content = true
    })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

local pop
local waiting = false
local lastpop

RegisterNetEvent('renzu_popui:drawtextuiwithinput', function (table)
    local coords = GetEntityCoords(PlayerPedId())

    if waiting or open then return end

    pop = table.title

    while IsNuiFocused() do
        waiting = true
        Wait(100)
        open = false
    end
    waiting = false

    local tbl = {}

    tbl.type = 'drawtext'
    tbl.fa = table.fa or '<i class="fad fa-sign"></i>'
    tbl.event = table.event
    tbl.title = table.title
    tbl.server_event = table.server_event
    tbl.unpack_arg = table.unpack_arg or false
    tbl.invehicle_title = table.invehicle_title or false
    tbl.custom_arg = table.custom_arg
    tbl.key = table.key or 'E'

    Wait(200)
    open = true

    SendNUIMessage({
        type = 'inzone',
        table = tbl,
        invehicle = IsPedInAnyVehicle(PlayerPedId(), false)
    })
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    Wait(1000)

    CreateThread(function()
        while open do
            if not IsNuiFocused() and not closing then
                SetNuiFocus(true, false)
                SetNuiFocusKeepInput(true)
            end
            if #(GetEntityCoords(PlayerPedId()) - coords) > 5 then
                open = false
                SendNUIMessage({
                    type = "reset", 
                    content = true
                })
                SetNuiFocus(false, false)
                SetNuiFocusKeepInput(false)
                closing = true
                Wait(2000)
                break
            end
            Wait(100)
        end
        TriggerEvent('renzu_popui:closeui')
        open = false
        closing = false
    end)
    lastpop = table.title
end)

RegisterNetEvent('renzu_popui:showui', function(table)
    if not open then
        local coord = GetEntityCoords(PlayerPedId())
        Wait(1000)
        open = false
        if waiting then return end
        while IsNuiFocused() do 
            waiting = true 
            Wait(100) 
            open = false 
        end
        waiting = false
        Wait(1000)
        pop = table.title
        local t = {}
        t.type = 'normal'
        t.event = table.event
        t.title = table.title
        t.fa = table.fa or '<i class="fad fa-sign"></i>'
        t.server_event = table.server_event
        t.unpack_arg = table.unpack_arg or false
        t.invehicle_title = table.invehicle_title or false
        t.confirm = table.confirm or '[ENTER]'
        t.reject = table.reject or '[CLOSE]'
        t.custom_arg = table.custom_arg
        t.use_cursor = table.use_cursor or false

        SendNUIMessage({
            type = "inzone", 
            table = t, 
            invehicle = IsPedInAnyVehicle(PlayerPedId(), false)
        })
        SetNuiFocus(true, table.use_cursor)
        SetNuiFocusKeepInput(true)
        open = true
        CreateThread(function()
            while open do
                if not IsNuiFocused() and not closing then
                    SetNuiFocus(true, table.use_cursor)
                    SetNuiFocusKeepInput(true)
                end
                Wait(100)
            end
            open = false
            closing = false
        end)
        CreateThread(function()
            while open do
                if not IsNuiFocused() and not closing then
                    SetNuiFocus(true, false)
                    SetNuiFocusKeepInput(true)
                end
                if #(GetEntityCoords(PlayerPedId()) - coord) > 5 then
                    open = false
                    SendNUIMessage({
                        type = "reset", 
                        content = true
                    })
                    SetNuiFocus(false, false)
                    SetNuiFocusKeepInput(false)
                    closing = true
                    Wait(2000)
                    break
                end
                Wait(100)
            end
            TriggerEvent('renzu_popui:closeui')
            open = false
            closing = false
        end)
        lastpop = table.title
        while open and table.use_cursor and not closing do
            DisableControlAction(1, 1, true)
            DisableControlAction(1, 2, true)
            DisableControlAction(1, 69, true)
            DisableControlAction(1, 70, true)
            DisableControlAction(1, 91, true)
            DisableControlAction(1, 92, true)
            DisableControlAction(1, 24, true)
            DisableControlAction(1, 25, true)
            DisableControlAction(1, 14, true)
            DisableControlAction(1, 15, true)
            DisableControlAction(1, 16, true)
            DisableControlAction(1, 17, true)
            DisablePlayerFiring(PlayerId(), true)
            Wait(1)
        end
    end
    SetNuiFocus(false,false)
    SetNuiFocusKeepInput(false)
end)

RegisterNetEvent('renzu_popui:closeui', function(force)
    if open or force then
        open = false
        SendNUIMessage({
            type = "reset", 
            content = true
        })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)

RegisterCommand('popui_drwtxt', function ()
    local table = {
        key = 'E',
        event = 'script:myevent',
        title = 'Press [E] to buy COLA',
        invehicle_title = 'Buy COLA',
        server_event = false,
        unpack_arg = false,
        fa = '<i class="fad fa-gas-pump"></i>',
        custom_arg = {}, -- example: {1,2,3,4}
    }

    TriggerEvent('renzu_popui:drawtextuiwithinput', table)
end, false)

RegisterCommand('popui_close', function ()
    TriggerEvent('renzu_popui:closeui')
end, false)