--- 角色驻守玩法驻守选择列表界面
---@class XUiGuildWarStayChoose: XLuaUi
---@field _Control XGuildWarControl
local XUiGuildWarStayChoose = XLuaUiManager.Register(XLuaUi, 'UiGuildWarStayChoose')
local XUiGridGuildWarStayChoose = require('XUi/XUiGuildWar/RoleStationChoose/XUiGridGuildWarStayChoose')

function XUiGuildWarStayChoose:OnAwake()
    self.BtnStay:AddEventListener(handler(self, self.OnBtnStayClick))
    self.BtnWithdraw:AddEventListener(handler(self, self.OnBtnWithDrawClick))
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiGuildWarStayChoose:OnStart(nodeId)
    self.NodeId = nodeId
    
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelCharacter, XUiGridGuildWarStayChoose)
end

function XUiGuildWarStayChoose:OnEnable()
    self:Refresh()
    self:RefreshBtnShow()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
end

function XUiGuildWarStayChoose:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
end

function XUiGuildWarStayChoose:Refresh()
    local ownCharList = self._Control.RoleStationControl:GetOwnCharacterListWithStationSort(self.NodeId)
    self.DynamicTable:SetDataSource(ownCharList)
    self.DynamicTable:ReloadDataSync()
end

function XUiGuildWarStayChoose:RefreshBtnShow()
    self.BtnStay.gameObject:SetActiveEx(false)
    self.BtnWithdraw.gameObject:SetActiveEx(false)
    
    if XTool.IsNumberValidEx(self.CurSelectIndex) then
        local characterId = self:_GetCurSelectCharacterId()
        -- 如果当前选择的角色驻扎在当前关卡，显示撤回
        -- 如果当前选择的角色驻扎在别的关卡，显示驻扎按钮，但表现改为禁用
        if self._Control.RoleStationControl:CheckCharacterIsStationedInTargetNode(characterId, self.NodeId) then
            self.BtnWithdraw.gameObject:SetActiveEx(true)
        elseif self._Control.RoleStationControl:CheckCharacterIsStationedAnyNode(characterId) then
            self.BtnStay.gameObject:SetActiveEx(true)
            self.BtnStay:SetButtonState(CS.UiButtonState.Disable)
            self.BtnStay:SetNameByGroup(0, self._Control.RoleStationControl:GetClientConfigRoleStationBtnName(false))
        else
            self.BtnStay.gameObject:SetActiveEx(true)
            self.BtnStay:SetButtonState(CS.UiButtonState.Normal)
            self.BtnStay:SetNameByGroup(0, self._Control.RoleStationControl:GetClientConfigRoleStationBtnName(true))
        end
    end
end

function XUiGuildWarStayChoose:_GetCurSelectCharacterId()
    if XTool.IsNumberValidEx(self.CurSelectIndex) then
        local characterData = self.DynamicTable.DataSource[self.CurSelectIndex]

        if characterData then
            return characterData.Id
        end
    end
end

--- 选择驻守
function XUiGuildWarStayChoose:OnBtnStayClick()
    if XTool.IsNumberValidEx(self.CurSelectIndex) then
        local characterData = self.DynamicTable.DataSource[self.CurSelectIndex]
        
        if characterData then
            if self._Control.RoleStationControl:CheckCharacterIsStationedAnyNode(characterData.Id) then
                XUiManager.TipMsg(self._Control.RoleStationControl:GetClientConfigRoleStationedOtherNodeTips())
            else
                local curStationedCount = self._Control.RoleStationControl:GetCurNodeStationedRoleCount(self.NodeId)
                local stationedMaxCount = self._Control.RoleStationControl:GetCurNodeStationedMaxCount(self.NodeId)
                local hasStationed = self._Control.RoleStationControl:CheckNodeIsAnyCharacterStationed(self.NodeId)
                
                if hasStationed or curStationedCount < stationedMaxCount then
                    XMVCA.XGuildWar.RoleStationAgency:RequestXGuildWarBeStationed(self.NodeId, characterData.Id, function(success)
                        XUiManager.TipMsg(self._Control.RoleStationControl:GetClientConfigRoleStationedSuccessTips())
                        self:Close()
                    end)
                else
                    XUiManager.TipMsg(self._Control.RoleStationControl:GetClientConfigCannotStationedWithMaxTips())
                    self:Close()
                end
            end
        else
            XLog.Error('选择的角色数据不存在，索引: ' .. tostring(self.CurSelectIndex))    
        end
    else
        XUiManager.TipMsg(self._Control.RoleStationControl:GetClientConfigNoRoleSelectForStation())
    end
end

--- 撤回驻守
function XUiGuildWarStayChoose:OnBtnWithDrawClick()
    XMVCA.XGuildWar.RoleStationAgency:RequestXGuildWarBeStationed(self.NodeId, 0, function()
        XUiManager.TipMsg(self._Control.RoleStationControl:GetClientConfigRoleStationedRemoveTips())
        self:Close()
    end)
end

function XUiGuildWarStayChoose:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:Refresh(self.DynamicTable.DataSource[index])
        grid:SetSelectState(index == self.CurSelectIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local isSameIndex = self.CurSelectIndex == index
        
        if XTool.IsNumberValidEx(self.CurSelectIndex) then
            local grid = self.DynamicTable:GetGridByIndex(self.CurSelectIndex)

            if grid then
                grid:SetSelectState(false)
            end
        end

        if isSameIndex then
            -- 点击同一个位置，取消选择
            self.CurSelectIndex = nil
        else
            self.CurSelectIndex = index

            local grid = self.DynamicTable:GetGridByIndex(self.CurSelectIndex)

            if grid then
                grid:SetSelectState(true)
            end
        end
        
        self:RefreshBtnShow()
    end
end

function XUiGuildWarStayChoose:CheckClose(actionList)
    local IsClose = false

    if not XTool.IsTableEmpty(actionList) then
        for _, action in pairs(actionList) do
            if action.NodeId and action.NodeId == self.NodeId then
                IsClose = true
                break
            end

            -- 如果是龙怒动画，也需要关闭
            if action.ActionType == XGuildWarConfig.GWActionType.DragonRageFull or action.ActionType == XGuildWarConfig.GWActionType.DragonRageEmpty then
                IsClose = true
                break
            end
        end
    end
    if IsClose then
        self:Close()
    end
end

return XUiGuildWarStayChoose