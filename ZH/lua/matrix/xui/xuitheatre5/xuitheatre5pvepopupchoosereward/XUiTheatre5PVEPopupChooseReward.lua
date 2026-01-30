---道具宝箱三选一 / 遗物三选一
---@class XUiTheatre5PVEPopupChooseReward: XLuaUi
---@field private _Control XTheatre5Control
---@field self._ItemBoxSelectData CSTheatre5ItemBoxSelectData
local XUiTheatre5PVEPopupChooseReward = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEPopupChooseReward')
local XUiTheatre5PVEChooseRewardItem = require("XUi/XUiTheatre5/XUiTheatre5PVEPopupChooseReward/XUiTheatre5PVEChooseRewardItem")

function XUiTheatre5PVEPopupChooseReward:OnAwake()
    self:AddUIListener()
    self:AddEventListener()
    self._ItemGridList = {}
    self._ItemBoxSelectData = nil
    self._ChapterBattlePromoteCb = nil
    self._ChooseRewardType = nil
end

function XUiTheatre5PVEPopupChooseReward:OnStart(chooseRewardType, chapterBattlePromoteCb)
    self._ChooseRewardType = chooseRewardType
    self._ChapterBattlePromoteCb = chapterBattlePromoteCb
    self:ChapterBattlePromote()
end

function XUiTheatre5PVEPopupChooseReward:AddUIListener()
    self:RegisterClickEvent(self.BtnCharacterDetail, self.OnClickCharacterDetail, true, true)
    self:RegisterClickEvent(self.BtnRefresh, self.OnClickRefresh, true, true)
end

function XUiTheatre5PVEPopupChooseReward:AddEventListener()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_ITEM_BOX_SELECT, self.OnItemBoxSelect, self)
end

function XUiTheatre5PVEPopupChooseReward:OnItemBoxSelect(theatre5Item)
    if self._ChooseRewardType == XMVCA.XTheatre5.EnumConst.ChooseRewardType.Item then
        XMVCA.XTheatre5.PVEAgency:RequestItemBoxSelect(self._ItemBoxSelectData.BoxInstanceId, theatre5Item.InstanceId, function(success)
            if success then
                local rewardList = { { Id = theatre5Item.ItemId, Type = theatre5Item.ItemType, Count = 1 } }
                XLuaUiManager.Open("UiTheatre5PopupGetReward", nil, rewardList, function()
                    self:ChapterBattlePromote()
                end)
            end
        end)
        return
    end
    if self._ChooseRewardType == XMVCA.XTheatre5.EnumConst.ChooseRewardType.Relic then
        XMVCA.XTheatre5:XTheatre5RelicChooseRequest(theatre5Item.InstanceId, function()
            if XMVCA.XTheatre5:HasRelicToSelect() then
                self:ChapterBattlePromote()
                return
            end
            self:Close()
            -- 怎么推进呢?
            --XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CHAPTER_BATTLE_PROMOTE)
        end)
    end
end

function XUiTheatre5PVEPopupChooseReward:ChapterBattlePromote()
    if self._ChooseRewardType == XMVCA.XTheatre5.EnumConst.ChooseRewardType.Item then
        self.BtnRefresh.gameObject:SetActiveEx(false)
        local itemBoxSelectDatas = self._Control.PVEControl:GetItemBoxSelectData()
        if not XTool.IsTableEmpty(itemBoxSelectDatas) then
            self._ItemBoxSelectData = itemBoxSelectDatas[1]
            self:RefreshPanel(self._ItemBoxSelectData.ItemList)
            return
        end
        if self._ChapterBattlePromoteCb then
            local canPveBattle = self._Control.PVEControl:CanPveBattle()
            local nextNodeType = canPveBattle and XMVCA.XTheatre5.EnumConst.PVENodeType.Battle or XMVCA.XTheatre5.EnumConst.PVENodeType.Event
            local chapterBattleData = self._Control.PVEControl:GetCurChapterBattleData()
            local param = canPveBattle and chapterBattleData or self._Control.PVEControl:GetCurEventId()
            self._ChapterBattlePromoteCb(nextNodeType, param)
        end
        return
    end
    if self._ChooseRewardType == XMVCA.XTheatre5.EnumConst.ChooseRewardType.Relic then
        local refreshCount = self._Control:GetRemainRelicRefreshCount()
        if refreshCount > 0 then
            self.BtnRefresh.gameObject:SetActiveEx(true)
            self.BtnRefresh:SetButtonState(CS.UiButtonState.Normal)
            self.BtnRefresh:SetNameByGroup(1, refreshCount)
        else
            self.BtnRefresh.gameObject:SetActiveEx(true)
            self.BtnRefresh:SetButtonState(CS.UiButtonState.Disable)
            self.BtnRefresh:SetNameByGroup(1, refreshCount)
        end
        local relics = self._Control:GetRandomRelics()
        if not XTool.IsTableEmpty(relics) then
            self._ItemBoxSelectData = relics
            self:RefreshPanel(self._ItemBoxSelectData)
            return
        end
        self:Close()
    end
end

function XUiTheatre5PVEPopupChooseReward:RefreshPanel(itemList)
    XTool.UpdateDynamicItem(self._ItemGridList, itemList, self.GridReward, XUiTheatre5PVEChooseRewardItem, self)
end

function XUiTheatre5PVEPopupChooseReward:OnClickCharacterDetail()
    XLuaUiManager.Open("UiTheatre5PVECheckCharacter")
end

function XUiTheatre5PVEPopupChooseReward:OnDestroy()
    self._itemGridList = nil
    self._ItemBoxSelectData = nil
    self._ChapterBattlePromoteCb = nil
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_ITEM_BOX_SELECT, self.OnItemBoxSelect, self)
end

function XUiTheatre5PVEPopupChooseReward:OnClickRefresh()
    local refreshCount = self._Control:GetRemainRelicRefreshCount()
    if refreshCount <= 0 then
        XUiManager.TipMsg(XMVCA.XTheatre5:GetText("RelicRefreshCountIsZero"))
        return
    end
    XMVCA.XTheatre5:XTheatre5RelicRefreshRequest(function()
        self:ChapterBattlePromote()
    end)
end

return XUiTheatre5PVEPopupChooseReward