HOTKEY_MANAGER_USE = nil
HOTKEY_MANAGER_USEONSELF = 1
HOTKEY_MANAGER_USEONTARGET = 2
HOTKEY_MANAGER_USEWITH = 3

HOTKEY_ACTION_TOGGLE_WASD = 1
HOTKEY_ACTION_ATTACK_NEXT = 2
HOTKEY_ACTION_ATTACK_PREV = 3
HOTKEY_ACTION_TOGGLE_CHASE = 4

HotkeyActions = {{
    id = HOTKEY_ACTION_TOGGLE_WASD,
    text = tr('Toggle WASD chat mode')
}, {
    id = HOTKEY_ACTION_ATTACK_NEXT,
    text = tr('Attack next creature in battle list')
}, {
    id = HOTKEY_ACTION_ATTACK_PREV,
    text = tr('Attack previous creature in battle list')
}, {
    id = HOTKEY_ACTION_TOGGLE_CHASE,
    text = tr('Toggle chase mode')
}}

-- Structured bindings are action based instead of key based.  Keeping the
-- legacy list below allows existing text/item hotkeys to continue working.
HotkeyCategories = {{
    id = 'movement',
    text = tr('Movement'),
    description = tr('Walking supports two bindings, so WASD and arrow keys can be used together.')
}, {
    id = 'pokemon',
    text = tr('Pokemon'),
    description = tr('Use the active Pokemon moves or release a Pokemon from a Pokebag slot.')
}, {
    id = 'combat',
    text = tr('Combat'),
    description = tr('Target selection and combat actions used by the Pokemon client.')
}, {
    id = 'modules',
    text = tr('Modules'),
    description = tr('Open or close the main game windows.')
}, {
    id = 'chat',
    text = tr('Chat'),
    description = tr('Open chat and manage its channels and tabs.')
}, {
    id = 'interface',
    text = tr('Interface'),
    description = tr('Map, screen and session shortcuts.')
}, {
    id = 'custom',
    text = tr('Custom'),
    description = tr('Text and item hotkeys.')
}}

HotkeyBindings = {
    { id = 'walk_north', category = 'movement', text = tr('Walk north'), description = tr('Move one floor tile north.'), defaults = {'W', 'Up'}, direction = North },
    { id = 'walk_east', category = 'movement', text = tr('Walk east'), description = tr('Move one floor tile east.'), defaults = {'D', 'Right'}, direction = East },
    { id = 'walk_south', category = 'movement', text = tr('Walk south'), description = tr('Move one floor tile south.'), defaults = {'S', 'Down'}, direction = South },
    { id = 'walk_west', category = 'movement', text = tr('Walk west'), description = tr('Move one floor tile west.'), defaults = {'A', 'Left'}, direction = West },
    { id = 'walk_north_east', category = 'movement', text = tr('Walk north-east'), description = tr('Move diagonally north-east.'), defaults = {'E', 'Numpad9'}, direction = NorthEast },
    { id = 'walk_south_east', category = 'movement', text = tr('Walk south-east'), description = tr('Move diagonally south-east.'), defaults = {'C', 'Numpad3'}, direction = SouthEast },
    { id = 'walk_south_west', category = 'movement', text = tr('Walk south-west'), description = tr('Move diagonally south-west.'), defaults = {'Z', 'Numpad1'}, direction = SouthWest },
    { id = 'walk_north_west', category = 'movement', text = tr('Walk north-west'), description = tr('Move diagonally north-west.'), defaults = {'Q', 'Numpad7'}, direction = NorthWest },
    { id = 'turn_north', category = 'movement', text = tr('Turn north'), description = tr('Face north without moving.'), defaults = {'Ctrl+Up', ''}, turnDirection = North },
    { id = 'turn_east', category = 'movement', text = tr('Turn east'), description = tr('Face east without moving.'), defaults = {'Ctrl+Right', ''}, turnDirection = East },
    { id = 'turn_south', category = 'movement', text = tr('Turn south'), description = tr('Face south without moving.'), defaults = {'Ctrl+Down', ''}, turnDirection = South },
    { id = 'turn_west', category = 'movement', text = tr('Turn west'), description = tr('Face west without moving.'), defaults = {'Ctrl+Left', ''}, turnDirection = West },

    { id = 'pokemon_move_1', category = 'pokemon', text = tr('Pokemon move 1'), description = tr('Use the first active move.'), defaults = {'1', ''} },
    { id = 'pokemon_move_2', category = 'pokemon', text = tr('Pokemon move 2'), description = tr('Use the second active move.'), defaults = {'2', ''} },
    { id = 'pokemon_move_3', category = 'pokemon', text = tr('Pokemon move 3'), description = tr('Use the third active move.'), defaults = {'3', ''} },
    { id = 'pokemon_move_4', category = 'pokemon', text = tr('Pokemon move 4'), description = tr('Use the fourth active move.'), defaults = {'4', ''} },
    { id = 'pokemon_slot_1', category = 'pokemon', text = tr('Pokebag slot 1'), description = tr('Release or recall the Pokemon in slot 1.'), defaults = {'', ''} },
    { id = 'pokemon_slot_2', category = 'pokemon', text = tr('Pokebag slot 2'), description = tr('Release or recall the Pokemon in slot 2.'), defaults = {'', ''} },
    { id = 'pokemon_slot_3', category = 'pokemon', text = tr('Pokebag slot 3'), description = tr('Release or recall the Pokemon in slot 3.'), defaults = {'', ''} },
    { id = 'pokemon_slot_4', category = 'pokemon', text = tr('Pokebag slot 4'), description = tr('Release or recall the Pokemon in slot 4.'), defaults = {'', ''} },
    { id = 'pokemon_slot_5', category = 'pokemon', text = tr('Pokebag slot 5'), description = tr('Release or recall the Pokemon in slot 5.'), defaults = {'', ''} },
    { id = 'pokemon_slot_6', category = 'pokemon', text = tr('Pokebag slot 6'), description = tr('Release or recall the Pokemon in slot 6.'), defaults = {'', ''} },
    { id = 'toggle_mount', category = 'pokemon', text = tr('Mount / ride'), description = tr('Mount or dismount the current ride.'), defaults = {'Ctrl+R', ''}, allowInChat = true },

    { id = 'cancel_target', category = 'combat', text = tr('Cancel target'), description = tr('Stop attacking or following the current target.'), defaults = {'Escape', ''} },
    { id = 'attack_next', category = 'combat', text = tr('Next target'), description = tr('Attack the next creature in the battle list.'), defaults = {'', ''} },
    { id = 'attack_previous', category = 'combat', text = tr('Previous target'), description = tr('Attack the previous creature in the battle list.'), defaults = {'', ''} },
    { id = 'toggle_chase', category = 'combat', text = tr('Toggle chase'), description = tr('Switch chase mode on or off.'), defaults = {'', ''} },

    { id = 'open_hotkeys', category = 'modules', text = tr('Hotkeys'), description = tr('Open this hotkey window.'), defaults = {'Ctrl+K', ''}, allowInChat = true },
    { id = 'open_inventory', category = 'modules', text = tr('Inventory'), description = tr('Open or close the inventory.'), defaults = {'I', ''} },
    { id = 'open_pokebag', category = 'modules', text = tr('Pokebag'), description = tr('Open or close the Pokebag.'), defaults = {'P', ''} },
    { id = 'open_box', category = 'modules', text = tr('Pokemon Box'), description = tr('Open or close Pokemon storage.'), defaults = {'B', ''} },
    { id = 'open_trainer_card', category = 'modules', text = tr('Trainer Card'), description = tr('Open or close the Trainer Card.'), defaults = {'T', ''} },
    { id = 'open_skills', category = 'modules', text = tr('Skills'), description = tr('Open or close the skills window.'), defaults = {'Alt+S', ''}, allowInChat = true },
    { id = 'open_battle', category = 'modules', text = tr('Battle list'), description = tr('Open or close the battle list.'), defaults = {'Ctrl+B', ''}, allowInChat = true },
    { id = 'open_minimap', category = 'modules', text = tr('Minimap'), description = tr('Open or close the minimap.'), defaults = {'Ctrl+M', ''}, allowInChat = true },
    { id = 'open_vip', category = 'modules', text = tr('VIP list'), description = tr('Open or close the friends list.'), defaults = {'Ctrl+P', ''}, allowInChat = true },
    { id = 'open_tasks', category = 'modules', text = tr('Tasks'), description = tr('Open or close the task window.'), defaults = {'Ctrl+A', ''}, allowInChat = true },
    { id = 'open_combat_controls', category = 'modules', text = tr('Combat controls'), description = tr('Open or close combat controls.'), defaults = {'', ''} },
    { id = 'open_options', category = 'modules', text = tr('Options'), description = tr('Open or close client options.'), defaults = {'', ''}, allowInChat = true },
    { id = 'open_shaders', category = 'modules', text = tr('Shaders'), description = tr('Open or close shader controls.'), defaults = {'Ctrl+Y', ''}, allowInChat = true },
    { id = 'open_bug_report', category = 'modules', text = tr('Bug report'), description = tr('Open the bug report window.'), defaults = {'Ctrl+Z', ''}, allowInChat = true },

    { id = 'open_chat', category = 'chat', text = tr('Open chat'), description = tr('Focus chat to type a message.'), defaults = {'Enter', ''}, allowInChat = true },
    { id = 'open_channels', category = 'chat', text = tr('Channel list'), description = tr('Open the available channel list.'), defaults = {'Ctrl+O', ''}, allowInChat = true },
    { id = 'close_channel', category = 'chat', text = tr('Close channel'), description = tr('Close the selected chat tab.'), defaults = {'Ctrl+E', ''}, allowInChat = true },
    { id = 'chat_help', category = 'chat', text = tr('Chat help'), description = tr('Open chat help.'), defaults = {'Ctrl+H', ''}, allowInChat = true },

    { id = 'zoom_in', category = 'interface', text = tr('Zoom in'), description = tr('Zoom the game map in.'), defaults = {'Ctrl+=', ''}, allowInChat = true },
    { id = 'zoom_out', category = 'interface', text = tr('Zoom out'), description = tr('Zoom the game map out.'), defaults = {'Ctrl+-', ''}, allowInChat = true },
    { id = 'toggle_full_map', category = 'interface', text = tr('Full map'), description = tr('Open or close the full map.'), defaults = {'Ctrl+Shift+M', ''}, allowInChat = true },
    { id = 'map_pan_left', category = 'interface', text = tr('Move minimap left'), description = tr('Move the minimap view to the left.'), defaults = {'Alt+Left', ''}, allowInChat = true },
    { id = 'map_pan_right', category = 'interface', text = tr('Move minimap right'), description = tr('Move the minimap view to the right.'), defaults = {'Alt+Right', ''}, allowInChat = true },
    { id = 'map_pan_up', category = 'interface', text = tr('Move minimap up'), description = tr('Move the minimap view up.'), defaults = {'Alt+Up', ''}, allowInChat = true },
    { id = 'map_pan_down', category = 'interface', text = tr('Move minimap down'), description = tr('Move the minimap view down.'), defaults = {'Alt+Down', ''}, allowInChat = true },
    { id = 'toggle_fullscreen', category = 'interface', text = tr('Fullscreen'), description = tr('Switch fullscreen mode on or off.'), defaults = {'Ctrl+Shift+F', ''}, allowInChat = true },
    { id = 'toggle_displays', category = 'interface', text = tr('Creature information'), description = tr('Show or hide names and status bars.'), defaults = {'Ctrl+N', ''}, allowInChat = true },
    { id = 'toggle_topmenu', category = 'interface', text = tr('Top menu'), description = tr('Show or hide the top menu.'), defaults = {'Ctrl+Shift+T', ''}, allowInChat = true },
    { id = 'clear_screen', category = 'interface', text = tr('Clear screen text'), description = tr('Remove floating and status messages.'), defaults = {'Alt+W', ''}, allowInChat = true },
    { id = 'logout', category = 'interface', text = tr('Logout'), description = tr('Open the logout confirmation.'), defaults = {'Ctrl+Q', 'Ctrl+L'}, allowInChat = true }
}

local HotkeyBindingsById = {}
for _, binding in ipairs(HotkeyBindings) do
    HotkeyBindingsById[binding.id] = binding
end

HotkeyColors = {
    text = '#888888',
    textAutoSend = '#FFFFFF',
    itemUse = '#8888FF',
    itemUseSelf = '#00FF00',
    itemUseTarget = '#FF0000',
    itemUseWith = '#F5B325',
    action = '#F97ACD'
}

hotkeysManagerLoaded = false
hotkeysWindow = nil
hotkeysButton = nil
currentHotkeyLabel = nil
currentItemPreview = nil
itemWidget = nil
addHotkeyButton = nil
removeHotkeyButton = nil
hotkeyActionCombo = nil
hotkeyText = nil
hotKeyTextLabel = nil
sendAutomatically = nil
selectObjectButton = nil
clearObjectButton = nil
useOnSelf = nil
useOnTarget = nil
useWith = nil
defaultComboKeys = nil
perServer = true
perCharacter = true
mouseGrabberWidget = nil
useRadioGroup = nil
currentHotkeys = nil
boundCombosCallback = {}
hotkeysList = {}
disableHotkeysCount = 0
lastHotkeyTime = g_clock.millis()
categoryPanel = nil
actionPanel = nil
customPanel = nil
actionsScroll = nil
currentCategory = 'movement'
categoryButtons = {}
configuredBindings = {}
configuredCallbacks = {}
movementEnabled = true
captureWindow = nil

local function copyDefaultBindings(binding)
    return {
        primary = binding.defaults[1] or '',
        secondary = binding.defaults[2] or ''
    }
end

local function getConfiguredSettings(create)
    local root = g_settings.getNode('game_keybindings') or {}
    local settings = root

    if perServer then
        local host = G.host or ''
        if create and not settings[host] then
            settings[host] = {}
        end
        settings = settings[host]
    end

    if perCharacter and settings then
        local character = g_game.getCharacterName() or ''
        if create and not settings[character] then
            settings[character] = {}
        end
        settings = settings[character]
    end

    return root, settings
end

function loadConfiguredBindings(forceDefaults)
    configuredBindings = {}
    local _, saved = getConfiguredSettings(false)
    local savedBindings = saved and (saved.bindings or saved) or {}

    for _, binding in ipairs(HotkeyBindings) do
        local values = copyDefaultBindings(binding)
        local stored = not forceDefaults and savedBindings[binding.id] or nil
        if type(stored) == 'table' then
            if stored.primary ~= nil then
                values.primary = tostring(stored.primary)
            elseif stored[1] ~= nil then
                values.primary = tostring(stored[1])
            end
            if stored.secondary ~= nil then
                values.secondary = tostring(stored.secondary)
            elseif stored[2] ~= nil then
                values.secondary = tostring(stored[2])
            end
        end
        configuredBindings[binding.id] = values
    end
end

function saveConfiguredBindings()
    local root, settings = getConfiguredSettings(true)
    settings.bindings = {}
    settings.version = 2
    for _, binding in ipairs(HotkeyBindings) do
        local values = configuredBindings[binding.id] or copyDefaultBindings(binding)
        settings.bindings[binding.id] = {
            primary = values.primary or '',
            secondary = values.secondary or ''
        }
    end
    g_settings.setNode('game_keybindings', root)
end

function getBinding(actionId, bindingSlot)
    local values = configuredBindings[actionId]
    if not values then
        return ''
    end
    return values[bindingSlot or 'primary'] or ''
end

local function isCustomKey(keyCombo)
    return keyCombo and hotkeyList and hotkeyList[keyCombo] ~= nil
end

local LegacyActionMigration = {
    [HOTKEY_ACTION_TOGGLE_WASD] = 'open_chat',
    [HOTKEY_ACTION_ATTACK_NEXT] = 'attack_next',
    [HOTKEY_ACTION_ATTACK_PREV] = 'attack_previous',
    [HOTKEY_ACTION_TOGGLE_CHASE] = 'toggle_chase'
}

local function migrateLegacyAction(keyCombo, setting)
    local actionId = setting and LegacyActionMigration[tonumber(setting.action)]
    local values = actionId and configuredBindings[actionId]
    if not values then
        return false
    end
    if values.primary ~= keyCombo and values.secondary ~= keyCombo then
        if values.primary == '' then
            values.primary = keyCombo
        elseif values.secondary == '' then
            values.secondary = keyCombo
        else
            return false
        end
    end
    return true
end

function unbindConfiguredHotkeys()
    for _, record in ipairs(configuredCallbacks) do
        if record.turning then
            if modules.game_interface and modules.game_interface.unbindTurnKey then
                modules.game_interface.unbindTurnKey(record.key)
            end
        elseif record.movement then
            if modules.game_interface and modules.game_interface.unbindWalkKey then
                modules.game_interface.unbindWalkKey(record.key)
            end
        else
            g_keyboard.unbindKeyDown(record.key, record.callback)
        end
    end
    configuredCallbacks = {}
end

local function bindConfiguredAction(binding, keyCombo)
    if not keyCombo or keyCombo == '' or isCustomKey(keyCombo) then
        return
    end

    if binding.direction then
        if movementEnabled and modules.game_interface and modules.game_interface.bindWalkKey then
            modules.game_interface.bindWalkKey(keyCombo, binding.direction)
            table.insert(configuredCallbacks, { key = keyCombo, movement = true })
        end
        return
    end

    if binding.turnDirection then
        if movementEnabled and modules.game_interface and modules.game_interface.bindTurnKey then
            modules.game_interface.bindTurnKey(keyCombo, binding.turnDirection)
            table.insert(configuredCallbacks, { key = keyCombo, turning = true })
        end
        return
    end

    local actionId = binding.id
    local callback = function()
        executeConfiguredAction(actionId)
    end
    g_keyboard.bindKeyDown(keyCombo, callback)
    table.insert(configuredCallbacks, { key = keyCombo, callback = callback })
end

function bindConfiguredHotkeys()
    unbindConfiguredHotkeys()
    for _, binding in ipairs(HotkeyBindings) do
        local values = configuredBindings[binding.id]
        if values then
            bindConfiguredAction(binding, values.primary)
            bindConfiguredAction(binding, values.secondary)
        end
    end
    if modules.game_pokemonmoves and modules.game_pokemonmoves.refreshHotkeys then
        modules.game_pokemonmoves.refreshHotkeys()
    end
    if modules.game_pokebar and modules.game_pokebar.refreshHotkeys then
        modules.game_pokebar.refreshHotkeys()
    end
end

function setMovementEnabled(enabled)
    movementEnabled = enabled
    bindConfiguredHotkeys()
end

local function canExecuteConfigured(binding)
    if captureWindow then
        return false
    end
    -- MainWindow:show() suspends gameplay hotkeys. Module shortcuts must stay
    -- available so the same configured key can close the window it opened.
    if disableHotkeysCount > 0 and binding.category ~= 'modules' then
        return false
    end
    if modules.game_console and modules.game_console.isChatEnabled and modules.game_console.isChatEnabled() then
        return binding.allowInChat == true
    end
    return true
end

local function toggleModule(moduleName, functionName)
    local gameModule = modules[moduleName]
    local callback = gameModule and gameModule[functionName or 'toggle']
    if callback then
        callback()
    end
end

function executeConfiguredAction(actionId)
    local binding = HotkeyBindingsById[actionId]
    if not binding or not canExecuteConfigured(binding) then
        return
    end

    if actionId == 'open_hotkeys' then
        toggle()
        return
    end
    if not g_game.isOnline() then
        return
    end

    if actionId:match('^pokemon_move_') then
        local slot = tonumber(actionId:match('(%d+)$'))
        if modules.game_pokemonmoves and modules.game_pokemonmoves.useMove then
            modules.game_pokemonmoves.useMove(slot)
        end
    elseif actionId:match('^pokemon_slot_') then
        local partyIndex = tonumber(actionId:match('(%d+)$'))
        local player = g_game.getLocalPlayer()
        local slot = InventoryPokeballSlotFirst + partyIndex - 1
        local item = player and player:getInventoryItem(slot)
        if item then
            g_game.use(item, slot)
        end
    elseif actionId == 'toggle_mount' then
        toggleModule('game_playermount', 'toggleMount')
    elseif actionId == 'cancel_target' then
        g_game.cancelAttackAndFollow()
    elseif actionId == 'attack_next' then
        toggleModule('game_battle', 'attackNext')
    elseif actionId == 'attack_previous' then
        if modules.game_battle and modules.game_battle.attackNext then
            modules.game_battle.attackNext(true)
        end
    elseif actionId == 'toggle_chase' then
        toggleModule('game_combatcontrols', 'toggleChaseMode')
    elseif actionId == 'open_inventory' then
        toggleModule('game_inventory')
    elseif actionId == 'open_pokebag' then
        toggleModule('game_pokebag')
    elseif actionId == 'open_box' then
        toggleModule('game_box')
    elseif actionId == 'open_trainer_card' then
        toggleModule('game_trainercard')
    elseif actionId == 'open_skills' then
        toggleModule('game_skills')
    elseif actionId == 'open_battle' then
        toggleModule('game_battle')
    elseif actionId == 'open_minimap' then
        toggleModule('game_minimap')
    elseif actionId == 'open_vip' then
        toggleModule('game_viplist')
    elseif actionId == 'open_tasks' then
        toggleModule('game_tasks', 'toggleWindow')
    elseif actionId == 'open_combat_controls' then
        toggleModule('game_combatcontrols')
    elseif actionId == 'open_options' then
        toggleModule('client_options')
    elseif actionId == 'open_shaders' then
        toggleModule('game_shaders')
    elseif actionId == 'open_bug_report' then
        toggleModule('game_bugreport', 'show')
    elseif actionId == 'open_chat' then
        if modules.game_console and not modules.game_console.isChatEnabled() then
            modules.game_console.switchChatOnCall()
        end
    elseif actionId == 'open_channels' then
        g_game.requestChannels()
    elseif actionId == 'close_channel' then
        toggleModule('game_console', 'removeCurrentTab')
    elseif actionId == 'chat_help' then
        toggleModule('game_console', 'openHelp')
    elseif actionId == 'zoom_in' then
        modules.game_interface.getMapPanel():zoomIn()
    elseif actionId == 'zoom_out' then
        modules.game_interface.getMapPanel():zoomOut()
    elseif actionId == 'toggle_full_map' then
        toggleModule('game_minimap', 'toggleFullMap')
    elseif actionId == 'map_pan_left' then
        toggleModule('game_minimap', 'panLeft')
    elseif actionId == 'map_pan_right' then
        toggleModule('game_minimap', 'panRight')
    elseif actionId == 'map_pan_up' then
        toggleModule('game_minimap', 'panUp')
    elseif actionId == 'map_pan_down' then
        toggleModule('game_minimap', 'panDown')
    elseif actionId == 'toggle_fullscreen' then
        if modules.client_options and modules.client_options.toggleOption then
            modules.client_options.toggleOption('fullscreen')
        end
    elseif actionId == 'toggle_displays' then
        toggleModule('client_options', 'toggleDisplays')
    elseif actionId == 'toggle_topmenu' then
        toggleModule('client_topmenu')
    elseif actionId == 'clear_screen' then
        g_map.cleanTexts()
        modules.game_textmessage.clearMessages()
    elseif actionId == 'logout' then
        modules.game_interface.tryLogout(false)
    end
end

function createCategoryButtons()
    categoryPanel:destroyChildren()
    categoryButtons = {}
    for _, category in ipairs(HotkeyCategories) do
        local categoryId = category.id
        local button = g_ui.createWidget('HotkeyCategoryButton', categoryPanel)
        button:setId('category_' .. categoryId)
        button:setText(category.text)
        button.onClick = function()
            selectCategory(categoryId)
        end
        categoryButtons[categoryId] = button
    end
end

local function bindingButtonText(keyCombo)
    if not keyCombo or keyCombo == '' then
        return tr('Not assigned')
    end
    return keyCombo
end

function renderCurrentCategory()
    if not actionsScroll or currentCategory == 'custom' then
        return
    end

    actionsScroll:destroyChildren()
    for _, binding in ipairs(HotkeyBindings) do
        if binding.category == currentCategory then
            local actionId = binding.id
            local row = g_ui.createWidget('HotkeyActionRow', actionsScroll)
            row:setId('binding_' .. actionId)
            row:getChildById('actionName'):setText(binding.text)
            row:getChildById('actionDescription'):setText(binding.description)
            local values = configuredBindings[actionId] or copyDefaultBindings(binding)
            local primary = row:getChildById('primaryKey')
            local secondary = row:getChildById('secondaryKey')
            primary:setText(bindingButtonText(values.primary))
            secondary:setText(bindingButtonText(values.secondary))
            primary.onClick = function()
                startBindingCapture(actionId, 'primary')
            end
            secondary.onClick = function()
                startBindingCapture(actionId, 'secondary')
            end
        end
    end
end

function refreshCurrentCategoryRows()
    if not actionsScroll or currentCategory == 'custom' then
        return
    end
    for _, binding in ipairs(HotkeyBindings) do
        if binding.category == currentCategory then
            local row = actionsScroll:getChildById('binding_' .. binding.id)
            local values = configuredBindings[binding.id]
            if row and values then
                row:getChildById('primaryKey'):setText(bindingButtonText(values.primary))
                row:getChildById('secondaryKey'):setText(bindingButtonText(values.secondary))
            end
        end
    end
end

function selectCategory(categoryId)
    currentCategory = categoryId
    for id, button in pairs(categoryButtons) do
        button:setOn(id == categoryId)
    end

    local isCustom = categoryId == 'custom'
    actionPanel:setVisible(not isCustom)
    customPanel:setVisible(isCustom)
    if isCustom then
        updateHotkeyForm(true)
        return
    end

    local category
    for _, candidate in ipairs(HotkeyCategories) do
        if candidate.id == categoryId then
            category = candidate
            break
        end
    end
    if category then
        actionPanel:getChildById('categoryTitle'):setText(category.text)
        actionPanel:getChildById('categoryDescription'):setText(category.description)
    end
    renderCurrentCategory()
end

function resetCurrentCategory()
    if currentCategory == 'custom' then
        for _, child in pairs(currentHotkeys:getChildren()) do
            g_keyboard.unbindKeyPress(child.keyCombo, boundCombosCallback[child.keyCombo])
        end
        boundCombosCallback = {}
        currentHotkeys:destroyChildren()
        currentHotkeyLabel = nil
        hotkeyList = {}
        updateHotkeyForm(true)
        return
    end

    for _, binding in ipairs(HotkeyBindings) do
        if binding.category == currentCategory then
            configuredBindings[binding.id] = copyDefaultBindings(binding)
        end
    end
    bindConfiguredHotkeys()
    refreshCurrentCategoryRows()
end

local function findConfiguredOwner(keyCombo, ignoredAction, ignoredSlot)
    if not keyCombo or keyCombo == '' then
        return nil
    end
    for _, binding in ipairs(HotkeyBindings) do
        local values = configuredBindings[binding.id]
        if values then
            if values.primary == keyCombo and (binding.id ~= ignoredAction or ignoredSlot ~= 'primary') then
                return binding, 'primary'
            elseif values.secondary == keyCombo and (binding.id ~= ignoredAction or ignoredSlot ~= 'secondary') then
                return binding, 'secondary'
            end
        end
    end
    return nil
end

function startBindingCapture(actionId, bindingSlot)
    if captureWindow then
        captureWindow:destroy()
    end
    captureWindow = g_ui.createWidget('HotkeyAssignWindow', rootWidget)
    captureWindow.actionId = actionId
    captureWindow.bindingSlot = bindingSlot
    captureWindow:grabKeyboard()
    captureWindow.onKeyDown = hotkeyCapture
    captureWindow:raise()
    captureWindow:focus()
    enableHotkeys(false)
    setMovementEnabled(false)
end

function cancelCapture(window)
    if window then
        window:destroy()
    end
    if captureWindow == window then
        captureWindow = nil
    end
    enableHotkeys(true)
    setMovementEnabled(not (modules.game_console and modules.game_console.isChatEnabled()))
end

function clearCapturedBinding(window)
    if window and window.actionId then
        configuredBindings[window.actionId][window.bindingSlot] = ''
        bindConfiguredHotkeys()
        refreshCurrentCategoryRows()
    end
    cancelCapture(window)
end

local function removeCustomKey(keyCombo)
    local label = currentHotkeys and currentHotkeys:getChildById(keyCombo)
    if not label then
        return
    end
    g_keyboard.unbindKeyPress(keyCombo, boundCombosCallback[keyCombo])
    boundCombosCallback[keyCombo] = nil
    hotkeyList[keyCombo] = nil
    if currentHotkeyLabel == label then
        currentHotkeyLabel = nil
    end
    label:destroy()
end

function applyCapturedBinding(window)
    if not window or not window.capturedKey or window.capturedKey == '' then
        return
    end

    local keyCombo = window.capturedKey
    if window.actionId then
        local owner, ownerSlot = findConfiguredOwner(keyCombo, window.actionId, window.bindingSlot)
        if owner then
            configuredBindings[owner.id][ownerSlot] = ''
        end
        removeCustomKey(keyCombo)
        configuredBindings[window.actionId][window.bindingSlot] = keyCombo
        bindConfiguredHotkeys()
        refreshCurrentCategoryRows()
    else
        local owner, ownerSlot = findConfiguredOwner(keyCombo)
        if owner then
            configuredBindings[owner.id][ownerSlot] = ''
        end
        addKeyCombo(keyCombo, nil, true)
        bindConfiguredHotkeys()
    end
    cancelCapture(window)
end

-- public functions
function init()
    hotkeysButton = modules.client_topmenu.addLeftGameButton('hotkeysButton', tr('Hotkeys'),
                                                             '/images/topbuttons/hotkeys', toggle)
    hotkeysWindow = g_ui.displayUI('hotkeys_manager')
    hotkeysWindow:setVisible(false)

    categoryPanel = hotkeysWindow:getChildById('categoryPanel')
    actionPanel = hotkeysWindow:getChildById('actionPanel')
    customPanel = hotkeysWindow:getChildById('customPanel')
    actionsScroll = actionPanel:getChildById('actionsScroll')
    currentHotkeys = customPanel:getChildById('currentHotkeys')
    currentItemPreview = customPanel:getChildById('itemPreview')
    addHotkeyButton = customPanel:getChildById('addHotkeyButton')
    removeHotkeyButton = customPanel:getChildById('removeHotkeyButton')
    hotkeyText = customPanel:getChildById('hotkeyText')
    hotKeyTextLabel = customPanel:getChildById('hotKeyTextLabel')
    sendAutomatically = customPanel:getChildById('sendAutomatically')
    selectObjectButton = customPanel:getChildById('selectObjectButton')
    clearObjectButton = customPanel:getChildById('clearObjectButton')
    useOnSelf = customPanel:getChildById('useOnSelf')
    useOnTarget = customPanel:getChildById('useOnTarget')
    useWith = customPanel:getChildById('useWith')

    useRadioGroup = UIRadioGroup.create()
    useRadioGroup:addWidget(useOnSelf)
    useRadioGroup:addWidget(useOnTarget)
    useRadioGroup:addWidget(useWith)
    useRadioGroup.onSelectionChange = function(self, selected)
        onChangeUseType(selected)
    end

    hotkeyActionCombo = customPanel:getChildById('hotkeyActionCombo')

    hotkeyActionCombo:addOption('None', 0)
    for _, action in pairs(HotkeyActions) do
        hotkeyActionCombo:addOption(action.text, action.id)
    end

    hotkeyActionCombo.onOptionChange = onActionChange

    mouseGrabberWidget = g_ui.createWidget('UIWidget')
    mouseGrabberWidget:setVisible(false)
    mouseGrabberWidget:setFocusable(false)
    mouseGrabberWidget.onMouseRelease = onChooseItemMouseRelease

    createCategoryButtons()

    currentHotkeys.onChildFocusChange = function(self, hotkeyLabel)
        onSelectHotkeyLabel(hotkeyLabel)
    end
    g_keyboard.bindKeyPress('Down', function()
        currentHotkeys:focusNextChild(KeyboardFocusReason)
    end, hotkeysWindow)
    g_keyboard.bindKeyPress('Up', function()
        currentHotkeys:focusPreviousChild(KeyboardFocusReason)
    end, hotkeysWindow)

    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    load()
    selectCategory(currentCategory)
end

function terminate()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    unload()

    if captureWindow then
        captureWindow:destroy()
        captureWindow = nil
    end

    hotkeysWindow:destroy()
    hotkeysButton:destroy()
    mouseGrabberWidget:destroy()
    hotkeysWindow = nil
    hotkeysButton = nil
    hotkeyActionCombo = nil
    hotKeyTextLabel = nil
    hotkeyText = nil
    sendAutomatically = nil
    selectObjectButton = nil
    clearObjectButton = nil
    mouseGrabberWidget = nil
    addHotkeyButton = nil
    removeHotkeyButton = nil
    itemPreview = nil
    useOnSelf = nil
    useOnTarget = nil
    useWith = nil
    currentHotkeys = nil
    categoryPanel = nil
    actionPanel = nil
    customPanel = nil
    actionsScroll = nil
    categoryButtons = {}
end

function configure(savePerServer, savePerCharacter)
    perServer = savePerServer
    perCharacter = savePerCharacter
    reload()
end

function online()
    reload()
    hide()
end

function offline()
    unload()
    hide()
end

function show()
    if not g_game.isOnline() then
        return
    end
    hotkeysWindow:show()
    hotkeysWindow:raise()
    hotkeysWindow:focus()
end

function hide()
    hotkeysWindow:hide()
end

function toggle()
    if not hotkeysWindow:isVisible() then
        show()
    else
        hide()
    end
end

function ok()
    save()
    hide()
end

function cancel()
    reload()
    hide()
end

function load(forceDefaults)
    hotkeysManagerLoaded = false

    loadConfiguredBindings(forceDefaults)

    local hotkeySettings = g_settings.getNode('game_hotkeys')
    local hotkeys = {}

    if not table.empty(hotkeySettings) then
        hotkeys = hotkeySettings
    end
    if perServer and not table.empty(hotkeys) then
        hotkeys = hotkeys[G.host]
    end
    if perCharacter and not table.empty(hotkeys) then
        hotkeys = hotkeys[g_game.getCharacterName()]
    end

    hotkeyList = {}
    if not forceDefaults then
        if not table.empty(hotkeys) then
            for keyCombo, setting in pairs(hotkeys) do
                keyCombo = tostring(keyCombo)
                if not migrateLegacyAction(keyCombo, setting) then
                    addKeyCombo(keyCombo, setting)
                    hotkeyList[keyCombo] = setting
                end
            end
        end
    end

    if currentHotkeys:getChildCount() == 0 then
        loadDefautComboKeys()
    end

    hotkeysManagerLoaded = true
    bindConfiguredHotkeys()
    renderCurrentCategory()
end

function unload()
    unbindConfiguredHotkeys()
    for keyCombo, callback in pairs(boundCombosCallback) do
        g_keyboard.unbindKeyPress(keyCombo, callback)
    end
    boundCombosCallback = {}
    currentHotkeys:destroyChildren()
    currentHotkeyLabel = nil
    updateHotkeyForm(true)
    hotkeyList = {}
    configuredBindings = {}
end

function reset()
    unload()
    load(true)
end

function reload()
    unload()
    load()
end

function save()
    local hotkeySettings = g_settings.getNode('game_hotkeys') or {}
    local hotkeys = hotkeySettings

    if perServer then
        if not hotkeys[G.host] then
            hotkeys[G.host] = {}
        end
        hotkeys = hotkeys[G.host]
    end

    if perCharacter then
        local char = g_game.getCharacterName()
        if not hotkeys[char] then
            hotkeys[char] = {}
        end
        hotkeys = hotkeys[char]
    end

    table.clear(hotkeys)

    for _, child in pairs(currentHotkeys:getChildren()) do
        hotkeys[child.keyCombo] = {
            autoSend = child.autoSend,
            itemId = child.itemId,
            subType = child.subType,
            useType = child.useType,
            value = child.value,
            action = child.action
        }
    end

    hotkeyList = hotkeys
    g_settings.setNode('game_hotkeys', hotkeySettings)
    saveConfiguredBindings()
    g_settings.save()
end

function loadDefautComboKeys()
    if defaultComboKeys then
        for keyCombo, keySettings in pairs(defaultComboKeys) do
            addKeyCombo(keyCombo, keySettings)
        end
    end
end

function setDefaultComboKeys(combo)
    defaultComboKeys = combo
end

function onActionChange(comboBox, option)
    local action = comboBox:getCurrentOption().data
    if currentHotkeyLabel then
        if action > 0 then
            currentHotkeyLabel.action = action
            currentHotkeyLabel.itemId = nil
            currentHotkeyLabel.value = nil
            currentHotkeyLabel.autoSend = nil
        else
            currentHotkeyLabel.action = nil
        end
        updateHotkeyLabel(currentHotkeyLabel)
        updateHotkeyForm(true, true)
    end
end

function onChooseItemMouseRelease(self, mousePosition, mouseButton)
    local item = nil
    if mouseButton == MouseLeftButton then
        local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
        if clickedWidget then
            if clickedWidget:getClassName() == 'UIGameMap' then
                local tile = clickedWidget:getTile(mousePosition)
                if tile then
                    local thing = tile:getTopMoveThing()
                    if thing and thing:isItem() then
                        item = thing
                    end
                end
            elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
                item = clickedWidget:getItem()
            end
        end
    end

    if item and currentHotkeyLabel then
        currentHotkeyLabel.itemId = item:getId()
        if item:isFluidContainer() then
            currentHotkeyLabel.subType = item:getSubType()
        end
        if item:isMultiUse() then
            currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
        else
            currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
        end
        currentHotkeyLabel.value = nil
        currentHotkeyLabel.autoSend = false
        updateHotkeyLabel(currentHotkeyLabel)
        updateHotkeyForm(true)
    end

    show()

    g_mouse.popCursor('target')
    self:ungrabMouse()
    return true
end

function startChooseItem()
    if g_ui.isMouseGrabbed() then
        return
    end
    mouseGrabberWidget:grabMouse()
    g_mouse.pushCursor('target')
    hide()
end

function clearObject()
    currentHotkeyLabel.itemId = nil
    currentHotkeyLabel.subType = nil
    currentHotkeyLabel.useType = nil
    currentHotkeyLabel.autoSend = nil
    currentHotkeyLabel.value = nil
    currentHotkeyLabel.action = nil
    updateHotkeyLabel(currentHotkeyLabel)
    updateHotkeyForm(true)
end

function addHotkey()
    if captureWindow then
        captureWindow:destroy()
    end
    local assignWindow = g_ui.createWidget('HotkeyAssignWindow', rootWidget)
    captureWindow = assignWindow
    assignWindow:getChildById('clearButton'):hide()
    assignWindow:grabKeyboard()
    assignWindow.onKeyDown = hotkeyCapture
    assignWindow:raise()
    assignWindow:focus()
    enableHotkeys(false)
    setMovementEnabled(false)
end

function addKeyCombo(keyCombo, keySettings, focus)
    if keyCombo == nil or #keyCombo == 0 then
        return
    end
    if not keyCombo then
        return
    end
    local hotkeyLabel = currentHotkeys:getChildById(keyCombo)
    if not hotkeyLabel then
        hotkeyLabel = g_ui.createWidget('HotkeyListLabel')
        hotkeyLabel:setId(keyCombo)

        local children = currentHotkeys:getChildren()
        children[#children + 1] = hotkeyLabel
        table.sort(children, function(a, b)
            if a:getId():len() < b:getId():len() then
                return true
            elseif a:getId():len() == b:getId():len() then
                return a:getId() < b:getId()
            else
                return false
            end
        end)
        for i = 1, #children do
            if children[i] == hotkeyLabel then
                currentHotkeys:insertChild(i, hotkeyLabel)
                break
            end
        end

        if keySettings then
            currentHotkeyLabel = hotkeyLabel
            hotkeyLabel.keyCombo = keyCombo
            hotkeyLabel.autoSend = toboolean(keySettings.autoSend)
            hotkeyLabel.itemId = tonumber(keySettings.itemId)
            hotkeyLabel.subType = tonumber(keySettings.subType)
            hotkeyLabel.useType = tonumber(keySettings.useType)
            hotkeyLabel.action = tonumber(keySettings.action)
            if keySettings.value then
                hotkeyLabel.value = tostring(keySettings.value)
            end
        else
            hotkeyLabel.keyCombo = keyCombo
            hotkeyLabel.autoSend = false
            hotkeyLabel.itemId = nil
            hotkeyLabel.subType = nil
            hotkeyLabel.useType = nil
            hotkeyLabel.action = nil
            hotkeyLabel.value = ''
        end

        updateHotkeyLabel(hotkeyLabel)

        boundCombosCallback[keyCombo] = function()
            doKeyCombo(keyCombo)
        end
        g_keyboard.bindKeyPress(keyCombo, boundCombosCallback[keyCombo])
    end

    if focus then
        currentHotkeys:focusChild(hotkeyLabel)
        currentHotkeys:ensureChildVisible(hotkeyLabel)
        updateHotkeyForm(true)
    end
end

function doKeyCombo(keyCombo)
    if not g_game.isOnline() then
        return
    end
    if not canPerformKeyCombo(keyCombo) then
        return
    end
    local hotKey = hotkeyList[keyCombo]
    if not hotKey then
        return
    end

    if g_clock.millis() - lastHotkeyTime < modules.client_options.getOption('hotkeyDelay') then
        return
    end
    lastHotkeyTime = g_clock.millis()

    if hotKey.action then
        if hotKey.action == HOTKEY_ACTION_TOGGLE_WASD then
            modules.game_console.toggleChat()
        elseif hotKey.action == HOTKEY_ACTION_ATTACK_NEXT then
            modules.game_battle.attackNext()
        elseif hotKey.action == HOTKEY_ACTION_ATTACK_PREV then
            modules.game_battle.attackNext(true)
        elseif hotKey.action == HOTKEY_ACTION_TOGGLE_CHASE then
            modules.game_combatcontrols.toggleChaseMode()
        end

    elseif hotKey.itemId == nil then
        if not hotKey.value or #hotKey.value == 0 then
            return
        end
        if hotKey.autoSend then
            modules.game_console.sendMessage(hotKey.value)
        else
            scheduleEvent(function()
                if not modules.game_console.isChatEnabled() then
                    modules.game_console.switchChatOnCall()
                end
                modules.game_console.setTextEditText(hotKey.value)
            end, 1)
        end
    else
        executeHotkeyItem(hotKey.useType, hotKey.itemId, hotKey.subType)
    end
end

function executeHotkeyItem(action, itemId, subType)
    if action == HOTKEY_MANAGER_USE then
        if g_game.getClientVersion() < 780 or subType then
            local item = g_game.findPlayerItem(itemId, subType or -1)
            if item then
                g_game.use(item)
            end
        else
            g_game.useInventoryItem(itemId)
        end
    elseif action == HOTKEY_MANAGER_USEONSELF then
        if g_game.getClientVersion() < 780 or subType then
            local item = g_game.findPlayerItem(itemId, subType or -1)
            if item then
                g_game.useWith(item, g_game.getLocalPlayer())
            end
        else
            g_game.useInventoryItemWith(itemId, g_game.getLocalPlayer())
        end
    elseif action == HOTKEY_MANAGER_USEONTARGET then
        local attackingCreature = g_game.getAttackingCreature()
        if not attackingCreature then
            local item = Item.create(itemId)
            if g_game.getClientVersion() < 780 or subType then
                local tmpItem = g_game.findPlayerItem(itemId, subType or -1)
                if not tmpItem then
                    return
                end
                item = tmpItem
            end

            modules.game_interface.startUseWith(item)
            return
        end

        if not attackingCreature:getTile() then
            return
        end
        if g_game.getClientVersion() < 780 or subType then
            local item = g_game.findPlayerItem(itemId, subType or -1)
            if item then
                g_game.useWith(item, attackingCreature)
            end
        else
            g_game.useInventoryItemWith(itemId, attackingCreature)
        end
    elseif action == HOTKEY_MANAGER_USEWITH then
        local item = Item.create(itemId)
        if g_game.getClientVersion() < 780 or subType then
            local tmpItem = g_game.findPlayerItem(itemId, subType or -1)
            if not tmpItem then
                return true
            end
            item = tmpItem
        end
        modules.game_interface.startUseWith(item)
    end
end

function updateHotkeyLabel(hotkeyLabel)
    if not hotkeyLabel then
        return
    end
    if hotkeyLabel.useType == HOTKEY_MANAGER_USEONSELF then
        hotkeyLabel:setText(tr('%s: (use object on yourself)', hotkeyLabel.keyCombo))
        hotkeyLabel:setColor(HotkeyColors.itemUseSelf)
    elseif hotkeyLabel.useType == HOTKEY_MANAGER_USEONTARGET then
        hotkeyLabel:setText(tr('%s: (use object on target)', hotkeyLabel.keyCombo))
        hotkeyLabel:setColor(HotkeyColors.itemUseTarget)
    elseif hotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
        hotkeyLabel:setText(tr('%s: (use object with crosshair)', hotkeyLabel.keyCombo))
        hotkeyLabel:setColor(HotkeyColors.itemUseWith)
    elseif hotkeyLabel.itemId ~= nil then
        hotkeyLabel:setText(tr('%s: (use object)', hotkeyLabel.keyCombo))
        hotkeyLabel:setColor(HotkeyColors.itemUse)
    elseif hotkeyLabel.action then
        for _, action in pairs(HotkeyActions) do
            if action.id == hotkeyLabel.action then
                hotkeyLabel:setText(tr('%s: ' .. action.text, hotkeyLabel.keyCombo))
                break
            end
        end
        hotkeyLabel:setColor(HotkeyColors.action)
    else
        local text = hotkeyLabel.keyCombo .. ': '
        if hotkeyLabel.value then
            text = text .. hotkeyLabel.value
        end
        hotkeyLabel:setText(text)
        if hotkeyLabel.autoSend then
            hotkeyLabel:setColor(HotkeyColors.textAutoSend)
        else
            hotkeyLabel:setColor(HotkeyColors.text)
        end
    end
end

function updateHotkeyForm(reset, dontUpdateCombo)
    if currentHotkeyLabel then
        removeHotkeyButton:enable()
        if currentHotkeyLabel.itemId ~= nil then
            if not dontUpdateCombo then
                hotkeyActionCombo:setCurrentIndex(1)
            end
            hotkeyActionCombo:disable()
            hotkeyText:clearText()
            hotkeyText:disable()
            hotKeyTextLabel:disable()
            sendAutomatically:setChecked(false)
            sendAutomatically:disable()
            selectObjectButton:disable()
            clearObjectButton:enable()
            currentItemPreview:setItemId(currentHotkeyLabel.itemId)
            if currentHotkeyLabel.subType then
                currentItemPreview:setItemSubType(currentHotkeyLabel.subType)
            end
            if currentItemPreview:getItem():isMultiUse() then
                useOnSelf:enable()
                useOnTarget:enable()
                useWith:enable()
                if currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONSELF then
                    useRadioGroup:selectWidget(useOnSelf)
                elseif currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONTARGET then
                    useRadioGroup:selectWidget(useOnTarget)
                elseif currentHotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
                    useRadioGroup:selectWidget(useWith)
                end
            else
                useOnSelf:disable()
                useOnTarget:disable()
                useWith:disable()
                useRadioGroup:clearSelected()
            end
        elseif currentHotkeyLabel.action then
            if not dontUpdateCombo then
                hotkeyActionCombo:setCurrentOptionByData(currentHotkeyLabel.action)
            end
            hotkeyActionCombo:enable()
            hotkeyText:clearText()
            hotkeyText:disable()
            hotKeyTextLabel:disable()
            sendAutomatically:setChecked(false)
            sendAutomatically:disable()
            selectObjectButton:disable()
            useOnSelf:disable()
            useOnTarget:disable()
            useWith:disable()
            useRadioGroup:clearSelected()
            selectObjectButton:disable()
            clearObjectButton:disable()
        else
            if not dontUpdateCombo then
                hotkeyActionCombo:setCurrentIndex(1)
            end
            hotkeyActionCombo:enable()
            useOnSelf:disable()
            useOnTarget:disable()
            useWith:disable()
            useRadioGroup:clearSelected()
            hotkeyText:enable()
            hotkeyText:focus()
            hotKeyTextLabel:enable()
            if reset then
                hotkeyText:setCursorPos(-1)
            end
            hotkeyText:setText(currentHotkeyLabel.value)
            sendAutomatically:setChecked(currentHotkeyLabel.autoSend)
            sendAutomatically:setEnabled(currentHotkeyLabel.value and #currentHotkeyLabel.value > 0)
            selectObjectButton:enable()
            clearObjectButton:disable()
            currentItemPreview:clearItem()
        end
    else
        if not dontUpdateCombo then
            hotkeyActionCombo:setCurrentIndex(1)
        end
        hotkeyActionCombo:disable()
        removeHotkeyButton:disable()
        hotkeyText:disable()
        sendAutomatically:disable()
        selectObjectButton:disable()
        clearObjectButton:disable()
        useOnSelf:disable()
        useOnTarget:disable()
        useWith:disable()
        hotkeyText:clearText()
        useRadioGroup:clearSelected()
        sendAutomatically:setChecked(false)
        currentItemPreview:clearItem()
    end
end

function removeHotkey()
    if currentHotkeyLabel == nil then
        return
    end
    g_keyboard.unbindKeyPress(currentHotkeyLabel.keyCombo, boundCombosCallback[currentHotkeyLabel.keyCombo])
    hotkeyList[currentHotkeyLabel.keyCombo] = nil
    boundCombosCallback[currentHotkeyLabel.keyCombo] = nil
    currentHotkeyLabel:destroy()
    currentHotkeyLabel = nil
    bindConfiguredHotkeys()
    updateHotkeyForm(true)
end

function onHotkeyTextChange(value)
    if not hotkeysManagerLoaded then
        return
    end
    if currentHotkeyLabel == nil then
        return
    end
    currentHotkeyLabel.value = value
    if value == '' then
        currentHotkeyLabel.autoSend = false
    end
    updateHotkeyLabel(currentHotkeyLabel)
    updateHotkeyForm()
end

function onSendAutomaticallyChange(autoSend)
    if not hotkeysManagerLoaded then
        return
    end
    if currentHotkeyLabel == nil then
        return
    end
    if not currentHotkeyLabel.value or #currentHotkeyLabel.value == 0 then
        return
    end
    currentHotkeyLabel.autoSend = autoSend
    updateHotkeyLabel(currentHotkeyLabel)
    updateHotkeyForm()
end

function onChangeUseType(useTypeWidget)
    if not hotkeysManagerLoaded then
        return
    end
    if currentHotkeyLabel == nil then
        return
    end
    if useTypeWidget == useOnSelf then
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USEONSELF
    elseif useTypeWidget == useOnTarget then
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USEONTARGET
    elseif useTypeWidget == useWith then
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
    else
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
    end
    updateHotkeyLabel(currentHotkeyLabel)
    updateHotkeyForm()
end

function onSelectHotkeyLabel(hotkeyLabel)
    currentHotkeyLabel = hotkeyLabel
    updateHotkeyForm(true)
end

function hotkeyCapture(assignWindow, keyCode, keyboardModifiers)
    local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
    if not keyCombo or keyCombo == '' then
        return true
    end
    local comboPreview = assignWindow:getChildById('comboPreview')
    comboPreview:setText(tr('Current key: %s', keyCombo))
    assignWindow.capturedKey = keyCombo
    comboPreview:resizeToText()
    assignWindow:getChildById('applyButton'):enable()

    local conflictLabel = assignWindow:getChildById('conflictLabel')
    local owner = findConfiguredOwner(keyCombo, assignWindow.actionId, assignWindow.bindingSlot)
    if owner then
        conflictLabel:setText(tr('This key is currently used by %s and will be reassigned.', owner.text))
    elseif isCustomKey(keyCombo) and assignWindow.actionId then
        conflictLabel:setText(tr('This key is currently used by a custom hotkey and will be reassigned.'))
    else
        conflictLabel:setText('')
    end
    return true
end

function hotkeyCaptureOk(assignWindow, keyCombo)
    assignWindow.capturedKey = keyCombo
    applyCapturedBinding(assignWindow)
end

function enableHotkeys(value)
    disableHotkeysCount = disableHotkeysCount + (value and -1 or 1)

    if disableHotkeysCount < 0 then
        disableHotkeysCount = 0;
    end
end

function areHotkeysDisabled()
    return disableHotkeysCount > 0
end

-- Even if hotkeys are enabled, only the hotkeys containing Ctrl or Alt or F1-F12 will be enabled when
-- chat is opened (no WASD mode). This is made to prevent executing hotkeys while typing...
function canPerformKeyCombo(keyCombo)
    return disableHotkeysCount == 0 and
               (not modules.game_console:isChatEnabled() or string.match(keyCombo, 'F%d%d?') or
                   string.match(keyCombo, 'Ctrl%+') or string.match(keyCombo, 'Shift%+..+') or
                   string.match(keyCombo, 'Alt%+'))
end
