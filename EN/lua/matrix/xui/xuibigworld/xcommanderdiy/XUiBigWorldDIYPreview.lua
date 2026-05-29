---@class XUiBigWorldDIYPreview : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtPreview UnityEngine.UI.Text
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field _Control XBigWorldCommanderDIYControl
---@field BtnSkip XUiComponent.XUiButton
local XUiBigWorldDIYPreview = XClass(XUiNode, "XUiBigWorldDIYPreview")

function XUiBigWorldDIYPreview:OnStart()
    self:_RegisterButtonClicks()
end

function XUiBigWorldDIYPreview:OnBtnTanchuangCloseClick()
    self:Close()
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYPreview:Refresh(entity)
    self.ActivieSkip = nil
    self.TxtTitle.text = entity:GetName()
    self.TxtPreview.text = entity:GetDescription()
    self.Skips = entity:GetSkipFunctions() or {}
    self:RefreshActiveShip()
    self.BtnGo.gameObject:SetActiveEx(self.ActivieSkip ~= nil)
end

function XUiBigWorldDIYPreview:RefreshActiveShip()
    for i, skipId in ipairs(self.Skips) do
        if XMVCA.XBigWorldSkipFunction:IsAllowSkip(skipId, true) then
            self.ActivieSkip = skipId
            break
        end
    end
end

function XUiBigWorldDIYPreview:_RegisterButtonClicks()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
    self.BtnGo:AddEventListener(handler(self, self.OnBtnSkipClick))
end

function XUiBigWorldDIYPreview:OnBtnSkipClick()
    if self.ActivieSkip then
        local isUnlock, desc = XMVCA.XBigWorldSkipFunction:CheckUnlock(self.ActivieSkip)
        if isUnlock then
            if self._Control:CheckNeedSyncInfo() then
                XMVCA.XBigWorldSkipFunction:SkipTo(self.ActivieSkip, true, {
                    tipKey = "DIYNoSaveThenGoSkipConfirmTips",
                    sureCallback = function()
                        self._Control:RestorePreviewPart()
                    end
                })
            else
                XMVCA.XBigWorldSkipFunction:SkipTo(self.ActivieSkip, true)
            end
        else
            XUiManager.TipMsg(desc)
        end
    else
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("BigWorldCourseTaskSkipUnableTip"))
    end
end

return XUiBigWorldDIYPreview
