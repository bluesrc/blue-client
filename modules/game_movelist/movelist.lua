local MovelistProfile = 'Default'

movelistWindow = nil
movelistButton = nil
moveList = nil
nameValueLabel = nil
formulaValueLabel = nil
vocationValueLabel = nil
groupValueLabel = nil
typeValueLabel = nil
cooldownValueLabel = nil
levelValueLabel = nil
manaValueLabel = nil
premiumValueLabel = nil
descriptionValueLabel = nil

vocationBoxAny = nil
vocationBoxSorcerer = nil
vocationBoxDruid = nil
vocationBoxPaladin = nil
vocationBoxKnight = nil

groupBoxAny = nil
groupBoxAttack = nil
groupBoxHealing = nil
groupBoxSupport = nil

premiumBoxAny = nil
premiumBoxNo = nil
premiumBoxYes = nil

vocationRadioGroup = nil
groupRadioGroup = nil
premiumRadioGroup = nil

-- consts
FILTER_PREMIUM_ANY = 0
FILTER_PREMIUM_NO = 1
FILTER_PREMIUM_YES = 2

FILTER_VOCATION_ANY = 0
FILTER_VOCATION_SORCERER = 1
FILTER_VOCATION_DRUID = 2
FILTER_VOCATION_PALADIN = 3
FILTER_VOCATION_KNIGHT = 4

FILTER_GROUP_ANY = 0
FILTER_GROUP_ATTACK = 1
FILTER_GROUP_HEALING = 2
FILTER_GROUP_SUPPORT = 3

-- Filter Settings
local filters = {
    level = false,
    vocation = false,

    vocationId = FILTER_VOCATION_ANY,
    premium = FILTER_PREMIUM_ANY,
    groupId = FILTER_GROUP_ANY
}

function getMovelistProfile()
    return MovelistProfile
end

function setMovelistProfile(name)
    if MovelistProfile == name then
        return
    end

    if MovelistSettings[name] and MoveInfo[name] then
        local oldProfile = MovelistProfile
        MovelistProfile = name
        changeMovelistProfile(oldProfile)
    else
        perror('Movelist profile \'' .. name .. '\' could not be set.')
    end
end

function online()
    if g_game.getFeature(GameMoveList) then
        movelistButton:show()
    else
        movelistButton:hide()
    end

    -- Vocation is only send in newer clients
    if g_game.getClientVersion() >= 950 then
        movelistWindow:getChildById('buttonFilterVocation'):setVisible(true)
    else
        movelistWindow:getChildById('buttonFilterVocation'):setVisible(false)
    end
end

function offline()
    resetWindow()
end

function init()
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    movelistWindow = g_ui.displayUI('movelist', modules.game_interface.getRightPanel())
    movelistWindow:hide()

    movelistButton = modules.client_topmenu.addRightGameToggleButton('movelistButton', tr('Move List'),
                                                                      '/images/topbuttons/movelist', toggle)
    movelistButton:setOn(false)

    nameValueLabel = movelistWindow:getChildById('labelNameValue')
    formulaValueLabel = movelistWindow:getChildById('labelFormulaValue')
    vocationValueLabel = movelistWindow:getChildById('labelVocationValue')
    groupValueLabel = movelistWindow:getChildById('labelGroupValue')
    typeValueLabel = movelistWindow:getChildById('labelTypeValue')
    cooldownValueLabel = movelistWindow:getChildById('labelCooldownValue')
    levelValueLabel = movelistWindow:getChildById('labelLevelValue')
    manaValueLabel = movelistWindow:getChildById('labelManaValue')
    premiumValueLabel = movelistWindow:getChildById('labelPremiumValue')
    descriptionValueLabel = movelistWindow:getChildById('labelDescriptionValue')

    vocationBoxAny = movelistWindow:getChildById('vocationBoxAny')
    vocationBoxSorcerer = movelistWindow:getChildById('vocationBoxSorcerer')
    vocationBoxDruid = movelistWindow:getChildById('vocationBoxDruid')
    vocationBoxPaladin = movelistWindow:getChildById('vocationBoxPaladin')
    vocationBoxKnight = movelistWindow:getChildById('vocationBoxKnight')

    groupBoxAny = movelistWindow:getChildById('groupBoxAny')
    groupBoxAttack = movelistWindow:getChildById('groupBoxAttack')
    groupBoxHealing = movelistWindow:getChildById('groupBoxHealing')
    groupBoxSupport = movelistWindow:getChildById('groupBoxSupport')

    premiumBoxAny = movelistWindow:getChildById('premiumBoxAny')
    premiumBoxYes = movelistWindow:getChildById('premiumBoxYes')
    premiumBoxNo = movelistWindow:getChildById('premiumBoxNo')

    vocationRadioGroup = UIRadioGroup.create()
    vocationRadioGroup:addWidget(vocationBoxAny)
    vocationRadioGroup:addWidget(vocationBoxSorcerer)
    vocationRadioGroup:addWidget(vocationBoxDruid)
    vocationRadioGroup:addWidget(vocationBoxPaladin)
    vocationRadioGroup:addWidget(vocationBoxKnight)

    groupRadioGroup = UIRadioGroup.create()
    groupRadioGroup:addWidget(groupBoxAny)
    groupRadioGroup:addWidget(groupBoxAttack)
    groupRadioGroup:addWidget(groupBoxHealing)
    groupRadioGroup:addWidget(groupBoxSupport)

    premiumRadioGroup = UIRadioGroup.create()
    premiumRadioGroup:addWidget(premiumBoxAny)
    premiumRadioGroup:addWidget(premiumBoxYes)
    premiumRadioGroup:addWidget(premiumBoxNo)

    premiumRadioGroup:selectWidget(premiumBoxAny)
    vocationRadioGroup:selectWidget(vocationBoxAny)
    groupRadioGroup:selectWidget(groupBoxAny)

    vocationRadioGroup.onSelectionChange = toggleFilter
    groupRadioGroup.onSelectionChange = toggleFilter
    premiumRadioGroup.onSelectionChange = toggleFilter

    moveList = movelistWindow:getChildById('moveList')

    g_keyboard.bindKeyPress('Down', function()
        moveList:focusNextChild(KeyboardFocusReason)
    end, movelistWindow)
    g_keyboard.bindKeyPress('Up', function()
        moveList:focusPreviousChild(KeyboardFocusReason)
    end, movelistWindow)

    initializeMovelist()
    resizeWindow()

    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    disconnect(moveList, {
        onChildFocusChange = function(self, focusedChild)
            if focusedChild == nil then
                return
            end
            updateMoveInformation(focusedChild)
        end
    })

    movelistWindow:destroy()
    movelistButton:destroy()

    vocationRadioGroup:destroy()
    groupRadioGroup:destroy()
    premiumRadioGroup:destroy()
end

function initializeMovelist()
    for i = 1, #MovelistSettings[MovelistProfile].moveOrder do
        local move = MovelistSettings[MovelistProfile].moveOrder[i]
        local info = MoveInfo[MovelistProfile][move]

        local tmpLabel = g_ui.createWidget('MoveListLabel', moveList)
        tmpLabel:setId(move)
        tmpLabel:setText(move .. '\n\'' .. info.words .. '\'')
        tmpLabel:setPhantom(false)

        local iconId = tonumber(info.icon)
        if not iconId and MoveIcons[info.icon] then
            iconId = MoveIcons[info.icon][1]
        end

        if not (iconId) then
            perror('Move icon \'' .. info.icon .. '\' not found.')
        end

        tmpLabel:setHeight(MovelistSettings[MovelistProfile].iconSize.height + 4)
        tmpLabel:setTextOffset(topoint((MovelistSettings[MovelistProfile].iconSize.width + 10) .. ' ' ..
                                           (MovelistSettings[MovelistProfile].iconSize.height - 32) / 2 + 3))
        tmpLabel:setImageSource(MovelistSettings[MovelistProfile].iconFile)
        tmpLabel:setImageClip(Moves.getImageClip(iconId, MovelistProfile))
        tmpLabel:setImageSize(tosize(MovelistSettings[MovelistProfile].iconSize.width .. ' ' ..
                                         MovelistSettings[MovelistProfile].iconSize.height))
        tmpLabel.onClick = updateMoveInformation
    end

    connect(moveList, {
        onChildFocusChange = function(self, focusedChild)
            if focusedChild == nil then
                return
            end
            updateMoveInformation(focusedChild)
        end
    })
end

function changeMovelistProfile(oldProfile)
    -- Delete old labels
    for i = 1, #MovelistSettings[oldProfile].moveOrder do
        local move = MovelistSettings[oldProfile].moveOrder[i]
        local tmpLabel = moveList:getChildById(move)

        tmpLabel:destroy()
    end

    -- Create new movelist and ajust window
    initializeMovelist()
    resizeWindow()
    resetWindow()
end

function updateMovelist()
    for i = 1, #MovelistSettings[MovelistProfile].moveOrder do
        local move = MovelistSettings[MovelistProfile].moveOrder[i]
        local info = MoveInfo[MovelistProfile][move]
        local tmpLabel = moveList:getChildById(move)

        local localPlayer = g_game.getLocalPlayer()
        if (not (filters.level) or info.level <= localPlayer:getLevel()) and
            (not (filters.vocation) or table.find(info.vocations, localPlayer:getVocation())) and
            (filters.vocationId == FILTER_VOCATION_ANY or table.find(info.vocations, filters.vocationId) or
                table.find(info.vocations, filters.vocationId + 4)) and
            (filters.groupId == FILTER_GROUP_ANY or info.group[filters.groupId]) and
            (filters.premium == FILTER_PREMIUM_ANY or (info.premium and filters.premium == FILTER_PREMIUM_YES) or
                (not (info.premium) and filters.premium == FILTER_PREMIUM_NO)) then
            tmpLabel:setVisible(true)
        else
            tmpLabel:setVisible(false)
        end
    end
end

function updateMoveInformation(widget)
    local move = widget:getId()

    local name = ''
    local formula = ''
    local vocation = ''
    local group = ''
    local type = ''
    local cooldown = ''
    local level = ''
    local mana = ''
    local premium = ''
    local description = ''

    if MoveInfo[MovelistProfile][move] then
        local info = MoveInfo[MovelistProfile][move]

        name = move
        formula = info.words

        for i = 1, #info.vocations do
            local vocationId = info.vocations[i]
            if vocationId <= 4 or not (table.find(info.vocations, (vocationId - 4))) then
                vocation = vocation .. (vocation:len() == 0 and '' or ', ') .. VocationNames[vocationId]
            end
        end

        cooldown = (info.exhaustion / 1000) .. 's'
        for groupId, groupName in ipairs(MoveGroups) do
            if info.group[groupId] then
                group = group .. (group:len() == 0 and '' or ' / ') .. groupName
                cooldown = cooldown .. ' / ' .. (info.group[groupId] / 1000) .. 's'
            end
        end

        type = info.type
        level = info.level
        mana = info.mana .. ' / ' .. info.soul
        premium = (info.premium and 'yes' or 'no')
        description = info.description or '-'
    end

    nameValueLabel:setText(name)
    formulaValueLabel:setText(formula)
    vocationValueLabel:setText(vocation)
    groupValueLabel:setText(group)
    typeValueLabel:setText(type)
    cooldownValueLabel:setText(cooldown)
    levelValueLabel:setText(level)
    manaValueLabel:setText(mana)
    premiumValueLabel:setText(premium)
    descriptionValueLabel:setText(description)
end

function toggle()
    if movelistButton:isOn() then
        movelistButton:setOn(false)
        movelistWindow:hide()
    else
        movelistButton:setOn(true)
        movelistWindow:show()
        movelistWindow:raise()
        movelistWindow:focus()
    end
end

function toggleFilter(widget, selectedWidget)
    if widget == vocationRadioGroup then
        local boxId = selectedWidget:getId()
        if boxId == 'vocationBoxAny' then
            filters.vocationId = FILTER_VOCATION_ANY
        elseif boxId == 'vocationBoxSorcerer' then
            filters.vocationId = FILTER_VOCATION_SORCERER
        elseif boxId == 'vocationBoxDruid' then
            filters.vocationId = FILTER_VOCATION_DRUID
        elseif boxId == 'vocationBoxPaladin' then
            filters.vocationId = FILTER_VOCATION_PALADIN
        elseif boxId == 'vocationBoxKnight' then
            filters.vocationId = FILTER_VOCATION_KNIGHT
        end
    elseif widget == groupRadioGroup then
        local boxId = selectedWidget:getId()
        if boxId == 'groupBoxAny' then
            filters.groupId = FILTER_GROUP_ANY
        elseif boxId == 'groupBoxAttack' then
            filters.groupId = FILTER_GROUP_ATTACK
        elseif boxId == 'groupBoxHealing' then
            filters.groupId = FILTER_GROUP_HEALING
        elseif boxId == 'groupBoxSupport' then
            filters.groupId = FILTER_GROUP_SUPPORT
        end
    elseif widget == premiumRadioGroup then
        local boxId = selectedWidget:getId()
        if boxId == 'premiumBoxAny' then
            filters.premium = FILTER_PREMIUM_ANY
        elseif boxId == 'premiumBoxNo' then
            filters.premium = FILTER_PREMIUM_NO
        elseif boxId == 'premiumBoxYes' then
            filters.premium = FILTER_PREMIUM_YES
        end
    else
        local id = widget:getId()
        if id == 'buttonFilterLevel' then
            filters.level = not (filters.level)
            widget:setOn(filters.level)
        elseif id == 'buttonFilterVocation' then
            filters.vocation = not (filters.vocation)
            widget:setOn(filters.vocation)
        end
    end

    updateMovelist()
end

function resizeWindow()
    movelistWindow:setWidth(MovelistSettings['Default'].moveWindowWidth +
                                 MovelistSettings[MovelistProfile].iconSize.width - 32)
    moveList:setWidth(
        MovelistSettings['Default'].moveListWidth + MovelistSettings[MovelistProfile].iconSize.width - 32)
end

function resetWindow()
    movelistWindow:hide()
    movelistButton:setOn(false)

    -- Resetting filters
    filters.level = false
    filters.vocation = false

    local buttonFilterLevel = movelistWindow:getChildById('buttonFilterLevel')
    buttonFilterLevel:setOn(filters.level)

    local buttonFilterVocation = movelistWindow:getChildById('buttonFilterVocation')
    buttonFilterVocation:setOn(filters.vocation)

    vocationRadioGroup:selectWidget(vocationBoxAny)
    groupRadioGroup:selectWidget(groupBoxAny)
    premiumRadioGroup:selectWidget(premiumBoxAny)

    updateMovelist()
end
