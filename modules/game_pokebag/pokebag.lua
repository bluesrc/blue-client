local pokebagWindow
local pokebagButton
local pokemonList
local detailsPanel
local emptyPanel
local statsGrid
local pokemonInfo = {}
local selectedSlot

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
        addStatCell('PokebagStatCell', tr(stat.label), statColor)
        addStatCell('PokebagStatCell', info.stats[stat.key], statColor)
        addStatCell('PokebagStatCell', info.ivs[stat.key])
        addStatCell('PokebagStatCell', info.evs[stat.key])
    end
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

    local types = tr(typeNames[info.primaryType] or 'None')
    if info.secondaryType and info.secondaryType ~= 0 then
        types = types .. ' / ' .. tr(typeNames[info.secondaryType] or 'None')
    end
    setValue('typesInfo', tr('Types') .. ': ' .. types)

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
        onPokemonInfo = updatePokemonInfo
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
        onPokemonInfo = updatePokemonInfo
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
    pokemonInfo = {}
    selectedSlot = nil
end

function online()
    refreshList()
end

function offline()
    pokemonInfo = {}
    selectedSlot = nil
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
        stats = makeStats(statHp, statAttack, statDefense, statSpecialAttack, statSpecialDefense, statSpeed),
        ivs = makeStats(ivHp, ivAttack, ivDefense, ivSpecialAttack, ivSpecialDefense, ivSpeed),
        evs = makeStats(evHp, evAttack, evDefense, evSpecialAttack, evSpecialDefense, evSpeed)
    }
    refreshList()
end
