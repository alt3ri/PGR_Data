local XUiGridBattleCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiGridBattleCard")
local XUiGridBattleCardSlot = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiGridBattleCardSlot")
local XUiNodeList = require("XUi/XUiCommon/XUiNodeList")

--- 战斗卡牌列表容器
--- 开局建列表（卡牌集固定，MVP 无增删卡）：FillCardEntityIds 一次建 grid；
--- 每帧 CardCdChanged 事件只轮询刷每张卡 CD，不重建列表。
---@class XUiPunishaarFightMainPanelBattleCardList : XUiNode
---@field _Control XPunishaarControl
---@field PanelBagList UnityEngine.RectTransform
---@field GridCard UnityEngine.RectTransform
---@field PanelBagSlotList UnityEngine.RectTransform
---@field GridSlot UnityEngine.RectTransform
---@field BtnBag XUiComponent.XUiButton 背包入口按钮（战斗中只读显容量，Disable 态无点击响应）#背包容量显示
local XUiPunishaarFightMainPanelBattleCardList = XClass(XUiNode, "XUiPunishaarFightMainPanelBattleCardList")

function XUiPunishaarFightMainPanelBattleCardList:OnStart(...)
    -- 卡牌/槽位列表容器：模板恒 inactive 仅作克隆源（根治 XUiEffectLayer 特效层级二次叠层），
    -- 内部持 XUiNode 实例替代原 _CardGridDict/_CardSlotGridDict + _CardSlotList 手工缓存。
    ---@type XUiNodeList
    self._CardList = XUiNodeList.New(self.GridCard, self.PanelBagList.transform, XUiGridBattleCard, self)
    ---@type XUiNodeList
    self._SlotList = XUiNodeList.New(self.GridSlot, self.PanelBagSlotList.transform, XUiGridBattleCardSlot, self)
end

function XUiPunishaarFightMainPanelBattleCardList:OnEnable()
    -- 战斗中 BtnBag 只读显容量（Disable 无点击）；容量战斗内不变（无买卖/拖拽），OnEnable 刷一次 #背包容量显示
    self:_RefreshBtnBagCapacity()
end

function XUiPunishaarFightMainPanelBattleCardList:OnDisable()
end

--- 刷 BtnBag 容量显示（战斗中只读，Disable 态无点击响应）。#背包容量显示
--- 容量文本同 ComBottomBagBase._RefreshBtnBagState 范式（GetBagGridLimit/FillBagAreaCards/GetBagCapacityText）。
function XUiPunishaarFightMainPanelBattleCardList:_RefreshBtnBagCapacity()
    if not self.BtnBag then
        return
    end
    local total = self._Control:GetBagGridLimit() or 0
    if not self._BagCapacityList then
        self._BagCapacityList = XTool.XListNew()
    end
    local used = self._Control:FillBagAreaCards(self._BagCapacityList)
    local fmt = self._Control:GetBagCapacityText()
    local capacityText
    if not string.IsNilOrEmpty(fmt) then
        capacityText = XUiHelper.FormatTextEx(fmt, tostring(used), tostring(total))
    else
        capacityText = tostring(used) .. "/" .. tostring(total)
    end
    self.BtnBag:SetNameByGroup(1, capacityText)
    self.BtnBag:SetDisable(true)  -- 战斗中只读 Disable 态，不响应点击
end

function XUiPunishaarFightMainPanelBattleCardList:OnDestroy()
end

--- 初始化建单位空格列表，构造索引，用于卡牌生成时布局。
function XUiPunishaarFightMainPanelBattleCardList:RefreshSlot()
    local maxCount = XMVCA.XPunishaar:GetClientNumberByKey("EquipCardMaxSlotCount")
    -- 战斗区槽位解锁上限（按 stage.FightAreaGridLimit 判定，未解锁的 slot 显锁定态）
    local unlockLimit = self._Control:GetFightAreaGridLimit() or maxCount

    self._SlotList:Refresh(maxCount, function(index, grid)
        grid:RefreshUnlockState(index <= unlockLimit)
    end)

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelBagSlotList.transform)
end

function XUiPunishaarFightMainPanelBattleCardList:GetGridSlotByIndex(index)
    return self._SlotList and self._SlotList:GetActive(index)
end

--- 开局建卡牌列表（按 uid 有序建 grid，每张 grid 绑定一个 uid）。
function XUiPunishaarFightMainPanelBattleCardList:Refresh()
    local reader = self._Control.GameControl.FightControl.STEReader

    local uidList = self:_GetNewOrResetUidList()
    local count = reader:FillCardEntityIds(uidList)

    self._CardList:Refresh(count, function(index, grid)
        grid:Refresh(uidList[index], self.GridSlot)

        local posIndex = self._Control.GameControl.FightControl.STEReader:GetCardPosIndex(uidList[index])
        local slot = self:GetGridSlotByIndex(posIndex)
        if slot then
            grid:RefreshPosition(slot)
        end
    end)
end

--- 仅刷球数显示（消球/产球变化，遍历已有 grid 转发 RefreshBallCount，不全量重建）。
function XUiPunishaarFightMainPanelBattleCardList:RefreshBallCount()
    if not self._CardList then
        return
    end
    -- ForEachActive 只遍历在用项（已 Close 的不在其中），无需再判 IsNodeShow
    self._CardList:ForEachActive(function(_, grid)
        grid:RefreshBallCount()
    end)
end

--- 帧刷所有卡 CD（CardCdChanged 事件触发；只刷 CD 进度不重建）。
function XUiPunishaarFightMainPanelBattleCardList:RefreshAllCardCd()
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        grid:RefreshCd()
    end)
end

function XUiPunishaarFightMainPanelBattleCardList:_GetNewOrResetUidList()
    if self._UidList == nil then
        self._UidList = {}
    else
        for i = #self._UidList, 1, -1 do
            self._UidList[i] = nil
        end
    end
    return self._UidList
end

return XUiPunishaarFightMainPanelBattleCardList
