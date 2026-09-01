local dialog
local npcNameLabel
local npcOutfit
local speechPanel
local speechScrollBar
local optionsPanel
local optionInput
local bottomResizeBorder
local gameMapPanel
local currentNpc
local currentNpcName
local closeEvent
local scrollEvent
local pendingFarewell = false
local userPositioned = false
local tradeAvailable = false
local tradeLabel = 'Trade'
local tradeKeyword = 'trade'

local OPTION_HEIGHT = 30
local MINIMUM_DIALOG_HEIGHT = 220
local DIALOG_CHROME_HEIGHT = 162
local FAREWELL_CLOSE_DELAY = 450
local FAREWELL_FALLBACK_DELAY = 1000
local KEYWORD_COLOR = '#4f7fa3'

local function cancelCloseEvent()
    if closeEvent then
        removeEvent(closeEvent)
        closeEvent = nil
    end
end

local function clearConversation()
    cancelCloseEvent()
    if scrollEvent then
        removeEvent(scrollEvent)
        scrollEvent = nil
    end

    currentNpc = nil
    currentNpcName = nil
    optionInput = nil
    pendingFarewell = false
    tradeAvailable = false
    tradeLabel = 'Trade'
    tradeKeyword = 'trade'

    if speechPanel then
        speechPanel:destroyChildren()
    end
    if optionsPanel then
        optionsPanel:destroyChildren()
    end
    if dialog then
        dialog:setVisible(false)
    end
end

local function findNpc(name, position)
    if not gameMapPanel then
        return nil
    end

    local fallback
    for _, creature in ipairs(gameMapPanel:getSpectators()) do
        if creature:isNpc() and creature:getName() == name then
            fallback = fallback or creature
            local creaturePosition = creature:getPosition()
            if position and creaturePosition.x == position.x and creaturePosition.y == position.y and
                creaturePosition.z == position.z then
                return creature
            end
        end
    end
    return fallback
end

local function isInTalkRange()
    local player = g_game.getLocalPlayer()
    if not player or not currentNpc then
        return false
    end

    local playerPosition = player:getPosition()
    local npcPosition = currentNpc:getPosition()
    if playerPosition.z ~= npcPosition.z then
        return false
    end

    return math.max(math.abs(playerPosition.x - npcPosition.x), math.abs(playerPosition.y - npcPosition.y)) <= 3
end

local function placeDialog()
    if not dialog or not dialog:isVisible() or not currentNpc or userPositioned then
        return
    end

    if not gameMapPanel then
        return
    end

    local visible = gameMapPanel:getVisibleDimension()
    local camera = gameMapPanel:getCameraPosition()
    local npcPosition = currentNpc:getPosition()
    if not visible or visible.width == 0 or visible.height == 0 or npcPosition.z ~= camera.z then
        return
    end

    local mapPosition = { x = gameMapPanel:getX(), y = gameMapPanel:getY() }
    local tileSize = math.min(gameMapPanel:getWidth() / visible.width, gameMapPanel:getHeight() / visible.height)
    local creatureX = mapPosition.x + (gameMapPanel:getWidth() / 2) + ((npcPosition.x - camera.x) * tileSize)
    local creatureY = mapPosition.y + (gameMapPanel:getHeight() / 2) + ((npcPosition.y - camera.y) * tileSize)
    local margin = 8
    local x = creatureX - (dialog:getWidth() / 2)
    local y = creatureY - (tileSize / 2) - dialog:getHeight() - 12

    x = math.max(mapPosition.x + margin,
        math.min(x, mapPosition.x + gameMapPanel:getWidth() - dialog:getWidth() - margin))
    if y < mapPosition.y + margin then
        y = creatureY + (tileSize / 2) + 12
    end
    y = math.max(mapPosition.y + margin,
        math.min(y, mapPosition.y + gameMapPanel:getHeight() - dialog:getHeight() - margin))

    dialog:setPosition({ x = math.floor(x), y = math.floor(y) })
end

local function extractOptions(message)
    local options = {}
    local found = {}

    for keyword in message:gmatch('{([^}]+)}') do
        local normalized = keyword:lower()
        if normalized ~= 'bye' and not found[normalized] then
            table.insert(options, { label = keyword, keyword = keyword })
            found[normalized] = true
        end
    end

    local cleanMessage = message:gsub('{([^}]+)}', '%1')
    local coloredMessage = message:gsub('{([^}]+)}', '{%1, ' .. KEYWORD_COLOR .. '}')
    return options, cleanMessage, coloredMessage
end

local function scrollSpeechToBottom()
    if scrollEvent then
        removeEvent(scrollEvent)
    end
    scrollEvent = scheduleEvent(function()
        scrollEvent = nil
        if speechScrollBar and not speechScrollBar:isDestroyed() then
            speechScrollBar:setValue(speechScrollBar:getMaximum())
        end
    end, 1)
end

local function updateContentWidths()
    if speechPanel then
        for _, child in ipairs(speechPanel:getChildren()) do
            child:setWidth(math.max(40, speechPanel:getWidth() - 2))
        end
    end
    if optionsPanel then
        for _, child in ipairs(optionsPanel:getChildren()) do
            child:setWidth(math.max(40, optionsPanel:getWidth() - 2))
        end
    end
end

local function addHistoryMessage(text, fromPlayer, coloredText)
    local style = fromPlayer and 'NpcDialogPlayerMessage' or 'NpcDialogNpcMessage'
    local label = g_ui.createWidget(style, speechPanel)
    label:setWidth(math.max(40, speechPanel:getWidth() - 2))
    if coloredText then
        label:setColoredText(coloredText)
    else
        label:setText(text)
    end
    scrollSpeechToBottom()
end

local function updateOptionsHeight(optionCount)
    local optionsHeight = math.max(OPTION_HEIGHT, optionCount * OPTION_HEIGHT)
    optionsPanel:setHeight(optionsHeight)

    local requiredHeight = math.max(MINIMUM_DIALOG_HEIGHT, DIALOG_CHROME_HEIGHT + optionsHeight)
    bottomResizeBorder:setMinimum(requiredHeight)
    if dialog:getHeight() < requiredHeight then
        dialog:setHeight(requiredHeight)
    end
    dialog:bindRectToParent()
end

local function sendChoice(keyword)
    if not g_game.isOnline() or not currentNpcName then
        clearConversation()
        return
    end

    pendingFarewell = keyword:lower() == 'bye'
    addHistoryMessage(keyword, true)
    if pendingFarewell then
        optionsPanel:setEnabled(false)
    end
    g_game.talkPrivate(MessageModes.NpcTo, currentNpcName, keyword)

    if pendingFarewell then
        cancelCloseEvent()
        closeEvent = scheduleEvent(clearConversation, FAREWELL_FALLBACK_DELAY)
    end
end

local function sendTypedChoice()
    if not optionInput or optionInput:isDestroyed() or not optionsPanel:isEnabled() then
        return false
    end

    local keyword = optionInput:getText():trim()
    if #keyword == 0 then
        return false
    end

    optionInput:setText('')
    sendChoice(keyword)
    return true
end

local function setOptions(options)
    optionsPanel:destroyChildren()
    optionInput = nil
    optionsPanel:setEnabled(true)

    for _, option in ipairs(options) do
        if option.keyword:lower() == 'trade' then
            tradeAvailable = true
            tradeLabel = option.label
            tradeKeyword = option.keyword
        else
            local keyword = option.keyword
            local row = g_ui.createWidget('NpcDialogOptionRow', optionsPanel)
            local checkBox = row:getChildById('optionCheckBox')
            local button = row:getChildById('optionButton')
            button:setText(option.label)
            button.onClick = function()
                sendChoice(keyword)
            end
            checkBox.onCheckChange = function(self, checked)
                if checked then
                    self:setChecked(false)
                    sendChoice(keyword)
                end
            end
        end
    end

    local inputRow = g_ui.createWidget('NpcDialogInputRow', optionsPanel)
    local inputCheckBox = inputRow:getChildById('optionCheckBox')
    optionInput = inputRow:getChildById('optionInput')
    optionInput.onKeyDown = function(_, keyCode)
        if keyCode == KeyEnter then
            sendTypedChoice()
            return true
        end
        return false
    end
    inputCheckBox.onCheckChange = function(self, checked)
        if checked then
            self:setChecked(false)
            sendTypedChoice()
        end
    end

    if tradeAvailable then
        local tradeRow = g_ui.createWidget('NpcDialogTradeRow', optionsPanel)
        local tradeCheckBox = tradeRow:getChildById('optionCheckBox')
        local tradeButton = tradeRow:getChildById('optionButton')
        tradeButton:setText(tradeLabel)
        tradeButton.onClick = function()
            sendChoice(tradeKeyword)
        end
        tradeCheckBox.onCheckChange = function(self, checked)
            if checked then
                self:setChecked(false)
                sendChoice(tradeKeyword)
            end
        end
    end

    local byeRow = g_ui.createWidget('NpcDialogByeRow', optionsPanel)
    local byeCheckBox = byeRow:getChildById('optionCheckBox')
    local byeButton = byeRow:getChildById('optionButton')
    byeButton:setText(tr('Bye'))
    byeButton.onClick = sayBye
    byeCheckBox.onCheckChange = function(self, checked)
        if checked then
            self:setChecked(false)
            sayBye()
        end
    end

    local optionCount = #options + 2
    if tradeAvailable then
        local currentResponseHasTrade = false
        for _, option in ipairs(options) do
            if option.keyword:lower() == 'trade' then
                currentResponseHasTrade = true
                break
            end
        end
        if not currentResponseHasTrade then
            optionCount = optionCount + 1
        end
    end
    updateOptionsHeight(optionCount)
    updateContentWidths()
    optionInput:focus()
end

local function showNpc(creature)
    if not creature then
        return
    end

    currentNpc = creature
    currentNpcName = creature:getName()
    npcNameLabel:setText(currentNpcName)
    npcOutfit:setOutfit(creature:getOutfit())
    dialog:setVisible(true)
    dialog:raise()
    placeDialog()
end

function init()
    g_ui.importStyle('npcdialog')
    gameMapPanel = modules.game_interface.getMapPanel()
    dialog = g_ui.createWidget('NpcDialogPanel', rootWidget)
    npcNameLabel = dialog:recursiveGetChildById('npcName')
    npcOutfit = dialog:recursiveGetChildById('npcOutfit')
    speechPanel = dialog:recursiveGetChildById('speechPanel')
    speechScrollBar = dialog:recursiveGetChildById('speechScrollBar')
    optionsPanel = dialog:recursiveGetChildById('optionsPanel')
    bottomResizeBorder = dialog:recursiveGetChildById('bottomResizeBorder')

    dialog.onDragEnter = function(self, mousePosition)
        userPositioned = true
        return UIWindow.onDragEnter(self, mousePosition)
    end
    dialog.onDragMove = function(self, mousePosition, mouseMoved)
        return UIWindow.onDragMove(self, mousePosition, mouseMoved)
    end
    dialog.onGeometryChange = function()
        updateContentWidths()
    end

    connect(g_game, {
        onTalk = onTalk,
        onGameEnd = clearConversation
    })
    connect(LocalPlayer, { onPositionChange = onCreaturePositionChange })
    connect(Creature, {
        onPositionChange = onCreaturePositionChange,
        onDisappear = onCreatureDisappear
    })
    connect(UIMap, { onZoomChange = placeDialog })
    connect(gameMapPanel, { onGeometryChange = placeDialog })
end

function terminate()
    disconnect(g_game, {
        onTalk = onTalk,
        onGameEnd = clearConversation
    })
    disconnect(LocalPlayer, { onPositionChange = onCreaturePositionChange })
    disconnect(Creature, {
        onPositionChange = onCreaturePositionChange,
        onDisappear = onCreatureDisappear
    })
    disconnect(UIMap, { onZoomChange = placeDialog })
    disconnect(gameMapPanel, { onGeometryChange = placeDialog })

    cancelCloseEvent()
    if dialog then
        dialog:destroy()
        dialog = nil
    end
    gameMapPanel = nil
end

function handlesNpcMessages(name)
    return dialog and dialog:isVisible() and currentNpcName == name
end

function useNpc(creature)
    if not creature or not creature:isNpc() then
        return
    end

    clearConversation()
    showNpc(creature)
    setOptions({})
    g_game.talkPrivate(MessageModes.NpcTo, creature:getName(), 'hi')
end

function sayBye()
    if not currentNpcName then
        clearConversation()
        return
    end
    sendChoice('bye')
end

function onTalk(name, _, mode, message, _, creaturePosition)
    if mode ~= MessageModes.NpcFrom and mode ~= MessageModes.NpcFromStartBlock then
        return
    end

    if not dialog:isVisible() or not currentNpcName or currentNpcName ~= name then
        return
    end

    local creature = findNpc(name, creaturePosition)
    if not creature then
        return
    end

    if not currentNpc then
        showNpc(creature)
    end

    cancelCloseEvent()
    local options, cleanMessage, coloredMessage = extractOptions(message)
    addHistoryMessage(cleanMessage, false, coloredMessage)
    setOptions(options)

    if pendingFarewell then
        optionsPanel:setEnabled(false)
        closeEvent = scheduleEvent(clearConversation, FAREWELL_CLOSE_DELAY)
    end
end

function onCreaturePositionChange(creature)
    if not currentNpc then
        return
    end

    if creature == currentNpc or creature:isLocalPlayer() then
        if not isInTalkRange() then
            clearConversation()
        else
            placeDialog()
        end
    end
end

function onCreatureDisappear(creature)
    if currentNpc and creature == currentNpc then
        clearConversation()
    end
end
