---@class XUiBigWorldMapOverviewPanel : XUiNode
---@field Parent XUiBigWorldMapOverview
---@field _Control XBigWorldMapControl
local XUiBigWorldMapOverviewPanel = XClass(XUiNode, "XUiBigWorldMapOverviewPanel")

function XUiBigWorldMapOverviewPanel:OnStart(levelId)
    self._CurrentLevelId = levelId
    self._CurrentEnableCount = 0
    self._CurrentDisableCount = 0
end

function XUiBigWorldMapOverviewPanel:ShowBackground(isShow)
    if self._Background then
        self._Background.gameObject:SetActiveEx(isShow)
    end
end

function XUiBigWorldMapOverviewPanel:PlayEnableAnimation(parent)
    self:Open()
    self._CurrentEnableCount = 0

    if not XTool.IsTableEmpty(self._EnableAnimations) then
        XMVCA.XBigWorldUI:SetMaskActive(true, "XUiBigWorldMapOverviewPanel")
        for _, animation in pairs(self._EnableAnimations) do
            animation:PlayTimelineAnimation(function()
                self._CurrentEnableCount = self._CurrentEnableCount + 1

                if self._CurrentEnableCount >= #self._EnableAnimations then
                    XMVCA.XBigWorldUI:SetMaskActive(false, "XUiBigWorldMapOverviewPanel")
                    self:SetParent(parent)
                end
            end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
        end
    else
        self:SetParent(parent)
    end
end

function XUiBigWorldMapOverviewPanel:PlayDisableAnimation(parent)
    self._CurrentDisableCount = 0

    if not XTool.IsTableEmpty(self._DisableAnimations) then
        XMVCA.XBigWorldUI:SetMaskActive(true, "XUiBigWorldMapOverviewPanel")
        for _, animation in pairs(self._DisableAnimations) do
            animation:PlayTimelineAnimation(function()
                self._CurrentDisableCount = self._CurrentDisableCount + 1

                if self._CurrentDisableCount >= #self._DisableAnimations then
                    XMVCA.XBigWorldUI:SetMaskActive(false, "XUiBigWorldMapOverviewPanel")
                    self:SetParent(parent)
                    self:Close()
                end
            end, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
        end
    else
        self:SetParent(parent)
        self:Close()
    end
end

function XUiBigWorldMapOverviewPanel:SetParent(parent)
    if not XTool.UObjIsNil(parent) then
        self.Transform:SetParent(parent, false)
    end
end

function XUiBigWorldMapOverviewPanel:SetBackgroundParent(backgroundParent)
    if not XTool.UObjIsNil(backgroundParent) then
        if self._Background then
            self._Background.transform:SetParent(backgroundParent, false)
        end
    end
end

function XUiBigWorldMapOverviewPanel:Refresh(overviewId, mapConfigs, background)
    self._OverviewId = overviewId
    self._Background = background

    self._EnableAnimations = {}
    self._DisableAnimations = {}
    for _, config in pairs(mapConfigs) do
        local levelId = config.LevelId
        local button = self["BtnSkyGarden" .. levelId]

        if button then
            local conditionId = config.ConditionId
            local isUnlock = true
            local lockTip = nil

            if XTool.IsNumberValid(conditionId) then
                isUnlock, lockTip = XMVCA.XBigWorldService:CheckCondition(conditionId)
            end

            button.gameObject:SetActiveEx(true)
            button:SetNameByGroup(0, config.MapName)
            button:ShowTag(levelId == self._CurrentLevelId)
            button:SetDisable(not isUnlock)
            button:AddEventListener(function()
                if not isUnlock and lockTip then
                    if lockTip then
                        XMVCA.XBigWorldUI:TipMsg(lockTip)
                    end

                    return
                end

                if XTool.IsNumberValid(levelId) then
                    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_SWITCH, levelId)
                end

                self.Parent:Close()
            end)

            local animationNode = button.transform:FindTransform("Animation")

            if animationNode then
                self._EnableAnimations[levelId] = animationNode:FindTransform("Enable")
                self._DisableAnimations[levelId] = animationNode:FindTransform("Disable")
            end
        end
    end
end

return XUiBigWorldMapOverviewPanel
