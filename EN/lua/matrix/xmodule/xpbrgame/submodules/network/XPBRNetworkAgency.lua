---@class XPBRNetworkAgency : XAgency
---@field private _Model XPBRGameModel
---@field private _MainAgency XPBRGameAgency
local XPBRNetworkAgency = XClass(XAgency, "XPBRNetworkAgency")

-- 请求锁是内部用的，在内部定义枚举即可
local NetworkLockFlagEnum = {
    PbrProgressionUnlockRequest = 1,
    PbrShopChooseRequest = 2,
    PbrShopFreshRequest = 3,
    PbrForceSettleRequest = 4,
}

function XPBRNetworkAgency:OnInit()
    self._NetworkRequestLock = nil
end

function XPBRNetworkAgency:InitRpc()
    XRpc.PbrActivityDataNotify = handler(self, self.OnPbrActivityDataNotify)
    XRpc.PbrCompendiumPush = handler(self, self.OnPbrCompendiumPush)
end

function XPBRNetworkAgency:InitEvent()

end

function XPBRNetworkAgency:ResetAll()
    self._NetworkRequestLock = nil
end

function XPBRNetworkAgency:OnRelease()

end

--region Lock - 简单的逻辑锁，主要是控制协议请求频率

function XPBRNetworkAgency:CheckFlagIsLock(flag)
    return self._NetworkRequestLock and self._NetworkRequestLock[flag] or false
end

function XPBRNetworkAgency:LockWithFlag(flag)
    if self._NetworkRequestLock == nil then
        self._NetworkRequestLock = {}
    end
    
    self._NetworkRequestLock[flag] = true
end

function XPBRNetworkAgency:UnlockWithFlag(flag)
    if XTool.IsTableEmpty(self._NetworkRequestLock) then
        return
    end

    self._NetworkRequestLock[flag] = false
end

--endregion

--region Network Request

--- 天赋解锁
function XPBRNetworkAgency:DoPbrProgressionUnlockRequest(nodeId, cb)
    if self:CheckFlagIsLock(NetworkLockFlagEnum.PbrProgressionUnlockRequest) then
        return
    end
    
    self:LockWithFlag(NetworkLockFlagEnum.PbrProgressionUnlockRequest)
    
    XNetwork.Call("PbrProgressionUnlockRequest", { NodeId = nodeId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrProgressionUnlockRequest)

        if res.Code ~= XCode.Success then
            if cb then
                cb(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end
        
        -- 手动缓存
        self._Model:SetUnlockStrengthNode(nodeId)

        if cb then
            cb(true)
        end
    end, nil, function(exception) 
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrProgressionUnlockRequest)

        -- 因为重写了这个回调，所以这里要手动处理错误提示，与C#端逻辑一致
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 商店选择道具
function XPBRNetworkAgency:DoPbrShopChooseRequest(itemId, cb)
    if self:CheckFlagIsLock(NetworkLockFlagEnum.PbrShopChooseRequest) then
        return
    end

    self:LockWithFlag(NetworkLockFlagEnum.PbrShopChooseRequest)
    
    XNetwork.Call("PbrShopChooseRequest", { ItemId = itemId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrShopChooseRequest)

        if res.Code ~= XCode.Success then
            if cb then
                cb(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:SetShopUseChooseCount(res.UseChooseCount)
        self._Model:SetShopItemList(res.SellItems)
        self._Model:UpdateItemDataFromSelect(itemId, res.ChooseResultItem, res.ChooseResultType)

        if res.UseFreshCount then
            self._Model:SetShopUseFreshCount(res.UseFreshCount)
        end
        
        if cb then
            cb(true)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrShopChooseRequest)

        -- 因为重写了这个回调，所以这里要手动处理错误提示，与C#端逻辑一致
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 商店刷新
function XPBRNetworkAgency:DoPbrShopFreshRequest(cb, isGiveUpChoose)
    if self:CheckFlagIsLock(NetworkLockFlagEnum.PbrShopFreshRequest) then
        return
    end
    
    -- 检查是否有刷新次数
    if not self._Model:GetIsShopHasFreshTimes() and not isGiveUpChoose then
        XUiManager.TipMsg(self._Model:GetClientPBRText('ShopNoFreshTimesTips'))
        return
    end

    self:LockWithFlag(NetworkLockFlagEnum.PbrShopFreshRequest)

    local useFreshCount = self._Model:GetShopUseFreshCount() or 0
    isGiveUpChoose = isGiveUpChoose or false

    XNetwork.Call("PbrShopFreshRequest", { UseFreshCount = useFreshCount, IsForceGiveUpFresh = isGiveUpChoose }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrShopFreshRequest)

        if res.Code ~= XCode.Success then
            if cb then
                cb(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end

        -- 手动缓存
        self._Model:SetShopUseFreshCount(res.UseFreshCount)
        self._Model:SetShopItemList(res.SellItems)

        if res.UseChooseCount then
            self._Model:SetShopUseChooseCount(res.UseChooseCount)
        end

        if cb then
            cb(true)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrShopFreshRequest)

        -- 因为重写了这个回调，所以这里要手动处理错误提示，与C#端逻辑一致
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 局外手动结算
function XPBRNetworkAgency:DoPbrForceSettleRequest(cb)
    if self:CheckFlagIsLock(NetworkLockFlagEnum.PbrForceSettleRequest) then
        return
    end

    self:LockWithFlag(NetworkLockFlagEnum.PbrForceSettleRequest)
    
    XNetwork.Call("PbrForceSettleRequest", nil, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrForceSettleRequest)

        if res.Code ~= XCode.Success then
            if cb then
                cb(false)
            end
            XUiManager.TipCode(res.Code)
            return
        end

        -- 清空商店弹窗屏蔽缓存
        self._Model:SetShopSelectGiveupIgnorePopup(nil)

        ---@type PbrFightSettleShowData
        local pbrSettleData = res.PbrFightSettleShowData

        if pbrSettleData then
            local stageId = self._Model:GetStageIdInSegmentSettleData()
            
            -- 通关数据本地缓存
            self._Model:UpdateStageRecordByStageId(stageId, pbrSettleData.FinalSettleShowData.PbrStageRecord)
            
            -- 记录通关角色
            if res.IsWin and XTool.IsNumberValidEx(pbrSettleData.FinalSettleShowData.CharacterId) then
                self._Model:SetLastPassStageCharId(pbrSettleData.FinalSettleShowData.CharacterId)
            end

            -- 清理局内数据
            self._Model:UpdateFullSegmentSettleData(nil)
        end

        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XUiManager.OpenUiTipReward(res.RewardGoodsList)
        end

        if cb then
            cb(true)
        end

    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.PbrForceSettleRequest)

        -- 因为重写了这个回调，所以这里要手动处理错误提示，与C#端逻辑一致
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--endregion

--region RPC
function XPBRNetworkAgency:OnPbrActivityDataNotify(data)
    self._Model:UpdateFUllActivityData(data.PbrDataDb)
end

function XPBRNetworkAgency:OnPbrCompendiumPush(data)
    if not XTool.IsTableEmpty(data.AddCompendiumItems) then
        for i, v in pairs(data.AddCompendiumItems) do
            self._Model.CollectionModel:UpdateItemCompendium(v)
        end
    end

    if not XTool.IsTableEmpty(data.UpdateCompendiumItems) then
        for i, v in pairs(data.UpdateCompendiumItems) do
            self._Model.CollectionModel:UpdateItemCompendium(v)
        end
    end

    if not XTool.IsTableEmpty(data.AddCompendiumMonsters) then
        for i, v in pairs(data.AddCompendiumMonsters) do
            self._Model.CollectionModel:UpdateMonsterCompendium(v)
        end
    end

    if not XTool.IsTableEmpty(data.UpdateCompendiumMonsters) then
        for i, v in pairs(data.UpdateCompendiumMonsters) do
            self._Model.CollectionModel:UpdateMonsterCompendium(v)
        end
    end
end
--endregion

return XPBRNetworkAgency