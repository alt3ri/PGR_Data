local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")

---@class XUiAreaWarCollection : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarCollection = XLuaUiManager.Register(XLuaUi, "UiAreaWarCollection")

function XUiAreaWarCollection:OnAwake()
    self.BtnHave.gameObject:SetActiveEx(true)
    self.BtnUnHave.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridCost.gameObject:SetActiveEx(false)
    self.AttrUiObjs = { self.GridBuff, self.GridBuff2, self.GridBuff3, self.GridBuff4 }
    for _, attrUiObj in pairs(self.AttrUiObjs) do
        attrUiObj.gameObject:SetActiveEx(false)
    end
    
    self.IsFilterHave = false           -- 是否筛选已拥有藏品
    ---@type XUiGridAreaWarItem[]
    self.GridCostItems = {}
    ---@type table<number, boolean>     -- 缓存收藏室内的道具，在退出界面的时候用于清除新获得标签，防止中间获得又用掉
    self.CacheItemIdDic = {}
    self:InitDynamicTable()
    self:RegisterUiEvents()
end

function XUiAreaWarCollection:OnStart()
end

function XUiAreaWarCollection:OnEnable()
    self:Refresh()
    self:StartTimer()
end

function XUiAreaWarCollection:OnDisable()
    self:StopTimer()
    self._Control:GetItemRoom():ClearAllItemNewGet(self.CacheItemIdDic)
end

function XUiAreaWarCollection:OnDestroy()
    self:RemoveObtainTimer()
end

function XUiAreaWarCollection:OnGetLuaEvents()
    return {
        XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE
    }
end

function XUiAreaWarCollection:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE then
        self:RefreshItemList()
        self:RefreshPaneLevelUp()
    end
end

function XUiAreaWarCollection:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "AreaWarMain") -- TODO 图文教程名称
    self:RegisterClickEvent(self.BtnHave, self.OnBtnHaveClick)
    self:RegisterClickEvent(self.BtnUnHave, self.OnBtnUnHaveClick)
    self:RegisterClickEvent(self.BtnAuction, self.OnBtnAuctionClick)
    self:RegisterClickEvent(self.BtnRare, self.OnBtnRareClick)
    self:RegisterClickEvent(self.BtnLevelUp, self.OnBtnLevelUpClick)
end

function XUiAreaWarCollection:OnBtnBackClick()
    self:Close()
end

function XUiAreaWarCollection:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiAreaWarCollection:OnBtnHaveClick()
    self.IsFilterHave = true
    self.BtnHave.gameObject:SetActiveEx(false)
    self.BtnUnHave.gameObject:SetActiveEx(true)
    self:RefreshItemList()
end

function XUiAreaWarCollection:OnBtnUnHaveClick()
    self.IsFilterHave = false
    self.BtnHave.gameObject:SetActiveEx(true)
    self.BtnUnHave.gameObject:SetActiveEx(false)
    self:RefreshItemList()
end

function XUiAreaWarCollection:OnBtnAuctionClick()
    XLuaUiManager.Open("UiAreaWarAuction")
end

function XUiAreaWarCollection:OnBtnRareClick()
    XLuaUiManager.Open("UiAreaWarRare")
end

function XUiAreaWarCollection:OnBtnLevelUpClick()
    if self.IsFullLv then return end

    local lv = self._Control:GetItemRoom():GetLv()
    local nextLv = lv + 1
    local needCleanBlockId = self._Control:GetConfig():GetItemRoomLevelNeedCleanBlock(nextLv)
    local isUnlock = true
    if XTool.IsNumberValidEx(needCleanBlockId) then
        isUnlock = XDataCenter.AreaWarManager.IsBlockClear(needCleanBlockId)
    end
    if not isUnlock then
        local tips = XAreaWarConfigs.GetCollectionLockTips()
        local blockName = XAreaWarConfigs.GetBlockNameEn(needCleanBlockId)
        XUiManager.TipError(string.format(tips, blockName))
        return
    end

    if not self.IsLvUpItemEnough then
        local tips = XAreaWarConfigs.GetItemRoomLvUpNoEnoughTips()
        XUiManager.TipError(tips)
        return
    end

    XMVCA.XAreaWar:RequestAreaWar4ItemRoomLevelUp(function(rewards)
        self:PlayAnimation("Unlock")
        self:Refresh()
        self:StartObtainTimer(rewards)
    end)
end

-- 延迟弹出奖励弹窗，先播动效
function XUiAreaWarCollection:StartObtainTimer(rewards)
    self:RemoveObtainTimer()
    self.ObtainTimer = XScheduleManager.ScheduleOnce(function()
        self.ObtainTimer = nil
        XUiManager.OpenUiObtain(rewards)
    end, 1000)
end

function XUiAreaWarCollection:RemoveObtainTimer()
    if self.ObtainTimer then
        XScheduleManager.UnSchedule(self.ObtainTimer)
        self.ObtainTimer = nil
    end
end

function XUiAreaWarCollection:Refresh()
    self:RefreshItemList()
    self:RefreshCollection()
    self:RefreshPaneLevelUp()
    self:RefreshAuctionBubble()
    self:RefreshBtnRare()
    self:RefreshBtnAuction()
end

--region 藏品列表
function XUiAreaWarCollection:InitDynamicTable()
    self.GridItem.gameObject:SetActiveEx(false)
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridAreaWarItem, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新藏品列表
function XUiAreaWarCollection:RefreshItemList()
    self.ItemDataList = self._Control:GetCollectionItemDataList(self.IsFilterHave)
    for _, itemData in ipairs(self.ItemDataList) do
        if itemData.Num > 0 then
            self.CacheItemIdDic[itemData.ItemId] = true
        end
    end
    
    self.DynamicTable:SetDataSource(self.ItemDataList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridAreaWarItem
function XUiAreaWarCollection:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local itemData = self.ItemDataList[index]
        grid:RefreshItem(itemData.ItemId, itemData.Num)
        grid:RefreshUnlockTips()
        grid:RefreshLockState()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnItemClick(index)
    end
end

function XUiAreaWarCollection:OnItemClick(index)
    local itemData = self.ItemDataList[index]
    XLuaUiManager.Open("UiAreaWarPopupCollectionTip", itemData.ItemId)
end
--endregion

--region 收藏室详情/升级
-- 刷新收藏室详情
function XUiAreaWarCollection:RefreshCollection()
    -- 等级变化
    local lv = self._Control:GetItemRoom():GetLv()
    local nextLv = lv + 1
    local isNextLvExit = self._Control:GetConfig():IsItemRoomLevelExit(nextLv)
    self.TxtLevelNow.text = tostring(lv)
    self.TxtLevelNext.text = tostring(nextLv)
    self.ImgLevelArrow.gameObject:SetActiveEx(isNextLvExit)
    self.TxtLevelNext.gameObject:SetActiveEx(isNextLvExit)
    
    -- 属性
    local attrNames = XAreaWarConfigs.GetItemRoomAttrs()
    local attrValues = self._Control:GetConfig():GetItemRoomLevelShowAttrs(lv)
    local nextValues = isNextLvExit and self._Control:GetConfig():GetItemRoomLevelShowAttrs(nextLv) or {}
    self.AttrUiObjs = self.AttrUiObjs or {}
    for i, attrName in ipairs(attrNames) do
        local attrUiObj = self.AttrUiObjs[i]
        if not attrUiObj then
            local go = XUiHelper.Instantiate(self.GridBuff.gameObject, self.GridBuff.transform.parent)
            attrUiObj = go:GetComponent(typeof(CS.UiObject))
            self.AttrUiObjs[i] = attrUiObj
            go.gameObject:SetActiveEx(true)
        end
        attrUiObj.gameObject:SetActiveEx(true)
        local isLast = i == #attrNames
        attrUiObj:GetObject("TxtBuffName").text = attrName
        attrUiObj:GetObject("TxtNumNow").text = isLast and attrValues[i] or "+" .. attrValues[i] .. "%"
        
        -- 下一等级属性
        local imgArrow = attrUiObj:GetObject("ImgArrow")
        local txtNumNext = attrUiObj:GetObject("TxtNumNext")
        imgArrow.gameObject:SetActiveEx(isNextLvExit)
        txtNumNext.gameObject:SetActiveEx(isNextLvExit)
        if isNextLvExit then
            txtNumNext.text = isLast and nextValues[i] or "+" .. tostring(nextValues[i]) .. "%"
        end
    end
    
    -- 升级奖励
    local rewardId = self._Control:GetConfig():GetItemRoomLevelRewardId(lv)
    local isShowReward = XTool.IsNumberValidEx(rewardId)
    self.PanelReward.gameObject:SetActiveEx(isShowReward)
    if isShowReward then
        local rewardItems = XRewardManager.GetRewardList(rewardId)
        self.Items = self.Items or {}
        local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
        XUiHelper.CreateTemplates(self, self.Items, rewardItems, XUiGridCommon.New, self.GridReward, self.GridReward.transform.parent, function(grid, data)
            grid:Refresh(data, nil, nil, false)
        end)
    end
end

-- 刷新升级面板
function XUiAreaWarCollection:RefreshPaneLevelUp()
    self.BtnLevelUp.gameObject:SetActiveEx(false)
    self.BtnLevelFull.gameObject:SetActiveEx(false)
    for _, grid in ipairs(self.GridCostItems) do
        grid:Close()
    end
    
    local lv = self._Control:GetItemRoom():GetLv()
    local nextLv = lv + 1
    self.IsFullLv = not self._Control:GetConfig():IsItemRoomLevelExit(nextLv)
    if self.IsFullLv then 
        self.BtnLevelFull.gameObject:SetActiveEx(true)
        self.BtnLevelFull:SetDisable(true)
        self.PaneLevelUp.gameObject:SetActiveEx(false)
        return 
    end

    self.PaneLevelUp.gameObject:SetActiveEx(true)
    self.BtnLevelUp.gameObject:SetActiveEx(true)
    local needCleanBlockId = self._Control:GetConfig():GetItemRoomLevelNeedCleanBlock(nextLv)
    local isUnlock = true
    if XTool.IsNumberValidEx(needCleanBlockId) then
        isUnlock = XDataCenter.AreaWarManager.IsBlockClear(needCleanBlockId)
    end
    self.BtnLevelUp:SetDisable(not isUnlock)
    self.BtnLevelUp:ShowReddot(false)
    
    self.IsLvUpItemEnough = true
    local lvUpItems = self._Control:GetConfig():GetItemRoomLevelLvUpItems(lv)
    local lvUpItemCounts = self._Control:GetConfig():GetItemRoomLevelLvUpItemCounts(lv)
    for i, itemId in ipairs(lvUpItems) do
        local needNum = lvUpItemCounts[i]
        local ownNum = self._Control:GetItemRoom():GetItemNum(itemId)
        local grid = self.GridCostItems[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCost.gameObject, self.GridCost.transform.parent)
            grid = XUiGridAreaWarItem.New(go, self)
            self.GridCostItems[i] = grid
        end
        grid:Open()
        grid:RefreshItemByCost(itemId, needNum)

        if ownNum < needNum then
            self.IsLvUpItemEnough = false
        end
    end
    
    self.BtnLevelUp:ShowReddot(self.IsLvUpItemEnough and isUnlock)
end
--endregion

function XUiAreaWarCollection:StartTimer()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshAuctionBubble()
    end, XScheduleManager.SECOND, 0)
end

function XUiAreaWarCollection:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 刷新交易行气泡
function XUiAreaWarCollection:RefreshAuctionBubble()
    local isShowBubble = self._Control:GetItemRoom():IsExitOrderSellSuccess()
    self.ImgAuctionBubble.gameObject:SetActiveEx(isShowBubble)
end

-- 刷新珍稀图鉴按钮的蓝点
function XUiAreaWarCollection:RefreshBtnRare()
    local isRed = self._Control:IsRedCanSubmitRaceItem()
    self.BtnRare:ShowReddot(isRed)
end

-- 刷新拍卖行按钮
function XUiAreaWarCollection:RefreshBtnAuction()
    local isRed = self._Control:IsRedAuctionOrder()
    self.BtnAuction:ShowReddot(isRed)
end

return XUiAreaWarCollection
