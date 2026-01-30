---@class XUiTheatre5PopupChoose: XLuaUi
---@field _Control XTheatre5Control
---@field BtnGroup XUiButtonGroup
local XUiTheatre5PopupChoose = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PopupChoose')

function XUiTheatre5PopupChoose:OnAwake()
    self.BtnSure:AddEventListener(handler(self, self.OnSubmit))
    self.BtnSure.gameObject:SetActiveEx(false)
end

function XUiTheatre5PopupChoose:OnStart(cfg)
    ---@type XTableTheatre5PveStoryLineContent
    self.Cfg = cfg

    if not self.Cfg then
        XLog.Error('分支选择节点配置不存在')
        self:Close()
        return
    end
    
    self:InitShow()
end


function XUiTheatre5PopupChoose:InitShow()
    self.TxtDescription.text = self.Cfg.CharacterStoryDesc

    -- 初始化选项组
    local btnGroup = {}
    
    for i = 1, 10 do
        local btn = self['BtnOption' .. i]

        if btn then
            local label = self.Cfg.ChooseLabels[i]

            if not string.IsNilOrEmpty(label) then
                table.insert(btnGroup, btn)
                
                btn:SetNameByGroup(0, label)
                
                local isLock = XTool.IsNumberValidEx(self.Cfg.ChooseConditions[i]) and not XConditionManager.CheckCondition(self.Cfg.ChooseConditions[i])
                
                btn:SetButtonState(isLock and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
            end
        end
    end

    if not XTool.IsTableEmpty(btnGroup) then
        self.BtnGroup:Init(btnGroup, handler(self, self.OnBranchSelect))
    end
    
    self._NotSelectAnyYield = true
end

function XUiTheatre5PopupChoose:OnBranchSelect(index, force)
    if self.CurIndex == index and not force then
        return
    end
    
    local condition = self.Cfg.ChooseConditions[index]

    if XTool.IsNumberValidEx(condition) then
        local isUnlock, desc = XConditionManager.CheckCondition(condition)

        if not isUnlock then
            XUiManager.TipMsg(desc)
            return
        end
    end

    if self._NotSelectAnyYield then
        self._NotSelectAnyYield = false

        self:PlayAnimationWithMask('Switch' .. tostring(index))
    else
        self:PlayAnimationWithMask('Switch' .. tostring(self.CurIndex) .. 'To' .. tostring(index))
    end

    self.CurIndex = index

    self.BtnSure.gameObject:SetActiveEx(true)
end

function XUiTheatre5PopupChoose:OnSubmit()
    local chooseContentId = self.Cfg.ChooseContents[self.CurIndex]

    if not XTool.IsNumberValidEx(self.CurIndex) then
        XLog.Error('选择的选项没有有效的节点Id, Index: ' .. tostring(self.CurIndex) .. ' ContentId: ' .. tostring(chooseContentId))
        return
    end

    XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self.Cfg.StoryLineId, self.Cfg.Id, function()
        self._Control.FlowControl:EnterStroryLineContent(self.Cfg.StoryLineId)
        -- 因为不确定其他节点是否会处理该界面，因此使用安全接口进行关闭
        XLuaUiManager.SafeClose('UiTheatre5PopupChoose')
    end, chooseContentId)
end

return XUiTheatre5PopupChoose