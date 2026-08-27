local movesWindow
local activeInventorySlot = 0
local activePokemonId = 0
local activeMoves = {}
local cooldownEvent

local ENTRY_HEIGHT = 38
local ENTRY_SPACING = 4
local UPDATE_INTERVAL = 100

local function stopCooldownUpdate()
    if cooldownEvent then
        removeEvent(cooldownEvent)
        cooldownEvent = nil
    end
end

local function clearMoves()
    stopCooldownUpdate()
    activeInventorySlot = 0
    activePokemonId = 0
    activeMoves = {}

    if movesWindow then
        movesWindow:destroyChildren()
        movesWindow:setHeight(1)
        movesWindow:hide()
    end
end

local function formatDuration(milliseconds)
    return string.format('%.1fs', math.max(milliseconds, 0) / 1000)
end

local function updateCooldowns()
    cooldownEvent = nil
    if not movesWindow or not movesWindow:isVisible() then
        return
    end

    local now = g_clock.millis()
    local hasActiveCooldown = false

    for slot = 1, 4 do
        local move = activeMoves[slot]
        local entry = movesWindow:getChildById('move' .. slot)
        if move and entry then
            local cooldownLabel = entry:getChildById('cooldown')
            local cooldownProgress = entry:getChildById('cooldownProgress')
            local remaining = move.endsAt and math.max(move.endsAt - now, 0) or 0
            if remaining > 0 then
                local duration = math.max(move.cooldownDuration or move.cooldown or 0, 1)
                local elapsed = math.max(duration - remaining, 0)
                local percent = math.min(math.floor((elapsed / duration) * 100), 100)

                cooldownLabel:setText(formatDuration(remaining))
                cooldownLabel:setColor('#e7ad52')
                cooldownProgress:setPercent(percent)
                cooldownProgress:setBackgroundColor('#d18b36')
                entry:setBackgroundColor('#251d17ee')
                hasActiveCooldown = true
            else
                move.endsAt = 0
                move.cooldownDuration = 0
                cooldownLabel:setText(formatDuration(move.cooldown))
                cooldownLabel:setColor('#8fd694')
                cooldownProgress:setPercent(100)
                cooldownProgress:setBackgroundColor('#4f9f62')
                entry:setBackgroundColor('#111820dd')
            end
        end
    end

    if hasActiveCooldown then
        cooldownEvent = scheduleEvent(updateCooldowns, UPDATE_INTERVAL)
    end
end

local function renderMoves()
    stopCooldownUpdate()
    movesWindow:destroyChildren()

    local rendered = 0
    for slot = 1, 4 do
        local move = activeMoves[slot]
        if move and move.name ~= '' then
            local currentSlot = slot
            local entry = g_ui.createWidget('PokemonMoveEntry', movesWindow)
            entry:setId('move' .. slot)
            local keyCombo = modules.game_hotkeys and modules.game_hotkeys.getBinding and
                                 modules.game_hotkeys.getBinding('pokemon_move_' .. slot) or tostring(slot)
            if keyCombo == '' then
                keyCombo = '-'
            end
            entry:getChildById('slot'):setText(keyCombo)
            entry:getChildById('moveName'):setText(move.name)
            entry:setTooltip(tr('Click to use %s', move.name) .. ' (' .. keyCombo .. ')')
            entry.onMousePress = function(_, _, button)
                return button == MouseLeftButton
            end
            entry.onMouseRelease = function(_, _, button)
                if button ~= MouseLeftButton then
                    return false
                end
                useMove(currentSlot)
                return true
            end
            rendered = rendered + 1
        end
    end

    if rendered == 0 then
        movesWindow:setHeight(1)
        movesWindow:hide()
        return
    end

    movesWindow:setHeight((rendered * ENTRY_HEIGHT) + ((rendered - 1) * ENTRY_SPACING))
    movesWindow:show()
    updateCooldowns()
end

function refreshHotkeys()
    if movesWindow and activePokemonId ~= 0 then
        renderMoves()
    end
end

function useMove(slot)
    local move = activeMoves[slot]
    if not g_game.isOnline() or not move or move.name == '' then
        return false
    end
    if move.endsAt and move.endsAt > g_clock.millis() then
        return false
    end
    g_game.talk(move.name)
    return true
end

function init()
    connect(LocalPlayer, {
        onPokemonMoves = onPokemonMoves,
        onPokemonMoveCooldown = onPokemonMoveCooldown
    })
    connect(g_game, {
        onGameEnd = offline
    })

    movesWindow = g_ui.loadUI('pokemonmoves', modules.game_interface.getMapPanel())
    movesWindow:hide()
end

function terminate()
    disconnect(LocalPlayer, {
        onPokemonMoves = onPokemonMoves,
        onPokemonMoveCooldown = onPokemonMoveCooldown
    })
    disconnect(g_game, {
        onGameEnd = offline
    })

    stopCooldownUpdate()
    if movesWindow then
        movesWindow:destroy()
        movesWindow = nil
    end
    activeMoves = {}
end

function offline()
    clearMoves()
end

function onPokemonMoves(_, inventorySlot, pokemonId, active,
                        move1Name, move1Cooldown, move2Name, move2Cooldown,
                        move3Name, move3Cooldown, move4Name, move4Cooldown)
    if not active then
        if activeInventorySlot == inventorySlot then
            clearMoves()
        end
        return
    end

    local previousMoves = activePokemonId == pokemonId and activeMoves or {}
    local received = {
        { name = move1Name, cooldown = move1Cooldown },
        { name = move2Name, cooldown = move2Cooldown },
        { name = move3Name, cooldown = move3Cooldown },
        { name = move4Name, cooldown = move4Cooldown }
    }

    for slot = 1, 4 do
        local previous = previousMoves[slot]
        if previous and previous.name == received[slot].name then
            received[slot].endsAt = previous.endsAt
            received[slot].cooldownDuration = previous.cooldownDuration
        else
            received[slot].endsAt = 0
            received[slot].cooldownDuration = 0
        end
    end

    activeInventorySlot = inventorySlot
    activePokemonId = pokemonId
    activeMoves = received
    renderMoves()
end

function onPokemonMoveCooldown(_, pokemonId, slot, duration)
    if pokemonId ~= activePokemonId or slot < 1 or slot > 4 or not activeMoves[slot] then
        return
    end

    activeMoves[slot].cooldownDuration = duration
    activeMoves[slot].endsAt = g_clock.millis() + duration
    stopCooldownUpdate()
    updateCooldowns()
end
