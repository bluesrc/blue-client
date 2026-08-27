local actionsWindow
local evolutionAction
local activePokemonId = 0
local evolutionTarget = ''
local clickLocked = false
local unlockEvent
local cooldownWidgets = {}
local cooldownStates = {}
local cooldownUpdateEvent

local ACTION_SIZE = 32
local ACTION_SPACING = 6
local UPDATE_INTERVAL = 100

local cooldownDefinitions = {
    [1] = { id = 'actionCooldown', label = 'Action', icon = '/images/game/pokemonactions/action' },
    [2] = { id = 'gobackCooldown', label = 'GoBack', icon = '/images/game/pokemonactions/goback' },
    [3] = { id = 'tryCatchCooldown', label = 'TryCatch', icon = '/images/game/pokemonactions/trycatch' },
    [4] = { id = 'combatCooldown', label = 'Combat lock', icon = '/images/game/pokemonactions/combat' }
}

local function stopCooldownUpdate()
    if cooldownUpdateEvent then
        removeEvent(cooldownUpdateEvent)
        cooldownUpdateEvent = nil
    end
end

local function updateWindowGeometry()
    if not actionsWindow then
        return
    end

    local actionCount = 0
    if evolutionAction and evolutionAction:isExplicitlyVisible() then
        actionCount = actionCount + 1
    end

    for cooldown in pairs(cooldownDefinitions) do
        local widget = cooldownWidgets[cooldown]
        if widget and widget:isExplicitlyVisible() then
            actionCount = actionCount + 1
        end
    end

    if actionCount == 0 then
        actionsWindow:hide()
        return
    end

    actionsWindow:setWidth((actionCount * ACTION_SIZE) + ((actionCount - 1) * ACTION_SPACING))
    if g_game.isOnline() then
        actionsWindow:show()
    end
end

local function setCooldownReady(cooldown)
    local definition = cooldownDefinitions[cooldown]
    local widget = cooldownWidgets[cooldown]
    if not definition or not widget then
        return
    end

    local progress = widget:getChildById('cooldownProgress')
    progress:setPercent(100)
    progress:setText('')
    progress:hide()
    widget:getChildById('actionIcon'):setOpacity(1)
    widget:setBorderColor('#6d8295')
    widget:setTooltip(tr('%s: ready', definition.label))
    widget:hide()
end

local function clearCooldowns()
    stopCooldownUpdate()
    cooldownStates = {}
    for cooldown in pairs(cooldownDefinitions) do
        setCooldownReady(cooldown)
    end
    updateWindowGeometry()
end

local function formatRemaining(milliseconds)
    if milliseconds >= 10000 then
        return tostring(math.ceil(milliseconds / 1000))
    end
    return string.format('%.1f', milliseconds / 1000)
end

local function updateCooldowns()
    cooldownUpdateEvent = nil
    local now = g_clock.millis()
    local hasActiveCooldown = false
    local expiredCooldowns = {}

    for cooldown, state in pairs(cooldownStates) do
        local widget = cooldownWidgets[cooldown]
        local definition = cooldownDefinitions[cooldown]
        if widget and definition then
            local remaining = math.max(state.endsAt - now, 0)
            if remaining > 0 then
                local elapsed = math.max(state.duration - remaining, 0)
                local percent = math.min(math.floor((elapsed / state.duration) * 100), 100)
                local text = formatRemaining(remaining)
                local progress = widget:getChildById('cooldownProgress')
                progress:setPercent(percent)
                progress:setText(text)
                progress:show()
                widget:getChildById('actionIcon'):setOpacity(0.65)
                widget:setBorderColor('#d18b36')
                widget:setTooltip(tr('%s: %s seconds remaining', definition.label, text))
                hasActiveCooldown = true
            else
                table.insert(expiredCooldowns, cooldown)
            end
        end
    end

    for _, cooldown in ipairs(expiredCooldowns) do
        cooldownStates[cooldown] = nil
        setCooldownReady(cooldown)
    end

    if #expiredCooldowns > 0 then
        updateWindowGeometry()
    end

    if hasActiveCooldown then
        cooldownUpdateEvent = scheduleEvent(updateCooldowns, UPDATE_INTERVAL)
    end
end

local function startCooldown(cooldown, duration)
    local widget = cooldownWidgets[cooldown]
    if not widget then
        return
    end

    if duration <= 0 then
        cooldownStates[cooldown] = nil
        setCooldownReady(cooldown)
        stopCooldownUpdate()
        updateCooldowns()
        updateWindowGeometry()
        return
    end

    local now = g_clock.millis()
    local endsAt = now + duration
    cooldownStates[cooldown] = {
        duration = duration,
        endsAt = endsAt
    }
    widget:show()
    updateWindowGeometry()
    stopCooldownUpdate()
    updateCooldowns()
end

local function unlockClick()
    clickLocked = false
    unlockEvent = nil
end

local function cancelUnlockEvent()
    if unlockEvent then
        removeEvent(unlockEvent)
        unlockEvent = nil
    end
    clickLocked = false
end

local function clearActions()
    cancelUnlockEvent()
    clearCooldowns()
    activePokemonId = 0
    evolutionTarget = ''

    if evolutionAction then
        evolutionAction:hide()
    end
    if actionsWindow then
        actionsWindow:hide()
    end
end

local function online()
    cancelUnlockEvent()
    clearCooldowns()
    activePokemonId = 0
    evolutionTarget = ''
    evolutionAction:hide()
    updateWindowGeometry()
end

local function updateEvolutionAction(active, pokemonId, target)
    if not actionsWindow or not evolutionAction then
        return
    end

    activePokemonId = active and pokemonId or 0
    evolutionTarget = active and target or ''
    if activePokemonId == 0 or evolutionTarget == '' then
        evolutionAction:hide()
        updateWindowGeometry()
        return
    end

    evolutionAction:setTooltip(tr('Evolve into %s', evolutionTarget))
    evolutionAction:show()
    updateWindowGeometry()
    actionsWindow:show()
end

local function evolveActivePokemon(_, _, button)
    if button ~= MouseLeftButton then
        return false
    end
    if clickLocked or activePokemonId == 0 or evolutionTarget == '' or not g_game.isOnline() then
        return true
    end

    clickLocked = true
    g_game.talk('/evolve')
    unlockEvent = scheduleEvent(unlockClick, 750)
    return true
end

function init()
    connect(LocalPlayer, {
        onPokemonEvolution = onPokemonEvolution,
        onPlayerCooldown = onPlayerCooldown
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    actionsWindow = g_ui.loadUI('pokemonactions', modules.game_interface.getMapPanel())
    evolutionAction = actionsWindow:getChildById('evolutionAction')
    evolutionAction.onMousePress = function(_, _, button)
        return button == MouseLeftButton
    end
    evolutionAction.onMouseRelease = evolveActivePokemon
    for cooldown, definition in pairs(cooldownDefinitions) do
        cooldownWidgets[cooldown] = actionsWindow:getChildById(definition.id)
        cooldownWidgets[cooldown]:getChildById('actionIcon'):setImageSource(definition.icon)
    end

    if g_game.isOnline() then
        online()
    else
        clearActions()
    end
end

function terminate()
    disconnect(LocalPlayer, {
        onPokemonEvolution = onPokemonEvolution,
        onPlayerCooldown = onPlayerCooldown
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    cancelUnlockEvent()
    clearCooldowns()
    if actionsWindow then
        actionsWindow:destroy()
        actionsWindow = nil
    end
    evolutionAction = nil
    cooldownWidgets = {}
end

function offline()
    clearActions()
end

function onPokemonEvolution(_, _, pokemonId, active, target)
    updateEvolutionAction(active, pokemonId, target or '')
end

function onPlayerCooldown(_, cooldown, duration)
    startCooldown(cooldown, duration)
end
