--- 角色驻守玩法在节点详情页中的面板
---@class XUiPanelRoleStationed: XUiNode
---@field _Control XGuildWarControl
local XUiPanelRoleStationed = XClass(XUiNode, 'XUiPanelRoleStationed')

function XUiPanelRoleStationed:OnStart()
    self.BtnStay:AddEventListener(handler(self, self._OnBtnStayClickEvent))
end

function XUiPanelRoleStationed:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PLAYER_STATION_CHANGE, self.RefreshShow, self)
end

function XUiPanelRoleStationed:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PLAYER_STATION_CHANGE, self.RefreshShow, self)
end

function XUiPanelRoleStationed:InitNodeId(nodeId)
    self.NodeId = nodeId

    if self:CheckCanShow() then
        self:RefreshShow()
    else
        self:Close()
    end
end

function XUiPanelRoleStationed:CheckCanShow()
    -- 目前状态由固定配置决定，所以nodeId不变的情况下可缓存状态
    self._NodeCanBeStationed = self._Control.RoleStationControl:CheckNodeCanBeStationed(self.NodeId)
    
    return self._NodeCanBeStationed
end

function XUiPanelRoleStationed:RefreshShow()
    if not XTool.IsNumberValidEx(self.NodeId) then
        return
    end
    
    self:_RefreshCharacterShow()
    self:_RefreshStationProgressShow()
end

function XUiPanelRoleStationed:_RefreshCharacterShow()
    --- 获取并显示玩家驻守角色的头像
    local characterId = self._Control.RoleStationControl:GetMyRoleStationCharacterIdByNodeId(self.NodeId)
    local hasCharacter = XTool.IsNumberValidEx(characterId)

    self.RImgHead.gameObject:SetActiveEx(hasCharacter)

    if hasCharacter then
        local iconUrl = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)

        if not string.IsNilOrEmpty(iconUrl) then
            self.RImgHead:SetRawImage(iconUrl)
        end
    end
end

function XUiPanelRoleStationed:_RefreshStationProgressShow()
    -- 标题
    local hasStationed = self._Control.RoleStationControl:CheckNodeIsAnyCharacterStationed(self.NodeId)
    local isStationedMax = self._Control.RoleStationControl:CheckNodeStationedIsMax(self.NodeId)
    
    --self.TxtTitle.text = self._Control.RoleStationControl:GetClientConfigPanelRoleStationStateShow(hasStationed, not isStationedMax)
    
    -- UI状态
    if self.PanelRoleAdd then
        self.PanelRoleAdd.gameObject:SetActiveEx(not hasStationed and not isStationedMax)
    end

    if self.PanelRoleNor then
        self.PanelRoleNor.gameObject:SetActiveEx(hasStationed)
    end

    if self.PanelRoleMax then
        self.PanelRoleMax.gameObject:SetActiveEx(not hasStationed and isStationedMax)
    end
    
    -- 驻扎进度及效果
    self.TxtDetails.text = self._Control.RoleStationControl:GetClientConfigPanelRoleStationProgressShow(self.NodeId)
end

function XUiPanelRoleStationed:_OnBtnStayClickEvent()
    if self._NodeCanBeStationed then
        local hasStationed = self._Control.RoleStationControl:CheckNodeIsAnyCharacterStationed(self.NodeId)
        local curStationedCount = self._Control.RoleStationControl:GetCurNodeStationedRoleCount(self.NodeId)
        local stationedMaxCount = self._Control.RoleStationControl:GetCurNodeStationedMaxCount(self.NodeId)

        if hasStationed or curStationedCount < stationedMaxCount then
            XLuaUiManager.Open('UiGuildWarStayChoose', self.NodeId)
        else
            XUiManager.TipMsg(self._Control.RoleStationControl:GetClientConfigCannotStationedWithMaxTips())
        end
    end
end

return XUiPanelRoleStationed