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

-- 数值类型
local ValueType = {
    Damage = 1, -- 伤害
    CureOrProtector = 2, -- 治疗或护盾
}

-- 来源类型
local SourceType = {
    Skill = 0,
    Other = 1,
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
        self.Parent:UpdateRelics(self.ResultData.ResultData.WorldData.AutoChessGameplayData.SelfData, true)
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

            ---@type XTableTheatre5ItemRune
            local gemCfg = self._Control:GetTheatre5ItemRuneCfgById(id)

            if gemCfg and gemCfg.Type == XMVCA.XTheatre5.EnumConst.GemType.Passive then
                grid:SetPassiveShow()
            else
                local timesVal = 0

                if runesData:ContainsKey(id) then
                    timesVal = runesData[id]
                end

                grid:SetTriggerTimes(timesVal)
            end

            self._GridGemList[itemData.Index] = grid
            grid.Transform:SetAsLastSibling()
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

    self:_CollectSkillAndOtherOutputData()    

    -- 如果至少有一个指标有有效值，则需要列出来
    if XTool.IsNumberValidEx(self.MaxDamageRecord) or XTool.IsNumberValidEx(self.MaxCureOrProtectorRecord) then
        if not XTool.IsTableEmpty(self.RecordDataList) then
            XUiHelper.RefreshCustomizedList(self.ListData.transform, self.GridData, #self.RecordDataList, function(index, go)
                local grid = self._SkillItemList[go]

                if not grid then
                    grid = XUiGridTheatre5SettleSkillSlot.New(go, self)

                    self._SkillItemList[go] = grid
                end

                grid:Open()
                --- 需要在打开后再初始化，接口内已做重复初始化跳过判断
                grid:InitBindItem(XUiGridTheatre5SettleSkill)
                
                local damageRecord = 0
                local cureOrProtectorRecord = 0
                
                local recordData = self.RecordDataList[index]

                if recordData.Type == SourceType.Skill then
                    local skillId = recordData.Id
                    if self.SkillDamageRecordDict and self.SkillDamageRecordDict:ContainsKey(skillId) then
                        damageRecord = self.SkillDamageRecordDict[skillId]
                    end

                    if not XTool.IsTableEmpty(self.SkillCureOrProtectorRecordTable) then
                        cureOrProtectorRecord = self.SkillCureOrProtectorRecordTable[skillId] or 0
                    end

                    grid:SetItemShowById(skillId, skillId == self.NormalATKSkillId)
                elseif recordData.Type == SourceType.Other then
                    damageRecord = self.OtherDamageRecord
                    cureOrProtectorRecord = self.OtherCureOrProtectorRecord
                    
                    grid:SetOtherSourceShow()    
                end
                
                grid:ShowDamage(damageRecord, self.MaxDamageRecord)
                grid:ShowHeal(cureOrProtectorRecord, self.MaxCureOrProtectorRecord)
            end)
        end
    end
end

-- 分类和收集数据
function XUiPanelTheatre5SettleSummary:_CollectSkillAndOtherOutputData()
    -- 各种数值输出，不仅仅是技能
    local dataList = {}
    
    local skillIdList = nil
    local recordData = nil

    self.SkillDamageRecordDict = nil
    self.SkillCureOrProtectorRecordTable = nil

    self.OtherDamageRecord = 0
    self.OtherCureOrProtectorRecord = 0
    
    if self.ViewSide == ViewSideEnum.Self then
        skillIdList = self._Control:GetCurSelfSkillIdListWithNormalATK()
        self.NormalATKSkillId = self._Control:GetCurSelfNormalAttackSkillId()

        recordData = self.SummaryData.AutoChessRecord.SelfRecord
    else
        skillIdList = self._Control:GetCurEnemySkillIdListWithNormalATK()
        self.NormalATKSkillId = self._Control:GetCurEnemyNormalAttackSkillId()
        recordData = self.SummaryData.AutoChessRecord.EnemyRecord
    end
    
    -- 设置技能数据
    if not XTool.IsTableEmpty(skillIdList) then
        for i, v in pairs(skillIdList) do
            local data = {
                Type = SourceType.Skill,
                Id = v,
            }
            
            table.insert(dataList, data)
        end
    end
    
    -- 收集各来源及各类型的统计数值
    if recordData then
        -- 默认技能类型产生的数据是0号位, 其他位置归类为“其他来源”
        
        -- 先收集单一类型：伤害值
        if recordData.DamageRecord then
            local damageRecord = recordData.DamageRecord

            if damageRecord:ContainsKey(SourceType.Skill) then
                self.SkillDamageRecordDict = damageRecord[SourceType.Skill]
            end
            
            -- 收集除了技能以外的来源
            self.OtherDamageRecord = self:_CollectOtherSourceDamageRecord(damageRecord)
        end

        -- 再收集复合类型：治疗和护盾
        local cureAndProtectorRecordTable = self:_MergeCureAndProtectorRecordDict(recordData.CureRecord, recordData.ProtectorRecord)

        if not XTool.IsTableEmpty(cureAndProtectorRecordTable) then
            self.SkillCureOrProtectorRecordTable = cureAndProtectorRecordTable[SourceType.Skill]
            
            -- 收集除了技能以外的来源
            self.OtherCureOrProtectorRecord = self:_CollectOtherSourceCureAndProtectorRecord(cureAndProtectorRecordTable)
        end
        
    end
    
    -- 如果其他来源的数据不都为0，则额外增加一个“其他来源”的数据
    if XTool.IsNumberValidEx(self.OtherDamageRecord) or XTool.IsNumberValidEx(self.OtherCureOrProtectorRecord) then
        local data = {
            Type = SourceType.Other,
            Id = 0,
        }

        table.insert(dataList, data)
    end
    
    -- 查找伤害最大值、治疗/护盾最大值，作为进度条范围
    local maxDamage = self.OtherDamageRecord
    local maxCurOrProtector = self.OtherCureOrProtectorRecord

    if self.SkillDamageRecordDict and self.SkillDamageRecordDict.GetEnumerator then
        local iter = self.SkillDamageRecordDict:GetEnumerator()
        while iter:MoveNext() do
            if iter.Current.Value > maxDamage then
                maxDamage = iter.Current.Value
            end
        end
    end

    if not XTool.IsTableEmpty(self.SkillCureOrProtectorRecordTable) then
        for i, v in pairs(self.SkillCureOrProtectorRecordTable) do
            if v > maxCurOrProtector then
                maxCurOrProtector = v
            end
        end
    end
    
    self.MaxDamageRecord = maxDamage
    self.MaxCureOrProtectorRecord = maxCurOrProtector
    self.RecordDataList = dataList
end

--- 收集除了技能以外其他来源造成的伤害之和
function XUiPanelTheatre5SettleSummary:_CollectOtherSourceDamageRecord(damageRecord)
    local sum = 0
    
    local iter = damageRecord:GetEnumerator()
    while iter:MoveNext() do
        if iter.Current.Key ~= SourceType.Skill then
            local secondDict = iter.Current.Value

            if secondDict and secondDict.GetEnumerator then
                local secondIter = secondDict:GetEnumerator()
                while secondIter:MoveNext() do
                    sum = sum + secondIter.Current.Value
                end
            end
        end
    end
    
    return sum
end

--- 收集除了技能以外其他来源产生的治疗/护盾数值之和
---@param cureAndProjectorRecord table
function XUiPanelTheatre5SettleSummary:_CollectOtherSourceCureAndProtectorRecord(cureAndProjectorRecord)
    local sum = 0

    if not XTool.IsTableEmpty(cureAndProjectorRecord) then
        for sourceType, dict in pairs(cureAndProjectorRecord) do
            if sourceType ~= SourceType.Skill then
                for i, v in pairs(dict) do
                    sum = sum + v
                end
            end
        end
    end
    
    return sum
end

-- 将治疗和护盾的数值，按照来源类型、具体来源进行合并
---@return table
function XUiPanelTheatre5SettleSummary:_MergeCureAndProtectorRecordDict(cureRecord, protectorRecord)
    -- 一级字典，按照来源类型划分
    local firstDict = {}

    -- 先将治疗统计转移到table中
    local iter = cureRecord:GetEnumerator()
    while iter:MoveNext() do
        local secondCureDict = iter.Current.Value
        
        local finalSecondDict = firstDict[iter.Current.Key] or {}

        if secondCureDict and secondCureDict.GetEnumerator then
            local secondIter = secondCureDict:GetEnumerator()
            while secondIter:MoveNext() do
                finalSecondDict[secondIter.Current.Key] = secondIter.Current.Value
            end
        end

        firstDict[iter.Current.Key] = finalSecondDict
    end
    
    -- 再将护盾部分累加过去
    iter = protectorRecord:GetEnumerator()
    while iter:MoveNext() do
        local secondCureDict = iter.Current.Value

        local finalSecondDict = firstDict[iter.Current.Key] or {}

        if secondCureDict and secondCureDict.GetEnumerator then
            local secondIter = secondCureDict:GetEnumerator()
            while secondIter:MoveNext() do
                local oldValue = finalSecondDict[secondIter.Current.Key] or 0
                finalSecondDict[secondIter.Current.Key] = secondIter.Current.Value + oldValue
            end
        end

        firstDict[iter.Current.Key] = finalSecondDict
    end
    
    return firstDict
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

            -- PVE模式没有敌人等级
            if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
                self.TxtLevelEnemy.transform.parent.gameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiPanelTheatre5SettleSummary
