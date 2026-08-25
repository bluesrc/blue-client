local actionsWindow
local evolutionAction
local activePokemonId = 0
local evolutionTarget = ''
local clickLocked = false
local unlockEvent

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
    activePokemonId = 0
    evolutionTarget = ''

    if evolutionAction then
        evolutionAction:hide()
    end
    if actionsWindow then
        actionsWindow:hide()
    end
end

local function updateEvolutionAction(active, pokemonId, target)
    if not actionsWindow or not evolutionAction then
        return
    end

    activePokemonId = active and pokemonId or 0
    evolutionTarget = active and target or ''
    if activePokemonId == 0 or evolutionTarget == '' then
        evolutionAction:hide()
        actionsWindow:hide()
        return
    end

    evolutionAction:setTooltip(tr('Evolve into %s', evolutionTarget))
    evolutionAction:show()
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
        onPokemonEvolution = onPokemonEvolution
    })
    connect(g_game, {
        onGameEnd = offline
    })

    actionsWindow = g_ui.loadUI('pokemonactions', modules.game_interface.getMapPanel())
    evolutionAction = actionsWindow:getChildById('evolutionAction')
    evolutionAction.onMousePress = function(_, _, button)
        return button == MouseLeftButton
    end
    evolutionAction.onMouseRelease = evolveActivePokemon
    clearActions()
end

function terminate()
    disconnect(LocalPlayer, {
        onPokemonEvolution = onPokemonEvolution
    })
    disconnect(g_game, {
        onGameEnd = offline
    })

    cancelUnlockEvent()
    if actionsWindow then
        actionsWindow:destroy()
        actionsWindow = nil
    end
    evolutionAction = nil
end

function offline()
    clearActions()
end

function onPokemonEvolution(_, _, pokemonId, active, target)
    updateEvolutionAction(active, pokemonId, target or '')
end
