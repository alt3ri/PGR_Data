---@class XUiDlcMultiPlayerSkillDescGrid : XUiNode
---@field private _Control XDlcMultiMouseHunterControl
---@field BtnBuffIcon XUiComponent.XUiButton
local XUiDlcMultiPlayerSkillDescGrid = XClass(XUiNode, "XUiDlcMultiPlayerSkillDescGrid")

function XUiDlcMultiPlayerSkillDescGrid:OnStart(callback)
    self._Callback = callback
    -- self.BtnBuffIcon:AddEventListener(handler(self, self.OnBtnBuffIconClick))
    ---@type UiObject[]
    self.PanelUsingList = { self.PanelUsingNormal, self.PanelUsingPress, self.PanelUsingSelect }
end

function XUiDlcMultiPlayerSkillDescGrid:OnDisable()
    self._SkillConfig = nil
end

function XUiDlcMultiPlayerSkillDescGrid:GetSkillId()
    return self._SkillId
end

function XUiDlcMultiPlayerSkillDescGrid:GetSkillConfig()
    return self._SkillConfig
end

---@param skillId number 技能Id
function XUiDlcMultiPlayerSkillDescGrid:Refresh(skillId)
    self._SkillId = skillId
    self._SkillConfig = self._Control:GetDlcMultiplayerSkillConfigById(skillId)

    self:RefreshBtnBuff()
end

function XUiDlcMultiPlayerSkillDescGrid:RefreshBtnBuff()
    -- 图标和名称
    self.BtnBuffIcon:SetRawImage(self._SkillConfig.Icon)
    self.BtnBuffIcon:SetNameByGroup(0, self._SkillConfig.Name)
    self.BtnBuffIcon:SetNameByGroup(1, XUiHelper.GetText("NotUnlock"))

    -- 解锁状态和红点
    local isUnlock = self._Control:CheckSkillUnlock(self._SkillId)
    self.BtnBuffIcon:SetDisable(not isUnlock)
    self.BtnBuffIcon:ShowReddot(self._Control:CheckNewSkillRedPoint(self._SkillId))

    self.TxtName.text = isUnlock and self._SkillConfig.Name or XUiHelper.GetText("NotUnlock")
end


-- 设置技能使用状态和显示序号
-- @param isUsing 是否正在使用
-- @param skillIndex 技能在选择列表中的序号
function XUiDlcMultiPlayerSkillDescGrid:SetUsing(isUsing, skillIndex)
    for _, panel in ipairs(self.PanelUsingList) do
        panel:GetObject("ImgYuan").gameObject:SetActiveEx(isUsing)
        panel:GetObject("ImgNum").gameObject:SetActiveEx(isUsing)
        if isUsing and skillIndex then
            panel:GetObject("TxtNum").text = tostring(skillIndex)
        end
    end
end

function XUiDlcMultiPlayerSkillDescGrid:SetChangeState(isChange)
    for _, panel in ipairs(self.PanelUsingList) do
        panel:GetObject("ImgChange").gameObject:SetActiveEx(isChange)
    end
end

function XUiDlcMultiPlayerSkillDescGrid:SetMask(isMask)
    if self.ImgMask then
        self.ImgMask.gameObject:SetActiveEx(isMask)
    end
    self.IsMask = isMask
    -- self.BtnBuffIcon.enabled =not isMask
end

function XUiDlcMultiPlayerSkillDescGrid:OnBtnBuffIconClick()
    if self.IsMask then
        XUiManager.TipMsg(XUiHelper.GetText("DlcMultiPlayerSkillTips2"))
        return
    end
    if self._Callback then
        self._Callback(self)
    end
end

return XUiDlcMultiPlayerSkillDescGrid
