--- 肉鸽6单次战斗结算伤害数据格子
---@class XUiGridTheatre6RoundData : XUiNode
---@field _Control XTheatre6Control
local XUiGridTheatre6RoundData = XClass(XUiNode, "XUiGridTheatre6RoundData")
local XUiGridTheatre6Skill = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Skill")
local XUiGridTheatre6Buff = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Buff")

function XUiGridTheatre6RoundData:OnStart()
    ---@type XUiGridTheatre6Skill
    self._GridSkill = XUiGridTheatre6Skill.New(self.UiTheatre6GridSkill, self)
    ---@type XUiGridTheatre6Buff
    self._GridBuff = XUiGridTheatre6Buff.New(self.UiTheatre6GridBuff, self)
    self._GridSkill:SetClickCb(handler(self, self.OpenSkillDetail))
    self._GridBuff:SetCustomClickCb(handler(self, self.OpenBuffDetail))
end

function XUiGridTheatre6RoundData:Update(data)
    self._Data = data
    if data.IsBuff then
        local buffId = self._Control:GetBuffIdByTag(data.SkillId)
        self._GridSkill:Close()
        self._GridBuff:Open()
        self._GridBuff:Update(buffId)
    else
        self._GridSkill:Open()
        self._GridSkill:Update(data.SkillId)
        self._GridBuff:Close()
    end

    if data.Times == 0 then
        self.TxtTimes.text = ""
    else
        self.TxtTimes.text = "X" .. data.Times
    end

    self:RefreshHpHurt(data.HpDamage, data.Times)
    self:RefreshSpHurt(data.SpDamage, data.Times)
end

function XUiGridTheatre6RoundData:RefreshHpHurt(damage, times)
    if times == 0 then
        self.TxtHpHurtNum.text = "---"
        self.ImgHpHurtBar.fillAmount = 0
    else
        self.TxtHpHurtNum.text = damage
        self.ImgHpHurtBar.fillAmount = XTool.IsNumberValid(self._Data.TotalDamage) and math.min(damage / self._Data.TotalDamage, 1) or 0
    end
end

function XUiGridTheatre6RoundData:RefreshSpHurt(damage, times)
    if times == 0 then
        self.TxtSpHurtNum.text = "---"
        self.ImgSpHurtBar.fillAmount = 0
    else
        self.TxtSpHurtNum.text = damage
        self.ImgSpHurtBar.fillAmount = XTool.IsNumberValid(self._Data.TotalEnergyCast) and math.min(damage / self._Data.TotalEnergyCast, 1) or 0
    end
end

function XUiGridTheatre6RoundData:OpenSkillDetail()
    local parent = self:GetParentUi()
    if parent and parent.OpenSkillDetailBubble then
        parent:OpenSkillDetailBubble(self._Data.SkillId, self.Transform)
    end
end

function XUiGridTheatre6RoundData:OpenBuffDetail()
    local buffId = self._Control:GetBuffIdByTag(self._Data.SkillId)
    local parent = self:GetParentUi()
    if parent and parent.OpenBuffDetailBubble then
        parent:OpenBuffDetailBubble(buffId, self.Transform)
    end
end

---获取主界面
---@return XUiTheatre6RoundSettlement
function XUiGridTheatre6RoundData:GetParentUi()
    local parent = self.Parent
    while parent do
        if parent.OpenSkillDetailBubble then
            return parent
        end
        parent = parent.Parent
    end
    return nil
end

return XUiGridTheatre6RoundData