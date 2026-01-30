---@class XUiGridDlcRelinkCharacterSkill : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkCharacterSkill = XClass(XUiNode, "XUiGridDlcRelinkCharacterSkill")

function XUiGridDlcRelinkCharacterSkill:OnStart(callBack)
    self.CallBack = callBack
    self.BtnSkill:AddEventListener(handler(self, self.OnBtnSkillClick))
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
end

function XUiGridDlcRelinkCharacterSkill:GetSkillId()
    return self.SkillId
end

function XUiGridDlcRelinkCharacterSkill:GetIsRemodel()
    return self.IsRemodel
end

function XUiGridDlcRelinkCharacterSkill:Refresh(skillId, characterId, isRemodel, isNotSelf)
    self.SkillId = skillId
    self.IsRemodel = isRemodel

    -- 是否改造
    self.BgReform.gameObject:SetActiveEx(isRemodel)
    -- 技能图标
    local skillIcon = self._Control:GetSkillDescIcon(skillId)
    if not string.IsNilOrEmpty(skillIcon) then
        self.IconSkill:SetRawImage(skillIcon)
    end
    -- 技能名称
    self.TxtName.text = self._Control:GetSkillDescTypeDesc(skillId)
    -- 技能伤害进度条
    local curDamage = self._Control:GetSkillCurrentDamage(skillId, characterId, isNotSelf)
    local maxDamage = self._Control:GetSkillMaxDamageLimit(skillId, characterId, isNotSelf)
    self.ImgExpSlider.fillAmount = (maxDamage > 0) and (curDamage / maxDamage) or 0
    local colorIndex = (maxDamage > 0 and curDamage >= maxDamage) and 2 or 1
    local color = self._Control:GetClientConfig("SkillDamageSliderColor", colorIndex)
    self.ImgExpSlider.color = XUiHelper.Hexcolor2Color(color)
end

-- 选中
function XUiGridDlcRelinkCharacterSkill:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

-- 锁定
function XUiGridDlcRelinkCharacterSkill:SetLock(isLock)
    self.ImgLock.gameObject:SetActiveEx(isLock)
end

-- 红点
function XUiGridDlcRelinkCharacterSkill:SetRedDot(isRed)
    self.Red.gameObject:SetActiveEx(isRed)
end

-- 设置是否响应穿透事件
function XUiGridDlcRelinkCharacterSkill:SetRespondPassEvent(isRespond)
    self.BtnSkill.IsRespondPassEvent = isRespond
end

function XUiGridDlcRelinkCharacterSkill:OnBtnSkillClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridDlcRelinkCharacterSkill
