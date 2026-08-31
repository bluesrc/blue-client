local DUEL_OPCODE = 78
local inviteWindow
local invitePlayerId
local controlWindow
local forfeitWindow
local boundaryEffects = {}
local rosterWidgets = {}
local duel = nil

local function sendAction(buffer)
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(DUEL_OPCODE, buffer)
    end
end

local function splitFields(buffer)
    local fields = {}
    for value in (buffer .. ';'):gmatch('(.-);') do
        table.insert(fields, value)
    end
    return fields
end

local function hasBit(mask, index)
    return math.floor((tonumber(mask) or 0) / (2 ^ index)) % 2 == 1
end

local function closeInvite()
    if inviteWindow then
        inviteWindow:destroy()
        inviteWindow = nil
    end
    invitePlayerId = nil
end

local function answerInvite(accept)
    local playerId = invitePlayerId
    closeInvite()
    if playerId then
        sendAction((accept and 'Y;' or 'N;') .. playerId)
    end
    return true
end

local function showInvite(playerId, playerName)
    closeInvite()
    invitePlayerId = playerId
    inviteWindow = displayGeneralBox(tr('Duel invitation'),
        tr('%s challenged you to a duel with fully healed virtual teams.', playerName), {{
            text = tr('Accept'),
            callback = function() answerInvite(true) end
        }, {
            text = tr('Reject'),
            callback = function() answerInvite(false) end
        }}, function() answerInvite(true) end, function() answerInvite(false) end)
end

local function clearBoundary()
    for _, boundary in ipairs(boundaryEffects) do
        if boundary.tile and boundary.effect then
            boundary.tile:detachEffect(boundary.effect)
        end
    end
    boundaryEffects = {}
end

local function drawBoundary()
    clearBoundary()
    if not duel then
        return
    end
    for x = duel.minX, duel.maxX do
        for y = duel.minY, duel.maxY do
            if x == duel.minX or x == duel.maxX or y == duel.minY or y == duel.maxY then
                local tile = g_map.getTile({x = x, y = y, z = duel.z})
                if tile then
                    local effect = AttachedEffect.create(68, ThingCategoryEffect)
                    if effect then
                        effect:setPermanent(true)
                        effect:setLoop(-1)
                        tile:attachEffect(effect)
                        table.insert(boundaryEffects, {tile = tile, effect = effect})
                    end
                end
            end
        end
    end
end

local function destroyRosterWidgets()
    for _, widget in pairs(rosterWidgets) do
        if widget then
            widget:destroy()
        end
    end
    rosterWidgets = {}
end

local function updateRoster(playerId)
    if not duel or not duel.players[playerId] then
        return
    end
    local state = duel.players[playerId]
    local creature = g_map.getCreatureById(playerId)
    if not creature then
        return
    end

    local widget = rosterWidgets[playerId]
    if not widget then
        widget = g_ui.createWidget('DuelRosterWidget', modules.game_interface.getMapPanel())
        widget:setId('duelRoster' .. playerId)
        creature:attachWidget(widget)
        rosterWidgets[playerId] = widget
    end
    widget:destroyChildren()

    local iconCount = 0
    local rosterWidth = 0
    for index = 0, 5 do
        if hasBit(state.teamMask, index) then
            local icon = g_ui.createWidget('DuelBallIcon', widget)
            iconCount = iconCount + 1
            if iconCount > 1 then
                rosterWidth = rosterWidth + 2
            end
            local alive = hasBit(state.aliveMask, index)
            if not alive then
                icon:setImageColor('#555555')
                icon:setMarginTop(2)
                rosterWidth = rosterWidth + 14
                icon:setTooltip(tr('Defeated Pokemon'))
            elseif state.activeSlot == index + 1 then
                icon:setWidth(18)
                icon:setHeight(18)
                icon:setImageSize({width = 18, height = 18})
                icon:setImageColor('#ffffff')
                rosterWidth = rosterWidth + 18
                icon:setTooltip(tr('Active Pokemon'))
            else
                icon:setImageColor('#ffffff')
                icon:setMarginTop(2)
                rosterWidth = rosterWidth + 14
                icon:setTooltip(tr('Available Pokemon'))
            end
        end
    end
    rosterWidth = math.max(14, rosterWidth)
    widget:setWidth(rosterWidth)
    widget:setMarginLeft(-math.floor(rosterWidth / 2))
end

local function cleanupDuel()
    clearBoundary()
    destroyRosterWidgets()
    if controlWindow then
        controlWindow:destroy()
        controlWindow = nil
    end
    if forfeitWindow then
        forfeitWindow:destroy()
        forfeitWindow = nil
    end
    duel = nil
end

local function confirmForfeit()
    if not duel or forfeitWindow then
        return
    end
    local function answerForfeit(accept)
        if forfeitWindow then
            forfeitWindow:destroy()
            forfeitWindow = nil
        end
        if accept and duel then
            sendAction('F')
        end
        return true
    end
    forfeitWindow = displayGeneralBox(tr('Forfeit duel'), tr('Do you really want to forfeit this duel?'), {{
        text = tr('Yes'),
        callback = function() answerForfeit(true) end
    }, {
        text = tr('No'),
        callback = function() answerForfeit(false) end
    }}, function() answerForfeit(true) end, function() answerForfeit(false) end)
end

local function startDuel(fields)
    if #fields < 17 then
        return
    end
    cleanupDuel()
    closeInvite()

    local firstId = tonumber(fields[8])
    local secondId = tonumber(fields[13])
    if not firstId or not secondId then
        return
    end
    duel = {
        id = tonumber(fields[2]),
        minX = tonumber(fields[3]),
        minY = tonumber(fields[4]),
        z = tonumber(fields[5]),
        maxX = tonumber(fields[6]),
        maxY = tonumber(fields[7]),
        firstName = fields[9],
        secondName = fields[14],
        players = {}
    }
    duel.players[firstId] = {
        teamMask = tonumber(fields[10]) or 0,
        aliveMask = tonumber(fields[11]) or 0,
        activeSlot = tonumber(fields[12]) or 0
    }
    duel.players[secondId] = {
        teamMask = tonumber(fields[15]) or 0,
        aliveMask = tonumber(fields[16]) or 0,
        activeSlot = tonumber(fields[17]) or 0
    }

    drawBoundary()
    updateRoster(firstId)
    updateRoster(secondId)
    local topMenu = modules.client_topmenu.getTopMenu()
    controlWindow = g_ui.createWidget('DuelControlWindow', topMenu:getParent())
    controlWindow:recursiveGetChildById('duelTitle'):setText(
        string.format('%s  vs  %s', duel.firstName, duel.secondName))
    controlWindow:recursiveGetChildById('forfeitButton').onClick = confirmForfeit
end

local function updateState(fields)
    if not duel or #fields < 5 then
        return
    end
    local playerId = tonumber(fields[2])
    if not playerId or not duel.players[playerId] then
        return
    end
    local state = duel.players[playerId]
    state.teamMask = tonumber(fields[3]) or state.teamMask
    state.aliveMask = tonumber(fields[4]) or state.aliveMask
    state.activeSlot = tonumber(fields[5]) or 0
    updateRoster(playerId)
end

function onDuelExtendedOpcode(_, _, buffer)
    local fields = splitFields(buffer)
    if fields[1] == 'Q' and #fields >= 3 then
        local playerId = tonumber(fields[2])
        if playerId then
            showInvite(playerId, fields[3])
        end
    elseif fields[1] == 'C' then
        closeInvite()
    elseif fields[1] == 'S' then
        startDuel(fields)
    elseif fields[1] == 'U' then
        updateState(fields)
    elseif fields[1] == 'F' then
        cleanupDuel()
    end
end

function requestDuel(creature)
    if not creature or not creature:isPlayer() or creature:isLocalPlayer() or duel then
        return
    end
    sendAction('I;' .. creature:getId())
end

function init()
    g_ui.importStyle('duel')
    ProtocolGame.registerExtendedOpcode(DUEL_OPCODE, onDuelExtendedOpcode)
    connect(g_game, { onGameEnd = cleanupDuel })
end

function terminate()
    ProtocolGame.unregisterExtendedOpcode(DUEL_OPCODE)
    disconnect(g_game, { onGameEnd = cleanupDuel })
    closeInvite()
    cleanupDuel()
end
