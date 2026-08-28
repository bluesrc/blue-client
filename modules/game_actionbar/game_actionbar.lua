HOTKEY_USE = nil
HOTKEY_USEONSELF = 1
HOTKEY_USEONTARGET = 2
HOTKEY_USEWITH = 3

local maxSlots = 60
actionBar = nil
actionBarPanel = nil
bottomPanel = nil
slotToEdit = nil
textAssignWindow = nil
objectAssignWindow = nil
mouseGrabberWidget = nil
actionRadioGroup = nil
editHotkeyWindow = nil
missedSlotToEdit = nil
itemDragRetry = nil
slotReassign = nil
lastHotkeyTime = 0
function init()
    bottomPanel = modules.game_interface.getBottomPanel()
    actionBar = g_ui.loadUI('game_actionbar', bottomPanel)
    actionBarPanel = actionBar:getChildById('actionBarPanel')
    mouseGrabberWidget = g_ui.createWidget('UIWidget')
    mouseGrabberWidget:setVisible(false)
    mouseGrabberWidget:setFocusable(false)
    mouseGrabberWidget.onMouseRelease = onChooseItemMouseRelease

    if g_game.isOnline() then
        addEvent(function()
            setupActionBar()
            loadActionBar()
        end)
    end

    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

end

function terminate()
    actionBar:destroy()
    mouseGrabberWidget:destroy()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    if objectAssignWindow then
        closeObjectAssignWindow()
    end
    if textAssignWindow then
        closeTextAssignWindow()
    end
    if editHotkeyWindow then
        closeEditHotkeyWindow()
    end
end

function online()
    actionBarPanel:destroyChildren()
    addEvent(function()
        setupActionBar()
        loadActionBar()
    end)
end

function offline()
    saveActionBar()
    unbindHotkeys()
end

function copySlot(fromSlotId, toSlotId, visible)
    local fromSlot = actionBarPanel:getChildById(fromSlotId)
    local tmpslot = actionBarPanel:getChildById(toSlotId)
    if not tmpslot then
        tmpslot = g_ui.createWidget('ActionSlot', actionBarPanel)
        tmpslot:setId(toSlotId)
    end
    tmpslot:setVisible(visible)
    local tmptext = not fromSlot.text
    local tmpid = not fromSlot.itemId
    local imageSource = fromSlot:getImageSource()
    local imageClip = fromSlot:getImageClip()
    local imgsrcbool = not imageSource
    local imgclipbool = not imageClip
    imageSource = (imgsrcbool or (tmptext and tmpid)) and '/images/game/actionbar/slot-actionbar' or
                      imageSource
    imageClip = imgclipbool and '0 0 0 0' or imageClip
    tmpslot:setImageSource(imageSource)
    tmpslot:setImageClip(imageClip)
    local tmpItem = fromSlot:getItem()
    if tmpItem then
        tmpslot:setItem(tmpItem)
    else
        tmpslot:setItem(nil)
    end
    tmpslot:setText(fromSlot:getText())
    tmpslot.autoSend = fromSlot.autoSend
    tmpslot.itemId = fromSlot.itemId
    tmpslot.subType = fromSlot.subType
    tmpslot.text = fromSlot.text
    tmpslot.parameter = fromSlot.parameter
    tmpslot.useType = fromSlot.useType
    tmpslot:getChildById('text'):setText(fromSlot:getChildById('text'):getText())
    tmpslot:setTooltip(fromSlot:getTooltip())
end

function onDropFunc(slotId)
    if slotReassign then
        local fromSlotId = slotToEdit
        local toSlotId = slotId
        local fromSlot = actionBarPanel:getChildById(fromSlotId)
        local toSlot = actionBarPanel:getChildById(toSlotId)
        if fromSlot and toSlot then
            local tmpslotid = 'slot' .. maxSlots + 1
            copySlot(fromSlotId, tmpslotid, false)
            copySlot(toSlotId, fromSlotId, true)
            copySlot(tmpslotid, toSlotId, true)
            clearSlotById(tmpslotid)
        end
        slotReassign = nil
        slotToEdit = nil
    end
    slotToEdit = slotId
    if itemDragRetry and missedSlotToEdit then -- first drag doesn't register slotToEdit
        local widget1 = missedSlotToEdit[1]
        local mousePos1 = missedSlotToEdit[2]
        local item1 = missedSlotToEdit[3]
        if widget1 and mousePos1 and item1 then
            onChooseItemByDrag(widget1, mousePos1, item1)
        end
        itemDragRetry = nil
        missedSlotToEdit = nil
    end
    setupHotkeys()
end

function setupActionBar()
    local slotsToDisplay = math.floor((actionBarPanel:getWidth()) / 34)
    for i = 1, maxSlots do
        slot = g_ui.createWidget('ActionSlot', actionBarPanel)
        slot:setId('slot' .. i)
        slot:setVisible(true)
        slot.itemId = nil
        slot.subType = nil
        slot.text = nil
        slot.useType = nil
        g_mouse.bindPress(slot, function()
            slotToEdit = 'slot' .. i .. ''
        end, MouseLeftButton)
        g_mouse.bindPress(slot, function()
            createMenu('slot' .. i)
        end, MouseRightButton)
        g_mouse.bindOnDrop(slot, function()
            if slotToEdit == 'slot' .. i then
                slotReassign = 'slot' .. i
            end
            onDropFunc('slot' .. i)
        end)
        if i == 1 then
            slot:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        end
    end
end

function createMenu(slotId)
    local menu = g_ui.createWidget('PopupMenu')
    slotToEdit = slotId
    menu:addOption('Assign Object', function()
        startChooseItem()
        openObjectAssignWindow()
    end)
    menu:addOption('Assign Text', function()
        openTextAssignWindow()
    end)
    menu:addOption('Edit Hotkey', function()
        openEditHotkeyWindow()
    end)
    local actionSlot = actionBarPanel:recursiveGetChildById(slotToEdit)
    if actionSlot.itemId or actionSlot.text or actionSlot.useType or actionSlot.hotkey then
        menu:addOption('Clear Slot', function()
            clearSlot()
            clearHotkey()
        end)
    end
    menu:display()
end

function clearSlot()
    local slot = actionBarPanel:getChildById(slotToEdit)
    slot:setImageSource('/images/game/actionbar/slot-actionbar')
    slot:setImageClip('0 0 0 0')
    slot:clearItem()
    slot:setText('')
    slot.itemId = nil
    slot.subType = nil
    slot.text = nil
    slot.useType = nil
    slot:getChildById('text'):setText('')
    slot:setTooltip('')
end

function clearSlotById(slotId)
    local slot = actionBarPanel:getChildById(slotId)
    slot:setImageSource('/images/game/actionbar/slot-actionbar')
    slot:setImageClip('0 0 0 0')
    slot:clearItem()
    slot:setText('')
    slot.itemId = nil
    slot.subType = nil
    slot.text = nil
    slot.useType = nil
    slot:getChildById('text'):setText('')
    slot:setTooltip('')
end

function clearHotkey()
    local slot = actionBarPanel:getChildById(slotToEdit)
    slot.hotkey = nil
    slot:getChildById('key'):setText('')
end

function openTextAssignWindow()
    textAssignWindow = g_ui.loadUI('assign_text', g_ui.getRootWidget())
    textAssignWindow:raise()
    textAssignWindow:focus()
    modules.game_hotkeys.enableHotkeys(false)
end

function closeTextAssignWindow()
    textAssignWindow:destroy()
    textAssignWindow = nil
    modules.game_hotkeys.enableHotkeys(true)
end

function textAssignAccept()
    local text = textAssignWindow:getChildById('textToSendTextEdit'):getText()
    if text == '' then
        return
    end
    local slot = actionBarPanel:getChildById(slotToEdit)
    clearSlot()
    slot:getChildById('text'):setText(text)
    while slot:getChildById('text'):getTextSize().height > 30 do
        local subString = slot:getChildById('text'):getText()
        subString = string.sub(subString, 1, #subString - 1)
        slot:getChildById('text'):setText(subString)
    end
    slot:setImageSource('/images/game/actionbar/item-background')
    slot.text = text
    slot.itemId = 469
    slot:setItemId(469)
    slot.autoSend = textAssignWindow:recursiveGetChildById('sendAutomaticallyCheckBox'):isChecked()
    slot:setTooltip(slot.text)
    setupHotkeys()
    closeTextAssignWindow()
end

function openObjectAssignWindow()
    if objectAssignWindow ~= nil then
        objectAssignWindow:destroy()
    end
    objectAssignWindow = g_ui.loadUI('assign_object', g_ui.getRootWidget())
    actionRadioGroup = UIRadioGroup.create()
    actionRadioGroup:addWidget(objectAssignWindow:getChildById('useOnYourselfCheckbox'))
    actionRadioGroup:addWidget(objectAssignWindow:getChildById('useOnTargetCheckbox'))
    actionRadioGroup:addWidget(objectAssignWindow:getChildById('useWithCrosshairCheckbox'))
    actionRadioGroup:addWidget(objectAssignWindow:getChildById('equipCheckbox'))
    actionRadioGroup:addWidget(objectAssignWindow:getChildById('useCheckbox'))
    objectAssignWindow:setVisible(false)
end

function closeObjectAssignWindow()
    objectAssignWindow:destroy()
    objectAssignWindow = nil
    actionRadioGroup = nil
    modules.game_hotkeys.enableHotkeys(true)
end

function startChooseItem()
    if g_ui.isMouseGrabbed() then
        return
    end
    mouseGrabberWidget:grabMouse()
    g_mouse.pushCursor('target')
end

function objectAssignAccept()
    clearSlot()
    local item = objectAssignWindow:getChildById('previewItem'):getItem()
    if not item then
        return
    end
    local slot = actionBarPanel:getChildById(slotToEdit)
    slot:setItem(item)
    slot:setImageSource('/images/game/actionbar/item-background')
    slot:setBorderWidth(0)
    slot.itemId = item:getId()
    if item:isFluidContainer() then
        slot.subType = item:getSubType()
    end
    if objectAssignWindow:getChildById('equipCheckbox'):isChecked() then
        slot.useType = 'equip'
    elseif objectAssignWindow:getChildById('useCheckbox'):isChecked() then
        slot.useType = 'use'
    elseif objectAssignWindow:getChildById('useOnYourselfCheckbox'):isChecked() then
        slot.useType = 'useOnSelf'
    elseif objectAssignWindow:getChildById('useOnTargetCheckbox'):isChecked() then
        slot.useType = 'useOnTarget'
    elseif objectAssignWindow:getChildById('useWithCrosshairCheckbox'):isChecked() then
        slot.useType = 'useWith'
    end
    setupHotkeys()
    closeObjectAssignWindow()
end

function onChooseItemMouseRelease(self, mousePosition, mouseButton)
    local item = nil
    if mouseButton == MouseLeftButton then
        local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
        if clickedWidget then
            if clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
                item = clickedWidget:getItem()
            end
        end
    end

    if item and item:getPosition().x == 65535 and slotToEdit then
        objectAssignWindow:getChildById('previewItem'):setItemId(item:getId())
        objectAssignWindow:getChildById('previewItem'):setItemCount(1)
        objectAssignWindow:getChildById('equipCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useOnYourselfCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useOnTargetCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useWithCrosshairCheckbox'):setEnabled(false)
        if item:getClothSlot() > 0 then
            objectAssignWindow:getChildById('equipCheckbox'):setEnabled(true)
            if item:isMultiUse() then
                objectAssignWindow:getChildById('useOnYourselfCheckbox'):setEnabled(true)
                objectAssignWindow:getChildById('useOnTargetCheckbox'):setEnabled(true)
                objectAssignWindow:getChildById('useWithCrosshairCheckbox'):setEnabled(true)
            else
                objectAssignWindow:getChildById('useCheckbox'):setEnabled(true)
            end
            actionRadioGroup:selectWidget(objectAssignWindow:getChildById('equipCheckbox'))
        elseif item:isMultiUse() then
            objectAssignWindow:getChildById('useOnYourselfCheckbox'):setEnabled(true)
            objectAssignWindow:getChildById('useOnTargetCheckbox'):setEnabled(true)
            objectAssignWindow:getChildById('useWithCrosshairCheckbox'):setEnabled(true)
            objectAssignWindow:getChildById('equipCheckbox'):setEnabled(true)
            actionRadioGroup:selectWidget(objectAssignWindow:getChildById('useOnYourselfCheckbox'))
        else
            objectAssignWindow:getChildById('useCheckbox'):setEnabled(true)
            actionRadioGroup:selectWidget(objectAssignWindow:getChildById('useCheckbox'))
        end
        if not objectAssignWindow:isVisible() then
            objectAssignWindow:show()
        end
        objectAssignWindow:raise()
        objectAssignWindow:focus()
    end
    g_mouse.popCursor('target')
    self:ungrabMouse()
    return true
end

function onChooseItemByDrag(self, mousePosition, item)
    if item and item:getPosition().x == 65535 and slotToEdit then
        openObjectAssignWindow()
        objectAssignWindow:getChildById('previewItem'):setItemId(item:getId())
        objectAssignWindow:getChildById('previewItem'):setItemCount(1)
        objectAssignWindow:getChildById('equipCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useOnYourselfCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useOnTargetCheckbox'):setEnabled(false)
        objectAssignWindow:getChildById('useWithCrosshairCheckbox'):setEnabled(false)
        if item:getClothSlot() > 0 then
            objectAssignWindow:getChildById('equipCheckbox'):setEnabled(true)
            if item:isMultiUse() then
                objectAssignWindow:getChildById('useOnYourselfCheckbox'):setEnabled(true)
                objectAssignWindow:getChildById('useOnTargetCheckbox'):setEnabled(true)
                objectAssignWindow:getChildById('useWithCrosshairCheckbox'):setEnabled(true)
            else
                objectAssignWindow:getChildById('useCheckbox'):setEnabled(true)
            end
            actionRadioGroup:selectWidget(objectAssignWindow:getChildById('equipCheckbox'))
        elseif item:isMultiUse() then
            objectAssignWindow:getChildById('useOnYourselfCheckbox'):setEnabled(true)
            objectAssignWindow:getChildById('useOnTargetCheckbox'):setEnabled(true)
            objectAssignWindow:getChildById('useWithCrosshairCheckbox'):setEnabled(true)
            objectAssignWindow:getChildById('equipCheckbox'):setEnabled(true)
            actionRadioGroup:selectWidget(objectAssignWindow:getChildById('useOnYourselfCheckbox'))
        else
            objectAssignWindow:getChildById('useCheckbox'):setEnabled(true)
            actionRadioGroup:selectWidget(objectAssignWindow:getChildById('useCheckbox'))
        end
        if not objectAssignWindow:isVisible() then
            objectAssignWindow:show()
        end
        objectAssignWindow:raise()
        objectAssignWindow:focus()
    elseif not slotToEdit then
        itemDragRetry = true
        missedSlotToEdit = {self, mousePosition, item}
    end
end

function onDragReassign(self, item)
    slotReassign = self
end

function openEditHotkeyWindow()
    editHotkeyWindow = g_ui.loadUI('edit_hotkey', g_ui.getRootWidget())
    editHotkeyWindow:grabKeyboard()

    local comboLabel = editHotkeyWindow:recursiveGetChildById('comboPreview')
    comboLabel.keyCombo = ''
    editHotkeyWindow.onKeyDown = hotkeyCapture
    editHotkeyWindow:raise()
    editHotkeyWindow:focus()
    modules.game_hotkeys.enableHotkeys(false)
end

function closeEditHotkeyWindow()
    editHotkeyWindow:destroy()
    editHotkeyWindow = nil
    modules.game_hotkeys.enableHotkeys(true)
end

function unbindHotkeys()
    for v, slot in pairs(actionBarPanel:getChildren()) do
        if slot.hotkey and slot.hotkey ~= '' then
            g_keyboard.unbindKeyPress(slot.hotkey)
        end
    end
end

function setupHotkeys()
    unbindHotkeys()
    for v, slot in pairs(actionBarPanel:getChildren()) do
        slot.onMouseRelease = function()
            if g_clock.millis() - lastHotkeyTime < modules.client_options.getOption('hotkeyDelay') then
                return
            end

            lastHotkeyTime = g_clock.millis()
            if slot.itemId and slot.useType then
                if slot.useType == 'use' then
                    modules.game_hotkeys.executeHotkeyItem(HOTKEY_USE, slot.itemId, slot.subType)
                elseif slot.useType == 'useOnTarget' then
                    modules.game_hotkeys.executeHotkeyItem(HOTKEY_USEONTARGET, slot.itemId, slot.subType)
                elseif slot.useType == 'useWith' then
                    modules.game_hotkeys.executeHotkeyItem(HOTKEY_USEWITH, slot.itemId, slot.subType)
                elseif slot.useType == 'useOnSelf' then
                    modules.game_hotkeys.executeHotkeyItem(HOTKEY_USEONSELF, slot.itemId, slot.subType)
                elseif slot.useType == 'equip' then
                    local item = g_game.findPlayerItem(slot.itemId, -1)
                    if item then
                        g_game.equipItem(item)
                    end
                end
            elseif slot.text then
                if slot.autoSend then
                    g_game.talk(slot.text)
                else
                    if not modules.game_console.isChatEnabled() then
                        modules.game_console.switchChatOnCall()
                    end
                    modules.game_console.setTextEditText(slot.text)
                end
            end
        end

        if slot.hotkey and slot.hotkey ~= '' then
            g_keyboard.bindKeyPress(slot.hotkey, function()
                if not modules.game_hotkeys.canPerformKeyCombo(slot.hotkey) then
                    return
                end
                if g_clock.millis() - lastHotkeyTime < modules.client_options.getOption('hotkeyDelay') then
                    return
                end

                lastHotkeyTime = g_clock.millis()
                if slot.itemId and slot.useType then
                    if slot.useType == 'use' then
                        modules.game_hotkeys.executeHotkeyItem(HOTKEY_USE, slot.itemId, slot.subType)
                    elseif slot.useType == 'useOnTarget' then
                        modules.game_hotkeys.executeHotkeyItem(HOTKEY_USEONTARGET, slot.itemId, slot.subType)
                    elseif slot.useType == 'useWith' then
                        modules.game_hotkeys.executeHotkeyItem(HOTKEY_USEWITH, slot.itemId, slot.subType)
                    elseif slot.useType == 'useOnSelf' then
                        modules.game_hotkeys.executeHotkeyItem(HOTKEY_USEONSELF, slot.itemId, slot.subType)
                    elseif slot.useType == 'equip' then
                        local item = g_game.findPlayerItem(slot.itemId, -1)
                        if item then
                            g_game.equipItem(item)
                        end
                    end
                elseif slot.text then
                    if slot.autoSend then
                        modules.game_console.sendMessage(slot.text)
                    else
                        scheduleEvent(function()
                            if not modules.game_console.isChatEnabled() then
                                modules.game_console.switchChatOnCall()
                            end
                            modules.game_console.setTextEditText(slot.text)
                        end, 1)
                    end
                end
            end)
        end
    end
end

function checkHotkey(hotkey)
    for v, k in pairs(actionBarPanel:getChildren()) do
        if k.hotkey == hotkey then
            return true
        end
    end
end

function hotkeyCapture(assignWindow, keyCode, keyboardModifiers)
    local hotkeyAlreadyUsed = false
    assignWindow:raise()
    assignWindow:focus()
    local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
    local comboPreview = assignWindow:recursiveGetChildById('comboPreview')
    local errorLabel = editHotkeyWindow:recursiveGetChildById('errorLabel')
    if checkHotkey(keyCombo) then
        errorLabel:setVisible(true)
        editHotkeyWindow:setHeight(180)
    else
        errorLabel:setVisible(false)
        editHotkeyWindow:setHeight(160)
    end
    comboPreview:setText(tr('Current hotkey to change: %s', keyCombo))
    comboPreview.keyCombo = keyCombo
    comboPreview:resizeToText()
    assignWindow:getChildById('applyButton'):enable()
    return true
end

function hotkeyClear(assignWindow)
    local comboPreview = assignWindow:recursiveGetChildById('comboPreview')
    comboPreview:setText(tr('Current hotkey to change: none'))
    comboPreview.keyCombo = ''
    comboPreview:resizeToText()
    assignWindow:getChildById('applyButton'):disable()
end

function hotkeyCaptureOk(assignWindow, keyCombo)
    local slot = actionBarPanel:getChildById(slotToEdit)
    if checkHotkey(keyCombo) then
        for v, k in pairs(actionBarPanel:getChildren()) do
            if k.hotkey == keyCombo then
                k.hotkey = ''
                k:getChildById('key'):setText('')
            end
        end
    end
    unbindHotkeys()
    slot.hotkey = keyCombo
    local text = slot.hotkey
    text = text:gsub('Shift', 'S')
    text = text:gsub('Alt', 'A')
    text = text:gsub('Ctrl', 'C')
    text = text:gsub('+', '')
    slot:getChildById('key'):setText(text)
    setupHotkeys()
    if assignWindow == editHotkeyWindow then
        closeEditHotkeyWindow()
        return
    end
    assignWindow:destroy()
end

function saveActionBar()
    local hotkeySettings = g_settings.getNode('game_actionbar') or {}
    local hotkeys = hotkeySettings

    local char = g_game.getCharacterName()
    if not hotkeys[char] then
        hotkeys[char] = {}
    end
    hotkeys = hotkeys[char]

    table.clear(hotkeys)
    local currentHotkeys = actionBarPanel:getChildren()
    for v, slot in ipairs(currentHotkeys) do
        hotkeys[slot:getId()] = {
            hotkey = slot.hotkey,
            autoSend = slot.autoSend,
            itemId = slot.itemId,
            subType = slot.subType,
            useType = slot.useType,
            text = slot.text,
            parameter = slot.parameter
        }
    end

    g_settings.setNode('game_actionbar', hotkeySettings)
    g_settings.save()
end

function loadObject(slot)
    slot:setItemId(slot.itemId)
    slot:setImageSource('/images/game/actionbar/item-background')
    slot:setImageClip('0 0 0 0')
    slot:getChildById('text'):setText('')
    slot:setBorderWidth(0)
    setupHotkeys()
end

function loadText(slot)
    slot:getChildById('text'):setText(slot.text)
    while slot:getChildById('text'):getTextSize().height > 30 do
        local subString = slot:getChildById('text'):getText()
        subString = string.sub(subString, 1, #subString - 1)
        slot:getChildById('text'):setText(subString)
    end
    slot:setImageSource('/images/game/actionbar/item-background')
    slot:setImageClip('0 0 0 0')
    setupHotkeys()
end

function loadActionBar()
    unbindHotkeys()
    local hotkeySettings = g_settings.getNode('game_actionbar')
    local hotkeys = {}

    if not table.empty(hotkeySettings) then
        hotkeys = hotkeySettings
    end
    if not table.empty(hotkeys) then
        hotkeys = hotkeys[g_game.getCharacterName()]
    end
    if hotkeys then
        for slot, setting in pairs(hotkeys) do
            slot = actionBarPanel:getChildById(slot)
            if slot then
                slot.itemId = setting.itemId
                slot:setItemId(setting.itemId)
                slot.subType = setting.subType
                slot.text = setting.text
                slot.hotkey = setting.hotkey
                slot.useType = setting.useType
                slot.autoSend = setting.autoSend
                slot.parameter = setting.parameter
                if slot.hotkey then
                    local text = slot.hotkey
                    if type(text) == 'string' then
                        text = text:gsub('Shift', 'S')
                        text = text:gsub('Alt', 'A')
                        text = text:gsub('Ctrl', 'C')
                        text = text:gsub('+', '')
                    end
                    slot:getChildById('key'):setText(text)
                end
                if slot.text then
                    loadText(slot)
                elseif slot.itemId and slot.itemId > 0 then
                    loadObject(slot)
                end
            end
        end
    end
    setupHotkeys()
end
