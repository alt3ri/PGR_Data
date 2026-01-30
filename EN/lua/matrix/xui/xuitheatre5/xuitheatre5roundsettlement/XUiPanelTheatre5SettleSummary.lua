--- 回合结算统计数据显示
---@field Parent XUiTheatre5RoundSettlement
---@class XUiPanelTheatre5SettleSummary: XUiNode
---@field protected _Control XTheatre5Control
local XUiPanelTheatre5SettleSummary = XClass(XUiNode, 'XUiPanelTheatre5SettleSummary')
local XUiGridTheatre5SettleGemSlot = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleGemSlot')
local XUiGridTheatre5SettleSkillSlot = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleSkillSlot')
local XUiGridTheatre5SettleSkill = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleSkill')
local XUiGridTheatre5SettleGem = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleGem')

local ViewSideEnum = {
    Self = 1, -- 查看自己的统计数据
    Enemy = 2, -- 查看敌人的统计数据
}

function XUiPanelTheatre5SettleSummary:OnStart(resultData, summaryData)
    self.ResultData = resultData
    self.SummaryData = summaryData

    ---@type XPool
    self._GridGemPool = XPool.New(function()
        local go = CS.UnityEngine.GameObject.Instantiate(self.Container, self.ListGem.transform)
        local grid = XUiGridTheatre5SettleGemSlot.New(go, self)
        grid:Open()
        grid:InitBindItem(XUiGridTheatre5SettleGem)
        return grid
    end,
            function(grid)
                grid:Close()
            end, false)

    self.Container.gameObject:SetActiveEx(false)
    self.GridData.gameObject:SetActiveEx(false)

    self.ViewSide = ViewSideEnum.Self

    self.BtnChange:AddEventListener(handler(self, self.OnBtnChangeClickEvent))

    ---@type XDynamicTableNormal
    self.BtnBagMaskDetailShow:AddEventListener(handler(self, self.OnBtnMaskDetailShowClickEvent))

end

function XUiPanelTheatre5SettleSummary:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.OnItemDetailHideEvent, self)
end

function XUiPanelTheatre5SettleSummary:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.OnItemDetailHideEvent, self)
end

function XUiPanelTheatre5SettleSummary:RefreshAllShow()
    self.BtnChange:SetNameByGroup(0, self._Control:GetClientConfigRoundSettleSummaryChangeLabel(self.ViewSide == ViewSideEnum.Self))
    self:RefreshRunesShow()
    self:RefreshSkillShow()

    if self.ViewSide == ViewSideEnum.Self then
        self.Parent:UpdateRelics(self.ResultData.ResultData.WorldData.AutoChessGameplayData.SelfData)
    else
        self.Parent:UpdateRelics(self.ResultData.ResultData.WorldData.AutoChessGameplayData.EnemyData)
    end
    self:UpdateCharacterAndLevel()
end

---- 刷新宝珠列表
function XUiPanelTheatre5SettleSummary:RefreshRunesShow()
    if not XTool.IsTableEmpty(self._GridGemList) then
        ---@param v XUiGridTheatre5SettleGemSlot
        for i, v in pairs(self._GridGemList) do
            self._GridGemPool:ReturnItemToPool(v)
        end
    end

    if not self.SummaryData or not self.SummaryData.AutoChessRecord then
        self.TxtNone.gameObject:SetActiveEx(true)
        return
    end

    local runesData
    local runes

    if self.ViewSide == ViewSideEnum.Self then
        runesData = self.SummaryData.AutoChessRecord.SelfRecord and self.SummaryData.AutoChessRecord.SelfRecord.GemRecord or nil
        runes = self._Control:GetCurSelfGemIdList()
    else
        runesData = self.SummaryData.AutoChessRecord.EnemyRecord and self.SummaryData.AutoChessRecord.EnemyRecord.GemRecord or nil
        runes = self._Control:GetCurEnemyGemIdList()
    end

    if runesData and not XTool.IsTableEmpty(runes) then
        self.TxtNone.gameObject:SetActiveEx(false)

        self._GridGemList = {}

        for id, itemData in pairs(runes) do
            ---@type XUiGridTheatre5SettleGemSlot
            local grid = self._GridGemPool:GetItemFromPool()
            grid:Open()
            grid:SetItemData(itemData)

            grid.PanelTrigger.gameObject:SetActiveEx(true)
            if runesData:ContainsKey(id) then
                grid:SetTriggerTimes(runesData[id])
            else
                ---@type XTableTheatre5ItemRune
                local gemCfg = self._Control:GetTheatre5ItemRuneCfgById(id)

                if gemCfg and gemCfg.Type == XMVCA.XTheatre5.EnumConst.GemType.Passive then
                    grid:SetPassiveShow()
                else
                    grid:SetTriggerTimes(0)
                end
            end

            self._GridGemList[itemData.Index] = grid
        end

    else
        self.TxtNone.gameObject:SetActiveEx(true)
    end
end

--- 刷新技能输出统计
function XUiPanelTheatre5SettleSummary:RefreshSkillShow()
    if not XTool.IsTableEmpty(self._SkillItemList) then
        for i, v in pairs(self._SkillItemList) do
            v:Close()
        end
    end

    if not self.SummaryData or not self.SummaryData.AutoChessRecord then
        self.TxtNone.gameObject:SetActiveEx(true)
        return
    end

    if self._SkillItemList == nil then
        self._SkillItemList = {}
    end

    self.SkillDamageRecord = nil
    self.SkillCureRecord = nil
    self.SkillMaxDamage = 0
    self.SkillMaxCure = 0

    if self.ViewSide == ViewSideEnum.Self then
        self.SkillIdList = self._Control:GetCurSelfSkillIdListWithNormalATK()
        self.NormalATKSkillId = self._Control:GetCurSelfNormalAttackSkillId()
        self.SkillDamageRecord = self.SummaryData.AutoChessRecord.SelfRecord and self.SummaryData.AutoChessRecord.SelfRecord.SkillDamageRecord or nil
        self.SkillCureRecord = self.SummaryData.AutoChessRecord.SelfRecord and self.SummaryData.AutoChessRecord.SelfRecord.SkillCureRecord or nil
    else
        self.SkillIdList = self._Control:GetCurEnemySkillIdListWithNormalATK()
        self.NormalATKSkillId = self._Control:GetCurEnemyNormalAttackSkillId()
        self.SkillDamageRecord = self.SummaryData.AutoChessRecord.EnemyRecord and self.SummaryData.AutoChessRecord.EnemyRecord.SkillDamageRecord or nil
        self.SkillCureRecord = self.SummaryData.AutoChessRecord.EnemyRecord and self.SummaryData.AutoChessRecord.EnemyRecord.SkillCureRecord or nil
    end

    if self.SkillDamageRecord and self.SkillCureRecord then
        -- 查找最大伤害值和恢复量
        local iter = self.SkillDamageRecord:GetEnumerator()
        while iter:MoveNext() do
            local v = iter.Current.Value
            -- 处理v
            if v > self.SkillMaxDamage then
                self.SkillMaxDamage = v
            end
        end

        iter = self.SkillCureRecord:GetEnumerator()
        while iter:MoveNext() do
            local v = iter.Current.Value
            -- 处理v
            if v > self.SkillMaxCure then
                self.SkillMaxCure = v
            end
        end

        -- 刷新UI
        if not XTool.IsTableEmpty(self.SkillIdList) then
            XUiHelper.RefreshCustomizedList(self.ListData.transform, self.GridData, #self.SkillIdList, function(index, go)
                local grid = self._SkillItemList[go]

                if not grid then
                    grid = XUiGridTheatre5SettleSkillSlot.New(go, self)

                    self._SkillItemList[go] = grid
                end

                grid:Open()
                --- 需要在打开后再初始化，接口内已做重复初始化跳过判断
                grid:InitBindItem(XUiGridTheatre5SettleSkill)

                local skillId = self.SkillIdList[index]
                local damageRecord = self.SkillDamageRecord:ContainsKey(skillId) and self.SkillDamageRecord[skillId] or 0
                local cureRecord = self.SkillCureRecord:ContainsKey(skillId) and self.SkillCureRecord[skillId] or 0
                grid:ShowDamage(damageRecord, self.SkillMaxDamage)
                grid:ShowHeal(cureRecord, self.SkillMaxCure)
                grid:SetItemShowById(skillId, skillId == self.NormalATKSkillId)
            end)
        end
    end
end

function XUiPanelTheatre5SettleSummary:OnBtnChangeClickEvent()
    self.ViewSide = self.ViewSide == ViewSideEnum.Self and ViewSideEnum.Enemy or ViewSideEnum.Self

    self:RefreshAllShow()

    -- 取消可能的详情展开
    self._Control:TryCloseItemDetail()

    self.Parent:PlayAnimationWithMask('Qiehuan')
end

function XUiPanelTheatre5SettleSummary:OnItemDetailOpenEvent(itemData, containerType, uiPos)
    if not XLuaUiManager.IsUiShow('UiTheatre5BubbleItemDetail') then
        XLuaUiManager.Open('UiTheatre5BubbleItemDetail', itemData, containerType, uiPos)
    else
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_ITEM_DETAIL, itemData, containerType, uiPos)
    end

    if self.BtnBagMaskDetailShow then
        self.BtnBagMaskDetailShow.gameObject:SetActiveEx(true)
    end
end

function XUiPanelTheatre5SettleSummary:OnItemDetailHideEvent()
    if self.BtnBagMaskDetailShow then
        self.BtnBagMaskDetailShow.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre5SettleSummary:OnBtnMaskDetailShowClickEvent()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

function XUiPanelTheatre5SettleSummary:UpdateCharacterAndLevel()
    if self.ViewSide == ViewSideEnum.Self then
        if self.RoleSelf then
            self.PanelMyRole.gameObject:SetActiveEx(true)
            self.PanelEnemyRole.gameObject:SetActiveEx(false)
            self.TxtLevelSelf.text = self._Control.CharacterControl:GetCharacterLevel()
            local icon = self._Control:GetCharacterIcon()
            self.RoleSelf:SetRawImage(icon)
        end
    else
        if self.RoleEnemy then
            self.PanelMyRole.gameObject:SetActiveEx(false)
            self.PanelEnemyRole.gameObject:SetActiveEx(true)
            if self.ResultData.ResultData.WorldData.AutoChessGameplayData.EnemyData then
                local level = self.ResultData.ResultData.WorldData.AutoChessGameplayData.EnemyData.AutoChessData.CharacterLevel
                local characterId = self.ResultData.ResultData.WorldData.AutoChessGameplayData.EnemyData.AutoChessData.CharacterId
                local characterIcon = self._Control:GetCharacterIcon(characterId)
                self.TxtLevelEnemy.text = level
                self.RoleEnemy:SetRawImage(characterIcon)
            end
        end
    end
end

return XUiPanelTheatre5SettleSummary