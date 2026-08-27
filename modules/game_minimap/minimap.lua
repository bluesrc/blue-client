local otmm = true
local oldPos = nil
local minimapButton = nil

-- bot fix
minimapWidget = nil

local function updateCameraPosition()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local pos = player:getPosition()
    if not pos then
        return
    end

    local minimapWidget = controller.ui.contentsPanel.minimap
    if minimapWidget:isDragging() then
        return
    end

    if not minimapWidget.fullMapView then
        minimapWidget:setCameraPosition(pos)
    end

    minimapWidget:setCrossPosition(pos)
end

function toggle()
    if minimapButton:isOn() then
        controller.ui:close()
    else
        controller.ui:open()
    end
end

function toggleFullMap()
    local rootPanel = modules.game_interface.getRootPanel()
    local minimapWidget = controller.ui.contentsPanel.minimap
    if not minimapWidget then
        minimapWidget = rootPanel.minimap
    end
    local zoom;

    if minimapWidget.fullMapView then
        minimapWidget:setParent(controller.ui.contentsPanel)
        minimapWidget:fill('parent')
        controller.ui:show(true)
        zoom = minimapWidget.zoomMinimap
    else
        controller.ui:hide(true)
        minimapWidget:setParent(rootPanel)
        minimapWidget:fill('parent')
        zoom = minimapWidget.zoomFullmap
    end

    minimapWidget.fullMapView = not minimapWidget.fullMapView
    -- minimapWidget:setAlternativeWidgetsVisible(fullmapView)

    local pos = oldPos or minimapWidget:getCameraPosition()
    oldPos = minimapWidget:getCameraPosition()
    minimapWidget:setZoom(zoom)
    minimapWidget:setCameraPosition(pos)
end

function panLeft()
    minimapWidget:move(1, 0)
end

function panRight()
    minimapWidget:move(-1, 0)
end

function panUp()
    minimapWidget:move(0, 1)
end

function panDown()
    minimapWidget:move(0, -1)
end

controller = Controller:new()
controller:setUI('minimap', modules.game_interface.getRightPanel())
local localPlayerEvent = controller:addEvent(LocalPlayer, {
    onPositionChange = updateCameraPosition
})

function controller:onInit()
    minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', tr('Minimap'),
        '/images/topbuttons/minimap', toggle)
    minimapButton:setOn(true)

    minimapWidget = self.ui.contentsPanel.minimap

    self.ui:setContentMinimumHeight(80)
    self.ui:setup()
end

function controller:onGameStart()
    self.ui:setupOnStart() -- load character window configuration

    -- Load Map
    local minimapFile = '/minimap'
    local loadFnc = nil

    if otmm then
        minimapFile = minimapFile .. '.otmm'
        loadFnc = g_minimap.loadOtmm
    else
        minimapFile = minimapFile .. '_' .. g_game.getClientVersion() .. '.otcm'
        loadFnc = g_map.loadOtcm
    end

    if g_resources.fileExists(minimapFile) then
        loadFnc(minimapFile)
    end

    self.ui.contentsPanel.minimap:load()
end

function controller:onGameEnd()
    self.ui:setParent(nil, true)

    -- Save Map
    if otmm then
        g_minimap.saveOtmm('/minimap.otmm')
    else
        g_map.saveOtcm('/minimap_' .. g_game.getClientVersion() .. '.otcm')
    end

    self.ui.contentsPanel.minimap:save()

    g_minimap.clean()
end

function controller:onTerminate()
    minimapButton:destroy()
    minimapButton = nil
end

function onMiniWindowOpen()
    minimapButton:setOn(true)
    localPlayerEvent:connect()
    localPlayerEvent:execute('onPositionChange')
end

function onMiniWindowClose()
    minimapButton:setOn(false)
    localPlayerEvent:disconnect()
end
