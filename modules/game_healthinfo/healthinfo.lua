Icons = {}

local healthInfoWindow
local healthInfoButton
local healthBar
local experienceBar

function init()
    connect(LocalPlayer, {
        onHealthChange = onHealthChange,
        onLevelChange = onLevelChange,
        onStatesChange = onStatesChange
    })
    connect(g_game, { onGameStart = online, onGameEnd = offline })

    healthInfoButton = modules.client_topmenu.addRightGameToggleButton(
        'healthInfoButton', tr('Health Information'), '/images/topbuttons/healthinfo', toggle)
    healthInfoButton:setOn(true)
    healthInfoWindow = g_ui.loadUI('healthinfo')
    healthInfoWindow:disableResize()
    healthBar = healthInfoWindow:recursiveGetChildById('healthBar')
    experienceBar = healthInfoWindow:recursiveGetChildById('experienceBar')

    if g_game.isOnline() then online() end
    healthInfoWindow:setup()
end

function terminate()
    disconnect(LocalPlayer, {
        onHealthChange = onHealthChange,
        onLevelChange = onLevelChange,
        onStatesChange = onStatesChange
    })
    disconnect(g_game, { onGameStart = online, onGameEnd = offline })
    healthInfoWindow:destroy()
    healthInfoButton:destroy()
end

function online()
    local player = g_game.getLocalPlayer()
    if not player then return end
    onHealthChange(player, player:getHealth(), player:getMaxHealth())
    onLevelChange(player, player:getLevel(), player:getLevelPercent())
    healthInfoWindow:setupOnStart()
end

function offline()
    healthInfoWindow:setParent(nil, true)
end

function toggle()
    if healthInfoButton:isOn() then
        healthInfoWindow:close()
    else
        healthInfoWindow:open()
    end
end

function onMiniWindowOpen() healthInfoButton:setOn(true) end
function onMiniWindowClose() healthInfoButton:setOn(false) end

function onHealthChange(_, health, maxHealth)
    healthBar:setText(health .. ' / ' .. maxHealth)
    healthBar:setTooltip(tr('Your character health is %d out of %d.', health, maxHealth))
    healthBar:setValue(health, 0, maxHealth)
end

function onLevelChange(_, level, percent)
    experienceBar:setText(percent .. '%')
    experienceBar:setTooltip(tr('You have %d%% to advance to level %d.', percent, level + 1))
    experienceBar:setPercent(percent)
end

function onStatesChange() end
