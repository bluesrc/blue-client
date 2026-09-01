MessageSettings = {
    none = {},
    consoleRed = {
        color = TextColors.red,
        consoleTab = 'Default'
    },
    consoleOrange = {
        color = TextColors.orange,
        consoleTab = 'Default'
    },
    consoleBlue = {
        color = TextColors.blue,
        consoleTab = 'Default'
    },
    centerRed = {
        color = TextColors.red,
        consoleTab = 'Server Log',
        screenTarget = 'lowCenterLabel'
    },
    centerGreen = {
        color = TextColors.green,
        consoleTab = 'Server Log',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showInfoMessagesInConsole'
    },
    centerWhite = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'middleCenterLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    bottomWhite = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'statusLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    status = {
        color = TextColors.white,
        consoleTab = 'Server Log',
        screenTarget = 'statusLabel',
        consoleOption = 'showStatusMessagesInConsole'
    },
    statusSmall = {
        color = TextColors.white,
        screenTarget = 'statusLabel'
    },
    private = {
        color = TextColors.lightblue,
        screenTarget = 'privateLabel'
    }
}

MessageTypes = {
    [MessageModes.PokemonSay] = MessageSettings.consoleOrange,
    [MessageModes.PokemonYell] = MessageSettings.consoleOrange,
    [MessageModes.BarkLow] = MessageSettings.consoleOrange,
    [MessageModes.BarkLoud] = MessageSettings.consoleOrange,
    [MessageModes.Failure] = MessageSettings.statusSmall,
    [MessageModes.Login] = MessageSettings.bottomWhite,
    [MessageModes.Game] = MessageSettings.centerWhite,
    [MessageModes.Status] = MessageSettings.status,
    [MessageModes.Warning] = MessageSettings.centerRed,
    [MessageModes.Look] = MessageSettings.centerGreen,
    [MessageModes.Loot] = MessageSettings.centerGreen,
    [MessageModes.Red] = MessageSettings.consoleRed,
    [MessageModes.Blue] = MessageSettings.consoleBlue,
    [MessageModes.PrivateFrom] = MessageSettings.consoleBlue,

    [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,

    [MessageModes.DamageDealed] = MessageSettings.status,
    [MessageModes.DamageReceived] = MessageSettings.status,
    [MessageModes.Heal] = MessageSettings.status,
    [MessageModes.Exp] = MessageSettings.status,

    [MessageModes.DamageOthers] = MessageSettings.none,
    [MessageModes.HealOthers] = MessageSettings.none,
    [MessageModes.ExpOthers] = MessageSettings.none,
    [MessageModes.Potion] = MessageSettings.none,

    [MessageModes.TradeNpc] = MessageSettings.centerWhite,
    [MessageModes.Guild] = MessageSettings.centerWhite,
    [MessageModes.Party] = MessageSettings.centerGreen,
    [MessageModes.PartyManagement] = MessageSettings.centerWhite,
    [MessageModes.TutorialHint] = MessageSettings.centerWhite,
    [MessageModes.BeyondLast] = MessageSettings.centerWhite,
    [MessageModes.Report] = MessageSettings.consoleRed,
    [MessageModes.GameHighlight] = MessageSettings.centerRed,
    [MessageModes.HotkeyUse] = MessageSettings.centerGreen,
    [MessageModes.Attention] = MessageSettings.bottomWhite,
    [MessageModes.BoostedCreature] = MessageSettings.centerWhite,
    [MessageModes.Transaction] = MessageSettings.centerWhite,

    [254] = MessageSettings.private
}

messagesPanel = nil
local pendingLookItem = nil
local pendingLookEvent = nil
local pendingLookPosition = nil
local itemLookCard = nil
local itemLookClickCatcher = nil

local function capitalize(text)
    return (text:gsub('^%l', string.upper))
end

local function getItemName(item, description)
    local firstLine = description and description:match('([^\n]+)') or ''
    local describedName = firstLine:gsub('^You see%s+', ''):gsub('%.$', '')
    describedName = describedName:gsub('^%d+%s+', '')
    describedName = describedName:gsub('^[Aa]n?%s+', '')
    describedName = describedName:gsub('^[Tt]he%s+', '')
    describedName = describedName:gsub('%s+%b()$', '')
    if describedName ~= '' then
        return capitalize(describedName)
    end

    local thingType = g_things.getThingType(item:getId(), 0)
    local name = thingType and thingType:getName() or ''
    if name == '' then
        return tr('Item')
    end
    return capitalize(name)
end

local function buildItemTraits(item)
    local traits = {}
    if item:isContainer() then
        table.insert(traits, tr('Container'))
    end
    if item:isStackable() then
        table.insert(traits, tr('Stackable'))
    end
    if item:isUsable() then
        table.insert(traits, tr('Usable'))
    end
    if item:isPickupable() and not item:isNotMoveable() then
        table.insert(traits, tr('Moveable'))
    end
    return table.concat(traits, '  |  ')
end

local function isStaffLook(text)
    return g_game.isGM() or text:find('\nItem ID:%s*%d+') ~= nil or
        text:find('\nPosition:%s*%d+,%s*%d+,%s*%d+') ~= nil
end

local function clearPendingLook()
    pendingLookItem = nil
    pendingLookPosition = nil
    removeEvent(pendingLookEvent)
    pendingLookEvent = nil
end

function prepareItemLook(thing)
    clearPendingLook()
    if not thing or not thing:isItem() then
        return
    end

    local position = thing:getPosition()
    if not position or (position.x ~= 65535 and not thing:isPickupable()) then
        return
    end

    pendingLookItem = thing:clone()
    pendingLookPosition = g_window.getMousePosition()
    pendingLookEvent = scheduleEvent(clearPendingLook, 2500)
end

local function hideItemLookCard()
    if itemLookClickCatcher then
        itemLookClickCatcher:hide()
    end

    if not itemLookCard then
        return
    end
    removeEvent(itemLookCard.hideEvent)
    itemLookCard.hideEvent = nil
    g_effects.cancelFade(itemLookCard)
    itemLookCard:hide()
end

local function positionItemLookCard(mousePosition)
    local position = mousePosition or g_window.getMousePosition()
    local windowSize = g_window.getSize()
    local cardSize = itemLookCard:getSize()
    local spacing = 12
    local edge = 8

    local x = position.x + spacing
    local y = position.y + spacing
    if x + cardSize.width > windowSize.width - edge then
        x = position.x - cardSize.width - spacing
    end
    if y + cardSize.height > windowSize.height - edge then
        y = position.y - cardSize.height - spacing
    end

    position.x = math.max(edge, math.min(x, windowSize.width - cardSize.width - edge))
    position.y = math.max(edge, math.min(y, windowSize.height - cardSize.height - edge))
    itemLookCard:setPosition(position)
end

local function scheduleItemLookCardHide(visibleTime)
    removeEvent(itemLookCard.hideEvent)
    itemLookCard.hideEvent = scheduleEvent(function()
        if not itemLookCard or itemLookCard:isDestroyed() then
            return
        end
        g_effects.fadeOut(itemLookCard, 180)
        itemLookCard.hideEvent = scheduleEvent(function()
            if itemLookCard and not itemLookCard:isDestroyed() then
                itemLookCard:hide()
            end
            if itemLookClickCatcher and not itemLookClickCatcher:isDestroyed() then
                itemLookClickCatcher:hide()
            end
        end, 190)
    end, visibleTime)
end

local function displayItemLookCard(text)
    if not pendingLookItem or not itemLookCard then
        return false
    end

    local item = pendingLookItem
    local mousePosition = pendingLookPosition
    clearPendingLook()

    local sprite = itemLookCard:getChildById('itemLookSprite')
    local name = itemLookCard:getChildById('itemLookName')
    local quantity = itemLookCard:getChildById('itemLookQuantity')
    local staffIds = itemLookCard:getChildById('itemLookStaffIds')
    local traits = itemLookCard:getChildById('itemLookTraits')
    local separator = itemLookCard:getChildById('itemLookSeparator')
    local propertiesTitle = itemLookCard:getChildById('itemLookPropertiesTitle')
    local description = itemLookCard:getChildById('itemLookDescription')

    sprite:setItem(item)
    name:setText(getItemName(item, text))
    quantity:setVisible(item:isStackable())
    quantity:setText(item:isStackable() and string.format('%s: %d', tr('Quantity'), item:getCount()) or '')

    local isStaff = isStaffLook(text)
    local serverId = text:match('\nItem ID:%s*(%d+)') or '-'
    staffIds:setText(string.format('Client ID: %d\nServer ID: %s', item:getId(), serverId))
    local traitText = buildItemTraits(item)
    traits:setText(traitText)

    staffIds:setVisible(isStaff)
    traits:setVisible(isStaff and traitText ~= '')
    separator:setVisible(isStaff)
    propertiesTitle:setVisible(isStaff)
    description:setVisible(isStaff)

    if isStaff then
        local detailText = text:match('^[^\n]+\n(.+)$') or text:gsub('^You see%s+', '')
        detailText = detailText:gsub('Item ID:%s*%d+,?%s*', ''):gsub('^\n+', '')
        description:setText(detailText)
        description:setHeight(math.max(30, math.min(104, description:getTextSize().height)))
        itemLookCard:setHeight(171 + description:getHeight())
    else
        description:setText('')
        description:setHeight(0)
        itemLookCard:setHeight(76)
    end

    positionItemLookCard(mousePosition)

    removeEvent(itemLookCard.hideEvent)
    g_effects.cancelFade(itemLookCard)
    itemLookCard:setOpacity(1)
    itemLookCard:show()
    itemLookClickCatcher:show()
    itemLookClickCatcher:raise()
    itemLookCard:raise()
    g_effects.fadeIn(itemLookCard, 120)
    scheduleItemLookCardHide(math.max(6000, math.min(11000, calculateVisibleTime(text))))
    return true
end

function init()
    for messageMode, _ in pairs(MessageTypes) do
        registerMessageMode(messageMode, displayMessage)
    end

    connect(g_game, {
        onGameEnd = clearMessages,
        onLookRequest = prepareItemLook
    })
    messagesPanel = g_ui.loadUI('textmessage', modules.game_interface.getRootPanel())
    itemLookCard = messagesPanel:recursiveGetChildById('itemLookCard')
    itemLookCard:setParent(rootWidget)
    itemLookCard:breakAnchors()

    itemLookClickCatcher = g_ui.createWidget('Panel', rootWidget)
    itemLookClickCatcher:setId('itemLookClickCatcher')
    itemLookClickCatcher:fill('parent')
    itemLookClickCatcher:setPhantom(true)
    itemLookClickCatcher:setFocusable(false)
    itemLookClickCatcher.onMousePress = function()
        hideItemLookCard()
        return false
    end
    itemLookClickCatcher:hide()

    itemLookCard.onClick = hideItemLookCard
end

function terminate()
    for messageMode, _ in pairs(MessageTypes) do
        unregisterMessageMode(messageMode, displayMessage)
    end

    disconnect(g_game, {
        onGameEnd = clearMessages,
        onLookRequest = prepareItemLook
    })
    clearPendingLook()
    hideItemLookCard()
    clearMessages()
    itemLookClickCatcher:destroy()
    itemLookClickCatcher = nil
    itemLookCard:destroy()
    itemLookCard = nil
    messagesPanel:destroy()
    messagesPanel = nil
end

function calculateVisibleTime(text)
    return math.max(#text * 50, 4000)
end

function displayMessage(mode, text)
    if not g_game.isOnline() then
        return
    end

    local msgtype = MessageTypes[mode]
    if not msgtype then
        return
    end

    if msgtype == MessageSettings.none then
        return
    end

    if mode == MessageModes.Look then
        if displayItemLookCard(text) then
            return
        end
        if not isStaffLook(text) then
            return
        end
    end

    if msgtype.consoleTab ~= nil and
        (msgtype.consoleOption == nil or modules.client_options.getOption(msgtype.consoleOption)) then
        modules.game_console.addText(text, msgtype, tr(msgtype.consoleTab))
        -- TODO move to game_console
    end

    if msgtype.screenTarget then
        local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
        label:setText(text)
        label:setColor(msgtype.color)
        label:setVisible(true)
        removeEvent(label.hideEvent)
        label.hideEvent = scheduleEvent(function()
            label:setVisible(false)
        end, calculateVisibleTime(text))
    end
end

function displayPrivateMessage(text)
    displayMessage(254, text)
end

function displayStatusMessage(text)
    displayMessage(MessageModes.Status, text)
end

function displayFailureMessage(text)
    displayMessage(MessageModes.Failure, text)
end

function displayGameMessage(text)
    displayMessage(MessageModes.Game, text)
end

function displayBroadcastMessage(text)
    displayMessage(MessageModes.Warning, text)
end

function clearMessages()
    clearPendingLook()
    hideItemLookCard()
    for _i, child in pairs(messagesPanel:recursiveGetChildren()) do
        if child:getId():match('Label') then
            child:hide()
            removeEvent(child.hideEvent)
        end
    end
end

function LocalPlayer:onAutoWalkFail(player)
    modules.game_textmessage.displayFailureMessage(tr('There is no way.'))
end
