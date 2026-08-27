local statusWindow
local fixedStages
local dynamicStatuses
local stageWidgets = {}
local conditionWidgets = {}
local flinchWidget
local activeInventorySlot = 0
local flinchEvent
local flinchEndsAt = 0

local FIXED_HEIGHT = 26
local DYNAMIC_HEIGHT = 22
local DYNAMIC_MARGIN = 4

local stageDefinitions = {
    attack = {
        label = 'Attack',
        icon = '/images/game/combatmodes/fightoffensive',
        clip = '0 0 20 20'
    },
    defense = {
        label = 'Defense',
        icon = '/images/game/combatmodes/fightdefensive',
        clip = '0 0 20 20'
    },
    specialAttack = {
        label = 'Special Attack',
        icon = '/images/game/states/strengthened'
    },
    specialDefense = {
        label = 'Special Defense',
        icon = '/images/game/states/magic_shield'
    },
    speed = {
        label = 'Speed',
        icon = '/images/game/states/haste'
    },
    accuracy = {
        label = 'Accuracy',
        icon = '/images/game/crosshair/full'
    }
}

local conditionDefinitions = {
    [1] = { id = 'burn', label = 'Burn', icon = '/images/game/states/burning' },
    [2] = { id = 'freeze', label = 'Freeze', icon = '/images/game/states/freezing' },
    [3] = { id = 'paralysis', label = 'Paralysis', icon = '/images/game/states/electrified' },
    [4] = { id = 'poison', label = 'Poison', icon = '/images/game/states/poisoned' },
    [5] = { id = 'sleep', label = 'Sleep', icon = '/images/game/states/slowed' },
    [6] = { id = 'confusion', label = 'Confusion', icon = '/images/game/states/dazzled' }
}

local function stopFlinchEvent()
    if flinchEvent then
        removeEvent(flinchEvent)
        flinchEvent = nil
    end
    flinchEndsAt = 0
end

local function setStage(id, value)
    local definition = stageDefinitions[id]
    local widget = stageWidgets[id]
    if not definition or not widget then
        return
    end

    value = math.max(-6, math.min(6, value or 0))
    local label = widget:getChildById('stage')
    if value == 0 then
        label:setText('')
        label:setColor('#d7e2eb')
        widget:setTooltip(tr('%s: no stage change', definition.label))
    else
        label:setText(value > 0 and ('+' .. value) or tostring(value))
        label:setColor(value > 0 and '#78d990' or '#e77d72')
        widget:setTooltip(tr('%s stage: %s', definition.label, label:getText()))
    end
end

local function updateDynamicGeometry()
    local hasDynamicStatus = false
    for _, child in ipairs(dynamicStatuses:getChildren()) do
        if child:isExplicitlyVisible() then
            hasDynamicStatus = true
            break
        end
    end

    dynamicStatuses:setVisible(hasDynamicStatus)
    statusWindow:setHeight(hasDynamicStatus
        and (FIXED_HEIGHT + DYNAMIC_MARGIN + DYNAMIC_HEIGHT)
        or FIXED_HEIGHT)
end

local function hideFlinch()
    flinchEvent = nil
    if g_clock.millis() < flinchEndsAt then
        flinchEvent = scheduleEvent(hideFlinch, flinchEndsAt - g_clock.millis())
        return
    end

    flinchEndsAt = 0
    if statusWindow and flinchWidget then
        flinchWidget:hide()
        updateDynamicGeometry()
    end
end

local function setFlinch(duration)
    stopFlinchEvent()
    if duration <= 0 then
        flinchWidget:hide()
        return
    end

    flinchEndsAt = g_clock.millis() + duration
    flinchWidget:show()
    flinchEvent = scheduleEvent(hideFlinch, duration)
end

local function clearStatus()
    stopFlinchEvent()
    activeInventorySlot = 0

    if not statusWindow then
        return
    end

    for id in pairs(stageDefinitions) do
        setStage(id, 0)
    end
    for _, widget in pairs(conditionWidgets) do
        widget:hide()
    end
    stageWidgets.accuracy:hide()
    flinchWidget:hide()
    dynamicStatuses:hide()
    statusWindow:setHeight(FIXED_HEIGHT)
    statusWindow:hide()
end

local function setCondition(status)
    for condition, definition in pairs(conditionDefinitions) do
        local widget = conditionWidgets[definition.id]
        widget:setVisible(condition == status)
    end
end

function init()
    connect(LocalPlayer, {
        onPokemonStatus = onPokemonStatus
    })
    connect(g_game, {
        onGameEnd = offline
    })

    statusWindow = g_ui.loadUI('pokemonstatus', modules.game_interface.getMapPanel())
    fixedStages = statusWindow:getChildById('fixedStages')
    dynamicStatuses = statusWindow:getChildById('dynamicStatuses')

    for id, definition in pairs(stageDefinitions) do
        local parent = id == 'accuracy' and dynamicStatuses or fixedStages
        local widget = parent:getChildById(id)
        stageWidgets[id] = widget
        local icon = widget:getChildById('icon')
        icon:setImageSource(definition.icon)
        if definition.clip then
            icon:setImageClip(definition.clip)
        end
    end
    for _, definition in pairs(conditionDefinitions) do
        local widget = dynamicStatuses:getChildById(definition.id)
        conditionWidgets[definition.id] = widget
        widget:getChildById('icon'):setImageSource(definition.icon)
        widget:setTooltip(tr(definition.label))
    end

    flinchWidget = dynamicStatuses:getChildById('flinch')
    flinchWidget:getChildById('icon'):setImageSource('/images/game/states/logout_block')
    flinchWidget:setTooltip(tr('Flinch'))
    clearStatus()
end

function terminate()
    disconnect(LocalPlayer, {
        onPokemonStatus = onPokemonStatus
    })
    disconnect(g_game, {
        onGameEnd = offline
    })

    stopFlinchEvent()
    if statusWindow then
        statusWindow:destroy()
        statusWindow = nil
    end
    fixedStages = nil
    dynamicStatuses = nil
    stageWidgets = {}
    conditionWidgets = {}
    flinchWidget = nil
end

function offline()
    clearStatus()
end

function onPokemonStatus(_, inventorySlot, _pokemonId, active,
                         attack, defense, specialAttack, specialDefense,
                         speed, accuracy, status, flinchDuration)
    if not active then
        if inventorySlot == activeInventorySlot then
            clearStatus()
        end
        return
    end

    activeInventorySlot = inventorySlot
    setStage('attack', attack)
    setStage('defense', defense)
    setStage('specialAttack', specialAttack)
    setStage('specialDefense', specialDefense)
    setStage('speed', speed)
    setStage('accuracy', accuracy)

    stageWidgets.accuracy:setVisible(accuracy ~= 0)
    setCondition(status)
    setFlinch(flinchDuration)
    updateDynamicGeometry()
    statusWindow:show()
end
