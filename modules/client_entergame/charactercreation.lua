CharacterCreation = {}

local window
local protocol
local loadBox

local function populateWorlds()
  local worldBox = window:getChildById('world')
  worldBox:clearOptions()

  local worlds = G.characterAccount and G.characterAccount.worlds or {}
  local worldIds = {}
  for worldId in pairs(worlds) do
    table.insert(worldIds, worldId)
  end
  table.sort(worldIds)

  for _, worldId in ipairs(worldIds) do
    local world = worlds[worldId]
    worldBox:addOption(world.worldName, world)
  end
end

local function finishRequest()
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
  protocol = nil
end

local function showError(message)
  finishRequest()
  local errorBox = displayErrorBox(tr('Character creation'), tr(message))
  connect(errorBox, { onOk = CharacterCreation.show })
end

local function onCreationResult(_, action, success, message)
  if action ~= LoginActionCreateCharacter then
    return
  end
  finishRequest()
  if not success then
    local errorBox = displayErrorBox(tr('Character creation'), tr(message))
    connect(errorBox, { onOk = CharacterCreation.show })
    return
  end

  window:getChildById('characterName'):clearText()
  local infoBox = displayInfoBox(tr('Character creation'), tr(message))
  connect(infoBox, {
    onOk = function()
      CharacterCreation.hide(false)
      CharacterList.hide()
      EnterGame.loginWithCredentials(G.account, G.password, G.authenticatorToken)
    end
  })
end

function CharacterCreation.init()
  window = g_ui.displayUI('charactercreation')
  local sexBox = window:getChildById('sex')
  sexBox:addOption(tr('Female'), 0)
  sexBox:addOption(tr('Male'), 1)
  window:hide()
end

function CharacterCreation.terminate()
  if protocol then
    protocol:cancelLogin()
    protocol = nil
  end
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
  if window then
    window:destroy()
    window = nil
  end
  CharacterCreation = nil
end

function CharacterCreation.show()
  if not window or loadBox then
    return
  end
  CharacterList.hide()
  populateWorlds()
  window:show()
  window:raise()
  window:focus()
  window:getChildById('characterName'):focus()
end

function CharacterCreation.hide(showCharacterList)
  if window then
    window:hide()
  end
  if showCharacterList ~= false then
    CharacterList.show()
  end
end

function CharacterCreation.doCreate()
  local name = window:getChildById('characterName'):getText()
  local sex = window:getChildById('sex'):getCurrentOption().data
  local world = window:getChildById('world'):getCurrentOption()
  if #name < 3 or #name > 20 or not name:match('^[%a]+[ %a]*[%a]$') then
    displayErrorBox(tr('Character creation'), tr('Character name must contain 3 to 20 letters and single spaces.'))
    return
  end
  if name:find('  ', 1, true) then
    displayErrorBox(tr('Character creation'), tr('Character name must contain 3 to 20 letters and single spaces.'))
    return
  end
  if not world then
    displayErrorBox(tr('Character creation'), tr('No world is available for character creation.'))
    return
  end

  local host, port, errorMessage = EnterGame.prepareConnection()
  if errorMessage then
    displayErrorBox(tr('Character creation'), errorMessage)
    return
  end

  CharacterCreation.hide(false)
  protocol = ProtocolLogin.create()
  protocol.onLoginError = function(_, message) showError(message) end
  protocol.onCreationResult = onCreationResult
  loadBox = displayCancelBox(tr('Please wait'), tr('Creating character...'))
  connect(loadBox, {
    onCancel = function()
      loadBox = nil
      protocol:cancelLogin()
      protocol = nil
      CharacterCreation.show()
    end
  })
  protocol:createCharacter(host, port, G.account, G.password, G.authenticatorToken, name, sex, world.data.worldName)
end
