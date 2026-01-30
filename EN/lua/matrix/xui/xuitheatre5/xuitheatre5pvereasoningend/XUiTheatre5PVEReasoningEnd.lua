---@class XUiTheatre5PVEReasoningEnd: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEReasoningEnd = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEReasoningEnd')
local XUiTheatre5PVEMainClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVEMainClue")

function XUiTheatre5PVEReasoningEnd:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self._DeduceScriptId = nil
    self._MainClueId = nil
    self:RegisterClickEvent(self.BtnYes, self.OnConfirm, true)
    self.BtnBack.gameObject:SetActiveEx(false)
end

---@param mainClueId 核心线索id
---@param deduceScriptId 推演脚本id
function XUiTheatre5PVEReasoningEnd:OnStart(deduceScriptId, mainClueId, closeCb)
    self._MainClueId = mainClueId
    self._DeduceScriptId = deduceScriptId
    ---@type XUiTheatre5PVEMainClue
    self._MainCluePanel = XUiTheatre5PVEMainClue.New(self.UiTheatre5MainClue, self)
    self._MainCluePanel:Update(mainClueId)
    self._MainCluePanel:HideDeduceBtn()
    self._MainCluePanel:HideVideoBtn()
    
    self.CloseCb = closeCb
end

function XUiTheatre5PVEReasoningEnd:OnConfirm()
    --local deduceCfg = self._Control.PVEControl:GetDeduceScriptCfg(self._DeduceScriptId)
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(self._MainClueId)
    if not string.IsNilOrEmpty(clueCfg.StoryId) then
        --close会弹出上个界面触发bgm,故用remove
        XLuaUiManager.Remove(self.Name)
        XDataCenter.MovieManager.PlayMovie(clueCfg.StoryId, self.CloseCb)
    else
        local cb = self.CloseCb
        
        self:Close()

        if cb then
            cb()
        end
    end         
   
end

function XUiTheatre5PVEReasoningEnd:OnDestroy()
    self._DeduceScriptId = nil
    self._MainClueId = nil
end



function XUiTheatre5PVEReasoningEnd:OnBtnBackClick()
    local cb = self.CloseCb

    self:Close()

    if cb then
        cb()
    end
end

return XUiTheatre5PVEReasoningEnd