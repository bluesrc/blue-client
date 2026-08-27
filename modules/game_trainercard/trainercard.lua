local trainerCardWindow
local trainerCardButton

local function toggleFromHotkey()
    if modules.game_console and modules.game_console.isChatEnabled() then
        return
    end

    toggle()
end

local genderInfo = {
    [0] = { name = 'Female', image = '/images/gender/gender_female' },
    [1] = { name = 'Male', image = '/images/gender/gender_male' }
}

local function experienceForLevel(level)
    return math.floor((50 * level * level * level) / 3 - 100 * level * level + (850 * level) / 3 - 200)
end

local function setValue(id, value)
    if trainerCardWindow then
        trainerCardWindow:recursiveGetChildById(id):setText(tostring(value))
    end
end

local function refresh()
    if not trainerCardWindow then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    trainerCardWindow:recursiveGetChildById('trainerOutfit'):setOutfit(player:getOutfit())
    setValue('nameValue', player:getName())
    setValue('hometownValue', player:getHometown() ~= '' and player:getHometown() or tr('Unknown'))
    setValue('moneyValue', comma_value(player:getTrainerMoney()))
    setValue('levelValue', comma_value(player:getLevel()))
    setValue('guildValue', player:getGuildName() ~= '' and player:getGuildName() or tr('No guild'))
    setValue('pokedexValue', comma_value(player:getPokedexCount()))
    setValue('capturedValue', comma_value(player:getTotalCaught()))

    local gender = genderInfo[player:getTrainerGender()]
    local genderIcon = trainerCardWindow:recursiveGetChildById('genderIcon')
    genderIcon:setImageSource(gender and gender.image or '/images/gender/gender_undefined')
    genderIcon:setTooltip(tr(gender and gender.name or 'Unknown'))

    local level = player:getLevel()
    local currentLevelExperience = experienceForLevel(level)
    local nextLevelExperience = experienceForLevel(level + 1)
    local required = math.max(1, nextLevelExperience - currentLevelExperience)
    local earned = math.max(0, player:getExperience() - currentLevelExperience)
    local percent = math.max(0, math.min(100, math.floor((earned * 100 / required) + 0.5)))
    local experienceBar = trainerCardWindow:recursiveGetChildById('experienceBar')
    experienceBar:setPercent(percent)
    experienceBar:setText(percent .. '%')
    experienceBar:setTooltip(string.format('%s / %s', comma_value(earned), comma_value(required)))
end

function init()
    connect(LocalPlayer, {
        onExperienceChange = refresh,
        onLevelChange = refresh,
        onOutfitChange = refresh,
        onTrainerInfoChange = refresh
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    trainerCardWindow = g_ui.displayUI('trainercard')
    trainerCardWindow:hide()

    trainerCardButton = modules.client_topmenu.addRightGameToggleButton(
        'trainerCardButton', tr('Trainer Card'), '/images/topbuttons/skills', toggle)
    trainerCardButton:setIconWidth(16)
    trainerCardButton:setIconHeight(16)
    trainerCardButton:setIconOffsetX(5)
    trainerCardButton:setIconOffsetY(5)
    trainerCardButton:setOn(false)

    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(LocalPlayer, {
        onExperienceChange = refresh,
        onLevelChange = refresh,
        onOutfitChange = refresh,
        onTrainerInfoChange = refresh
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    if trainerCardButton then
        trainerCardButton:destroy()
    end
    if trainerCardWindow then
        trainerCardWindow:destroy()
    end
    trainerCardButton = nil
    trainerCardWindow = nil
end

function online()
    refresh()
end

function offline()
    hide()
end

function toggle()
    if not g_game.isOnline() then
        return
    end
    if trainerCardWindow:isVisible() then
        hide()
    else
        refresh()
        trainerCardWindow:show()
        trainerCardWindow:raise()
        trainerCardWindow:focus()
        trainerCardButton:setOn(true)
    end
end

function hide()
    if trainerCardWindow then
        trainerCardWindow:hide()
    end
    if trainerCardButton then
        trainerCardButton:setOn(false)
    end
end
