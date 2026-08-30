AccountCreation = {}

local window
local protocol
local loadBox

local function finishRequest()
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
  protocol = nil
end

local function showError(message)
  finishRequest()
  local errorBox = displayErrorBox(tr('Account creation'), tr(message))
  connect(errorBox, { onOk = AccountCreation.show })
end

local function onCreationResult(_, action, success, message)
  if action ~= LoginActionCreateAccount then
    return
  end
  finishRequest()
  if not success then
    local errorBox = displayErrorBox(tr('Account creation'), tr(message))
    connect(errorBox, { onOk = AccountCreation.show })
    return
  end

  local account = window:getChildById('accountName'):getText()
  local password = window:getChildById('password'):getText()
  window:getChildById('accountName'):clearText()
  window:getChildById('password'):clearText()
  window:getChildById('passwordConfirmation'):clearText()
  local infoBox = displayInfoBox(tr('Account creation'), tr(message))
  connect(infoBox, {
    onOk = function()
      AccountCreation.hide(false)
      EnterGame.loginWithCredentials(account, password, '')
    end
  })
end

function AccountCreation.init()
  window = g_ui.displayUI('accountcreation')
  window:hide()
end

function AccountCreation.terminate()
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
  AccountCreation = nil
end

function AccountCreation.show()
  if not window or loadBox then
    return
  end
  EnterGame.hide()
  window:show()
  window:raise()
  window:focus()
  window:getChildById('accountName'):focus()
end

function AccountCreation.hide(showLogin)
  if window then
    window:hide()
  end
  if showLogin ~= false then
    EnterGame.show()
  end
end

function AccountCreation.doCreate()
  local account = window:getChildById('accountName'):getText()
  local password = window:getChildById('password'):getText()
  local confirmation = window:getChildById('passwordConfirmation'):getText()

  if #account < 4 or #account > 32 or not account:match('^[%a%d]+$') then
    displayErrorBox(tr('Account creation'), tr('Account name must contain 4 to 32 letters or numbers.'))
    return
  end
  if #password < 6 or #password > 29 then
    displayErrorBox(tr('Account creation'), tr('Password must contain 6 to 29 characters.'))
    return
  end
  if password ~= confirmation then
    displayErrorBox(tr('Account creation'), tr('Passwords do not match.'))
    return
  end

  local host, port, errorMessage = EnterGame.prepareConnection()
  if errorMessage then
    displayErrorBox(tr('Account creation'), errorMessage)
    return
  end

  AccountCreation.hide(false)
  protocol = ProtocolLogin.create()
  protocol.onLoginError = function(_, message) showError(message) end
  protocol.onCreationResult = onCreationResult
  loadBox = displayCancelBox(tr('Please wait'), tr('Creating account...'))
  connect(loadBox, {
    onCancel = function()
      loadBox = nil
      protocol:cancelLogin()
      protocol = nil
      AccountCreation.show()
    end
  })
  protocol:createAccount(host, port, account, password)
end
