local BACKPACK_OPCODE = 75
local ITEMS_CONTAINER_ID = 13
local LOOT_CONTAINER_ID = 12

inventoryWindow = nil
inventoryPanel = nil
inventoryButton = nil

local itemsContainer = nil
local lootContainer = nil

local function sendBackpackCommand(command)
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(BACKPACK_OPCODE, command)
    end
end

local function requestContainers()
    sendBackpackCommand('A')
end

local function toggleFromHotkey()
    if modules.game_console and modules.game_console.isChatEnabled() then
        return
    end
    toggle()
end

local function getContainerKind(container)
    if not container then
        return nil
    end
    if container:getId() == ITEMS_CONTAINER_ID then
        return 'items'
    elseif container:getId() == LOOT_CONTAINER_ID then
        return 'loot'
    end
    return nil
end

local function getContainerForKind(kind)
    return kind == 'items' and itemsContainer or lootContainer
end

local function moveLootToItems(_, draggedWidget)
    local item = draggedWidget and draggedWidget.currentDragThing
    if not item or not item:isItem() or not itemsContainer or not lootContainer then
        return false
    end

    local itemPosition = item:getPosition()
    if not itemPosition or itemPosition.x ~= 65535 or bit.band(itemPosition.y, 0x0F) ~= lootContainer:getId() then
        return false
    end

    local destination = itemsContainer:getSlotPosition(itemsContainer:getSize())
    if item:getCount() > 1 then
        modules.game_interface.moveStackableItem(item, destination)
    else
        g_game.move(item, destination, 1)
    end

    selectTab('items')
    return true
end

local function refreshContainer(kind)
    local grid = inventoryWindow:recursiveGetChildById(kind .. 'Grid')
    if not grid then
        return
    end

    grid:destroyChildren()
    local container = getContainerForKind(kind)
    local nameLabel = inventoryWindow:recursiveGetChildById(kind .. 'Name')
    local upButton = inventoryWindow:recursiveGetChildById(kind .. 'UpButton')

    if not container then
        grid:setHeight(0)
        nameLabel:setText(kind == 'items' and tr('Items') or tr('Loot'))
        upButton:setVisible(false)
        return
    end

    local capacity = container:getCapacity()
    grid:setHeight(math.max(1, math.ceil(capacity / 5)) * 35)

    local name = container:getName()
    if not name or #name == 0 then
        name = kind == 'items' and tr('Items') or tr('Loot')
    end
    name = name:sub(1, 1):upper() .. name:sub(2)
    nameLabel:setText(name)
    nameLabel:setTooltip(name)
    upButton:setVisible(container:hasParent())

    for slot = 0, capacity - 1 do
        local itemWidget = g_ui.createWidget('InventoryBagSlot', grid)
        itemWidget:setId(kind .. 'Item' .. slot)
        itemWidget:setMargin(0)
        itemWidget.position = container:getSlotPosition(slot)

        local item = container:getItem(slot)
        itemWidget:setItem(item)
        if item and item:isContainer() then
            local currentItem = item
            local currentContainer = container
            itemWidget.onDoubleClick = function()
                g_game.open(currentItem, currentContainer)
                return true
            end
        end
    end
end

function init()
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    g_keyboard.bindKeyDown('I', toggleFromHotkey)
    inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Inventory') .. ' (I)',
                                                                      '/images/topbuttons/inventory', toggle)

    inventoryWindow = g_ui.loadUI('inventory')
    inventoryWindow:enableResize()
    inventoryWindow:setContentMinimumHeight(116)
    inventoryWindow:setContentMaximumHeight(254)
    inventoryPanel = inventoryWindow:getChildById('contentsPanel')

    inventoryWindow:setup()
    inventoryWindow:recursiveGetChildById('itemsTab').onDrop = moveLootToItems
    selectTab('items')

    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    g_keyboard.unbindKeyDown('I')
    inventoryWindow:destroy()
    inventoryButton:destroy()

    inventoryWindow = nil
    inventoryPanel = nil
    inventoryButton = nil
    itemsContainer = nil
    lootContainer = nil
end

function selectTab(kind)
    if kind ~= 'items' and kind ~= 'loot' then
        return
    end

    local itemsTab = inventoryWindow:recursiveGetChildById('itemsTab')
    local lootTab = inventoryWindow:recursiveGetChildById('lootTab')
    itemsTab:setChecked(kind == 'items')
    lootTab:setChecked(kind == 'loot')
    inventoryWindow:recursiveGetChildById('itemsPage'):setVisible(kind == 'items')
    inventoryWindow:recursiveGetChildById('lootPage'):setVisible(kind == 'loot')
    refreshContainer(kind)
end

function openContainerParent(kind)
    local container = getContainerForKind(kind)
    if container and container:hasParent() then
        g_game.openParent(container)
    end
end

function handlesContainer(container)
    return getContainerKind(container) ~= nil
end

function onContainerOpen(container, previousContainer)
    local kind = getContainerKind(container)
    if not kind then
        return false
    end

    local current = getContainerForKind(kind)
    if previousContainer and current and previousContainer ~= current then
        return false
    end

    if kind == 'items' then
        itemsContainer = container
    else
        lootContainer = container
    end

    if container.window and modules.game_containers then
        modules.game_containers.destroy(container)
    end
    refreshContainer(kind)
    return true
end

function onContainerClose(container)
    local kind = getContainerKind(container)
    if not kind then
        return false
    end

    if kind == 'items' and itemsContainer == container then
        itemsContainer = nil
        refreshContainer(kind)
    elseif kind == 'loot' and lootContainer == container then
        lootContainer = nil
        refreshContainer(kind)
    end
    return true
end

function onContainerChangeSize(container)
    local kind = getContainerKind(container)
    if not kind then
        return false
    end
    if getContainerForKind(kind) == container then
        refreshContainer(kind)
    end
    return true
end

function onContainerUpdateItem(container)
    return onContainerChangeSize(container)
end

function online()
    inventoryWindow:setupOnStart()

    inventoryButton:setOn(inventoryWindow:isVisible())

    itemsContainer = g_game.getContainer(ITEMS_CONTAINER_ID)
    lootContainer = g_game.getContainer(LOOT_CONTAINER_ID)
    if inventoryWindow:isVisible() then
        if not itemsContainer or not lootContainer then
            requestContainers()
        else
            refreshContainer('items')
            refreshContainer('loot')
        end
    end
end

function offline()
    itemsContainer = nil
    lootContainer = nil
    refreshContainer('items')
    refreshContainer('loot')
    inventoryWindow:setParent(nil, true)
end

function toggle()
    if inventoryWindow:isVisible() then
        inventoryWindow:close()
    else
        inventoryWindow:open()
    end
end

function onMiniWindowOpen()
    inventoryButton:setOn(true)
    if g_game.isOnline() then
        requestContainers()
    end
end

function onMiniWindowClose()
    inventoryButton:setOn(false)
    if g_game.isOnline() then
        sendBackpackCommand('C')
    end
end
