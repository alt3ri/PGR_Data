---@class XUiPanelTheatre6BuffDetail : XUiNode Buff详情
---@field _Control XTheatre6Control
---@field _Buff XUiGridTheatre6Buff
local XUiPanelTheatre6BuffDetail = XClass(XUiNode, "XUiPanelTheatre6BuffDetail")

function XUiPanelTheatre6BuffDetail:OnStart()
    self._ClickCb = nil
    self._IsBtnUseVisible = false
    self._IsSelected = false

    self._Buff = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Buff").New(self.GridBuff, self)

    self.BtnUse:AddEventListener(handler(self, self.OnBtnUseClick))
    self.UiTxtDes.requestImage = XMVCA.XTheatre6.RichTextImageCallBack

    self.UiTxtAdd.gameObject:SetActiveEx(false)
    self.UiTxtLeft.gameObject:SetActiveEx(false)
    self.BtnUse.gameObject:SetActiveEx(false)
    self:SetNowVisible(false)
    self:SetLockVisible(false)
end

---选择Buff
function XUiPanelTheatre6BuffDetail:SetBuffIdToChoose(roleId, index)
    local characterConfig = self._Control:GetCharacterConfig(roleId)
    self._BuffId = characterConfig.TagBuffIds[index]
    self._BuffConditionId = characterConfig.BuffConditionIds[index]
    self._BuffConfig = self._Control:GetBuffConfig(self._BuffId)
    self._Buff:Update(self._BuffId)

    self:ShowBaseInfo()
    self:ShowCondition()
    self:_UpdateSelectStatus()
end

---设置Buff
---@param info XTheatre6BuffData
function XUiPanelTheatre6BuffDetail:SetBuffInfo(info, buffData)
    self._BuffData = buffData or self._Control:GetBuffDataByUid(info.Uid)
    if not self._BuffData then
        XLog.Error(string.format("Buff不存在 uid：%s", info.Uid))
        return
    end
    self._BuffId = self._BuffData.BuffId
    self._BuffConfig = self._Control:GetBuffConfig(self._BuffId)
    self._Buff:UpdateByUid(info.Uid, self._BuffData)
    self._IsUnlock = true

    self:ShowBaseInfo()
    self:ShowTimes(info)
end

---@param info XTheatre6BuffSaveDataProtocol
function XUiPanelTheatre6BuffDetail:SetFileSaveBuff(info)
    self:SetBuffId(info.BuffId)
    self:SetEffectTimes(info.TriggerCount)
end

function XUiPanelTheatre6BuffDetail:SetBuffId(id)
    self._BuffId = id
    self._BuffConfig = self._Control:GetBuffConfig(self._BuffId)
    self._Buff:Update(id)

    self:ShowBaseInfo()
end

---显示名称、描述（富文本）
function XUiPanelTheatre6BuffDetail:ShowBaseInfo()
    self.UiTxtName.text = self._BuffConfig.Name
    self.UiTxtDes.text = self._Control:GetBuffDesc(self._BuffId)
    self:SetDebuff(self._BuffConfig.DebuffType == XEnumConst.Theatre6.DebuffType.Negative)
    self:SetBuffDestory(false)
end

---显示选择Buff所需的条件
function XUiPanelTheatre6BuffDetail:ShowCondition()
    local ret, desc = true, ""
    if XTool.IsNumberValid(self._BuffConditionId) then
        ret, desc = XConditionManager.CheckCondition(self._BuffConditionId)
    end
    self:SetLockVisible(not ret)
    self.UiTxtLock.text = desc
    self._IsUnlock = ret
end

---显示Buff生效和剩余次数
---@param info XTheatre6BuffData
function XUiPanelTheatre6BuffDetail:ShowTimes(info)
    if self._BuffConfig.CanStack then
        self:SetStackCount(info.StackCount) --只显示堆叠数量
        return
    end
    if XTool.IsNumberValid(self._BuffConfig.IsCount) then
        self:SetEffectTimes(self._BuffData.TriggerCount)
    end
    if not XTool.IsTableEmpty(self._BuffConfig.DurationValues) then
        self:SetRemainingTimes(self._BuffData.RemainCount)
    end
end

---是否显示选择按钮
---@param clickCb fun(buffId:number)
function XUiPanelTheatre6BuffDetail:SetBtnUseVisible(clickCb)
    self._ClickCb = clickCb
    self._IsBtnUseVisible = true
    self:_UpdateSelectStatus()
end

---设置当前选中的Buff
function XUiPanelTheatre6BuffDetail:SetCurChooseBuff(id)
    self._IsSelected = id == self._BuffId
    self:_UpdateSelectStatus()
end

function XUiPanelTheatre6BuffDetail:SetStackCount(count)
    self.UiTxtAdd.gameObject:SetActiveEx(true)
    self.UiTxtAdd.text = XUiHelper.GetText("Theatre6BuffStackCount", count)
end

---设置buff生效次数
function XUiPanelTheatre6BuffDetail:SetEffectTimes(times)
    self.UiTxtAdd.gameObject:SetActiveEx(true)
    self.UiTxtAdd.text = XUiHelper.GetText("Theatre6BuffEffectTimes", times)
end

---设置buff剩余生效次数
function XUiPanelTheatre6BuffDetail:SetRemainingTimes(times)
    self.UiTxtLeft.gameObject:SetActiveEx(true)
    self.UiTxtLeft.text = XUiHelper.GetText("Theatre6BuffRemainingTimes", times)
end

---Buff图标是否允许点击
function XUiPanelTheatre6BuffDetail:IsBuffCanClick(bo)
    self._Buff:IsCanClick(bo)
end

---是否被销毁
function XUiPanelTheatre6BuffDetail:SetBuffDestory(isDestroyed)
    self.ImgMaskRuin.gameObject:SetActiveEx(isDestroyed)
end

---是否为Debuff
function XUiPanelTheatre6BuffDetail:SetDebuff(isDebuff)
    self.ImgBgDebuff.gameObject:SetActiveEx(isDebuff)
end

---@private
function XUiPanelTheatre6BuffDetail:_UpdateSelectStatus()
    self.BtnUse.gameObject:SetActiveEx(self._IsBtnUseVisible and self._IsUnlock and not self._IsSelected)
    self:SetNowVisible(self._IsUnlock and self._IsSelected)
end

function XUiPanelTheatre6BuffDetail:OnBtnUseClick()
    if self._ClickCb then
        self._ClickCb(self._BuffId)
    end
end

function XUiPanelTheatre6BuffDetail:SetNowVisible(isVisible)
    if self.UiTxtNowBg then
        self.UiTxtNowBg.gameObject:SetActiveEx(isVisible)
    end
    self.UiTxtNow.gameObject:SetActiveEx(isVisible)
end

function XUiPanelTheatre6BuffDetail:SetLockVisible(isVisible)
    if self.UiTxtLockBg then
        self.UiTxtLockBg.gameObject:SetActiveEx(isVisible)
    end
    self.UiTxtLock.gameObject:SetActiveEx(isVisible)
end

return XUiPanelTheatre6BuffDetail
