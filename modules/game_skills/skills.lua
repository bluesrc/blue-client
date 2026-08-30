local skillsWindow
local skillsButton

local function setValue(id, value)
    local row = skillsWindow:recursiveGetChildById(id)
    if row then row:getChildById('value'):setText(value) end
end

local function setPercent(id, percent)
    local row = skillsWindow:recursiveGetChildById(id)
    if row then row:getChildById('percent'):setPercent(math.floor(percent)) end
end

function init()
    connect(LocalPlayer, {
        onExperienceChange = refresh,
        onLevelChange = refresh,
        onHealthChange = refresh,
        onStaminaChange = refresh,
        onSpeedChange = refresh,
        onBaseSpeedChange = refresh,
        onSkillChange = onSkillChange,
        onBaseSkillChange = onSkillChange
    })
    connect(g_game, { onGameStart = online, onGameEnd = offline })
    skillsButton = modules.client_topmenu.addRightGameToggleButton(
        'skillsButton', tr('Skills'), '/images/topbuttons/skills', toggle)
    skillsButton:setOn(true)
    skillsWindow = g_ui.loadUI('skills')
    skillsWindow:setup()
    if g_game.isOnline() then online() end
end

function terminate()
    disconnect(LocalPlayer, {
        onExperienceChange = refresh,
        onLevelChange = refresh,
        onHealthChange = refresh,
        onStaminaChange = refresh,
        onSpeedChange = refresh,
        onBaseSpeedChange = refresh,
        onSkillChange = onSkillChange,
        onBaseSkillChange = onSkillChange
    })
    disconnect(g_game, { onGameStart = online, onGameEnd = offline })
    skillsWindow:destroy()
    skillsButton:destroy()
end

function refresh()
    local player = g_game.getLocalPlayer()
    if not player or not skillsWindow then return end
    setValue('experience', player:getExperience())
    setValue('level', player:getLevel())
    setPercent('level', player:getLevelPercent())
    setValue('health', string.format('%d / %d', player:getHealth(), player:getMaxHealth()))
    setValue('speed', player:getSpeed())
    setValue('stamina', string.format('%d:%02d', math.floor(player:getStamina() / 60), player:getStamina() % 60))
    setValue('fishing', player:getSkillLevel(Skill.Fishing))
    setPercent('fishing', player:getSkillLevelPercent(Skill.Fishing))
end

function onSkillChange(_, skill)
    if skill == Skill.Fishing then refresh() end
end

function online()
    skillsWindow:setupOnStart()
    refresh()
end

function offline() skillsWindow:setParent(nil, true) end
function toggle()
    if skillsButton:isOn() then skillsWindow:close() else skillsWindow:open() end
end
function onMiniWindowOpen() skillsButton:setOn(true) end
function onMiniWindowClose() skillsButton:setOn(false) end
