local XUiGridTheatre5Container = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Container')
local XUiGridTheatre5SettleNormalAtk = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleNormalAtk')

--- 回合结算技能统计
---@class XUiGridTheatre5SettleSkillSlot: XUiGridTheatre5Container
local XUiGridTheatre5SettleSkillSlot = XClass(XUiGridTheatre5Container, 'XUiGridTheatre5SettleSkillSlot')

---@overload
function XUiGridTheatre5SettleSkillSlot:InitBindItem(cls)
    if self.GridSkill then
        -- 默认隐藏
        self.GridSkill.gameObject:SetActiveEx(false)
    end
    
    XUiGridTheatre5Container.InitBindItem(self, cls)

    if self.GridAttack then
        self.GridAttack.gameObject:SetActiveEx(false)
        self.GridNormalAtk = XUiGridTheatre5SettleNormalAtk.New(self.GridAttack, self)
        self.GridNormalAtk:Close()
    end

    if self.GridOther then
        self.GridOther.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5SettleSkillSlot:ShowDamage(damage, maxDamage)
    self.TxtHurtNum.text = damage
    self.ImgHurtBar.fillAmount = maxDamage ~= 0 and damage / maxDamage or 0
end

function XUiGridTheatre5SettleSkillSlot:ShowHeal(heal, maxHeal)
    self.TxtTreatNum.text = heal
    self.ImgTreatBar.fillAmount = maxHeal ~= 0 and heal / maxHeal or 0
end

function XUiGridTheatre5SettleSkillSlot:SetItemShowById(skillId, isNormalATK)
    if not XTool.IsNumberValid(skillId) then
        self:_ClearItemShow()
        return
    end

    ---@type XTableTheatre5Item
    local itemCfg = self._Control:GetTheatre5ItemCfgById(skillId)

    if itemCfg then
        self:_SetItemType(itemCfg.Type)

        if self.ImgSelect then
            self.ImgSelect.gameObject:SetActiveEx(false)
        end

        if not self.CurUiGrid then
            return
        end

        if self.GridSkillRoot then
            self.GridSkillRoot.gameObject:SetActiveEx(not isNormalATK)
        end

        if isNormalATK then
            self.CurUiGrid:Close()

            if self.GridNormalAtk then
                self.GridNormalAtk:Open()
                self.GridNormalAtk:RefreshShowById(skillId)
            end
        else
            if self.GridNormalAtk then
                self.GridNormalAtk:Close()
            end
            
            self.CurUiGrid:Open()
            self.CurUiGrid:SetIsNormalAttack(isNormalATK)
            self.CurUiGrid:RefreshShowById(skillId)
        end
    end
end

function XUiGridTheatre5SettleSkillSlot:SetOtherSourceShow()
    self:_ClearItemShow()

    if self.GridOther then
        self.GridOther.gameObject:SetActiveEx(true)
    end
end

return XUiGridTheatre5SettleSkillSlot