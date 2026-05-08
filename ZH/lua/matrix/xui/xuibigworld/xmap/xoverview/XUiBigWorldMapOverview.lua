local XUiBigWorldMapOverviewPanel = require("XUi/XUiBigWorld/XMap/XOverview/XUiBigWorldMapOverviewPanel")

---@class XUiBigWorldMapOverview : XBigWorldUi
---@field MapName UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButtonExt
---@field BtnArea XUiComponent.XUiButtonExt
---@field RImgBgCurrent UnityEngine.RectTransform
---@field RImgBgNext UnityEngine.RectTransform
---@field PanelCurrent UnityEngine.RectTransform
---@field PanelNext UnityEngine.RectTransform
---@field PanelMap UnityEngine.RectTransform
---@field PanelMapBg UnityEngine.RectTransform
---@field PanelAreaChangeTab XUiButtonGroup
---@field _Control XBigWorldMapControl
local XUiBigWorldMapOverview = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMapOverview")


function XUiBigWorldMapOverview:OnAwake()
    self._CurrentLevelId = 0
    self._CurrentOverviewIndex = 0

    self._AreaButtons = {}

    self._OverviewIndexMap = {}

    self._LockTips = {}

    ---@type table<number, XUiBigWorldMapOverviewPanel>
    self._PanelMap = {}

    ---@type XUiBigWorldMapOverviewPanel
    self._CurrentPanel = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMapOverview:OnStart()
    self:_InitLevelId()
    self:_Init()
end

function XUiBigWorldMapOverview:OnEnable()
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

function XUiBigWorldMapOverview:OnPanelAreaChangeTabClick(index)
    if index == self._CurrentOverviewIndex then
        return
    end

    local nextId = self._OverviewIndexMap[index]

    if self._LockTips[nextId] then
        XMVCA.XBigWorldUI:TipMsg(self._LockTips[nextId])
        return
    end

    local currentId = self._OverviewIndexMap[self._CurrentOverviewIndex]
    local currentPosX = self._Control:GetOverviewPosX(currentId)
    local currentPosY = self._Control:GetOverviewPosY(currentId)
    local nextPosX = self._Control:GetOverviewPosX(nextId)
    local nextPosY = self._Control:GetOverviewPosY(nextId)
    local offsetX = nextPosX - currentPosX
    local offsetY = nextPosY - currentPosY
    local animationName = nil
    local nextPanel = self._PanelMap[nextId]

    if math.abs(offsetX) > math.abs(offsetY) then
        if offsetX > 0 then
            animationName = "QiehuanLtoR"
        else
            animationName = "QiehuanRtoL"
        end
    elseif math.abs(offsetX) < math.abs(offsetY) then
        if offsetY > 0 then
            animationName = "QiehuanTtoD"
        else
            animationName = "QiehuanDtoT"
        end
    else
        animationName = "Qiehuan05"
    end

    nextPanel:SetParent(self.PanelNext)
    nextPanel:SetBackgroundParent(self.RImgBgCurrent)
    nextPanel:PlayEnableAnimation(self.PanelCurrent)
    self._CurrentPanel:SetBackgroundParent(self.RImgBgNext)
    self._CurrentPanel:PlayDisableAnimation(self.PanelMap, self.PanelMapBg)

    self:PlayAnimationWithMask(animationName, function()
        self:PlayAnimation("Loop")
    end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
    self:PlayAnimation("QiehuanBG")

    self._CurrentPanel = nextPanel
    self._CurrentOverviewIndex = index
end

function XUiBigWorldMapOverview:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(Handler(self, self.Close))
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

function XUiBigWorldMapOverview:_InitLevelId()
    local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

    if XMVCA.XBigWorldMap:CheckLevelHasMap(currentLevelId) then
        self._CurrentLevelId = currentLevelId
    else
        self._CurrentLevelId = XMVCA.XBigWorldMap:GetMapLinkLevelIdByLevelId(currentLevelId)
    end
end

function XUiBigWorldMapOverview:_InitUi()
    self.BtnArea.gameObject:SetActiveEx(false)
end

function XUiBigWorldMapOverview:_Init()
    local index = 1
    local overviewMapConfigs = self._Control:GetOverviewMapConfigs()
    local currentOverviewId = self._Control:GetOverviewIdByLevelId(self._CurrentLevelId)

    self._OverviewIndexMap = {}
    self._CurrentOverviewIndex = 1
    if not XTool.IsTableEmpty(overviewMapConfigs) then
        local buttons = {}

        for overviewId, mapConfigs in pairs(overviewMapConfigs) do
            local btn = self._AreaButtons[index]
            local isUnlock = false
            local lockTip = nil

            if not XTool.IsTableEmpty(mapConfigs) then
                for _, mapConfig in pairs(mapConfigs) do
                    local conditionId = mapConfig.ConditionId

                    if XTool.IsNumberValid(conditionId) then
                        local isSuccess, tip = XMVCA.XBigWorldService:CheckCondition(conditionId)

                        isUnlock = isSuccess
                        if not isSuccess and not lockTip then
                            lockTip = tip or ""
                        end
                    else
                        isUnlock = true
                        break
                    end
                end
            end

            if isUnlock then
                local prefab = self.PanelMap:LoadPrefabEx(self._Control:GetOverviewPrefab(overviewId))
                local background = self.PanelMapBg:LoadPrefabEx(self._Control:GetOverviewBackground(overviewId))

                prefab.gameObject:SetActiveEx(true)
                background.gameObject:SetActiveEx(true)

                ---@type XUiBigWorldMapOverviewPanel
                local panel = XUiBigWorldMapOverviewPanel.New(prefab, self, self._CurrentLevelId)

                self._PanelMap[overviewId] = panel
                panel:Refresh(overviewId, mapConfigs, background)
                if overviewId == currentOverviewId then
                    self._CurrentPanel = panel
                    self._CurrentPanel:PlayEnableAnimation(self.PanelCurrent)
                    self._CurrentPanel:SetBackgroundParent(self.RImgBgCurrent)
                    self:PlayAnimation("QiehuanBG")
                    self._CurrentOverviewIndex = index
                else
                    panel:ShowBackground(false)
                    panel:Close()
                end
            else
                self._LockTips[overviewId] = lockTip
            end

            if not btn then
                btn = XUiHelper.Instantiate(self.BtnArea, self.PanelAreaChangeTab.transform)

                self._AreaButtons[index] = btn
            end

            self._OverviewIndexMap[index] = overviewId
            table.insert(buttons, btn)
            btn.gameObject:SetActiveEx(true)
            btn:SetNameByGroup(0, self._Control:GetOverviewName(overviewId))
            btn:SetRawImage(self._Control:GetOverviewIcon(overviewId))
            btn:SetDisable(not isUnlock)
            index = index + 1
        end

        self.PanelAreaChangeTab.gameObject:SetActiveEx(true)
        self.PanelAreaChangeTab:Init(buttons, Handler(self, self.OnPanelAreaChangeTabClick))
        self.PanelAreaChangeTab:SelectIndex(self._CurrentOverviewIndex)
    else
        self.PanelAreaChangeTab.gameObject:SetActiveEx(false)
    end

    for i = index, #self._AreaButtons do
        self._AreaButtons[i].gameObject:SetActiveEx(false)
    end
end

return XUiBigWorldMapOverview
