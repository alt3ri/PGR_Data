
---@class XUiBigWorldMapOverview : XLuaUi
---@field MapName UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButtonExt
---@field BtnDetailClose XUiComponent.XUiButtonExt
---@field BtnSkyGarden4001 XUiComponent.XUiButtonExt
---@field BtnSkyGarden5001 XUiComponent.XUiButtonExt
---@field PanelMapBtn XUiButtonGroup
---@field _Control XBigWorldMapControl
local XUiBigWorldMapOverview = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMapOverview")


function XUiBigWorldMapOverview:OnAwake()
    self._CurrentLevelId = 0
    self._MapButtons = {}
    self._MapLevelIdIndexMap = {}

    self:_Init()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMapOverview:OnStart(currentLevelId)
    local mapLinkLevelId = self._Control:GetMapLinkLevelIdByLevelId(currentLevelId)

    if XTool.IsNumberValid(mapLinkLevelId) then
        currentLevelId = mapLinkLevelId
    end

    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    if XMVCA.XBigWorldMap:CheckLevelHasMap(levelId) then
        self._CurrentLevelId = levelId
    else
        self._CurrentLevelId = XMVCA.XBigWorldMap:GetMapLinkLevelIdByLevelId(levelId)
    end
end

function XUiBigWorldMapOverview:OnEnable()
    self:_Init()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMapOverview:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldMapOverview:OnDestroy()
end

function XUiBigWorldMapOverview:OnPanelMapBtnClick(index)
    local levelId = self._MapLevelIdIndexMap[index]
    
    if XTool.IsNumberValid(levelId) then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_SWITCH, levelId)
    end

    self:Close()
end

function XUiBigWorldMapOverview:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(Handler(self, self.Close))
    self.BtnDetailClose:AddEventListener(Handler(self, self.Close))
end

function XUiBigWorldMapOverview:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMapOverview:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMapOverview:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMapOverview:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMapOverview:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMapOverview:_Init()
    local mapConfigs = self._Control:GetAllMapConfigs()

    self._MapButtons = {}
    self._MapLevelIdIndexMap = {}
    if not XTool.IsTableEmpty(mapConfigs) then
        local index = 1

        for levelId, mapConfig in pairs(mapConfigs) do
            local mapButton = self["BtnSkyGarden" .. tostring(levelId)]

            if mapButton then
                self._MapLevelIdIndexMap[index] = levelId
                mapButton:SetNameByGroup(0, mapConfig.MapName)
                mapButton:ShowTag(levelId == self._CurrentLevelId)

                table.insert(self._MapButtons, mapButton)

                index = index + 1
            end
        end

        self.PanelMapBtn:Init(self._MapButtons, Handler(self, self.OnPanelMapBtnClick))
    end
end

return XUiBigWorldMapOverview
