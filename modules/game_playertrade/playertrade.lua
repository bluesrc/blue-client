local TRADE_OPCODE = 74
local BOX_OPCODE = 73
local BACKPACK_OPCODE = 75
local BACKPACK_CONTAINER_ID = 14
local BOX_CONTAINER_ID = 15
local ITEM_SLOT_COUNT = 50
local SOURCE_SLOT_COUNT = 50
local SOURCE_COLUMN_COUNT = 4
local SOURCE_CELL_HEIGHT = 28
local ITEM_BOX_COUNT = 5

tradeWindow = nil

local ownItems = {}
local counterItems = {}
local ownName = ''
local counterName = ''
local ownConfirmed = false
local counterConfirmed = false
local ownAccepted = false
local counterAccepted = false
local ownMoney = '0'
local counterMoney = '0'
local ownBalance = '0'
local updatingMoney = false
local tradeCountWindow

local sourceContainer
local sourceMode = 'bag'
local selectedSourceButton
local expectedSourceContainerId
local inviteWindow
local invitePlayerId
local closingTradeWindow = false

local function sendExtendedOpcode(opcode, buffer)
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(opcode, buffer)
    end
end

local function sendTradeAction(buffer)
    sendExtendedOpcode(TRADE_OPCODE, buffer)
end

local function splitFields(buffer)
    local fields = {}
    for value in (buffer .. ';'):gmatch('(.-);') do
        table.insert(fields, value)
    end
    return fields
end

local function formatMoney(value)
    value = tostring(value or '0'):gsub('^0+(%d)', '%1')
    local formatted = value:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return formatted:gsub('^%.', '')
end

local function sendItemToOffer(item, count)
    if not item or ownConfirmed then
        return false
    end

    local position = item:getPosition()
    if not position then
        return false
    end

    sendTradeAction(string.format('A;%d;%d;%d;%d;%d;%d', position.x, position.y, position.z,
        item:getStackPos(), item:getId(), count))
    return true
end

local function closeTradeCountWindow()
    if tradeCountWindow then
        tradeCountWindow:destroy()
        tradeCountWindow = nil
    end
end

local function chooseTradeItemCount(item)
    closeTradeCountWindow()

    local maximum = item:getCount()
    tradeCountWindow = g_ui.createWidget('CountWindow', rootWidget)
    tradeCountWindow:setText(tr('Trade item amount'))

    local itemBox = tradeCountWindow:getChildById('item')
    local scrollBar = tradeCountWindow:getChildById('countScrollBar')
    local spinBox = tradeCountWindow:getChildById('spinBox')
    local okButton = tradeCountWindow:getChildById('buttonOk')
    local cancelButton = tradeCountWindow:getChildById('buttonCancel')
	tradeCountWindow.onClose = function()
		tradeCountWindow = nil
	end

    itemBox:setItemId(item:getId())
    itemBox:setItemCount(maximum)
    scrollBar:setMinimum(1)
    scrollBar:setMaximum(maximum)
    scrollBar:setValue(maximum)
    spinBox:setMinimum(1)
    spinBox:setMaximum(maximum)
    spinBox:setValue(maximum)
    spinBox:hideButtons()
    spinBox:focus()

    local updatingCount = false
    scrollBar.onValueChange = function(_, value)
        if updatingCount then return end
        updatingCount = true
        itemBox:setItemCount(value)
        spinBox:setValue(value)
        updatingCount = false
    end
    spinBox.onValueChange = function(_, value)
        if updatingCount then return end
        updatingCount = true
        itemBox:setItemCount(value)
        scrollBar:setValue(value)
        updatingCount = false
    end

    local acceptCount = function()
        local count = math.max(1, math.min(maximum, spinBox:getValue()))
        closeTradeCountWindow()
        sendItemToOffer(item, count)
        return true
    end
    local cancelCount = function()
        closeTradeCountWindow()
        return true
    end

    tradeCountWindow.onEnter = acceptCount
    tradeCountWindow.onEscape = cancelCount
    okButton.onClick = acceptCount
    cancelButton.onClick = cancelCount
end

local function addItemToOffer(item)
    if not item or ownConfirmed then
        return false
    end
    if item:isStackable() and item:getCount() > 1 then
        chooseTradeItemCount(item)
        return true
    end
    return sendItemToOffer(item, 1)
end

function onTradeSlotDrop(_, widget, _)
    if not widget or not widget.currentDragThing then
        return false
    end
    return addItemToOffer(widget.currentDragThing)
end

local function clearItemSlot(slot, acceptsDrop)
    slot:setItem(nil)
    slot:setVirtual(false)
    slot.offerIndex = nil
    slot.position = nil
    slot:setBorderWidth(1)
    slot:setBorderColor('#4a5563')
    slot.onClick = nil
    slot.onDoubleClick = nil
    slot.onDrop = acceptsDrop and onTradeSlotDrop or nil
end

local function refreshOfferItems(items, panelId, counter)
    if not tradeWindow then
        return
    end

    local panel = tradeWindow:recursiveGetChildById(panelId)
    for visibleIndex = 1, ITEM_SLOT_COUNT do
        local slot = panel:getChildById((counter and 'counterItem' or 'ownItem') .. visibleIndex)
        local item = items[visibleIndex]
        if item then
            local selectedIndex = visibleIndex
            slot:setItem(item)
            slot:setVirtual(true)
            slot.offerIndex = selectedIndex
            slot.onDrop = not counter and onTradeSlotDrop or nil
            slot.onClick = function()
                g_game.inspectTrade(counter, selectedIndex - 1)
            end
            if not counter then
                slot.onDoubleClick = function()
                    if not ownConfirmed then
                        sendTradeAction('R;' .. (selectedIndex - 1))
                    end
                    return true
                end
            end
        else
            clearItemSlot(slot, not counter)
        end
    end
end

local function updateSourceButton(button)
    if selectedSourceButton then
        selectedSourceButton:setOn(false)
    end
    selectedSourceButton = button
    if selectedSourceButton then
        selectedSourceButton:setOn(true)
    end
end

local function getSourcePageInfo()
    if not sourceContainer or sourceMode ~= 'box' then
        return nil
    end

    local capacity = sourceContainer:getCapacity()
    if not capacity or capacity <= 0 then
        return nil
    end

    local size = math.max(0, sourceContainer:getSize())
    local firstIndex = math.max(0, sourceContainer:getFirstIndex())
    local pages = math.max(1, math.ceil(size / capacity))
    local currentPage = math.min(pages, 1 + math.floor(firstIndex / capacity))

    return {
        capacity = capacity,
        size = size,
        firstIndex = firstIndex,
        pages = pages,
        currentPage = currentPage
    }
end

local function updateSourceLayout(slotCount)
    if not tradeWindow then
        return
    end

    slotCount = math.max(0, math.min(SOURCE_SLOT_COUNT, slotCount or 0))
    local rows = slotCount > 0 and math.ceil(slotCount / SOURCE_COLUMN_COUNT) or 0
    local gridHeight = rows * SOURCE_CELL_HEIGHT
    local showPages = sourceContainer ~= nil and sourceMode == 'box'
    local sourceFrame = tradeWindow:recursiveGetChildById('sourceFrame')
    local itemsFrame = tradeWindow:recursiveGetChildById('sourceItemsFrame')
    local itemsPanel = tradeWindow:recursiveGetChildById('sourceItems')
    local previousButton = tradeWindow:recursiveGetChildById('sourcePreviousPage')
    local nextButton = tradeWindow:recursiveGetChildById('sourceNextPage')
    local pageLabel = tradeWindow:recursiveGetChildById('sourcePage')

    itemsFrame:setHeight(gridHeight)
    itemsPanel:setHeight(gridHeight)
    previousButton:setVisible(showPages)
    nextButton:setVisible(showPages)
    pageLabel:setVisible(showPages)
    sourceFrame:setHeight(math.max(140, 8 + gridHeight + (showPages and 27 or 0)))
end

local function refreshSourcePages()
    if not tradeWindow then
        return
    end

    local previousButton = tradeWindow:recursiveGetChildById('sourcePreviousPage')
    local nextButton = tradeWindow:recursiveGetChildById('sourceNextPage')
    local pageLabel = tradeWindow:recursiveGetChildById('sourcePage')

    local pageInfo = getSourcePageInfo()
    if not pageInfo then
        previousButton:setEnabled(false)
        nextButton:setEnabled(false)
        pageLabel:setText('')
        return
    end

    pageLabel:setText(string.format('Page %i of %i', pageInfo.currentPage, pageInfo.pages))
    previousButton:setEnabled(pageInfo.currentPage > 1)
    nextButton:setEnabled(pageInfo.currentPage < pageInfo.pages)
end

local function refreshSourceItems()
    if not tradeWindow then
        return
    end

	local panel = tradeWindow:recursiveGetChildById('sourceItems')

	if not sourceContainer then
        for slotIndex = 1, SOURCE_SLOT_COUNT do
            local slot = panel:getChildById('sourceItem' .. slotIndex)
            clearItemSlot(slot, false)
            slot:setVisible(false)
        end
        updateSourceLayout(0)
        refreshSourcePages()
        return
    end

    local visibleSlotCount = math.min(SOURCE_SLOT_COUNT, sourceContainer:getCapacity())
    updateSourceLayout(visibleSlotCount)

    for slotIndex = 1, SOURCE_SLOT_COUNT do
        local slot = panel:getChildById('sourceItem' .. slotIndex)
        local containerIndex = slotIndex - 1
        local visible = slotIndex <= visibleSlotCount
        local item = visible and sourceContainer:getItem(containerIndex) or nil
        clearItemSlot(slot, false)
        slot:setVisible(visible)
        if item then
            slot:setItem(item)
            slot.position = sourceContainer:getSlotPosition(containerIndex)
            slot.onDoubleClick = function()
                if item:isContainer() then
                    g_game.open(item, sourceContainer)
                else
                    addItemToOffer(item)
                end
                return true
            end
        end
    end

    refreshSourcePages()
end

local function adoptSourceContainer(container, previousContainer)
    if not tradeWindow or not container then
        return false
    end

	local isCurrentNavigation = previousContainer and sourceContainer and previousContainer == sourceContainer
	local isExpectedContainer = expectedSourceContainerId ~= nil and container:getId() == expectedSourceContainerId
	local isInitialBackpack = sourceMode == 'bag' and container:getId() == BACKPACK_CONTAINER_ID
	if not isCurrentNavigation and not isExpectedContainer and not isInitialBackpack then
		return false
	end

	sourceContainer = container
	expectedSourceContainerId = container:getId()
	refreshSourceItems()
	return true
end

function isTradeOpen()
    return tradeWindow ~= nil
end

function handlesSourceContainer(container, previousContainer)
    local handled = adoptSourceContainer(container, previousContainer)
    if handled and container.window and modules.game_containers then
        modules.game_containers.destroy(container)
    end
    return handled
end

function openBackpackSource(button)
    if not g_game.isOnline() then
        return
    end

    local bagButton = button or (tradeWindow and tradeWindow:recursiveGetChildById('bagSourceButton'))
    if sourceContainer and sourceMode == 'bag' and not sourceContainer:hasParent() then
		updateSourceButton(bagButton)
		refreshSourceItems()
		return
    end
    if sourceContainer then
        g_game.close(sourceContainer)
    end
	sourceMode = 'bag'
	sourceContainer = nil
	expectedSourceContainerId = nil
	updateSourceButton(bagButton)

	expectedSourceContainerId = BACKPACK_CONTAINER_ID
	refreshSourceItems()
	sendExtendedOpcode(BACKPACK_OPCODE, 'O')
end

function openBoxSource(depotId, button)
    if not g_game.isOnline() or depotId < 0 or depotId >= ITEM_BOX_COUNT then
        return
    end

	if sourceContainer then
		g_game.close(sourceContainer)
	end
	sourceMode = 'box'
	sourceContainer = nil
	expectedSourceContainerId = BOX_CONTAINER_ID
    updateSourceButton(button)
    refreshSourceItems()
    sendExtendedOpcode(BOX_OPCODE, tostring(depotId))
end

function sourcePreviousPage()
    local pageInfo = getSourcePageInfo()
    if pageInfo and pageInfo.currentPage > 1 then
        g_game.seekInContainer(sourceContainer:getId(), math.max(0, pageInfo.firstIndex - pageInfo.capacity))
    end
end

function sourceNextPage()
    local pageInfo = getSourcePageInfo()
    if pageInfo and pageInfo.currentPage < pageInfo.pages then
        g_game.seekInContainer(sourceContainer:getId(), pageInfo.firstIndex + pageInfo.capacity)
    end
end

local function createTrade()
    if tradeWindow then
        return
    end

    tradeWindow = g_ui.createWidget('TradeWindow', rootWidget)
	tradeWindow.onClose = function()
		if not closingTradeWindow then
			rejectOffer()
		end
	end

    local ownGrid = tradeWindow:recursiveGetChildById('ownItems')
    local counterGrid = tradeWindow:recursiveGetChildById('counterItems')
    local sourceGrid = tradeWindow:recursiveGetChildById('sourceItems')
    for index = 1, ITEM_SLOT_COUNT do
        local ownSlot = g_ui.createWidget('TradeItemSlot', ownGrid)
        ownSlot:setId('ownItem' .. index)
        ownSlot.onDrop = onTradeSlotDrop

        local counterSlot = g_ui.createWidget('TradeItemSlot', counterGrid)
        counterSlot:setId('counterItem' .. index)

        local sourceSlot = g_ui.createWidget('TradeSourceSlot', sourceGrid)
        sourceSlot:setId('sourceItem' .. index)
    end

    tradeWindow:show()
    tradeWindow:raise()
    tradeWindow:focus()
    sourceMode = 'bag'
    sourceContainer = nil
    expectedSourceContainerId = BACKPACK_CONTAINER_ID
    updateSourceButton(tradeWindow:recursiveGetChildById('bagSourceButton'))

    local initialBackpack = g_game.getContainer(BACKPACK_CONTAINER_ID)
    if initialBackpack then
        handlesSourceContainer(initialBackpack, nil)
    else
        refreshSourceItems()
    end
end

local function refreshState()
    if not tradeWindow then
        return
    end

    local ownSide = tradeWindow:recursiveGetChildById('ownSide')
    local counterSide = tradeWindow:recursiveGetChildById('counterSide')
    ownSide:setBorderWidth(ownConfirmed and 2 or 1)
    ownSide:setBorderColor(ownConfirmed and '#e5b93f' or '#4a5563')
    counterSide:setBorderWidth(counterConfirmed and 2 or 1)
    counterSide:setBorderColor(counterConfirmed and '#e5b93f' or '#4a5563')

    tradeWindow:recursiveGetChildById('ownStatus'):setText(ownConfirmed and tr('Items confirmed') or tr('Editing offer'))
    tradeWindow:recursiveGetChildById('counterStatus'):setText(counterConfirmed and tr('Items confirmed') or tr('Editing offer'))
    tradeWindow:recursiveGetChildById('ownName'):setText(ownName)
    tradeWindow:recursiveGetChildById('counterName'):setText(counterName)
    tradeWindow:recursiveGetChildById('ownBalance'):setText(tr('Your balance: %s', formatMoney(ownBalance)))
    tradeWindow:recursiveGetChildById('counterMoney'):setText(tr('Amount offered: %s', formatMoney(counterMoney)))

    local moneyInput = tradeWindow:recursiveGetChildById('moneyInput')
    updatingMoney = true
    if moneyInput:getText() ~= ownMoney then
        moneyInput:setText(ownMoney)
    end
    updatingMoney = false
    moneyInput:setEnabled(not ownConfirmed)

    local confirmButton = tradeWindow:recursiveGetChildById('confirmButton')
    confirmButton:setEnabled(not ownConfirmed)
    confirmButton:setText(ownConfirmed and tr('Confirmed') or tr('Confirm items'))

    local acceptButton = tradeWindow:recursiveGetChildById('acceptButton')
    acceptButton:setVisible(ownConfirmed and counterConfirmed)
    acceptButton:setEnabled(ownConfirmed and counterConfirmed and not ownAccepted)
    acceptButton:setText(ownAccepted and tr('Waiting for player') or tr('Accept trade'))

    refreshOfferItems(ownItems, 'ownItems', false)
    refreshOfferItems(counterItems, 'counterItems', true)
    refreshSourceItems()
end

function onMoneyChange(text)
    if updatingMoney or ownConfirmed then
        return
    end

    local digits = text:gsub('[^0-9]', '')
    if digits == '' then
        digits = '0'
    end
    digits = digits:gsub('^0+(%d)', '%1')

    local input = tradeWindow and tradeWindow:recursiveGetChildById('moneyInput')
    if input and input:getText() ~= digits then
        updatingMoney = true
        input:setText(digits)
        updatingMoney = false
    end

    sendTradeAction('M;' .. digits)
end

function confirmOffer()
	if tradeWindow and not ownConfirmed then
		local input = tradeWindow:recursiveGetChildById('moneyInput')
		local amount = input and input:getText():gsub('[^0-9]', '') or '0'
		if amount == '' then amount = '0' end
		sendTradeAction('C;' .. amount)
	end
end

function acceptOffer()
	if tradeWindow and ownConfirmed and counterConfirmed and not ownAccepted then
		sendTradeAction('T')
	end
end

function rejectOffer()
	sendTradeAction('X')
end

function requestTrade(creature)
	if not creature or not creature:isPlayer() or creature:isLocalPlayer() then
		return
	end
	sendTradeAction('I;' .. creature:getId())
end

local function closeInviteWindow()
	if inviteWindow then
		inviteWindow:destroy()
		inviteWindow = nil
	end
	invitePlayerId = nil
end

local function answerTradeInvite(accept)
	local playerId = invitePlayerId
	closeInviteWindow()
	if playerId then
		sendTradeAction((accept and 'Y;' or 'N;') .. playerId)
	end
	return true

end

local function showTradeInvite(playerId, playerName)
	closeInviteWindow()
	invitePlayerId = playerId
	inviteWindow = displayGeneralBox(tr('Trade invitation'),
		tr('%s wants to trade with you.', playerName), {{
			text = tr('Accept'),
			callback = function() answerTradeInvite(true) end
		}, {
			text = tr('Reject'),
			callback = function() answerTradeInvite(false) end
		}}, function() answerTradeInvite(true) end, function() answerTradeInvite(false) end)
end

function onTradeExtendedOpcode(_, _, buffer)
	local fields = splitFields(buffer)
	if fields[1] == 'Q' and #fields >= 3 then
		local playerId = tonumber(fields[2])
		if playerId then
			showTradeInvite(playerId, fields[3])
		end
		return
	end
	if fields[1] ~= 'S' or #fields < 8 then
		return
	end
	closeInviteWindow()

    ownConfirmed = fields[2] == '1'
    counterConfirmed = fields[3] == '1'
    ownAccepted = fields[4] == '1'
    counterAccepted = fields[5] == '1'
    ownMoney = fields[6] ~= '' and fields[6] or '0'
    counterMoney = fields[7] ~= '' and fields[7] or '0'
    ownBalance = fields[8] ~= '' and fields[8] or '0'
    createTrade()
    refreshState()
end

function onContainerOpen(container, previousContainer)
    adoptSourceContainer(container, previousContainer)
end

function onContainerClose(container)
    if sourceContainer == container then
		sourceContainer = nil
		expectedSourceContainerId = nil
        refreshSourceItems()
    end
end

function onContainerChange(container)
    if sourceContainer == container then
        refreshSourceItems()
    end
end

function init()
    g_ui.importStyle('tradewindow')
    ProtocolGame.registerExtendedOpcode(TRADE_OPCODE, onTradeExtendedOpcode)

    connect(g_game, {
        onOwnTrade = onGameOwnTrade,
        onCounterTrade = onGameCounterTrade,
        onCloseTrade = onGameCloseTrade,
        onGameEnd = onGameCloseTrade
    })
	connect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChange,
        onUpdateItem = onContainerChange
    })
end

function terminate()
    ProtocolGame.unregisterExtendedOpcode(TRADE_OPCODE)
    disconnect(g_game, {
        onOwnTrade = onGameOwnTrade,
        onCounterTrade = onGameCounterTrade,
        onCloseTrade = onGameCloseTrade,
        onGameEnd = onGameCloseTrade
    })
	disconnect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChange,
        onUpdateItem = onContainerChange
    })
    onGameCloseTrade()
end

function onGameOwnTrade(name, items)
    ownName = name
    ownItems = items
    createTrade()
    refreshState()
end

function onGameCounterTrade(name, items)
    counterName = name
    counterItems = items
    createTrade()
    refreshState()
end

function onGameCloseTrade()
    closeTradeCountWindow()
    sourceContainer = nil
    expectedSourceContainerId = nil
    selectedSourceButton = nil
    sourceMode = 'bag'

	if tradeWindow then
		closingTradeWindow = true
		tradeWindow:destroy()
		tradeWindow = nil
		closingTradeWindow = false
	end
	closeInviteWindow()

    ownItems = {}
    counterItems = {}
    ownName = ''
    counterName = ''
    ownConfirmed = false
    counterConfirmed = false
    ownAccepted = false
    counterAccepted = false
    ownMoney = '0'
    counterMoney = '0'
    ownBalance = '0'
end
