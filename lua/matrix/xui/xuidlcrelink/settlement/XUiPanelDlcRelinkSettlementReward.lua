local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiGridDlcRelinkSettlementCharacter = require("XUi/XUiDlcRelink/Settlement/XUiGridDlcRelinkSettlementCharacter")
---@class XUiPanelDlcRelinkSettlementReward : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkSettlementNew
local XUiPanelDlcRelinkSettlementReward = XClass(XUiNode, "XUiPanelDlcRelinkSettlementReward")

function XUiPanelDlcRelinkSettlementReward:OnStart()
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.PanelNone.gameObject:SetActiveEx(false)
    self.BtnLeave:AddEventListener(handler(self, self.OnBtnLeaveClick))
    self.BtnBackRoom:AddEventListener(handler(self, self.OnBtnBackRoomClick))

    ---@type XUiGridCommon[]
    self.RewardGridList = {}
    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipmentGridList = {}

    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0
end

---@param playerSettleResult XDlcRelinkPlayerSettleResult 玩家结算结果
---@param rewardGoodsList XDlcRelinkRewardGoods[] 奖励物品列表
---@param levelId number 关卡Id
function XUiPanelDlcRelinkSettlementReward:Refresh(playerSettleResult, rewardGoodsList, levelId)
    -- 刷新玩家信息
    if not self.CharacterNode then
        ---@type XUiGridDlcRelinkSettlementCharacter
        self.CharacterNode = XUiGridDlcRelinkSettlementCharacter.New(self.GridCharacter, self)
    end
    self.CharacterNode:Open()
    self.CharacterNode:Refresh(playerSettleResult)
    -- 研发进度
    self:RefreshProgress()
    -- 刷新奖励
    self:RefreshRewards(rewardGoodsList, levelId)
end

-- 刷新研发进度
function XUiPanelDlcRelinkSettlementReward:RefreshProgress()
    local settlementCacheData = self._Control:GetSettlementCacheData()
    if XTool.IsTableEmpty(settlementCacheData) then
        XLog.Error("XUiPanelDlcRelinkSettlementReward:RefreshProgress error: settlementCacheData is nil")
        return
    end

    local isMaxLevel = self._Control:GetPlayerLevelIsMax(settlementCacheData.CurLevel)
    local isUplevel = settlementCacheData.CurLevel > settlementCacheData.LastLevel
    self.GridTag.gameObject:SetActiveEx(isUplevel)

    local addExp = settlementCacheData.CurExp - settlementCacheData.LastExp
    if isUplevel then
        for level = settlementCacheData.LastLevel, settlementCacheData.CurLevel - 1 do
            addExp = addExp + self._Control:GetNextPlayerLevelExp(level)
        end
    end

    self.TxtNum.gameObject:SetActiveEx(addExp > 0)
    if addExp > 0 then
        self.TxtNum.text = string.format("+%d", addExp)
    end

    local levelDescIndex = 1
    if isMaxLevel then
        self.ImgProgress.fillAmount = 1
        self.ImgProgressAdd.fillAmount = 0
        levelDescIndex = 2
    else
        local nextLevelExp = self._Control:GetNextPlayerLevelExp(settlementCacheData.CurLevel)
        self.ImgProgress.fillAmount = isUplevel and 0 or (settlementCacheData.LastExp / nextLevelExp)
        self.ImgProgressAdd.fillAmount = settlementCacheData.CurExp / nextLevelExp
        if not isUplevel then
            levelDescIndex = settlementCacheData.CurExp > nextLevelExp and 2 or 1
        end
    end

    self.TxtTitle.text = string.format(self._Control:GetClientConfig("SettlementResearchTitle", levelDescIndex), settlementCacheData.CurLevel)
end

---@param rewardGoodsList XDlcRelinkRewardGoods[] 奖励物品列表
---@param levelId number 关卡Id
function XUiPanelDlcRelinkSettlementReward:RefreshRewards(rewardGoodsList, levelId)
    if XTool.IsTableEmpty(rewardGoodsList) then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end

    local rewardGoods = {}
    local equipUids = {}
    for _, data in pairs(rewardGoodsList) do
        if data.RewardGoods then
            table.insert(rewardGoods, data.RewardGoods)
        end
        if XTool.IsNumberValid(data.EquipUid) then
            table.insert(equipUids, data.EquipUid)
        end
    end

    -- 奖励
    local isFirstPass = self._Control:CheckSettlementCacheLevelFirstPass(levelId)
    rewardGoods = XRewardManager.MergeAndSortRewardGoodsList(rewardGoods)
    local rewardCount = #rewardGoods
    for index = 1, rewardCount do
        local grid = self.RewardGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridReward, self.Content)
            grid = XUiGridCommon.New(self.Parent, go)
            self.RewardGridList[index] = grid
        end
        grid:Refresh(rewardGoods[index])
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", grid.TemplateId)
        end)
        -- 首通标识
        if grid.ImgClear then
            grid.ImgClear.gameObject:SetActiveEx(isFirstPass)
        end
        grid.GameObject:SetActiveEx(true)
        grid.Transform:SetAsLastSibling()
    end

    for index = rewardCount + 1, #self.RewardGridList do
        self.RewardGridList[index].GameObject:SetActiveEx(false)
    end

    -- 装备
    for index, uid in pairs(equipUids) do
        local grid = self.EquipmentGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridEquipment, self.Content)
            grid = XUiGridDlcRelinkEquipment.New(go, self, handler(self, self.OnEquipItemCallBack))
            self.EquipmentGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(uid)
        grid.Transform:SetAsLastSibling()
    end

    for index = #equipUids + 1, #self.EquipmentGridList do
        self.EquipmentGridList[index]:Close()
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiPanelDlcRelinkSettlementReward:OnEquipItemCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if equipUid == self.CurSelectEquipUid then
        return
    end
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectEquipUid = equipUid
    self.CurSelectGrid = grid
    -- 响应穿透事件屏蔽
    for _, equipGrid in pairs(self.EquipmentGridList) do
        equipGrid:SetRespondPassEvent(equipGrid ~= grid)
    end
    -- 打开气泡详情
    XLuaUiManager.Open("UiDlcRelinkBubbleEquipDetail", equipUid, grid.Transform, handler(self, self.OnBubbleEquipDetailClose), { IsEventPass = true })
end

function XUiPanelDlcRelinkSettlementReward:OnBubbleEquipDetailClose()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
end

function XUiPanelDlcRelinkSettlementReward:OnBtnLeaveClick()
    XMVCA.XDlcRoom:Quit(function()
        self._Control:CommonRunRelinkRoomUiHandle(nil, function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            XLuaUiManager.Remove(self.Parent.Name)
        end)
    end)
end

function XUiPanelDlcRelinkSettlementReward:OnBtnBackRoomClick()
    self._Control:CommonRunRelinkRoomUiHandle(nil, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        XLuaUiManager.Remove(self.Parent.Name)
    end)
end

return XUiPanelDlcRelinkSettlementReward
