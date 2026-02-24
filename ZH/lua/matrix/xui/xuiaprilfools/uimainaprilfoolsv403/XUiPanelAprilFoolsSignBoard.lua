local XUiPanelSignBoard = require('XUi/XUiMain/XUiChildView/XUiPanelSignBoard')

---@class XUiPanelAprilFoolsSignBoard: XUiPanelSignBaord
---@field Parent XUiMainAprilFoolsV403
local XUiPanelAprilFoolsSignBoard = XClass(XUiPanelSignBoard, 'XUiPanelAprilFoolsSignBoard')

--region override

function XUiPanelAprilFoolsSignBoard:OnDisable()
    XUiPanelSignBoard.OnDisable(self)
    
    self:StopSpecialContentShowTimeId()
end

-- 面板随机角色
function XUiPanelAprilFoolsSignBoard:DoRandomAndChangeDisplayCharacter()
    -- 随机角色
    local displayCharacterId = self.Parent:GetDisplayRoleId()
    self:SetDisplayCharacterId(displayCharacterId)

    -- 刷新
    if not self.Parent then
        return
    end

    self:SetDisplayCharacterId(displayCharacterId)
    self:RefreshCharModel()
    if self.Parent.PlayChangeModelEffect then
        self.Parent:PlayChangeModelEffect()
    end
    self.SignBoardPlayer:Stop()

end

function XUiPanelAprilFoolsSignBoard:RefreshCharModel()
    if self.Parent.OnRefreshRoleBefore then
        self.Parent:OnRefreshRoleBefore()
    end
    
    self.DisplayState = self.Parent:UpdateRoleModel(self.RoleModel, self.DisplayCharacterId)
end

function XUiPanelAprilFoolsSignBoard:CheckBtnReplaceDisable()
    return true
end

function XUiPanelAprilFoolsSignBoard:OnMultClick(clickTimes)
    XUiPanelSignBoard.OnMultClick(self, clickTimes, true)
end

--============================
-- 动作/特效
--============================
function XUiPanelAprilFoolsSignBoard:_PlayAction(element, isCross)
    local actionId = element.SignBoardConfig.ActionId
    if not actionId then return end

    if isCross then
        self:PlayAnimaCross(actionId)
    else
        self:PlayAnima(actionId)
    end
    -- ignore
    --self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
end

function XUiPanelAprilFoolsSignBoard:AOPAfterOperationShowEnd()
    -- 踢飞按钮跟随一起隐藏
    self.Parent:SetBtnExpelActive(false)
end

function XUiPanelAprilFoolsSignBoard:AOPAfterOperationShowBegin()
    -- 显示“一键踢飞”
    self.Parent:SetBtnExpelActive(true)
    self.Parent:SetPanelQuitActive(true)
end

--endregion

--region 愚人节踢飞动画

function XUiPanelAprilFoolsSignBoard:OnTickOutShow(actionId, content, contentShowTime, cb)
    if not string.IsNilOrEmpty(actionId) then
        self:PlayAnimaCross(actionId)
    end

    self:StopSpecialContentShowTimeId()
    
    if not string.IsNilOrEmpty(content) then
        self.PanelChat.gameObject:SetActiveEx(true)
        self.TxtContent.text = content

        XLuaUiManager.SetMask(true, 'AprilFoolsTickOutAnimMask')
        self._SpecialContentShowTimeId = XScheduleManager.ScheduleOnce(function()
            self.PanelChat.gameObject:SetActiveEx(false)
            self:_SafeClearAprilFoolsTickOutAnimMask()

            if cb then
                cb()
            end
        end, contentShowTime)
    else
        self.PanelChat.gameObject:SetActiveEx(false)
    end
end

function XUiPanelAprilFoolsSignBoard:StopSpecialContentShowTimeId()
    if self._SpecialContentShowTimeId then
        XScheduleManager.UnSchedule(self._SpecialContentShowTimeId)
        self._SpecialContentShowTimeId = nil
    end

    self:_SafeClearAprilFoolsTickOutAnimMask()
end

function XUiPanelAprilFoolsSignBoard:_SafeClearAprilFoolsTickOutAnimMask()
    for i = 1, 10 do
        if XLuaUiManager.IsMaskShow('AprilFoolsTickOutAnimMask') then
            XLuaUiManager.SetMask(false, 'AprilFoolsTickOutAnimMask')
        else
            break
        end
    end
end
--endregion

return XUiPanelAprilFoolsSignBoard