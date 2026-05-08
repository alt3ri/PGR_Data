---@class XUiGridTheatre6Buff : XUiNode Buff图标节点
---@field _Control XTheatre6Control
local XUiGridTheatre6Buff = XClass(XUiNode, "XUiGridTheatre6Buff")

function XUiGridTheatre6Buff:OnStart()
    self.GridBuff:ShowReddot(false)
    self.UiImgUse.gameObject:SetActiveEx(false)
    self.ImgMask.gameObject:SetActiveEx(false)
    self.ImgTimesBg.gameObject:SetActiveEx(false)
    self:ShowStackCount(0)
    
    self.GridBuff:AddEventListener(handler(self, self.OnGridBuffClick))
end

---只显示基础Buff信息
function XUiGridTheatre6Buff:Update(buffId)
    local buffConfig = self._Control:GetBuffConfig(buffId)

    self._BuffId = buffId
    self._IsUnlock = true
    self.UiRImgIcon:SetRawImage(buffConfig.Icon)
end

function XUiGridTheatre6Buff:UpdateByChoose(buffId, characterId, index)
    local buffConfig = self._Control:GetBuffConfig(buffId)
    local characterConfig = self._Control:GetCharacterConfig(characterId)
    local conditionId = characterConfig.BuffConditionIds[index]
    local ret = not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)

    self._BuffId = buffId
    self._IsUnlock = ret
    self.UiRImgIcon:SetRawImage(buffConfig.Icon)
end

---显示Buff详细信息
function XUiGridTheatre6Buff:UpdateByUid(uid)
    self._BuffUid = uid
    self._BuffData = self._Control:GetBuffDataByUid(uid)
    self._BuffId = self._BuffData.BuffId
    self._IsUnlock = true

    local buffConfig = self._Control:GetBuffConfig(self._BuffId)
    self.UiRImgIcon:SetRawImage(buffConfig.Icon)
    self.UiTxtTimes.text = self._BuffData.RemainCount
end

---显示Buff堆叠信息
---@param info XTheatre6BuffData
function XUiGridTheatre6Buff:UpdateByInfo(info)
    self:UpdateByUid(info.Uid)

    local buffConfig = self._Control:GetBuffConfig(self._BuffId)
    if buffConfig.CanStack then
        self:ShowStackCount(info.StackCount)
        self.UiTxtTimes.text = info.RemainCount
    end
end

---如果Buff已消耗，则置灰显示
function XUiGridTheatre6Buff:CheckShowBuffDisable()
    local isDestory = self._Control:IsBuffDestory(self._BuffUid)
    self.GridBuff:SetButtonState(isDestory and XUiButtonState.Disable or XUiButtonState.Normal)
end

---设置当前选中的Buff
function XUiGridTheatre6Buff:SetChooseBuff(id)
    self.UiImgUse.gameObject:SetActiveEx(self._BuffId == id)
end

---是否允许点击
function XUiGridTheatre6Buff:IsCanClick(bo)
    self._IsGridClick = bo
end

---自定义点击事件
function XUiGridTheatre6Buff:SetCustomClickCb(cb)
    self._IsGridClick = true
    self._CustomClickCb = cb
end

---显示剩余生效次数
function XUiGridTheatre6Buff:ShowRemainingTimes()
    local isVisible = self:IsShowRemainingTimes()
    self.ImgTimesBg.gameObject:SetActiveEx(isVisible)
end

function XUiGridTheatre6Buff:IsShowRemainingTimes()
    local buffConfig = self._Control:GetBuffConfig(self._BuffId)
    if XTool.IsTableEmpty(buffConfig.DurationValues) then
        return false --没有配置持续时间
    end
    if self._BuffUid and self._Control:IsBuffDestory(self._BuffUid) then
        return false --Buff已销毁
    end
    return true
end

function XUiGridTheatre6Buff:ShowMore(count)
    self.ImgMask.gameObject:SetActiveEx(true)
    self.UiTxtNum.text = string.format("+%s", count)
end

---显示堆叠数量
function XUiGridTheatre6Buff:ShowStackCount(count)
    if self.ImgCountBg then
        self.ImgCountBg.gameObject:SetActiveEx(XTool.IsNumberValid(count))
    end
    if self.UiTxtCount then
        self.UiTxtCount.text = count
    end
end

function XUiGridTheatre6Buff:SetRedPoint(isRed)
    self.GridBuff:ShowReddot(isRed)
end

function XUiGridTheatre6Buff:InsertTab(tabs)
    table.insert(tabs, self.GridBuff)
end

function XUiGridTheatre6Buff:IsUnlock()
    return self._IsUnlock
end

function XUiGridTheatre6Buff:OnGridBuffClick()
    if not self._IsGridClick then
        return
    end
    if self._CustomClickCb then
        self._CustomClickCb(self._BuffId)
        return
    end
    XLuaUiManager.Open("UiTheatre6PopupBuffDetail", self._FileSaveBuffs)
end

---设置存档Buff数据
function XUiGridTheatre6Buff:SetFileSaveBuffs(buffs)
    self._FileSaveBuffs = buffs
end

return XUiGridTheatre6Buff
