local ITEM = 1
local POKEMON = 2

local BOX_OPCODE = 73
local BACKPACK_OPCODE = 75
local BACKPACK_CONTAINER_ID = 14
local BOX_CONTAINER_ID = 15
local ITEM_BOX_COUNT = 5
local TOTAL_BOX_COUNT = 17
local NORMAL_BOX_WIDTH = 800
local NORMAL_BOX_HEIGHT = 570
local POKEMON_DETAILS_WIDTH = 620
local POKEMON_DETAILS_HEIGHT = 630

local boxWindow
local sidePanel
local inventoryPanel
local inventoryItemsPanel
local inventoryUpButton
local inventoryName
local partyPanel
local pokemonDetailsHost
local pokemonDetailsContent
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
local inventoryContainer
local suppressBoxRequest = false
local selectedBoxSlot
local selectedPartySlot

local function toggleFromHotkey()
    if modules.game_console and modules.game_console.isChatEnabled() then
        return
    end

    toggle()
end

function init()
    boxWindow = g_ui.displayUI('box')
    boxWindow:setVisible(false)

    sidePanel = boxWindow:recursiveGetChildById('sidePanel')
    inventoryPanel = boxWindow:recursiveGetChildById('inventoryPanel')
    inventoryItemsPanel = boxWindow:recursiveGetChildById('inventoryItems')
    inventoryUpButton = boxWindow:recursiveGetChildById('inventoryUpButton')
    inventoryName = boxWindow:recursiveGetChildById('inventoryName')
    partyPanel = boxWindow:recursiveGetChildById('partyPanel')
    pokemonDetailsHost = boxWindow:recursiveGetChildById('pokemonDetailsHost')
    pokemonDetailsContent = boxWindow:recursiveGetChildById('pokemonDetailsContent')
    selectorPanel = boxWindow:recursiveGetChildById('selectorPanel')
    contentsPanel = boxWindow:recursiveGetChildById('contentsPanel')
    pagePanel = boxWindow:recursiveGetChildById('pagePanel')
    pageLabel = boxWindow:recursiveGetChildById('pageLabel')
    categoryLabel = boxWindow:recursiveGetChildById('categoryLabel')
    protectionZoneIcon = boxWindow:recursiveGetChildById('protectionZoneIcon')
    itemTab = boxWindow:recursiveGetChildById('itemTab')
    pokemonTab = boxWindow:recursiveGetChildById('pokemonTab')

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

local function clearInventoryItems()
    if inventoryItemsPanel then
        inventoryItemsPanel:destroyChildren()
        inventoryItemsPanel:setHeight(0)
    end
    if inventoryUpButton then
        inventoryUpButton:setVisible(false)
    end
    if inventoryName then
        inventoryName:setText('')
    end
end

local function closeInventory()
    local container = inventoryContainer
    inventoryContainer = nil
    clearInventoryItems()
    if container and g_game.isOnline() then
        g_game.close(container)
    end
end

local function resizeForPokemonDetails(visible)
    if not boxWindow then
        return
    end

    local oldCenter = boxWindow:getX() + math.floor(boxWindow:getWidth() / 2)
    local oldVerticalCenter = boxWindow:getY() + math.floor(boxWindow:getHeight() / 2)
    local targetWidth = NORMAL_BOX_WIDTH + (visible and POKEMON_DETAILS_WIDTH or 0)
    local rootWidth = rootWidget:getWidth()
    local rootHeight = rootWidget:getHeight()
    local targetHeight = visible and POKEMON_DETAILS_HEIGHT or NORMAL_BOX_HEIGHT
    targetWidth = math.min(targetWidth, rootWidth)
    targetHeight = math.min(targetHeight, rootHeight)
    pokemonDetailsHost:setWidth(visible and POKEMON_DETAILS_WIDTH or 0)
    pokemonDetailsHost:setVisible(visible)
    boxWindow:setWidth(targetWidth)
    boxWindow:setHeight(targetHeight)
    boxWindow:setX(math.max(0, math.min(oldCenter - math.floor(targetWidth / 2), rootWidth - targetWidth)))
    boxWindow:setY(math.max(0, math.min(oldVerticalCenter - math.floor(targetHeight / 2), rootHeight - targetHeight)))
end

function getPokemonDetailsHost()
    return pokemonDetailsContent
end

function showPokemonDetails()
    if selectedType == POKEMON and (selectedBoxSlot or selectedPartySlot) then
        resizeForPokemonDetails(true)
    end
end

function closePokemonDetails()
    selectedBoxSlot = nil
    selectedPartySlot = nil
    if contentsPanel then
        for _, child in ipairs(contentsPanel:getChildren()) do
            child:setOn(false)
            child:setBorderWidth(0)
            child:setBorderColor('#4a5563')
        end
    end
    if partyPanel then
        for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
            local itemWidget = partyPanel:recursiveGetChildById('slot' .. slot)
            if itemWidget then
                itemWidget:setOn(false)
            end
        end
    end
    resizeForPokemonDetails(false)
end

function deselectPokemon()
    if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
        modules.game_pokebag.hideBoxPokemon()
    end
    closePokemonDetails()
end

function requestInventory()
    if selectedType ~= ITEM or not boxWindow:isVisible() or not g_game.isOnline() then
        return
    end
    if modules.game_playertrade and modules.game_playertrade.isTradeOpen and
        modules.game_playertrade.isTradeOpen() then
        return
    end

    local existing = g_game.getContainer(BACKPACK_CONTAINER_ID)
    if existing then
        inventoryContainer = existing
        if existing.window and modules.game_containers then
            modules.game_containers.destroy(existing)
        end
        refreshInventoryItems()
        return
    end

    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(BACKPACK_OPCODE, 'B')
    end
end

function openInventoryParent()
    if inventoryContainer and inventoryContainer:hasParent() then
        g_game.openParent(inventoryContainer)
    end
end

function terminate()
    if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
        modules.game_pokebag.hideBoxPokemon()
    end
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
    if inventoryContainer and g_game.isOnline() then
        g_game.close(inventoryContainer)
    end

    radioTabs:destroy()
    boxWindow:destroy()

    currentContainer = nil
    inventoryContainer = nil
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
    if selectedType == ITEM then
        requestInventory()
    end
end

function hide()
    if currentContainer and g_game.isOnline() then
        g_game.close(currentContainer)
    end

    currentContainer = nil
    if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
        modules.game_pokebag.hideBoxPokemon()
    end
    closePokemonDetails()
    closeInventory()
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
    inventoryContainer = nil
    if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
        modules.game_pokebag.hideBoxPokemon()
    end
    closePokemonDetails()
    clearInventoryItems()
    clearContents()
    boxWindow:hide()
end

function onBoxTypeChange(_, selected, deselected)
    if deselected then
        deselected:setOn(false)
    end
    selected:setOn(true)

    selectedType = selected == pokemonTab and POKEMON or ITEM
    if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
        modules.game_pokebag.hideBoxPokemon()
    end
    closePokemonDetails()
    inventoryPanel:setVisible(selectedType == ITEM)
    partyPanel:setVisible(selectedType == POKEMON)
    sidePanel:setWidth(selectedType == ITEM and 200 or 112)
    if selectedType == POKEMON then
        closeInventory()
        refreshParty()
    end
    buildBoxSelectors()

    if boxWindow:isVisible() and not suppressBoxRequest then
        requestSelectedBox()
        if selectedType == ITEM then
            requestInventory()
        end
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
    if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
        modules.game_pokebag.hideBoxPokemon()
    end
    closePokemonDetails()

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

local function requestPokemonDetails(slot)
    if selectedType ~= POKEMON or not g_game.isOnline() then
        return
    end

    selectedBoxSlot = slot
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(BOX_OPCODE,
            string.format('I;%d;%d', selectedDepotId, slot))
    end
end

local function toggleBoxPokemonDetails(slot)
    if selectedBoxSlot == slot then
        deselectPokemon()
        return
    end

    selectedPartySlot = nil
    for partySlot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local itemWidget = partyPanel:recursiveGetChildById('slot' .. partySlot)
        if itemWidget then
            itemWidget:setOn(false)
        end
    end
    requestPokemonDetails(slot)
end

local function togglePartyPokemonDetails(slot)
    if selectedPartySlot == slot and pokemonDetailsHost:isVisible() then
        deselectPokemon()
        return true
    end

    local player = g_game.getLocalPlayer()
    if selectedType ~= POKEMON or not player or not player:getInventoryItem(slot) then
        return false
    end

    selectedBoxSlot = nil
    selectedPartySlot = slot
    for _, child in ipairs(contentsPanel:getChildren()) do
        child:setOn(false)
        child:setBorderWidth(0)
        child:setBorderColor('#4a5563')
    end
    refreshParty()

    if modules.game_pokebag and modules.game_pokebag.showPartyPokemonInBox and
        modules.game_pokebag.showPartyPokemonInBox(slot) then
        return true
    end

    closePokemonDetails()
    return false
end

function selectPartyPokemon(slot)
    if not boxWindow or not boxWindow:isVisible() or selectedType ~= POKEMON then
        return false
    end
    return togglePartyPokemonDetails(slot)
end

function getWindow()
    return boxWindow
end

function isSelectedPokemon(depotId, slot)
    return boxWindow and boxWindow:isVisible() and selectedType == POKEMON and
        selectedDepotId == depotId and selectedBoxSlot == slot
end

function isSelectedPartyPokemon(slot)
    return boxWindow and boxWindow:isVisible() and selectedType == POKEMON and selectedPartySlot == slot
end

function handlesContainer(container)
    if not container then
        return false
    end
    if container:getId() == BOX_CONTAINER_ID then
        return true
    end
    return container:getId() == BACKPACK_CONTAINER_ID and boxWindow and boxWindow:isVisible() and
        selectedType == ITEM and not (modules.game_playertrade and modules.game_playertrade.isTradeOpen and
        modules.game_playertrade.isTradeOpen())
end

function onContainerOpen(container, previousContainer)
    if not handlesContainer(container) then
        return false
    end

    if container:getId() == BACKPACK_CONTAINER_ID then
        local validNavigation = not previousContainer or previousContainer == inventoryContainer
        if not validNavigation then
            return false
        end
        inventoryContainer = container
        if container.window and modules.game_containers then
            modules.game_containers.destroy(container)
        end
        refreshInventoryItems()
        return true
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

    if container:getId() == BACKPACK_CONTAINER_ID then
        if inventoryContainer == container then
            inventoryContainer = nil
            clearInventoryItems()
        end
        return true
    end

    if currentContainer == container then
        currentContainer = nil
        if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
            modules.game_pokebag.hideBoxPokemon()
        end
        closePokemonDetails()
        clearContents()
    end
    return true
end

function onContainerChangeSize(container, _)
    if not handlesContainer(container) then
        return false
    end

    if inventoryContainer == container then
        refreshInventoryItems()
    elseif currentContainer == container then
        refreshContainerItems()
    end
    return true
end

function onContainerUpdateItem(container, _, _, _)
    if not handlesContainer(container) then
        return false
    end

    if inventoryContainer == container then
        refreshInventoryItems()
    elseif currentContainer == container then
        refreshContainerItems()
    end
    return true
end

function refreshInventoryItems()
    clearInventoryItems()
    if not inventoryContainer or selectedType ~= ITEM then
        return
    end

    local capacity = inventoryContainer:getCapacity()
    local rows = math.max(1, math.ceil(capacity / 4))
    inventoryItemsPanel:setHeight(rows * 36)

    local name = inventoryContainer:getName() or tr('Backpack')
    inventoryName:setText(name)
    inventoryName:setTooltip(name)
    inventoryUpButton:setVisible(inventoryContainer:hasParent())

    for slot = 0, capacity - 1 do
        local itemWidget = g_ui.createWidget('BoxInventorySlot', inventoryItemsPanel)
        itemWidget:setId('inventoryItem' .. slot)
        local item = inventoryContainer:getItem(slot)
        itemWidget:setItem(item)
        itemWidget.position = inventoryContainer:getSlotPosition(slot)

        if item then
            local currentItem = item
            itemWidget.onDoubleClick = function()
                if currentItem:isContainer() then
                    g_game.open(currentItem, inventoryContainer)
                    return true
                end
                return false
            end
        end
    end
end

function refreshContainerItems()
    if not currentContainer then
        clearContents()
        return
    end

    contentsPanel:destroyChildren()

    local itemsBySlot = {}
    for containerSlot = 0, currentContainer:getItemsCount() - 1 do
        local item = currentContainer:getItem(containerSlot)
        if item then
            local boxSlot = item:getBoxSlot()
            if boxSlot >= 0 and boxSlot < currentContainer:getCapacity() and not itemsBySlot[boxSlot] then
                itemsBySlot[boxSlot] = item
            end
        end
    end

    for slot = 0, currentContainer:getCapacity() - 1 do
        local itemWidget = g_ui.createWidget('BoxItemSlot', contentsPanel)
        itemWidget:setId('item' .. slot)
        local slotItem = itemsBySlot[slot]
        itemWidget:setItem(slotItem)
        local isSelected = selectedType == POKEMON and selectedBoxSlot == slot
        itemWidget:setOn(isSelected)
        itemWidget:setBorderWidth(isSelected and 2 or 0)
        itemWidget:setBorderColor(isSelected and '#65b9e8' or '#4a5563')
        itemWidget.position = currentContainer:getSlotPosition(slot)

        if selectedType == POKEMON and slotItem then
            local currentSlot = slot
            itemWidget.onClick = function(self)
                for _, child in ipairs(contentsPanel:getChildren()) do
                    child:setOn(false)
                    child:setBorderWidth(0)
                    child:setBorderColor('#4a5563')
                end
                toggleBoxPokemonDetails(currentSlot)
                if selectedBoxSlot == currentSlot then
                    self:setOn(true)
                    self:setBorderWidth(2)
                    self:setBorderColor('#65b9e8')
                end
            end
        end

        itemWidget.onDrop = function(self, widget, mousePos)
            local accepted = UIItem.onDrop(self, widget, mousePos)
            g_dispatcher.scheduleEvent(function()
                if self and not self:isDestroyed() then
                    self:setBorderWidth(self:isOn() and 2 or 0)
                    self:setBorderColor(self:isOn() and '#65b9e8' or '#4a5563')
                end
            end, 1)
            return accepted
        end

        itemWidget.onDragLeave = function(self, droppedWidget, mousePos)
            local accepted = UIItem.onDragLeave(self, droppedWidget, mousePos)
            self:setBorderWidth(self:isOn() and 2 or 0)
            self:setBorderColor(self:isOn() and '#65b9e8' or '#4a5563')
            return accepted
        end

    end

    if selectedType == POKEMON and selectedBoxSlot then
        if itemsBySlot[selectedBoxSlot] then
            requestPokemonDetails(selectedBoxSlot)
        else
            if modules.game_pokebag and modules.game_pokebag.hideBoxPokemon then
                modules.game_pokebag.hideBoxPokemon()
            end
            closePokemonDetails()
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
        local item = player and player:getInventoryItem(slot) or nil
        itemWidget:setItem(item)
        itemWidget:setOn(item and selectedPartySlot == slot or false)
        local currentSlot = slot
        itemWidget.onMouseRelease = function(self, mousePosition, mouseButton)
            if mouseButton == MouseLeftButton and self:containsPoint(mousePosition) then
                return togglePartyPokemonDetails(currentSlot)
            end
            return UIItem.onMouseRelease(self, mousePosition, mouseButton)
        end
    end
end

function onInventoryChange(_, slot, item, _)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    local itemWidget = partyPanel:recursiveGetChildById('slot' .. slot)
    itemWidget:setItem(item)
    if not item and selectedPartySlot == slot then
        deselectPokemon()
    else
        itemWidget:setOn(item and selectedPartySlot == slot or false)
    end
end
