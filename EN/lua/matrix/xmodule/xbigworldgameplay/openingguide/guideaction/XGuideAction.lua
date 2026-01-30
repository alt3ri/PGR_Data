
---@class XGuideAction 开场引导功能
---@field _OpenGuide XBigWorldOpenGuide
---@field _Template XTableBigWorldOpenGuide
local XGuideAction = XClass(nil, "XGuideAction")

function XGuideAction:Ctor(template, openGuide)
    self._OpenGuide = openGuide
    self._Template = template
end

function XGuideAction:Begin()
end

function XGuideAction:Finish()
    if not self._OpenGuide then
        return
    end
    --玩家已经登出了，就不需要再发协议了
    if not XLoginManager.IsLogin() then
        return
    end
    local openGuide = self._OpenGuide
    local id = self._Template.Id
    if XMVCA.XBigWorldGamePlay:GetCurrentAgency():CheckOpenGuideFinish(id) then
        if XMVCA.XBigWorldGamePlay:IsInGame() and XLoginManager.IsLogin() then
            self:OnFinish()
            openGuide:RunNext()
        end
        return
    end
    XNetwork.Call("BigWorldGuideOpenRequest", { GuideId = id }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            XMVCA.XBigWorldGamePlay:EnterGameError()
        else
            XMVCA.XBigWorldGamePlay:GetCurrentAgency():AddFinishGuideDict(id)
            self:OnFinish()
            openGuide:RunNext()
        end
    end, function()
        XMVCA.XBigWorldGamePlay:EnterGameError()
    end)
end

function XGuideAction:OnFinish()
end

function XGuideAction:Clear()
end

return XGuideAction