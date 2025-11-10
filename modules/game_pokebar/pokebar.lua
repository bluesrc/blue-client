pokebarWindow = nil
pokeballs = {}
pokeballsInfo = {}
local NORMAL_SIZE = 36
local ENLARGED_SIZE = 72
local activeCreatureId = 0

function init()
    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onPokemonInfo = updatePokemonInfo
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    connect(Creature, {
        onHealthPercentChange = changeHealth
    })

    pokebarWindow = g_ui.loadUI('pokebar', modules.game_interface.getMapPanel())
    pokebarWindow:setOn(true)
    pokebarWindow:setVisible(true)

    pokebarWindow.onMousePress = function(self, mousePos, button)
        return true
    end
end

function terminate()
    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onPokemonInfo = updatePokemonInfo
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    disconnect(Creature, {
        onHealthPercentChange = changeHealth
    })

    pokebarWindow:destroy()
    pokebarWindow = nil
end

function online()
    setup()
end

function offline()
    pokeballs = {}
end

local function removeValue(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return
        end
    end
end

function onInventoryChange(player, slot, item, oldItem)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    if not item then
        removeValue(pokeballs, slot)
        pokeballsInfo[slot] = nil
    end
        
    local slotExists = false
    for _, s in ipairs(pokeballs) do 
        if s == slot then
            slotExists = true
                break
        end
    end

    if not slotExists then
        table.insert(pokeballs, slot)
        table.sort(pokeballs)
    end
    
    if not pokeballsInfo[slot] then
        pokeballsInfo[slot] =
            {
                creatureId = 0,
                fainted = false,
                active = false,
                healthPercent = 100,
                number = 0,
            }
    end

    setup()
end

function changeHealth(creature, healthPercent, oldHealthPercent)
    local c_id = creature:getId()

    if c_id == activeCreatureId then
        local foundSlot = false
        for _, slot in ipairs(pokeballs) do
            local info = pokeballsInfo[slot]
            if info and info.active then
                info.healthPercent = healthPercent
                foundSlot = true
                break
            end
        end

        if foundSlot then
            g_dispatcher.scheduleEvent(setup, 1) 
        end
    end
end

function setup()
    pokebarWindow:destroyChildren()

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local marginTop = 10
    local currentActiveWidget = nil

    for i, v in ipairs(pokeballs) do 
        local item = player:getInventoryItem(v)
        
        if item and pokeballsInfo[v] then 
            local info = pokeballsInfo[v]
            local currentSlotId = 'slot' .. v 

            local isCurrentItemActive = info.active

            local widgetType = 'PokebarItem'
            if isCurrentItemActive then
                widgetType = 'PokebarActive'
            end

            local itemWidget = g_ui.createWidget(widgetType, pokebarWindow) 
            itemWidget:setId(currentSlotId)
            
            if i == 1 then
                itemWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
            else
                itemWidget:addAnchor(AnchorTop, 'prev', AnchorBottom)
            end
            
            local pokemon = itemWidget
            if isCurrentItemActive then
                pokemon = itemWidget:getChildById('activePokemon')
            end 
            
            if not info.number then return end
            local number = string.format("%04d", info.number)

            pokemon:setImage('/images/pokemon/icon/' .. number .. '.png')
            itemWidget:setPhantom(false)
            itemWidget:setFocusable(false)

            local healthBarId = isCurrentItemActive and 'activeHealthBar' or 'healthBar'
            local healthBar = itemWidget:getChildById(healthBarId) 

            if isCurrentItemActive then
                currentActiveWidget = itemWidget
            end

            if healthBar then
                healthBar:setPercent(info.healthPercent) 
                
                if info.fainted then
                    healthBar:setPercent(0) 
                end
                
                if info.healthPercent > 92 then
                    color = '#00BC00'
                elseif info.healthPercent > 60 then
                    color = '#50A150'
                elseif info.healthPercent > 30 then
                    color = '#A1A100'
                elseif info.healthPercent > 8 then
                    color = '#BF0A0A'
                elseif info.healthPercent > 3 then
                    color = '#910F0F'
                else
                    color = '#850C0F'
                end
                healthBar:setBackgroundColor(color)
            end
            if info.fainted then
                itemWidget:setOpacity(0.5)
            else
                itemWidget:setOpacity(1)
            end
            
            itemWidget.onMousePress = function(self, mousePos, button)
                if button == MouseLeftButton then
                    g_game.use(item, v) 
                    return true
                end
            end

            itemWidget.onMouseRelease = function(self, mousePos, button)
                if button == MouseRightButton then
                    return true 
                end
            end
        end
    end
    
    local activeHeightDifference = 0
    if currentActiveWidget then
        activeHeightDifference = ENLARGED_SIZE - NORMAL_SIZE
    end

    local totalHeight = #pokeballs * NORMAL_SIZE
    if #pokeballs > 0 then
        totalHeight = totalHeight + ((#pokeballs - 1) * marginTop)
    end
    
    totalHeight = totalHeight + activeHeightDifference + 10

    pokebarWindow:setHeight(totalHeight)
end

function updatePokemonInfo(player, slot, p_id, number, healthPercent, fainted, active)
    if pokeballsInfo[slot] then
        local info = pokeballsInfo[slot]

        info.creatureId = p_id
        info.number = number
        info.fainted = fainted
        info.healthPercent = healthPercent
        
        if fainted then
            info.healthPercent = 0
            info.active = false
        end
        
        if active then
            info.active = true
            activeCreatureId = p_id
            for _, s in ipairs(pokeballs) do
                if s ~= slot and pokeballsInfo[s] and pokeballsInfo[s].active then
                    pokeballsInfo[s].active = false
                end
            end
        else
            info.active = false
            if activeCreatureId == p_id then
                activeCreatureId = 0
            end
        end
    end
    
    setup()
end