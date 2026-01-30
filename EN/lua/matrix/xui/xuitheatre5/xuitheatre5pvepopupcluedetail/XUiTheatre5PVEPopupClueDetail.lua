---@class XUiTheatre5PVEPopupClueDetail: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEPopupClueDetail = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEPopupClueDetail')
local XUiTheatre5PVEMinorClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVEMinorClue")

function XUiTheatre5PVEPopupClueDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnClickClose, true)
end

function XUiTheatre5PVEPopupClueDetail:OnStart(clueId, closeCb)
    self._CloseCb = closeCb
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    if not clueCfg then
        return
    end
    if clueCfg.Type == XMVCA.XTheatre5.EnumConst.PVEClueType.Core then
        XLog.Error(string.format("核查配置表,只能获得次要线索,clueId:%s", clueId))
        return
    end
    local theatre5PVEMinorClue = XUiTheatre5PVEMinorClue.New(self.UiTheatre5MinorClue, self)
    theatre5PVEMinorClue:Update(clueId)
    
    local curContentId = self._Control.PVEControl:GetStoryLineContentId(self._Control.PVEControl:GetCurPveStoryLineId())
    local storyLineContentCfg = self._Control.PVEControl:GetStoryLineContentCfg(curContentId)
    local scriptCfg = self._Control.PVEControl:GetDeduceScriptCfg(storyLineContentCfg.NextScript)
    local clueCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(scriptCfg.PreClueGroupId)
    local unLockCount = self._Control.PVEControl:GetUnlockDeduceScriptCount(storyLineContentCfg.NextScript)
    self.TxtNum.text = string.format("%d/%d", unLockCount, #clueCfgs)  
end

function XUiTheatre5PVEPopupClueDetail:OnClickClose()
    XLuaUiManager.CloseWithCallback(self.Name, self._CloseCb)
end


return XUiTheatre5PVEPopupClueDetail