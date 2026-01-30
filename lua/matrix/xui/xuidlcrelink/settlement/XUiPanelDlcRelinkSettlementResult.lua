---@class XUiPanelDlcRelinkSettlementResult : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkSettlementNew
local XUiPanelDlcRelinkSettlementResult = XClass(XUiNode, "XUiPanelDlcRelinkSettlementResult")

local TipType = {
    EQUIPMENT = 1, -- 推荐角色去搞装备吸收提升装备等级
    TEAM = 2, -- 推荐玩家合理搭配队伍职业
    EQUIPMENT_MATCH = 3, -- 合理搭配装备可以有效提升角色实力
    SKILL_COMBO = 4         -- 合理利用极限技和必杀连携来逆转战局
}

function XUiPanelDlcRelinkSettlementResult:OnStart()
    self.PanelTips.gameObject:SetActiveEx(false)
    self.BtnLeft:AddEventListener(handler(self, self.OnBtnLeftClick))
    self.BtnRight:AddEventListener(handler(self, self.OnBtnRightClick))
    self.BtnNext:AddEventListener(handler(self, self.OnBtnNextClick))

    self.TipList = {}
    self.CurrentTipIndex = 1
end

---@ param resultData XDlcFightResultData
---@ param relinkSettleResult XDlcRelinkSettleResult
function XUiPanelDlcRelinkSettlementResult:Refresh(resultData, relinkSettleResult)
    self.ResultData = resultData
    self.RelinkSettleResult = relinkSettleResult
    -- 是否通关
    local isWin = resultData.IsPlayerWin
    if self.RImgFailBg then
        self.RImgFailBg.gameObject:SetActiveEx(not isWin)
    end
    if self.FailMask then
        self.FailMask.gameObject:SetActiveEx(not isWin)
    end
    if self.RImgWinBg then
        self.RImgWinBg.gameObject:SetActiveEx(isWin)
    end
    if self.WinMask then
        self.WinMask.gameObject:SetActiveEx(isWin)
    end
    -- 通关时间
    local timer = self:GetFinishTime()
    self.TxtTime.text = XUiHelper.GetTime(timer, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    -- 新纪录
    self.GridTag.gameObject:SetActiveEx(isWin and relinkSettleResult.IsNewRecord)
    -- 提示
    self.PanelTips.gameObject:SetActiveEx(not isWin)
    if not isWin then
        self:RefreshTips()
    end
    -- 背景图
    self.RImgBg:SetRawImage(self._Control:GetClientConfig("SettlementResultBg", isWin and 1 or 2))
    -- 背景特效
    -- 延后0.5s 加载特效
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.RImgBg.gameObject:LoadUiEffect(self._Control:GetClientConfig("SettlementResultEffect", isWin and 1 or 2))
    end, 500)
end

-- 获取通关时间
function XUiPanelDlcRelinkSettlementResult:GetFinishTime()
    -- 非强制退出状态,直接返回完成时间
    if self.ResultData.SettleState ~= XEnumConst.DlcWorld.SettleState.ForceExit then
        return self.ResultData.FinishTime or 0
    end

    -- 强制退出状态,查找当前玩家的结算时间
    ---@type table<number, XDlcFightResultPlayerData>
    local playerDataList = self.ResultData.PlayerData or {}
    for _, playerData in pairs(playerDataList) do
        if playerData.PlayerId == XPlayer.Id then
            return playerData.SettleTime or 0
        end
    end

    return 0
end

-- 刷新提示
function XUiPanelDlcRelinkSettlementResult:RefreshTips()
    -- 获取提示列表
    self.TipList = self:GenerateTipList()
    if XTool.IsTableEmpty(self.TipList) then
        self.PanelTips.gameObject:SetActiveEx(false)
        return
    end
    self.CurrentTipIndex = 1
    self:UpdateTipDisplay()
end

-- 生成提示列表
function XUiPanelDlcRelinkSettlementResult:GenerateTipList()
    local tipList = {}
    -- 检查队伍职业重复情况
    if self:CheckDuplicateProfession() then
        table.insert(tipList, TipType.TEAM)
    end
    -- 检查装备等级是否低于要求
    if self:CheckEquipmentLevel() then
        table.insert(tipList, TipType.EQUIPMENT)
    end
    table.insert(tipList, TipType.EQUIPMENT_MATCH)
    table.insert(tipList, TipType.SKILL_COMBO)
    return tipList
end

-- 检查队伍中是否存在多个相同职业
function XUiPanelDlcRelinkSettlementResult:CheckDuplicateProfession()
    local occupationTypeCount = {}
    local settleResults = self.RelinkSettleResult.SettleResults
    if XTool.IsTableEmpty(settleResults) then
        return false
    end

    for _, result in pairs(settleResults) do
        local occupationType = self._Control:GetCharacterOccupationType(result.CharacterId, result.StyleType)
        if occupationType > 0 then
            occupationTypeCount[occupationType] = (occupationTypeCount[occupationType] or 0) + 1
            if occupationTypeCount[occupationType] > 1 then
                return true
            end
        end
    end

    return false
end

-- 检查装备等级是否低于要求
function XUiPanelDlcRelinkSettlementResult:CheckEquipmentLevel()
    local levelId = self.ResultData.WorldData.LevelId
    local abilityLimit = self._Control:GetLevelAbilityLimit(levelId)
    if not XTool.IsNumberValid(abilityLimit) then
        return false
    end

    local settleResults = self.RelinkSettleResult.SettleResults
    if XTool.IsTableEmpty(settleResults) then
        return false
    end

    for _, result in pairs(settleResults) do
        if result.PlayerId == XPlayer.Id and result.EquLevel < abilityLimit then
            return true
        end
    end

    return false
end

-- 获取提示文本
function XUiPanelDlcRelinkSettlementResult:GetTipText(tipType)
    local tipTexts = self._Control:GetClientConfigParams("SettlementFailTips") or {}
    return tipTexts[tipType] or ""
end

-- 更新提示显示
function XUiPanelDlcRelinkSettlementResult:UpdateTipDisplay()
    -- 确保索引在有效范围内
    if self.CurrentTipIndex > #self.TipList then
        self.CurrentTipIndex = 1
    elseif self.CurrentTipIndex < 1 then
        self.CurrentTipIndex = #self.TipList
    end

    -- 更新提示文本
    local currentTipType = self.TipList[self.CurrentTipIndex]
    self.TxtTips.text = self:GetTipText(currentTipType)

    -- 更新页码显示
    self.TxtNum.text = string.format("%s/%s", self.CurrentTipIndex, #self.TipList)
end

function XUiPanelDlcRelinkSettlementResult:OnBtnLeftClick()
    self.CurrentTipIndex = self.CurrentTipIndex - 1
    self:UpdateTipDisplay()
end

function XUiPanelDlcRelinkSettlementResult:OnBtnRightClick()
    self.CurrentTipIndex = self.CurrentTipIndex + 1
    self:UpdateTipDisplay()
end

function XUiPanelDlcRelinkSettlementResult:OnBtnNextClick()
    if self.ResultData.SettleState == XEnumConst.DlcWorld.SettleState.ForceExit then
        -- 强制退出
        self._Control:CommonRunRelinkRoomUiHandle(nil, function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            XLuaUiManager.Remove(self.Parent.Name)
        end)
        return
    end
    self.Parent:RefreshPanelCharacter()
    self:Close()
end

return XUiPanelDlcRelinkSettlementResult
