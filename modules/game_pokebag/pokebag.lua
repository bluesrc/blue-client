local pokebagWindow
local pokebagButton
local pokemonList
local detailsPanel
local emptyPanel
local statsGrid
local topInfoPanel
local movesPanel
local infoTab
local movesTab
local activeMovesList
local learnedMovesList
local pokemonInfo = {}
local selectedSlot
local selectedMoveId
local currentDetailsTab = 'info'
local POKEMON_MOVE_SLOTS_OPCODE = 76

local natureNames = {
    [0] = 'None', 'Hardy', 'Lonely', 'Brave', 'Adamant', 'Naughty', 'Bold', 'Docile', 'Relaxed', 'Impish',
    'Lax', 'Timid', 'Hasty', 'Serious', 'Jolly', 'Naive', 'Modest', 'Mild', 'Quiet', 'Bashful', 'Rash',
    'Calm', 'Gentle', 'Sassy', 'Careful', 'Quirky'
}

local typeNames = {
    [0] = 'None', 'Bug', 'Dark', 'Dragon', 'Electric', 'Fairy', 'Fighting', 'Fire', 'Flying', 'Ghost',
    'Grass', 'Ground', 'Ice', 'Normal', 'Poison', 'Psychic', 'Rock', 'Steel', 'Water'
}

local genderNames = {
    [0] = 'Genderless',
    [1] = 'Male',
    [2] = 'Female',
    [3] = 'Undefined'
}

local genderImages = {
    [0] = '/images/gender/gender_undefined',
    [1] = '/images/gender/gender_male',
    [2] = '/images/gender/gender_female',
    [3] = '/images/gender/gender_undefined'
}

local moveCategoryNames = {
    [0] = 'Physical',
    [1] = 'Special',
    [2] = 'Status'
}

local moveTargetNames = {
    [0] = 'Target',
    [1] = 'Self',
    [2] = 'Area'
}

-- The type atlas follows the order used by the image, which differs from
-- PokemonType in the protocol. Each row in both atlases is 64x28 pixels.
local moveTypeSpriteRows = {
    [0] = 9,   -- None
    [1] = 6,   -- Bug
    [2] = 17,  -- Dark
    [3] = 16,  -- Dragon
    [4] = 13,  -- Electric
    [5] = 18,  -- Fairy
    [6] = 1,   -- Fighting
    [7] = 10,  -- Fire
    [8] = 2,   -- Flying
    [9] = 7,   -- Ghost
    [10] = 12, -- Grass
    [11] = 4,  -- Ground
    [12] = 15, -- Ice
    [13] = 0,  -- Normal
    [14] = 3,  -- Poison
    [15] = 14, -- Psychic
    [16] = 5,  -- Rock
    [17] = 8,  -- Steel
    [18] = 11  -- Water
}

local natureModifiers = {
    [2] = { attack = 1, defense = -1 },
    [3] = { attack = 1, speed = -1 },
    [4] = { attack = 1, specialAttack = -1 },
    [5] = { attack = 1, specialDefense = -1 },
    [6] = { defense = 1, attack = -1 },
    [8] = { defense = 1, speed = -1 },
    [9] = { defense = 1, specialAttack = -1 },
    [10] = { defense = 1, specialDefense = -1 },
    [11] = { speed = 1, attack = -1 },
    [12] = { speed = 1, defense = -1 },
    [14] = { speed = 1, specialAttack = -1 },
    [15] = { speed = 1, specialDefense = -1 },
    [16] = { specialAttack = 1, attack = -1 },
    [17] = { specialAttack = 1, defense = -1 },
    [18] = { specialAttack = 1, speed = -1 },
    [20] = { specialAttack = 1, specialDefense = -1 },
    [21] = { specialDefense = 1, attack = -1 },
    [22] = { specialDefense = 1, defense = -1 },
    [23] = { specialDefense = 1, speed = -1 },
    [24] = { specialDefense = 1, specialAttack = -1 }
}

local statRows = {
    { key = 'hp', label = 'HP' },
    { key = 'attack', label = 'Attack' },
    { key = 'defense', label = 'Defense' },
    { key = 'specialAttack', label = 'Sp. Attack' },
    { key = 'specialDefense', label = 'Sp. Defense' },
    { key = 'speed', label = 'Speed' }
}

local function makeStats(hp, attack, defense, specialAttack, specialDefense, speed)
    return {
        hp = hp or 0,
        attack = attack or 0,
        defense = defense or 0,
        specialAttack = specialAttack or 0,
        specialDefense = specialDefense or 0,
        speed = speed or 0
    }
end

local function healthColor(percent)
    if percent > 60 then
        return '#50a150'
    elseif percent > 30 then
        return '#a1a100'
    end
    return '#bf0a0a'
end

local function pokemonImagePath(info, portrait)
    if not portrait then
        return '/images/pokemon/icon/' .. string.format('%04d', info.number or 0) .. '.png'
    end

    local assetName = (info.name or ''):upper():gsub('[^A-Z0-9]+', '_'):gsub('^_', ''):gsub('_$', '')
    local folder = info.shiny and '/images/pokemon/front/shiny/' or '/images/pokemon/front/'
    local suffix = info.gender == 2 and '_female' or ''
    local path = folder .. assetName .. suffix .. '.png'
    if not g_resources.fileExists(path) then
        path = folder .. assetName .. '.png'
    end
    if not g_resources.fileExists(path) then
        path = pokemonImagePath(info, false)
    end
    return path
end

local function setValue(id, value)
    detailsPanel:recursiveGetChildById(id):setText(tostring(value))
end

local function addStatCell(style, text, color)
    local cell = g_ui.createWidget(style, statsGrid)
    cell:setText(tostring(text))
    if color then
        cell:setColor(color)
    end
    return cell
end

local function renderStats(info)
    statsGrid:destroyChildren()
    addStatCell('PokebagStatHeader', tr('Stat'))
    addStatCell('PokebagStatHeader', tr('Value'))
    addStatCell('PokebagStatHeader', 'IV')
    addStatCell('PokebagStatHeader', 'EV')

    local modifiers = natureModifiers[info.nature] or {}
    for _, stat in ipairs(statRows) do
        local modifier = modifiers[stat.key] or 0
        local statColor
        if modifier > 0 then
            statColor = '#50b96b'
        elseif modifier < 0 then
            statColor = '#d95757'
        end

		local statValue = info.stats[stat.key]
		local baseValue = info.baseStats and info.baseStats[stat.key] or statValue
		local battleDelta = info.active and (statValue - baseValue) or 0
		local displayedValue = statValue
		if battleDelta ~= 0 then
			displayedValue = string.format('%d (%+d)', statValue, battleDelta)
			statColor = battleDelta > 0 and '#50b96b' or '#d95757'
		end

        addStatCell('PokebagStatCell', tr(stat.label), statColor)
        addStatCell('PokebagStatCell', displayedValue, statColor)
        addStatCell('PokebagStatCell', info.ivs[stat.key])
        addStatCell('PokebagStatCell', info.evs[stat.key])
    end
end

local function setTypeIcon(icon, pokemonType)
    local typeRow = moveTypeSpriteRows[pokemonType] or moveTypeSpriteRows[0]
    icon:setImageClip(torect(string.format('0 %d 64 28', typeRow * 28)))
    icon:setTooltip(tr(typeNames[pokemonType] or 'None'))
end

local function setMoveIcons(entry, move)
    local typeIcon = entry:getChildById('moveTypeIcon')
    local categoryIcon = entry:getChildById('moveCategoryIcon')
    local category = math.max(0, math.min(2, move.category or 2))

    setTypeIcon(typeIcon, move.type)
    typeIcon:setVisible(true)

    categoryIcon:setImageClip(torect(string.format('0 %d 64 28', category * 28)))
    categoryIcon:setTooltip(tr(moveCategoryNames[category] or 'Status'))
    categoryIcon:setVisible(true)
end

local function hideMoveIcons(entry)
    entry:getChildById('moveTypeIcon'):setVisible(false)
    entry:getChildById('moveCategoryIcon'):setVisible(false)
end

local function setMoveEntry(entry, move, slot)
    local slotLabel = entry:getChildById('moveSlot')
    if slotLabel then
        slotLabel:setText(slot .. '.')
    end
    entry:getChildById('moveName'):setText(move.name)
    entry:getChildById('moveMeta'):setText(string.format('%s: %.1fs', tr('Cooldown'), move.cooldown / 1000))
    setMoveIcons(entry, move)
    entry:setTooltip(tr('Drag to reorder. Drag to Learned Moves to remove it.'))
end

local function findMoveById(info, moveId)
    for _, move in ipairs(info and info.moves or {}) do
        if move.id == moveId then
            return move
        end
    end
    return nil
end

local function getActiveMoveIds(info)
    local movesBySlot = {}
    for _, move in ipairs(info and info.moves or {}) do
        if move.activeSlot >= 1 and move.activeSlot <= 4 then
            movesBySlot[move.activeSlot] = move.id
        end
    end

    local moveIds = {}
    for slot = 1, 4 do
        if movesBySlot[slot] then
            table.insert(moveIds, movesBySlot[slot])
        end
    end
    return moveIds
end

local function sendActiveMoveIds(moveIds)
    if not selectedSlot or not pokemonInfo[selectedSlot] then
        return
    end

    local protocolGame = g_game.getProtocolGame()
    if not protocolGame then
        return
    end

    protocolGame:sendExtendedOpcode(POKEMON_MOVE_SLOTS_OPCODE, string.format(
        '%d;%d;%d;%d;%d', selectedSlot, moveIds[1] or 0, moveIds[2] or 0,
        moveIds[3] or 0, moveIds[4] or 0))
end

local function canChangeActiveMoves(showMessage)
    local info = selectedSlot and pokemonInfo[selectedSlot]
    local message
    if not info then
        return false
    elseif info.active then
        message = tr('Return this Pokemon before changing its active moves.')
    else
        local player = g_game.getLocalPlayer()
        if player and player:hasState(PlayerStates.Swords) then
            message = tr('You cannot change Pokemon moves while in combat.')
        end
    end

    if message then
        if showMessage and modules.game_textmessage then
            modules.game_textmessage.displayFailureMessage(message)
        end
        return false
    end
    return true
end

local function findActiveMoveIndex(moveIds, moveId)
    for index, activeMoveId in ipairs(moveIds) do
        if activeMoveId == moveId then
            return index
        end
    end
    return nil
end

local function dropMoveOnActiveSlots(draggedWidget, targetSlot)
    if not canChangeActiveMoves(true) then
        return false
    end

    local info = selectedSlot and pokemonInfo[selectedSlot]
    local move = info and draggedWidget and findMoveById(info, draggedWidget.moveId)
    if not move then
        return false
    end

    local moveIds = getActiveMoveIds(info)
    local sourceIndex = findActiveMoveIndex(moveIds, move.id)
    if sourceIndex then
        table.remove(moveIds, sourceIndex)
        targetSlot = math.max(1, math.min(targetSlot or (#moveIds + 1), #moveIds + 1))
        table.insert(moveIds, targetSlot, move.id)
    else
        if #moveIds >= 4 and not targetSlot then
            return true
        end

        targetSlot = math.max(1, math.min(targetSlot or (#moveIds + 1), math.min(4, #moveIds + 1)))
        if targetSlot <= #moveIds then
            moveIds[targetSlot] = move.id
        else
            table.insert(moveIds, move.id)
        end
    end
    sendActiveMoveIds(moveIds)
    return true
end

local function dropMoveOnLearnedList(draggedWidget)
    if not canChangeActiveMoves(true) then
        return false
    end

    local info = selectedSlot and pokemonInfo[selectedSlot]
    if not info or not draggedWidget or not draggedWidget.moveId then
        return false
    end

    local moveIds = getActiveMoveIds(info)
    local sourceIndex = findActiveMoveIndex(moveIds, draggedWidget.moveId)
    if not sourceIndex then
        return false
    end

    table.remove(moveIds, sourceIndex)
    sendActiveMoveIds(moveIds)
    return true
end

local function configureMoveDragging(entry, source)
    entry.moveSource = source
    entry:setDraggable(true)
    entry.onDragEnter = function(widget)
        if not canChangeActiveMoves(true) then
            return false
        end
        widget.dragOriginalOpacity = widget:getOpacity()
        widget:setOpacity(0.65)
        g_mouse.pushCursor('target')
        return true
    end
    entry.onDragLeave = function(widget)
        if not widget:isDestroyed() then
            widget:setOpacity(widget.dragOriginalOpacity or 1)
        end
        widget.dragOriginalOpacity = nil
        g_mouse.popCursor('target')
        return true
    end
end

local function refreshMoveSelection()
    if activeMovesList then
        for _, entry in ipairs(activeMovesList:getChildren()) do
            entry:setOn(entry.moveId == selectedMoveId)
        end
    end
    if learnedMovesList then
        for _, entry in ipairs(learnedMovesList:getChildren()) do
            entry:setOn(entry.moveId == selectedMoveId)
        end
    end
end

local function showMoveDetails(move)
    local nameLabel = movesPanel:recursiveGetChildById('moveDetailsName')
    local detailsLabel = movesPanel:recursiveGetChildById('moveDetailsText')
    if not move then
        selectedMoveId = nil
        nameLabel:setText(tr('Select an active move'))
        detailsLabel:setText('')
        refreshMoveSelection()
        return
    end

    selectedMoveId = move.id
    nameLabel:setText(move.name)
    detailsLabel:setText(string.format(
        '%s: %s\n%s: %d\nPP: %d\n%s: %d%%\n%s: %.1fs',
        tr('Target'), tr(moveTargetNames[move.target] or 'Self'),
        tr('Power'), move.power,
        move.pp,
        tr('Accuracy'), move.accuracy,
        tr('Cooldown'), move.cooldown / 1000))
    refreshMoveSelection()
end

local function renderMoves(info)
    activeMovesList:destroyChildren()
    learnedMovesList:destroyChildren()

    local movesBySlot = {}
    local selectedMove
    for _, move in ipairs(info.moves or {}) do
        if move.id == selectedMoveId then
            selectedMove = move
        end
    end
    for slot, moveId in ipairs(getActiveMoveIds(info)) do
        movesBySlot[slot] = findMoveById(info, moveId)
    end

    for slot = 1, 4 do
        local move = movesBySlot[slot]
        local entry = g_ui.createWidget('PokebagMoveEntry', activeMovesList)
        entry:setId('activeMove' .. slot)
        if move then
            local currentMove = move
            entry.moveId = move.id
            setMoveEntry(entry, move, slot)
            configureMoveDragging(entry, 'active')
            local targetSlot = slot
            entry.onDrop = function(_, draggedWidget)
                return dropMoveOnActiveSlots(draggedWidget, targetSlot)
            end
            entry.onMousePress = function(_, _, button)
                if button == MouseLeftButton then
                    showMoveDetails(currentMove)
                    return true
                end
                return false
            end
            selectedMove = selectedMove or move
        else
            entry:getChildById('moveSlot'):setText(slot .. '.')
            entry:getChildById('moveName'):setText('')
            entry:getChildById('moveMeta'):setText('')
            hideMoveIcons(entry)
            entry:setOpacity(0.5)
            entry:setDraggable(false)
            entry:setTooltip(tr('Drag a learned move here to activate it.'))
            local targetSlot = slot
            entry.onDrop = function(_, draggedWidget)
                return dropMoveOnActiveSlots(draggedWidget, targetSlot)
            end
        end
    end

    for _, move in ipairs(info.moves or {}) do
        local currentMove = move
        local entry = g_ui.createWidget('PokebagLearnedMoveEntry', learnedMovesList)
        entry:setId('learnedMove' .. move.id)
        entry.moveId = move.id
        local nameLabel = entry:getChildById('moveName')
        local metaLabel = entry:getChildById('moveMeta')
        nameLabel:setText(move.name)
        if move.activeSlot > 0 then
            nameLabel:setColor('#f3d66c')
            metaLabel:setText(tr('Active'))
            metaLabel:setColor('#62c979')
        else
            metaLabel:setText('')
        end
        setMoveIcons(entry, move)
        configureMoveDragging(entry, 'learned')
        entry:setTooltip(move.activeSlot > 0 and
            tr('Drag to Active Moves to reorder it, or inside Learned Moves to remove it.') or
            tr('Drag to Active Moves to activate it.'))
        entry.onDrop = function(_, draggedWidget)
            return dropMoveOnLearnedList(draggedWidget)
        end
        entry.onMousePress = function(_, _, button)
            if button == MouseLeftButton then
                showMoveDetails(currentMove)
                return true
            end
            return false
        end
        selectedMove = selectedMove or move
    end

    showMoveDetails(selectedMove)
end

function selectDetailsTab(tabName)
    currentDetailsTab = tabName == 'moves' and 'moves' or 'info'
    local showInfo = currentDetailsTab == 'info'
    infoTab:setOn(showInfo)
    movesTab:setOn(not showInfo)
    topInfoPanel:setVisible(showInfo)
    statsGrid:setVisible(showInfo)
    movesPanel:setVisible(not showInfo)
end

local function renderDetails()
    local info = selectedSlot and pokemonInfo[selectedSlot]
    if not info then
        detailsPanel:setVisible(false)
        emptyPanel:setVisible(true)
        return
    end

    emptyPanel:setVisible(false)
    detailsPanel:setVisible(true)
    local portrait = detailsPanel:recursiveGetChildById('portrait')
    portrait:setImage(pokemonImagePath(info, true))
    portrait:center()
    setValue('nameValue', info.name)
    setValue('numberValue', '#' .. string.format('%04d', info.number))
    setValue('levelInfo', tr('Level') .. ': ' .. info.level)
    setValue('natureInfo', tr('Nature') .. ': ' .. tr(natureNames[info.nature] or 'None'))

    local primaryTypeIcon = detailsPanel:recursiveGetChildById('primaryTypeIcon')
    local secondaryTypeIcon = detailsPanel:recursiveGetChildById('secondaryTypeIcon')
    setTypeIcon(primaryTypeIcon, info.primaryType)
    primaryTypeIcon:setVisible(true)
    if info.secondaryType and info.secondaryType ~= 0 then
        setTypeIcon(secondaryTypeIcon, info.secondaryType)
        secondaryTypeIcon:setVisible(true)
    else
        secondaryTypeIcon:setVisible(false)
    end

    local healthBar = detailsPanel:recursiveGetChildById('healthBar')
    setValue('healthLabel', tr('Health'))
    healthBar:setValue(info.health, 0, math.max(1, info.maxHealth))
    healthBar:setText(string.format('%d / %d', info.health, info.maxHealth))
    healthBar:setBackgroundColor(healthColor(info.healthPercent))
    healthBar:setTooltip(info.healthPercent .. '%')

    local genderIcon = detailsPanel:recursiveGetChildById('genderIcon')
    genderIcon:setImageSource(genderImages[info.gender] or genderImages[3])
    genderIcon:setTooltip(tr(genderNames[info.gender] or 'Undefined'))

    local shinyIcon = detailsPanel:recursiveGetChildById('shinyIcon')
    shinyIcon:setVisible(info.shiny)
    shinyIcon:setTooltip(tr('Shiny'))

    local experienceBar = detailsPanel:recursiveGetChildById('experienceBar')
    local experiencePercent = 100
    local earnedExperience = 0
    local requiredExperience = 0
    if info.nextLevelExperience > info.currentLevelExperience then
        earnedExperience = math.max(0, info.experience - info.currentLevelExperience)
        requiredExperience = info.nextLevelExperience - info.currentLevelExperience
        experiencePercent = math.max(0, math.min(100,
            math.floor((earnedExperience * 100 / requiredExperience) + 0.5)))
    end
    setValue('experienceLabel', tr('Experience') .. ': ' .. info.experience)
    experienceBar:setPercent(experiencePercent)
    experienceBar:setText(experiencePercent .. '%')
    if requiredExperience > 0 then
        experienceBar:setTooltip(string.format('%d / %d', earnedExperience, requiredExperience))
    else
        experienceBar:setTooltip(tr('Maximum level'))
    end

    local friendshipBar = detailsPanel:recursiveGetChildById('friendshipBar')
    setValue('friendshipLabel', tr('Friendship'))
    friendshipBar:setValue(info.friendship, 0, 255)
    friendshipBar:setText(info.friendship .. ' / 255')
    renderStats(info)
    renderMoves(info)
    selectDetailsTab(currentDetailsTab)
end

local function refreshSelection()
    for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local entry = pokemonList:getChildById('pokemon' .. slot)
        if entry then
            entry:setOn(slot == selectedSlot)
        end
    end
end

local function selectPokemon(slot)
    if not pokemonInfo[slot] then
        return
    end
    if selectedSlot ~= slot then
        selectedMoveId = nil
    end
    selectedSlot = slot
    refreshSelection()
    renderDetails()
end

local function refreshList()
    if not pokemonList then
        return
    end

    pokemonList:destroyChildren()
    local firstSlot
    for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local info = pokemonInfo[slot]
        if info and info.number > 0 then
            firstSlot = firstSlot or slot
            local currentSlot = slot
            local entry = g_ui.createWidget('PokebagEntry', pokemonList)
            entry:setId('pokemon' .. slot)
            entry:getChildById('pokemonIcon'):setImage(pokemonImagePath(info, false))
            entry:getChildById('pokemonName'):setText(info.name)
            entry:getChildById('pokemonLevel'):setText(tr('Level') .. ' ' .. info.level)

            local healthBar = entry:getChildById('pokemonHealth')
            local percent = info.fainted and 0 or info.healthPercent
            healthBar:setPercent(percent)
            healthBar:setBackgroundColor(healthColor(percent))
            entry:setOpacity(info.fainted and 0.55 or 1)
            entry.onMousePress = function(_, _, button)
                if button == MouseLeftButton then
                    selectPokemon(currentSlot)
                    return true
                end
                return false
            end
        end
    end

    if selectedSlot and not pokemonInfo[selectedSlot] then
        selectedSlot = nil
    end
    selectedSlot = selectedSlot or firstSlot
    refreshSelection()
    renderDetails()
end

local function toggleFromHotkey()
    if modules.game_console and modules.game_console.isChatEnabled() then
        return
    end

    toggle()
end

function init()
    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onPokemonInfo = updatePokemonInfo,
        onPokemonMoveList = onPokemonMoveList
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    connect(Creature, {
        onHealthPercentChange = onPokemonHealthChange
    })

    g_keyboard.bindKeyDown('P', toggleFromHotkey)

    pokebagWindow = g_ui.displayUI('pokebag')
    pokebagWindow:hide()
    pokemonList = pokebagWindow:recursiveGetChildById('pokemonList')
    detailsPanel = pokebagWindow:getChildById('detailsPanel')
    emptyPanel = pokebagWindow:getChildById('emptyPanel')
    statsGrid = detailsPanel:getChildById('statsGrid')
    topInfoPanel = detailsPanel:getChildById('topInfoPanel')
    movesPanel = detailsPanel:getChildById('movesPanel')
    infoTab = detailsPanel:getChildById('infoTab')
    movesTab = detailsPanel:getChildById('movesTab')
    activeMovesList = movesPanel:recursiveGetChildById('activeMovesList')
    learnedMovesList = movesPanel:recursiveGetChildById('learnedMovesList')

    activeMovesList.onDrop = function(_, draggedWidget)
        return dropMoveOnActiveSlots(draggedWidget)
    end
    learnedMovesList.onDrop = function(_, draggedWidget)
        return dropMoveOnLearnedList(draggedWidget)
    end
    movesPanel:recursiveGetChildById('activeMovesFrame').onDrop = function(_, draggedWidget)
        return dropMoveOnActiveSlots(draggedWidget)
    end
    movesPanel:recursiveGetChildById('learnedMovesFrame').onDrop = function(_, draggedWidget)
        return dropMoveOnLearnedList(draggedWidget)
    end
    selectDetailsTab('info')

    pokebagButton = modules.client_topmenu.addRightGameToggleButton(
        'pokebagButton', tr('Pokebag') .. ' (P)', '/images/topbuttons/pokeball', toggle)
    pokebagButton:setIconWidth(16)
    pokebagButton:setIconHeight(16)
    pokebagButton:setIconOffsetX(5)
    pokebagButton:setIconOffsetY(5)
    pokebagButton:setOn(false)

    if g_game.isOnline() then
        online()
    end
end

function terminate()
    g_keyboard.unbindKeyDown('P')

    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onPokemonInfo = updatePokemonInfo,
        onPokemonMoveList = onPokemonMoveList
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    disconnect(Creature, {
        onHealthPercentChange = onPokemonHealthChange
    })

    if pokebagButton then
        pokebagButton:destroy()
    end
    if pokebagWindow then
        pokebagWindow:destroy()
    end

    pokebagButton = nil
    pokebagWindow = nil
    pokemonList = nil
    detailsPanel = nil
    emptyPanel = nil
    statsGrid = nil
    topInfoPanel = nil
    movesPanel = nil
    infoTab = nil
    movesTab = nil
    activeMovesList = nil
    learnedMovesList = nil
    pokemonInfo = {}
    selectedSlot = nil
    selectedMoveId = nil
end

function online()
    refreshList()
end

function offline()
    pokemonInfo = {}
    selectedSlot = nil
    selectedMoveId = nil
    if pokebagWindow then
        pokebagWindow:hide()
        refreshList()
    end
    if pokebagButton then
        pokebagButton:setOn(false)
    end
end

function toggle()
    if not g_game.isOnline() then
        return
    end
    if pokebagWindow:isVisible() then
        hide()
    else
        pokebagWindow:show()
        pokebagWindow:raise()
        pokebagWindow:focus()
        pokebagButton:setOn(true)
        refreshList()
    end
end

function hide()
    if pokebagWindow then
        pokebagWindow:hide()
    end
    if pokebagButton then
        pokebagButton:setOn(false)
    end
end

function onInventoryChange(_, slot, item)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end
    if not item then
        pokemonInfo[slot] = nil
    end
    refreshList()
end

function onPokemonHealthChange(creature, healthPercent)
    for slot = InventoryPokeballSlotFirst, InventoryPokeballSlotLast do
        local info = pokemonInfo[slot]
        if info and info.active and info.creatureId == creature:getId() then
            info.healthPercent = healthPercent
            info.health = math.floor((info.maxHealth * healthPercent / 100) + 0.5)
            refreshList()
            return
        end
    end
end

function updatePokemonInfo(_, slot, p_id, number, level, healthPercent, fainted, active,
                           name, experience, currentLevelExperience, nextLevelExperience,
                           health, maxHealth, nature, friendship,
                           primaryType, secondaryType, gender, shiny,
                           statHp, statAttack, statDefense, statSpecialAttack, statSpecialDefense, statSpeed,
                           ivHp, ivAttack, ivDefense, ivSpecialAttack, ivSpecialDefense, ivSpeed,
                           evHp, evAttack, evDefense, evSpecialAttack, evSpecialDefense, evSpeed)
    if slot < InventoryPokeballSlotFirst or slot > InventoryPokeballSlotLast then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player or not player:getInventoryItem(slot) then
        pokemonInfo[slot] = nil
        refreshList()
        return
    end

    local previousInfo = pokemonInfo[slot]
    local previousMoves = previousInfo and previousInfo.moves or {}
    local receivedStats = makeStats(statHp, statAttack, statDefense, statSpecialAttack, statSpecialDefense, statSpeed)
    local baseStats = active and previousInfo and previousInfo.baseStats or receivedStats
    pokemonInfo[slot] = {
        creatureId = p_id or 0,
        number = number or 0,
        level = level or 1,
        healthPercent = fainted and 0 or (healthPercent or 0),
        fainted = fainted or false,
        active = active or false,
        name = name or tr('Unknown'),
        experience = experience or 0,
        currentLevelExperience = currentLevelExperience or 0,
        nextLevelExperience = nextLevelExperience or 0,
        health = health or 0,
        maxHealth = maxHealth or 0,
        nature = nature or 0,
        friendship = friendship or 0,
        primaryType = primaryType or 0,
        secondaryType = secondaryType or 0,
        gender = gender or 3,
        shiny = shiny or false,
        stats = receivedStats,
        baseStats = baseStats,
        ivs = makeStats(ivHp, ivAttack, ivDefense, ivSpecialAttack, ivSpecialDefense, ivSpeed),
        evs = makeStats(evHp, evAttack, evDefense, evSpecialAttack, evSpecialDefense, evSpeed),
        moves = previousMoves
    }
    refreshList()
end

function onPokemonMoveList(_, slot, receivedMoves)
    local info = pokemonInfo[slot]
    if not info then
        return
    end

    local moves = {}
    for _, data in ipairs(receivedMoves or {}) do
        table.insert(moves, {
            id = data[1] or 0,
            name = data[2] or tr('Unknown'),
            type = data[3] or 0,
            category = data[4] or 2,
            power = data[5] or 0,
            pp = data[6] or 0,
            accuracy = data[7] or 0,
            range = data[8] or 0,
            cooldown = data[9] or 0,
            activeSlot = data[10] or 0,
            learnLevel = data[11] or 1,
            target = data[12] or 1
        })
    end
    info.moves = moves

    if selectedSlot == slot then
        renderDetails()
    end
end
