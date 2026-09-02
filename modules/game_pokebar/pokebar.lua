local pokebarWindow
local pokeballsInfo = {}
local slotWidgets = {}
local setupEvent
local activeCreatureId = 0
local evolutionClickLocked = false
local evolutionUnlockEvent

local INACTIVE_HEIGHT = 52
local ACTIVE_HEIGHT = 62
local ITEM_SPACING = 4
local EXPERIENCE_COLOR = '#50AEE8'
local GENDER_IMAGES = {
    [0] = '/images/gender/gender_undefined',
    [1] = '/images/gender/gender_male',
    [2] = '/images/gender/gender_female',
    [3] = '/images/gender/gender_undefined'
}
local GENDER_NAMES = {
    [0] = 'Genderless',
    [1] = 'Male',
    [2] = 'Female',
    [3] = 'Undefined'
}

local function clampPercent(value)
    return math.max(0, math.min(100, tonumber(value) or 0))
end

local function healthColor(percent)
    if percent > 92 then
        return '#00BC00'
    elseif percent > 60 then
        return '#50A150'
    elseif percent > 30 then
        return '#A1A100'
    elseif percent > 8 then
        return '#BF0A0A'
    elseif percent > 3 then
        return '#910F0F'
    end
    return '#850C0F'
end

local function experienceProgress(info)
    local currentLevelExperience = tonumber(info.currentLevelExperience) or 0
    local nextLevelExperience = tonumber(info.nextLevelExperience) or 0
    local experience = tonumber(info.experience) or 0

    if nextLevelExperience <= currentLevelExperience then
        return 100, 0, 0
    end

    local required = nextLevelExperience - currentLevelExperience
    local earned = math.max(0, math.min(required, experience - currentLevelExperience))
    return clampPercent(math.floor((earned * 100 / required) + 0.5)), earned, required
end

local function createPendingInfo()
    return {
        creatureId = 0,
        fainted = false,
        active = false,
        healthPercent = 100,
        number = 0,
        level = 1,
        name = '',
        experience = 0,
        currentLevelExperience = 0,
        nextLevelExperience = 0,
        health = 0,
        maxHealth = 0,
        gender = 3,
        evolutionTarget = ''
    }
end

local function healthValues(info)
    local maxHealth = math.max(0, tonumber(info.maxHealth) or 0)
    local currentHealth = info.fainted and 0 or math.max(0, tonumber(info.health) or 0)
    return math.min(currentHealth, maxHealth), maxHealth
end

local function pokemonTooltip(slot, info)
    local partyIndex = slot - InventoryPokeballSlotFirst + 1
    local name = info.name ~= '' and info.name or tr('Pokemon')
    local currentHealth, maxHealth = healthValues(info)
    local lines = {
        name .. ' - ' .. tr('Level') .. ' ' .. (info.level or 1)
    }

    if maxHealth > 0 then
        lines[#lines + 1] = string.format('%s: %d / %d', tr('Health'), currentHealth, maxHealth)
    else
        lines[#lines + 1] = tr('Health')
    end
    lines[#lines + 1] = tr('Experience')

    local keyCombo = modules.game_hotkeys and modules.game_hotkeys.getBinding and
                         modules.game_hotkeys.getBinding('pokemon_slot_' .. partyIndex) or ''
    local slotText = tr('Pokebag slot %d', partyIndex)
    if keyCombo ~= '' then
        slotText = slotText .. ' (' .. keyCombo .. ')'
    end
    lines[#lines + 1] = slotText
    return table.concat(lines, '\n')
end

local function usePokemon(slot)
    local player = g_game.getLocalPlayer()
    local item = player and player:getInventoryItem(slot)
    if not item then
        return false
    end

    if modules.game_box and modules.game_box.selectPartyPokemon and
        modules.game_box.selectPartyPokemon(slot) then
        return true
    end

    g_game.use(item, slot)
    return true
end

local function configureInteraction(widget, slot)
    widget:setPhantom(false)
    widget:setFocusable(false)
    widget.onMousePress = function(_, _, button)
        if button == MouseLeftButton then
            return usePokemon(slot)
        end
        return false
    end
end

local function unlockEvolutionClick()
    evolutionClickLocked = false
    evolutionUnlockEvent = nil
end

local function cancelEvolutionUnlock()
    if evolutionUnlockEvent then
        removeEvent(evolutionUnlockEvent)
        evolutionUnlockEvent = nil
    end
    evolutionClickLocked = false
end

local function evolvePokemon(info, button)
    if button ~= MouseLeftButton then
        return false
    end
    if evolutionClickLocked or not info.active or info.evolutionTarget == '' or
        not g_game.isOnline() then
        return true
    end

    evolutionClickLocked = true
    g_game.talk('/evolve')
    evolutionUnlockEvent = scheduleEvent(unlockEvolutionClick, 750)
    return true
end

local function updateEvolutionAction(widget, info)
    local action = widget:recursiveGetChildById('evolutionAction')
    if not action then
        return
    end

    if not info.active or info.evolutionTarget == '' then
        action:hide()
        return
    end

    action:setTooltip(tr('Evolve into %s', info.evolutionTarget))
    action.onMousePress = function(_, _, button)
        return button == MouseLeftButton
    end
    action.onMouseRelease = function(_, _, button)
        return evolvePokemon(info, button)
    end
    action:show()
end

local function updateEntryWidget(widget, info, healthPercent, experiencePercent)
    local icon = widget:recursiveGetChildById('pokemonIcon')
    icon:setImage('/images/pokemon/icon/' .. string.format('%04d', info.number) .. '.png')
    icon:setOpacity(info.fainted and 0.42 or 1)

    local gender = tonumber(info.gender) or 3
    local genderIcon = widget:recursiveGetChildById('genderIcon')
    genderIcon:setImage(GENDER_IMAGES[gender] or GENDER_IMAGES[3])
    genderIcon:setTooltip(tr(GENDER_NAMES[gender] or GENDER_NAMES[3]))

    local levelLabel = widget:recursiveGetChildById('levelLabel')
    levelLabel:setText('Lv. ' .. (info.level or 1))
    levelLabel:setColor(info.active and '#101010' or '#ffffff')

    local healthBar = widget:recursiveGetChildById('healthBar')
    healthBar:setPercent(healthPercent)
    local currentHealth, maxHealth = healthValues(info)
    healthBar:setText(info.active and maxHealth > 0 and
                          string.format('%d / %d', currentHealth, maxHealth) or '')
    healthBar:setColor('#ffffff')
    healthBar:setBackgroundColor(healthColor(healthPercent))
    healthBar:setTooltip(maxHealth > 0 and
                             string.format('%s: %d / %d', tr('Health'), currentHealth, maxHealth) or
                             tr('Health'))

    local experienceBar = widget:recursiveGetChildById('experienceBar')
    experienceBar:setPercent(experiencePercent)
    experienceBar:setBackgroundColor(EXPERIENCE_COLOR)
    experienceBar:setTooltip(tr('Experience'))

    updateEvolutionAction(widget, info)
end

local function updateSlotWidget(widget, slot, info)
    local healthPercent = clampPercent(info.fainted and 0 or info.healthPercent)
    local experiencePercent = experienceProgress(info)

    updateEntryWidget(widget, info, healthPercent, experiencePercent)

    widget:setTooltip(pokemonTooltip(slot, info))
    widget.pokebarSlot = slot
    configureInteraction(widget, slot)
end

local function destroySlotWidget(slot)
    local widget = slotWidgets[slot]
    if widget then
        widget:destroy()
        slotWidgets[slot] = nil
    end
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
        onPokemonInfo = updatePokemonInfo,
        onPokemonEvolution = onPokemonEvolution
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

    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onPokemonInfo = updatePokemonInfo,
        onPokemonEvolution = onPokemonEvolution
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

    cancelEvolutionUnlock()

    if pokebarWindow then
        pokebarWindow:destroy()
        pokebarWindow = nil
    end
    pokeballsInfo = {}
    slotWidgets = {}
    activeCreatureId = 0
end

function online()
    cancelEvolutionUnlock()
    local player = g_game.getLocalPlayer()
    if player then
        for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
            if player:getInventoryItem(slot) then
                pokeballsInfo[slot] = pokeballsInfo[slot] or createPendingInfo()
            else
                pokeballsInfo[slot] = nil
                destroySlotWidget(slot)
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

    cancelEvolutionUnlock()
    pokeballsInfo = {}
    slotWidgets = {}
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
        destroySlotWidget(slot)
    elseif not oldItem or item ~= oldItem then
        -- Do not reuse data from the Pokemon that previously occupied this slot.
        local oldInfo = pokeballsInfo[slot]
        if oldInfo and oldInfo.active then
            activeCreatureId = 0
        end
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
            info.healthPercent = clampPercent(healthPercent)
            info.fainted = info.healthPercent <= 0
            if (tonumber(info.maxHealth) or 0) > 0 then
                info.health = math.floor(info.maxHealth * info.healthPercent / 100 + 0.5)
            end
            scheduleSetup()
            return
        end
    end
end

function setup()
    if not pokebarWindow then
        return
    end

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
        local canRender = item and info and info.number and info.number > 0

        if not canRender then
            destroySlotWidget(slot)
        else
            local widget = slotWidgets[slot]
            if widget and widget.pokebarActive ~= info.active then
                destroySlotWidget(slot)
                widget = nil
            end

            if not widget then
                widget = g_ui.createWidget(info.active and 'PokebarActive' or 'PokebarEntry', pokebarWindow)
                widget:setId('slot' .. slot)
                widget.pokebarActive = info.active
                slotWidgets[slot] = widget
            end

            renderedCount = renderedCount + 1
            pokebarWindow:moveChildToIndex(widget, renderedCount)
            widget:removeAnchor(AnchorTop)
            widget:addAnchor(AnchorTop, renderedCount == 1 and 'parent' or 'prev',
                             renderedCount == 1 and AnchorTop or AnchorBottom)
            widget:setMarginTop(renderedCount == 1 and 0 or ITEM_SPACING)
            updateSlotWidget(widget, slot, info)

            if renderedCount > 1 then
                totalHeight = totalHeight + ITEM_SPACING
            end
            totalHeight = totalHeight + (info.active and ACTIVE_HEIGHT or INACTIVE_HEIGHT)
        end
    end

    pokebarWindow:setHeight(math.max(totalHeight, 1))
end

function refreshHotkeys()
    scheduleSetup()
end

function getSlotAt(mousePosition)
    if not mousePosition then
        return nil
    end

    for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local widget = slotWidgets[slot]
        if widget and widget:isVisible() and widget:containsPoint(mousePosition) then
            return slot
        end
    end

    return nil
end

function onPokemonEvolution(_, slot, pokemonId, active, target)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player or not player:getInventoryItem(slot) then
        return
    end

    local info = pokeballsInfo[slot] or createPendingInfo()
    if info.creatureId ~= 0 and info.creatureId ~= pokemonId then
        return
    end

    pokeballsInfo[slot] = info
    info.creatureId = pokemonId or info.creatureId
    info.evolutionTarget = active and (target or '') or ''
    scheduleSetup()
end

function updatePokemonInfo(_, slot, p_id, number, level, healthPercent, fainted, active,
                           name, experience, currentLevelExperience, nextLevelExperience,
                           health, maxHealth, nature, friendship, primaryType, secondaryType, gender)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player or not player:getInventoryItem(slot) then
        pokeballsInfo[slot] = nil
        destroySlotWidget(slot)
        scheduleSetup()
        return
    end

    local info = pokeballsInfo[slot] or createPendingInfo()
    pokeballsInfo[slot] = info
    info.creatureId = p_id or 0
    info.number = number or 0
    info.level = level or 1
    info.fainted = fainted or false
    info.healthPercent = clampPercent(info.fainted and 0 or healthPercent)
    info.active = (active or false) and not info.fainted
    info.name = name or ''
    info.experience = experience or 0
    info.currentLevelExperience = currentLevelExperience or 0
    info.nextLevelExperience = nextLevelExperience or 0
    info.health = health or 0
    info.maxHealth = maxHealth or 0
    info.gender = gender or 3

    if info.active then
        activeCreatureId = info.creatureId
        for otherSlot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
            if otherSlot ~= slot and pokeballsInfo[otherSlot] then
                pokeballsInfo[otherSlot].active = false
            end
        end
    elseif activeCreatureId == info.creatureId then
        activeCreatureId = 0
    end

    scheduleSetup()
end
