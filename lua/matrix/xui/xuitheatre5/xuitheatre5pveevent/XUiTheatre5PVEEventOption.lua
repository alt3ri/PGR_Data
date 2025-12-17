--- 章节主界面事件节点
---@class XUiTheatre5PVEEventOption: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEEventOption = XClass(XUiNode, 'XUiTheatre5PVEEventOption')
local XUiTheatre5PVEEventOptionItem = require("XUi/XUiTheatre5/XUiTheatre5PVEEvent/XUiTheatre5PVEEventOptionItem")

function XUiTheatre5PVEEventOption:OnStart()
    self._CurEventId = nil
    self._CurOptionId = nil
    self._OptionGridList = {}
    XUiHelper.RegisterClickEvent(self, self.BtnSure, self.OnClickConfirm, true, true, 0.5) 
end

function XUiTheatre5PVEEventOption:UpdateData(eventCfg)
    if not eventCfg then
        return
    end
    self._CurOptionId = nil
    self._CurEventId = eventCfg.Id
    self.TxtContent.text = XUiHelper.ReplaceTextNewLine(eventCfg.Desc)
    self.BtnSure:SetName(eventCfg.ConfirmContent)
    self:UpdateOptions(eventCfg)
end

function XUiTheatre5PVEEventOption:UpdateOptions(eventCfg)
    local eventOptionCfgs = self._Control.PVEControl:GetPveEventOptionCfgs(eventCfg.OptionGroupId)
    local curShowEventOptionCfgs = {}
    for _, cfg in pairs(eventOptionCfgs) do
        local isUnlock,desc = XConditionManager.CheckConditionAndDefaultPass(cfg.OptionShowCondition)
        if isUnlock then
            table.insert(curShowEventOptionCfgs,{EventId = eventCfg.Id,EventOptionId = cfg.Id})
        end    
    end
    if XTool.IsTableEmpty(curShowEventOptionCfgs) then
        self.BtnOption.gameObject:SetActiveEx(false)
        return
    end   
    self.BtnSure:SetDisable(true, false) 
    XTool.UpdateDynamicItem(self._OptionGridList, curShowEventOptionCfgs, self.BtnOption, XUiTheatre5PVEEventOptionItem, self)
        
end

function XUiTheatre5PVEEventOption:UpdateSelectOption(optionId)
    self._CurOptionId = optionId
    if not XTool.IsTableEmpty(self._OptionGridList) then
        for _, item in pairs(self._OptionGridList) do
            item:SetSelect(optionId)
        end
    end
    self.BtnSure:SetDisable(false, true)   
end

function XUiTheatre5PVEEventOption:OnClickConfirm()
    if not XTool.IsNumberValid(self._CurOptionId) then
        return
    end    
    XMVCA.XTheatre5.PVEAgency:RequestPveEventPromote(self._CurEventId, self._CurOptionId)
    self._CurOptionId = nil  
end

function XUiTheatre5PVEEventOption:OnDestroy()
    self._CurEventId = nil
    self._CurOptionId = nil
    self._OptionGridList = nil
end

return XUiTheatre5PVEEventOption