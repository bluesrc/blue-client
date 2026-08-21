local ITEM = 1
local POKEMON = 2

local BOX_OPCODE = 73
local BOX_CONTAINER_ID = 15
local ITEM_BOX_COUNT = 5
local TOTAL_BOX_COUNT = 17

local boxWindow
local partyPanel
local selectorPanel
local contentsPanel
local pagePanel
local pageLabel
local categoryLabel
local protectionZoneIcon
local itemTab
local pokemonTab
local radioTabs
local selectedType = ITEM
local selectedDepotId = 0
local selectedButton
local currentContainer
local suppressBoxRequest = false

local function toggleFromHotkey()
    if modules.game_console and modules.game_console.isChatEnabled() then
        return
    end

    toggle()
end

function init()
    boxWindow = g_ui.displayUI('box')
    boxWindow:setVisible(false)

    partyPanel = boxWindow:recursiveGetChildById('partyPanel')
    selectorPanel = boxWindow:recursiveGetChildById('selectorPanel')
    contentsPanel = boxWindow:recursiveGetChildById('contentsPanel')
    pagePanel = boxWindow:recursiveGetChildById('pagePanel')
    pageLabel = boxWindow:recursiveGetChildById('pageLabel')
    categoryLabel = boxWindow:recursiveGetChildById('categoryLabel')
    protectionZoneIcon = boxWindow:recursiveGetChildById('protectionZoneIcon')
    itemTab = boxWindow:getChildById('itemTab')
    pokemonTab = boxWindow:getChildById('pokemonTab')

    radioTabs = UIRadioGroup.create()
    radioTabs:addWidget(itemTab)
    radioTabs:addWidget(pokemonTab)
    radioTabs.onSelectionChange = onBoxTypeChange
    radioTabs:selectWidget(itemTab)

    connect(g_game, {
        onGameStart = refreshParty,
        onGameEnd = offline
    })

    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange
    })

    connect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChangeSize,
        onUpdateItem = onContainerUpdateItem
    })

    g_keyboard.bindKeyDown('B', toggleFromHotkey)
    buildBoxSelectors()
    refreshParty()
end

function terminate()
    g_keyboard.unbindKeyDown('B')

    disconnect(g_game, {
        onGameStart = refreshParty,
        onGameEnd = offline
    })

    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange
    })

    disconnect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChangeSize,
        onUpdateItem = onContainerUpdateItem
    })

    if currentContainer and g_game.isOnline() then
        g_game.close(currentContainer)
    end

    radioTabs:destroy()
    boxWindow:destroy()

    currentContainer = nil
    selectedButton = nil
    radioTabs = nil
    boxWindow = nil
end

function show(requestBox)
    if not g_game.isOnline() then
        return
    end

    boxWindow:show()
    boxWindow:raise()
    boxWindow:focus()
    refreshParty()
    if requestBox ~= false then
        requestSelectedBox()
    end
end

function hide()
    if currentContainer and g_game.isOnline() then
        g_game.close(currentContainer)
    end

    currentContainer = nil
    clearContents()
    boxWindow:hide()
end

function toggle()
    if boxWindow:isVisible() then
        hide()
    else
        show()
    end
end

function closeBox()
    hide()
end

function showFromDepot()
    if not boxWindow:isVisible() then
        suppressBoxRequest = true
        if selectedType == ITEM then
            buildBoxSelectors()
        else
            radioTabs:selectWidget(itemTab)
        end
        suppressBoxRequest = false
        show(false)
    end
end

function offline()
    currentContainer = nil
    clearContents()
    boxWindow:hide()
end

function onBoxTypeChange(_, selected, deselected)
    if deselected then
        deselected:setOn(false)
    end
    selected:setOn(true)

    selectedType = selected == pokemonTab and POKEMON or ITEM
    buildBoxSelectors()

    if boxWindow:isVisible() and not suppressBoxRequest then
        requestSelectedBox()
    end
end

function buildBoxSelectors()
    selectorPanel:destroyChildren()
    selectedButton = nil

    local firstDepotId = selectedType == ITEM and 0 or ITEM_BOX_COUNT
    local count = selectedType == ITEM and ITEM_BOX_COUNT or TOTAL_BOX_COUNT - ITEM_BOX_COUNT

    categoryLabel:setText(selectedType == ITEM and tr('Item boxes') or tr('Pokemon boxes'))

    for index = 1, count do
        local button = g_ui.createWidget('BoxSelectorButton', selectorPanel)
        button:setId('box' .. index)
        button:setText(tostring(index))
        button.depotId = firstDepotId + index - 1

        button:addAnchor(AnchorTop, 'parent', AnchorTop)
        if index == 1 then
            button:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        else
            button:addAnchor(AnchorLeft, 'prev', AnchorRight)
            button:setMarginLeft(4)
        end

        button.onClick = function(widget)
            selectBox(widget)
        end

        if index == 1 then
            selectBox(button, true)
        end
    end
end

function selectBox(button, skipRequest)
    if selectedButton then
        selectedButton:setOn(false)
    end

    selectedButton = button
    selectedButton:setOn(true)
    selectedDepotId = button.depotId

    if not skipRequest and boxWindow:isVisible() then
        requestSelectedBox()
    end
end

function requestSelectedBox()
    if not g_game.isOnline() then
        return
    end

    contentsPanel:destroyChildren()
    pagePanel:setVisible(false)

    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(BOX_OPCODE, tostring(selectedDepotId))
    end
end

function handlesContainer(container)
    return container and container:getId() == BOX_CONTAINER_ID
end

function onContainerOpen(container, previousContainer)
    if not handlesContainer(container) then
        return false
    end

    if modules.game_playertrade and modules.game_playertrade.handlesSourceContainer(container, previousContainer) then
        currentContainer = nil
        clearContents()
        boxWindow:hide()
        return true
    end

    showFromDepot()
    currentContainer = container
    refreshContainerItems()
    return true
end

function onContainerClose(container)
    if not handlesContainer(container) then
        return false
    end

    if currentContainer == container then
        currentContainer = nil
        clearContents()
    end
    return true
end

function onContainerChangeSize(container, _)
    if not handlesContainer(container) then
        return false
    end

    if currentContainer == container then
        refreshContainerItems()
    end
    return true
end

function onContainerUpdateItem(container, _, _, _)
    if not handlesContainer(container) then
        return false
    end

    if currentContainer == container then
        refreshContainerItems()
    end
    return true
end

function refreshContainerItems()
    if not currentContainer then
        clearContents()
        return
    end

    contentsPanel:destroyChildren()

    for slot = 0, currentContainer:getCapacity() - 1 do
        local itemWidget = g_ui.createWidget('BoxItemSlot', contentsPanel)
        itemWidget:setId('item' .. slot)
        itemWidget:setItem(currentContainer:getItem(slot))
        itemWidget.position = currentContainer:getSlotPosition(slot)

        itemWidget.onDrop = function(self, widget, mousePos)
            local accepted = UIItem.onDrop(self, widget, mousePos)
            g_dispatcher.scheduleEvent(function()
                if self and not self:isDestroyed() then
                    self:setBorderWidth(0)
                end
            end, 1)
            return accepted
        end

        itemWidget.onDragLeave = function(self, droppedWidget, mousePos)
            local accepted = UIItem.onDragLeave(self, droppedWidget, mousePos)
            self:setBorderWidth(0)
            return accepted
        end

    end

    protectionZoneIcon:setVisible(currentContainer:isUnlocked())

    refreshContainerPages()
end

function refreshContainerPages()
    if not currentContainer or not currentContainer:hasPages() then
        pagePanel:setVisible(false)
        return
    end

    pagePanel:setVisible(true)

    local capacity = currentContainer:getCapacity()
    local currentPage = 1 + math.floor(currentContainer:getFirstIndex() / capacity)
    local pages = 1 + math.floor(math.max(0, currentContainer:getSize() - 1) / capacity)
    pageLabel:setText(string.format(tr('Page %i of %i'), currentPage, pages))

end

function clearContents()
    if not contentsPanel then
        return
    end

    contentsPanel:destroyChildren()
    pagePanel:setVisible(false)
    protectionZoneIcon:setVisible(false)
end

function refreshParty()
    local player = g_game.getLocalPlayer()
    for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local itemWidget = partyPanel:recursiveGetChildById('slot' .. slot)
        itemWidget:setItem(player and player:getInventoryItem(slot) or nil)
    end
end

function onInventoryChange(_, slot, item, _)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    local itemWidget = partyPanel:recursiveGetChildById('slot' .. slot)
    itemWidget:setItem(item)
end
