MenuData = {}
MenuData.Opened = {}
MenuData.RegisteredTypes = {}

--==================================FUNCTIONS ==================================
MenuData.RegisteredTypes['default'] = {
    open  = function(namespace, name, data,setnui)
        data.setNui = setnui
        SendNUIMessage({
            ak_menubase_action = 'openMenu',
            ak_menubase_namespace = namespace,
            ak_menubase_name = name,
            ak_menubase_data = data
        })
		SetNuiFocus(setnui,false)
	end,
    close  = function(namespace, name)
        SendNUIMessage({
            ak_menubase_action = 'closeMenu',
            ak_menubase_namespace = namespace,
            ak_menubase_name = name,
            ak_menubase_data = data
        })
    end
}




function MenuData.Open(type, namespace, name, data, submit, cancel, change, close,setnui)
    local menu = {}

    menu.type      = type
    menu.namespace = namespace
    menu.name      = name
    menu.data      = data
    menu.submit    = submit
    menu.cancel    = cancel
    menu.change    = change
    menu.setnui    = setnui or false
    menu.close = function()
        MenuData.RegisteredTypes[type].close(namespace, name,false)
        for i=1, #MenuData.Opened, 1 do
            if MenuData.Opened[i] then
                if MenuData.Opened[i].type == type and MenuData.Opened[i].namespace == namespace and MenuData.Opened[i].name == name then
                    MenuData.Opened[i] = nil
                end
            end
        end
        if #MenuData.Opened == 0 then
            SetNuiFocus(false,false)
        end
        if close then
            close(name)
        end

    end

    menu.update = function(query, newData)

        for i=1, #menu.data.elements, 1 do
            local match = true

            for k,v in pairs(query) do
                if menu.data.elements[i][k] ~= v then
                    match = false
                end
            end

            if match then
                for k,v in pairs(newData) do
                    menu.data.elements[i][k] = v
                end
            end
        end

    end

    menu.refresh = function()
        MenuData.RegisteredTypes[type].open(namespace, name, menu.data,menu.setnui)
    end

    menu.setElement = function(i, key, val)
        menu.data.elements[i][key] = val
    end

    menu.setElements = function(newElements)
        menu.data.elements = newElements
    end

    menu.setTitle = function(val)
        menu.data.title = val
    end

    menu.removeElement = function(query)
        for i=1, #menu.data.elements, 1 do
            for k,v in pairs(query) do
                if menu.data.elements[i] then
                    if menu.data.elements[i][k] == v then
						menu.data.elements[i] = nil
                        break
                    end
                end

            end
        end
    end
	MenuData.Opened[#MenuData.Opened+1]= menu
    MenuData.RegisteredTypes[type].open(namespace, name, data,menu.setnui)
    PlaySoundFrontend("SELECT", "RDRO_Character_Creator_Sounds", true, 0)
    return menu
end

function MenuData.Close(type, namespace, name)
    for i=1, #MenuData.Opened, 1 do
        if MenuData.Opened[i] then
            if MenuData.Opened[i].type == type and MenuData.Opened[i].namespace == namespace and MenuData.Opened[i].name == name then
                MenuData.Opened[i].close()
                MenuData.Opened[i] = nil
            end
        end
    end
    if #MenuData.Opened == 0 then
        SetNuiFocus(false,false)
    end
end

function MenuData.CloseAll()
    for i=1, #MenuData.Opened, 1 do
        if MenuData.Opened[i] then
            MenuData.Opened[i].close()
            MenuData.Opened[i] = nil
        end
    end
    SetNuiFocus(false,false)
end

function MenuData.GetOpened (type, namespace, name)
    for i=1, #MenuData.Opened, 1 do
        if MenuData.Opened[i] then
            if MenuData.Opened[i].type == type and MenuData.Opened[i].namespace == namespace and MenuData.Opened[i].name == name then
                return MenuData.Opened[i]
            end
        end
    end
end

function MenuData.GetOpenedMenus()
    return MenuData.Opened
end

function MenuData.IsOpen (type, namespace, name)
    return MenuData.GetOpened(type, namespace, name) ~= nil
end

function MenuData.ReOpen(oldMenu)
    MenuData.Open(oldMenu.type, oldMenu.namespace, oldMenu.name, oldMenu.data, oldMenu.submit, oldMenu.cancel, oldMenu.change, oldMenu.close)
end


--==================================FUNCTIONS ==================================

--================================== CALLBACKS ==================================

local Timer, MenuType = 0, 'default'

function checkdata(data, menu)
    for k,l in pairs(menu)do
        if (l.value and l.value == data.value) and (l.label and l.label == data.label) then
            for m,n in pairs(data)do
                if l[m] and l[m] ~= n then
                    return false
                end
            end
        end
    end
    return true
end
RegisterNUICallback('menu_submit', function(data,cb)
	cb({})
    PlaySoundFrontend("SELECT", "RDRO_Character_Creator_Sounds", true, 0)
    local menu = MenuData.GetOpened(MenuType, data._namespace, data._name)
    if menu and menu.submit ~= nil then
		local issue = checkdata(data.current,menu.data.elements)
		--if issue then
			menu.submit(data, menu)
		--else
			--print("invalid request")
		--end
    end
end)

RegisterNUICallback('playsound', function(data,cb)
	if data.type == "text" or data.type == "number" then
		SetNuiFocus(1, 0)
		--SetNuiFocusKeepInput(true)
	else
		SetNuiFocus(data.setNui or 0, 0)
		--SetNuiFocusKeepInput(true)
	end
    PlaySoundFrontend("NAV_LEFT", "PAUSE_MENU_SOUNDSET", true, 0)
	cb({})
    --Wait(100)
end)
RegisterNUICallback('menu_cancel', function(data,cb)
	SetNuiFocus(1, 0)
    PlaySoundFrontend("SELECT", "RDRO_Character_Creator_Sounds", true, 0)
    local menu = MenuData.GetOpened(MenuType, data._namespace, data._name)
    if menu.cancel ~= nil then
        menu.cancel(data, menu)
    end
	cb({})
end)
RegisterNUICallback('menu_change', function(data,cb)
    local menu = MenuData.GetOpened(MenuType, data._namespace, data._name)
	cb({})
    if not menu then return end
    for i=1, #data.elements, 1 do
        menu.setElement(i, 'value', data.elements[i].value)

        if data.elements[i].selected then
            menu.setElement(i, 'selected', true)
        else
            menu.setElement(i, 'selected', false)
        end
    end
    if menu.change ~= nil then
        menu.change(data, menu)
    end
end)
--================================== CALLBACKS ==================================


--==================================  CONTROL SECTION =========================================
Citizen.CreateThread(function()
    local PauseMenuState    = false
    local MenusToReOpen     = {}
    while true do
        Citizen.Wait(0)
        if #MenuData.Opened > 0 then
            if (IsControlJustReleased(0, 0x43DBF61F)  or  IsDisabledControlJustReleased(0, 0x43DBF61F)) then
                DisableControlAction(0, 0x43DBF61F,1)
                SendNUIMessage({ak_menubase_action = 'controlPressed', ak_menubase_control = 'ENTER'})
                EnableControlAction(0, 0x43DBF61F,1)
            end

            if (IsControlJustReleased(0, 0x308588E6)  or  IsDisabledControlJustReleased(0, 0x308588E6)) then
                DisableControlAction(0, 0x308588E6,1)
                SendNUIMessage({ak_menubase_action  = 'controlPressed', ak_menubase_control = 'BACKSPACE'})
                EnableControlAction(0, 0x308588E6,1)
            end

            if (IsControlJustReleased(0, 0x911CB09E)  or  IsDisabledControlJustReleased(0, 0x911CB09E)) then
                DisableControlAction(0, 0x911CB09E,1)
                SendNUIMessage({ak_menubase_action  = 'controlPressed', ak_menubase_control = 'TOP'})
                EnableControlAction(0, 0x911CB09E,1)
            end

            if ((IsControlJustReleased(0, 0x4403F97F)  or  IsDisabledControlJustReleased(0, 0x4403F97F)) or
                (IsControlJustReleased(0, 0xB238FE0B)  or  IsDisabledControlJustReleased(0, 0xB238FE0B))) then
                DisableControlAction(0, 0x4403F97F,1)
                DisableControlAction(0, 0xB238FE0B,1)
                SendNUIMessage({ak_menubase_action  = 'controlPressed', ak_menubase_control = 'DOWN'})
                EnableControlAction(0, 0x4403F97F,1)
                EnableControlAction(0, 0xB238FE0B,1)
            end

            if (IsControlJustReleased(0, 0xAD7FCC5B)  or  IsDisabledControlJustReleased(0, 0xAD7FCC5B)) then
                DisableControlAction(0, 0xAD7FCC5B,1)
                SendNUIMessage({ak_menubase_action  = 'controlPressed', ak_menubase_control = 'LEFT'})
                EnableControlAction(0, 0xAD7FCC5B,1)
            end

            if (IsControlJustReleased(0, 0x65F9EC5B)  or  IsDisabledControlJustReleased(0, 0x65F9EC5B)) then
                DisableControlAction(0, 0x65F9EC5B,1)
                SendNUIMessage({ak_menubase_action  = 'controlPressed', ak_menubase_control = 'RIGHT'})
                EnableControlAction(0, 0x65F9EC5B,1)
            end

            if IsPauseMenuActive() then
                if not PauseMenuState then
                    PauseMenuState = true
                    for k, v in pairs(MenuData.GetOpenedMenus()) do
                        table.insert(MenusToReOpen, v)
                    end
                    MenuData.CloseAll()
                end
            end
        else
            if PauseMenuState and not IsPauseMenuActive() then
                PauseMenuState = false
                Citizen.Wait(1000)
                for k, v in pairs(MenusToReOpen) do
                    MenuData.ReOpen(v)
                end
                MenusToReOpen = { }
            end
        end
    end
end)


--==================================  CONTROL SECTION =========================================

--==================================  SHARE FUNCTIONS =========================================
AddEventHandler('redemrp_menu_base:getData', function(cb)
    cb(MenuData)
end)
--==================================  SHARE FUNCTIONS =========================================

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        MenuData.CloseAll()
    end
end)