local pokebarWindow
local pokeballsInfo = {}
local setupEvent
local activeCreatureId = 0

local NORMAL_SIZE = 36
local ACTIVE_SIZE = 72
local ITEM_SPACING = 10

local function createPendingInfo()
    return {
        creatureId = 0,
        fainted = false,
        active = false,
        healthPercent = 100,
        number = 0,
        level = 1
    }
end

local function scheduleSetup()
    if setupEvent then
        removeEvent(setupEvent)
    end

    setupEvent = scheduleEvent(function()
        setupEvent = nil
        setup()
    end, 1)
end

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
    pokebarWindow.onMousePress = function()
        return true
    end

    if g_game.isOnline() then
        online()
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

    if setupEvent then
        removeEvent(setupEvent)
        setupEvent = nil
    end

    pokebarWindow:destroy()
    pokebarWindow = nil
    pokeballsInfo = {}
end

function online()
    local player = g_game.getLocalPlayer()
    if player then
        for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
            if player:getInventoryItem(slot) then
                pokeballsInfo[slot] = pokeballsInfo[slot] or createPendingInfo()
            else
                pokeballsInfo[slot] = nil
            end
        end
    end

    scheduleSetup()
end

function offline()
    if setupEvent then
        removeEvent(setupEvent)
        setupEvent = nil
    end

    pokeballsInfo = {}
    activeCreatureId = 0
    if pokebarWindow then
        pokebarWindow:destroyChildren()
        pokebarWindow:setHeight(1)
    end
end

function onInventoryChange(_, slot, item, oldItem)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    if not item then
        local oldInfo = pokeballsInfo[slot]
        if oldInfo and oldInfo.active then
            activeCreatureId = 0
        end
        pokeballsInfo[slot] = nil
    elseif not oldItem or item ~= oldItem then
        -- Wait for the matching PokemonInfo packet before rendering this slot.
        pokeballsInfo[slot] = createPendingInfo()
    elseif not pokeballsInfo[slot] then
        pokeballsInfo[slot] = createPendingInfo()
    end

    scheduleSetup()
end

function changeHealth(creature, healthPercent)
    if creature:getId() ~= activeCreatureId then
        return
    end

    for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local info = pokeballsInfo[slot]
        if info and info.active then
            info.healthPercent = healthPercent
            scheduleSetup()
            return
        end
    end
end

function setup()
    if not pokebarWindow then
        return
    end

    pokebarWindow:destroyChildren()

    local player = g_game.getLocalPlayer()
    if not player then
        pokebarWindow:setHeight(1)
        return
    end

    local renderedCount = 0
    local totalHeight = 0

    for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local item = player:getInventoryItem(slot)
        local info = pokeballsInfo[slot]

        -- number zero is pending data; rendering it would show the egg placeholder.
        if item and info and info.number and info.number > 0 then
            local currentItem = item
            local currentSlot = slot
            local isActive = info.active
            local widgetType = isActive and 'PokebarActive' or 'PokebarItem'
            local itemWidget = g_ui.createWidget(widgetType, pokebarWindow)
            itemWidget:setId('slot' .. slot)

            renderedCount = renderedCount + 1
            itemWidget:addAnchor(AnchorTop, renderedCount == 1 and 'parent' or 'prev',
                                 renderedCount == 1 and AnchorTop or AnchorBottom)
            itemWidget:setMarginTop(renderedCount == 1 and 0 or ITEM_SPACING)

            local pokemonImage = isActive and itemWidget:getChildById('activePokemon') or itemWidget
            pokemonImage:setImage('/images/pokemon/icon/' .. string.format('%04d', info.number) .. '.png')

            local healthBar = itemWidget:getChildById(isActive and 'activeHealthBar' or 'healthBar')
            if healthBar then
                local healthPercent = info.fainted and 0 or info.healthPercent
                healthBar:setPercent(healthPercent)

                local color
                if healthPercent > 92 then
                    color = '#00BC00'
                elseif healthPercent > 60 then
                    color = '#50A150'
                elseif healthPercent > 30 then
                    color = '#A1A100'
                elseif healthPercent > 8 then
                    color = '#BF0A0A'
                elseif healthPercent > 3 then
                    color = '#910F0F'
                else
                    color = '#850C0F'
                end
                healthBar:setBackgroundColor(color)
            end

            itemWidget:setOpacity(info.fainted and 0.5 or 1)
            itemWidget:setPhantom(false)
            itemWidget:setFocusable(false)

            itemWidget.onMousePress = function(_, _, button)
                if button == MouseLeftButton then
                    g_game.use(currentItem, currentSlot)
                    return true
                end
                return false
            end

            itemWidget.onMouseRelease = function(_, _, button)
                return button == MouseRightButton
            end

            if renderedCount > 1 then
                totalHeight = totalHeight + ITEM_SPACING
            end
            totalHeight = totalHeight + (isActive and ACTIVE_SIZE or NORMAL_SIZE)
        end
    end

    pokebarWindow:setHeight(math.max(totalHeight, 1))
end

function updatePokemonInfo(_, slot, p_id, number, level, healthPercent, fainted, active)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player or not player:getInventoryItem(slot) then
        return
    end

    local info = pokeballsInfo[slot] or createPendingInfo()
    pokeballsInfo[slot] = info
    info.creatureId = p_id
    info.number = number
    info.level = level
    info.fainted = fainted
    info.healthPercent = fainted and 0 or healthPercent
    info.active = active and not fainted

    if info.active then
        activeCreatureId = p_id
        for otherSlot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
            if otherSlot ~= slot and pokeballsInfo[otherSlot] then
                pokeballsInfo[otherSlot].active = false
            end
        end
    elseif activeCreatureId == p_id then
        activeCreatureId = 0
    end

    scheduleSetup()
end
