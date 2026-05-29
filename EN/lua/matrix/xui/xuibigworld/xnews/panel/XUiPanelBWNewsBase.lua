---@class XUiPanelBWNewsBase : XUiNode
---@field Parent XUiBigWorldPopupNews
---@field BtnTeach XUiComponent.XUiButton 若存在 *教学按钮* ，则需要命名为 **BtnTeach**
local XUiPanelBWNewsBase = XClass(XUiNode, "XUiPanelBWNewsBase")

function XUiPanelBWNewsBase:SetNewsId(newsId)
    self._NewsId = newsId
end

function XUiPanelBWNewsBase:GetNewsId()
    return self._NewsId
end

function XUiPanelBWNewsBase:Refresh()
    if XTool.IsNumberValid(self._NewsId) then
        self:RefreshContent(self._NewsId)
        self:RefreshReward(XMVCA.XBigWorldNews:GetNewsShowReward(self._NewsId))
        self:RefreshParams(XMVCA.XBigWorldNews:GetNewsParams(self._NewsId))
        self:RefreshTask(XMVCA.XBigWorldNews:GetNewsTaskGroupId(self._NewsId))
        self:RefreshTeach()
        self:RefreshOther()
    end
end

function XUiPanelBWNewsBase:RefreshContent(newsId)
end

function XUiPanelBWNewsBase:RefreshReward(rewardId)
end

function XUiPanelBWNewsBase:RefreshParams(params)
end

function XUiPanelBWNewsBase:RefreshTask(taskGroupId)
end

function XUiPanelBWNewsBase:RefreshOther()
end

function XUiPanelBWNewsBase:RefreshTeach()
    if XTool.UObjIsNil(self.BtnTeach) or not XTool.IsNumberValid(self._NewsId) then
        return
    end

    local dialogId = XMVCA.XBigWorldNews:GetNewsDialogId(self._NewsId)

    self.BtnTeach.gameObject:SetActiveEx(dialogId and dialogId > 0)
end

function XUiPanelBWNewsBase:RegisterButtonClick()
    if self.BtnTeach then
        self.BtnTeach:AddEventListener(Handler(self, self.OnBtnTeachClick))
    end
end

function XUiPanelBWNewsBase:OnBtnTeachClick()
    if not XTool.IsNumberValid(self._NewsId) then
        return
    end

    local dialogId = XMVCA.XBigWorldNews:GetNewsDialogId(self._NewsId)

    if not XTool.IsNumberValid(dialogId) then
        return
    end

    XMVCA.XBigWorldUI:OpenTextDialog(dialogId)
end

function XUiPanelBWNewsBase:IsInTime()
    return XMVCA.XBigWorldNews:CheckNewsInTime(self._NewsId)
end

---@return boolean
function XUiPanelBWNewsBase:IsFinish()
    return false
end

---@return boolean
function XUiPanelBWNewsBase:IsTime()
    return false
end

---@return boolean
function XUiPanelBWNewsBase:IsNew()
    return XMVCA.XBigWorldNews:CheckNewsNew(self._NewsId)
end

---@return boolean
function XUiPanelBWNewsBase:IsShowTag()
    return XMVCA.XBigWorldNews:CheckNewsShowTag(self._NewsId)
end

---@return boolean
function XUiPanelBWNewsBase:IsShowTimeTag()
    return self:IsTime() and self:IsShowTag() and self:IsInTime() and not self:IsNew() and not self:IsShowReddot()
end

---@return boolean
function XUiPanelBWNewsBase:IsShowNewTag()
    return self:IsNew() and not self:IsShowReddot()
end

function XUiPanelBWNewsBase:IsShowFinishTag()
    return self:IsFinish() and not (self:IsTime() and self:IsInTime() and self:IsShowTag()) and not self:IsNew() and not self:IsShowReddot()
end

---@return boolean
function XUiPanelBWNewsBase:IsShowReddot()
    return XMVCA.XBigWorldNews:CheckNewsRedPoint(self._NewsId)
end

return XUiPanelBWNewsBase
