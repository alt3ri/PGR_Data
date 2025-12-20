---@class XEquipAgency : XAgency
---@field _Model XEquipModel
local XEquipAgency = XClass(XAgency, "XEquipAgency")

function XEquipAgency:OnInit()
    --初始化一些变量
end

function XEquipAgency:InitRpc()
    -- 注册服务器事件
    XRpc.NotifyEquipDataList = Handler(self, self.NotifyEquipDataList)
    XRpc.NotifyEquipChipGroupList = Handler(self, self.NotifyEquipChipGroupList)
    XRpc.NotifyEquipChipAutoRecycleSite = Handler(self, self.NotifyEquipChipAutoRecycleSite)
    XRpc.NotifyEquipAutoRecycleChipList = Handler(self, self.NotifyEquipAutoRecycleChipList)
    XRpc.NotifyEquipDataTestList = Handler(self, self.NotifyEquipDataTestList)
end

function XEquipAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--============================================================== #region rpc ==============================================================
-- 登陆初始化装备数据
function XEquipAgency:InitEquipData(equipList)
    self._Model:InitEquipData(equipList)
    local equipDic = self._Model:GetEquipDic()
    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_DATA_INIT_NOTIFY)
end

function XEquipAgency:NotifyEquipDataTestList(data)
    if not data or XTool.IsTableEmpty(data.EquipDataList) then
        XLog.Warning("NotifyEquipDataTestList: EquipDataList is empty.")
        return
    end

    local equipDataList = data.EquipDataList
    local curTeam = XDataCenter.TeamManager.GetBattleRoomCacheTeam()
    if not curTeam then
        XLog.Warning("NotifyEquipDataTestList: No active battle team found.")
        return
    end

    local charIds = curTeam:GetEntityIds()
    local serverEquipMap = {}
    for _, equipData in pairs(equipDataList) do
        serverEquipMap[equipData.Id] = equipData
    end

    --------------------------------------------------------
    -- 工具函数
    --------------------------------------------------------
    local function AddDiff(diffs, field, localVal, serverVal)
        if type(localVal) ~= type(serverVal) or localVal ~= serverVal then
            table.insert(diffs, string.format("%s(local=%s, server=%s)", field, tostring(localVal), tostring(serverVal)))
        end
    end

    -- 将本地 XEquip 规范化为“服务端同形结构”的表，便于对比
    local function NormalizeLocalEquip(localEquip)
        -- 本地字段命名 -> 服务端命名
        -- OverrunData             -> WeaponOverrunData
        -- AwakeSlotListCheck仅是派生，用AwakeSlotList和服务端比
        -- 其余字段名一致：Id/TemplateId/CharacterId/Level/Exp/Breakthrough/IsLock/CreateTime/IsRecycle/ResonanceInfo/UnconfirmedResonanceInfo
        return {
            UnconfirmedResonanceInfo = localEquip.UnconfirmedResonanceInfo,
            Breakthrough = localEquip.Breakthrough,
            CharacterId = localEquip.CharacterId,
            Id = localEquip.Id,
            WeaponOverrunData = localEquip.OverrunData, -- ★ 关键映射
            AwakeSlotList = localEquip.AwakeSlotList,   -- 用AwakeSlotList对比，忽略AwakeSlotListCheck
            ResonanceInfo = localEquip.ResonanceInfo,
            IsLock = localEquip.IsLock,
            CreateTime = localEquip.CreateTime,
            IsRecycle = localEquip.IsRecycle,
            TemplateId = localEquip.TemplateId,
            Exp = localEquip.Exp,
            Level = localEquip.Level,
        }
    end

    local function CompareSimpleFields(localLikeServer, serverEquip, diffs)
        local fields = { "TemplateId", "CharacterId", "Level", "Exp", "Breakthrough", "IsLock", "CreateTime", "IsRecycle", "Id" }
        for _, field in ipairs(fields) do
            AddDiff(diffs, field, localLikeServer[field], serverEquip[field])
        end
    end

    local function CompareSubTable(localTbl, serverTbl, name, diffs)
        if not localTbl and not serverTbl then return end
        local localCount = localTbl and XTool.GetTableCount(localTbl) or 0
        local serverCount = serverTbl and XTool.GetTableCount(serverTbl) or 0
        if localCount ~= serverCount then
            table.insert(diffs, string.format("%s.Count(local=%d, server=%d)", name, localCount, serverCount))
            return
        end
        for k, v in pairs(serverTbl or {}) do
            local localVal = localTbl and localTbl[k]
            if type(v) ~= "table" then
                AddDiff(diffs, string.format("%s.%s", name, tostring(k)), localVal, v)
            end
        end
    end

    --------------------------------------------------------
    -- 收集装备信息：客户端(规范化) vs 服务端
    --------------------------------------------------------
    local localEquipList = {}
    local serverEquipList = {}

    for _, charId in pairs(charIds) do
        if not XTool.IsNumberValid(charId) then goto continue end
        local equips = self:GetCharacterEquips(charId)
        for _, localEquip in pairs(equips) do
            local equipId = localEquip.Id
            local equipName = XMVCA.XEquip:GetEquipName(localEquip.TemplateId) or "未知装备"

            -- 规范化后用于打印 & 对比
            local normalized = NormalizeLocalEquip(localEquip)

            table.insert(localEquipList, {
                Id = normalized.Id,
                TemplateId = normalized.TemplateId,
                CharacterId = normalized.CharacterId,
                Name = equipName,
                Data = normalized, -- ★ 存规范化后的Data，后续对比直接用它
            })

            if serverEquipMap[equipId] then
                table.insert(serverEquipList, serverEquipMap[equipId])
            end
        end
        ::continue::
    end

    --------------------------------------------------------
    -- 打印汇总列表（集中打印）
    --------------------------------------------------------
    XLog.Debug("================= NotifyEquipDataTestList 开始 =================")
    XLog.Debug("[NotifyEquipDataTestList] 检测的装备-客户端（已按服务端字段规范化）：", localEquipList)
    XLog.Debug("[NotifyEquipDataTestList] 检测的装备-服务端：", serverEquipList)

    --------------------------------------------------------
    -- 字段级对比（使用规范化后的本地数据）
    --------------------------------------------------------
    local totalMismatchCount = 0
    local totalEquipCount = 0

    for _, localEquipInfo in ipairs(localEquipList) do
        local localNorm = localEquipInfo.Data -- 已规范化
        local equipId = localNorm.Id
        local serverEquip = serverEquipMap[equipId]
        local charId = localNorm.CharacterId
        totalEquipCount = totalEquipCount + 1

        if not serverEquip then
            XLog.Error(string.format("[EquipTest] 本地角色(%d) 装备Id=%d 未在服务器数据中找到。", charId, equipId))
            totalMismatchCount = totalMismatchCount + 1
        else
            local diffs = {}
            -- 基础字段
            CompareSimpleFields(localNorm, serverEquip, diffs)
            -- 子表：Overrun/共鸣/觉醒槽
            CompareSubTable(localNorm.WeaponOverrunData, serverEquip.WeaponOverrunData, "WeaponOverrunData", diffs)
            CompareSubTable(localNorm.ResonanceInfo, serverEquip.ResonanceInfo, "ResonanceInfo", diffs)
            CompareSubTable(localNorm.UnconfirmedResonanceInfo, serverEquip.UnconfirmedResonanceInfo, "UnconfirmedResonanceInfo", diffs)
            CompareSubTable(localNorm.AwakeSlotList, serverEquip.AwakeSlotList, "AwakeSlotList", diffs)

            if #diffs > 0 then
                XLog.Error(string.format(
                    "[EquipTest] 不一致: 角色=%d 装备Id=%d(%s) → %s",
                    charId, equipId, localEquipInfo.Name, table.concat(diffs, "; ")
                ))
                totalMismatchCount = totalMismatchCount + #diffs
            end
        end
    end

    --------------------------------------------------------
    -- 最终总结
    --------------------------------------------------------
    if totalMismatchCount == 0 then
        XLog.Debug(string.format("[NotifyEquipDataTestList] ✅ 对比完成：全部 %d 件装备数据完全一致。", totalEquipCount))
    else
        XLog.Warning(string.format("[NotifyEquipDataTestList] ❌ 对比完成：共有 %d 项不一致。", totalMismatchCount))
    end
    XLog.Debug("================= NotifyEquipDataTestList 结束 =================")
end

function XEquipAgency:NotifyEquipDataList(data)
    if data.EquipDataList then
        self._Model:UpdateEquipData(data.EquipDataList)
    end
    if data.DeletedEquipIdList then 
        self._Model:DeleteEquips(data.DeletedEquipIdList)
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_DATA_LIST_UPDATE_NOTYFY)
end

function XEquipAgency:NotifyEquipChipGroupList(data)
    self._Model:InitEquipChipGroupList(data)
end

function XEquipAgency:NotifyEquipChipAutoRecycleSite(data)
    self._Model:UpdateAwarenessRecycleInfo(data.ChipRecycleSite)
end

function XEquipAgency:NotifyEquipAutoRecycleChipList(data)
    local equipIds = data.ChipIds
    if XTool.IsTableEmpty(equipIds) then
        return
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RECYCLE_NOTIFY, equipIds)
end

-- 穿戴装备
function XEquipAgency:PutOn(characterId, equipId, cb)
    if not XMVCA.XCharacter:IsOwnCharacter(characterId) then
        XUiManager.TipText("EquipPutOnNotChar")
        return
    end

    local equipSpecialCharacterId = self:GetEquipSpecialCharacterIdByEquipId(equipId)
    if equipSpecialCharacterId and equipSpecialCharacterId ~= characterId then
        local char = XMVCA.XCharacter:GetCharacter(equipSpecialCharacterId)
        if char then
            local characterName = XMVCA.XCharacter:GetCharacterName(equipSpecialCharacterId)
            local gradeName = XMVCA.XCharacter:GetCharGradeName(equipSpecialCharacterId, char.Grade)
            XUiManager.TipMsg(XUiHelper.GetText("EquipPutOnSpecialCharacterIdNotEqual", characterName, gradeName))
        end
        return
    end

    local characterEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
    if not self:IsTypeEqual(equipId, characterEquipType) then
        XUiManager.TipText("EquipPutOnEquipTypeError")
        return
    end

    local equip = self:GetEquip(equipId)
    local site = self:GetEquipSite(equip.TemplateId)
    local req = { CharacterId = characterId, Site = site, EquipId = equipId }
    XNetwork.CallWithAutoHandleErrorCode("EquipPutOnRequest", req, function(res)
        -- 更新装备数据
        self:OnEquipPutOnSuccess(characterId, equipId, cb)
    end)
end

function XEquipAgency:OnEquipPutOnSuccess(characterId, equipId, cb)
    local equip = self:GetEquip(equipId)
    local site = self:GetEquipSite(equip.TemplateId)
    local switchCharacterId = equip.CharacterId
    local oldEquipId = self:GetCharacterEquipId(characterId, site)
    local isWeapon = site == XEnumConst.EQUIP.EQUIP_SITE.WEAPON

    -- 卸下旧装备
    if oldEquipId then
        local oldEquip = self:GetEquip(oldEquipId)
        if isWeapon then
            oldEquip:PutOn(switchCharacterId)
        else
            oldEquip:TakeOff()
        end
        XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff({ equipId }, switchCharacterId, false)
    end

    local charIdDic = {}
    if switchCharacterId ~= 0 then
        charIdDic[switchCharacterId] = true
    end
    charIdDic[characterId] = true

    -- 穿戴新装备
    equip:PutOn(characterId)
    XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff({ equipId }, characterId, true)

    -- 更新数据模型
    if switchCharacterId ~= 0 then
        if oldEquipId and isWeapon then
            self._Model:SetCharacterEquipId(switchCharacterId, oldEquipId)
        else
            self._Model:RemoveCharacterEquipId(switchCharacterId, equipId)
        end
    end
    self._Model:SetCharacterEquipId(characterId, equipId)

    -- 通知系统
    XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_PUTON_NOTYFY, equipId)
    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_PUTON_NOTYFY, equipId)

    if isWeapon then
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_PUTON_WEAPON_NOTYFY, characterId, equipId)
    end

    if cb then cb() end
    self:TipEquipOperation(nil, XUiHelper.GetText("EquipPutOnSuc"))
end

-- 卸下装备
function XEquipAgency:TakeOff(equipIds)
    if not equipIds or not next(equipIds) then
        XLog.Error("XEquipAgency:TakeOff错误, 参数equipIds不能为为空")
        return
    end

    for _, equipId in pairs(equipIds) do
        if not self:IsWearing(equipId) then
            XUiManager.TipText("EquipTakeOffNotChar")
            return
        end
    end

    local req = {EquipIds = equipIds}
    XNetwork.CallWithAutoHandleErrorCode("EquipTakeOffRequest", req, function(res)
        self:TipEquipOperation(nil, XUiHelper.GetText("EquipTakeOffSuc"))

        local charIdDic = {}
        for _, equipId in pairs(equipIds) do
            local equip = self:GetEquip(equipId)
            local characterId = equip.CharacterId
            charIdDic[characterId] = true
            equip:TakeOff()
            XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff({ equipId }, characterId, false)
            self._Model:RemoveCharacterEquipId(characterId, equipId)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY, equipId)
        end

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
    end)
end

-- 替换装备意识套装
function XEquipAgency:EquipSuitPrefabEquip(prefabIndex, characterId, cb)
    if not characterId then
        return
    end
    local suitPrefabInfo = self:GetSuitPrefabInfo(prefabIndex)
    if not suitPrefabInfo then
        return
    end

    local oldEquipSiteToIdDic = {}
    local oldEquipIds = self:GetCharacterAwarenessIds(characterId)
    for _, equipId in pairs(oldEquipIds) do
        local equipSite = self:GetEquipSiteByEquipId(equipId)
        oldEquipSiteToIdDic[equipSite] = equipId
    end

    local isDifferent = false
    local newEquipSiteToIdDic = {}
    local newEquipIds = suitPrefabInfo:GetEquipIds()
    local newEquipIdDic = {}
    for _, equipId in pairs(newEquipIds) do
        local equipSpecialCharacterId = self:GetEquipSpecialCharacterIdByEquipId(equipId)
        if equipSpecialCharacterId and equipSpecialCharacterId ~= characterId then
            local char = XMVCA.XCharacter:GetCharacter(equipSpecialCharacterId)
            local characterName = XMVCA.XCharacter:GetCharacterName(equipSpecialCharacterId)
            local gradeName = XMVCA.XCharacter:GetCharGradeName(equipSpecialCharacterId, char.Grade)
            XUiManager.TipMsg(XUiHelper.GetText("EquipPutOnSpecialCharacterIdNotEqual", characterName, gradeName))
            return
        end

        local equipSite = self:GetEquipSiteByEquipId(equipId)
        newEquipSiteToIdDic[equipSite] = equipId
        newEquipIdDic[equipId] = true
        if oldEquipSiteToIdDic[equipSite] ~= equipId then
            isDifferent = true
        end
    end

    for _, oldequipId in pairs(oldEquipIds) do
        if not newEquipIdDic[oldequipId] then
            isDifferent = true
        end
    end

    if not isDifferent then
        XUiManager.TipText("EquipSuitPrefabEquipSame")
        return
    end

    local req = {CharacterId = characterId, GroupId = suitPrefabInfo:GetGroupId()}
    XNetwork.CallWithAutoHandleErrorCode("EquipPutOnChipGroupRequest", req, function(res)
        -- 卸下成员身上的旧装备
        for _, equipId in pairs(oldEquipIds) do
            local equip = self:GetEquip(equipId)
            equip:TakeOff()
            self._Model:RemoveCharacterEquipId(characterId, equipId)
        end
        XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff(oldEquipIds, characterId, false)

        -- 穿在其他成员身上，先卸下装备，再穿上装备
        local charIdDic = {}
        for _, equipId in pairs(newEquipIds) do
            local equip = self:GetEquip(equipId)
            -- 穿在其他成员身上
            if equip:IsWearing() then
                self._Model:RemoveCharacterEquipId(equip.CharacterId, equipId)
                charIdDic[equip.CharacterId] = true
            end
            -- 穿上装备
            equip:PutOn(characterId)
            self._Model:SetCharacterEquipId(characterId, equipId)
            charIdDic[characterId] = true
        end
        XDataCenter.EquipGuideManager.HandleEquipGuidePutOnOrTakeOff(newEquipIds, characterId, true)

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, newEquipIds)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, newEquipIds)

        if cb then cb() end
        XUiManager.TipText("EquipSuitPrefabEquipSuc")
    end)
end

-- 请求升级
function XEquipAgency:LevelUp(equipId, equipIdCheckList, useItemDic, callBackBeforeEvent)
    if not equipId then
        XLog.Error("XEquipAgency:LevelUp错误: 参数equipId不能为空")
        return
    end

    if self:IsMaxLevel(equipId) then
        XUiManager.TipText("EquipLevelUpMaxLevel")
        return
    end

    local costEmpty = true
    local costMoney = 0
    if equipIdCheckList and next(equipIdCheckList) then
        costEmpty = nil
        costMoney = costMoney + self._Model:GetEatEquipsCostMoney(equipIdCheckList)
    end

    if useItemDic and next(useItemDic) then
        costEmpty = nil
        costMoney = costMoney + self._Model:GetEatItemsCostMoney(useItemDic)
        XMessagePack.MarkAsTable(useItemDic)
    end

    if costEmpty then
        XUiManager.TipText("EquipLevelUpItemEmpty")
        return
    end

    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(
        XDataCenter.ItemManager.ItemId.Coin,
        costMoney,
        1,
        function()
            self:LevelUp(equipId, equipIdCheckList, useItemDic, callBackBeforeEvent)
        end,
        "EquipBreakCoinNotEnough")
    then
        return
    end

    local useEquipIdList = {}
    local containPrecious = false
    for tmpEquipId in pairs(equipIdCheckList) do
        containPrecious = containPrecious or self:GetEquipStar(self:GetEquipTemplateId(tmpEquipId)) >= XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR
        table.insert(useEquipIdList, tmpEquipId)
    end

    local req = {EquipId = equipId, UseEquipIdList = useEquipIdList, UseItems = useItemDic}
    local callFunc = function()
        XNetwork.CallWithAutoHandleErrorCode("EquipLevelUpRequest", req, function(res)
            local charIdDic = {}
            local equip = self:GetEquip(equipId)
            equip:SetLevel(res.Level)
            equip:SetExp(res.Exp)
            if equip:IsWearing() then
                charIdDic[equip.CharacterId] = true
            end

            local closeCb
            if self:CanBreakThrough(equipId) then
                closeCb = function()
                    self:TipEquipOperation(equipId, nil, nil, true)
                end
            end
            self:TipEquipOperation(nil, XUiHelper.GetText("EquipStrengthenSuc"), closeCb, true)

            if callBackBeforeEvent then
                callBackBeforeEvent()
            end

            -- 更新角色数据
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
        end)
    end

    if containPrecious then
        local title = XUiHelper.GetText("EquipStrengthenPreciousTipTitle")
        local content = XUiHelper.GetText("EquipStrengthenPreciousTipContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    else
        callFunc()
    end
end

-- 请求突破
function XEquipAgency:Breakthrough(equipId)
    if not equipId then
        XLog.Error("XEquipAgency:Breakthrough错误: 参数equipId不能为空")
        return
    end

    if self:IsMaxBreakthrough(equipId) then
        XUiManager.TipText("EquipBreakMax")
        return
    end

    if not self:IsReachBreakthroughLevel(equipId) then
        XUiManager.TipText("EquipBreakMinLevel")
        return
    end

    local consumeItems = self._Model:GetBreakthroughConsumeItems(equipId)
    if not XDataCenter.ItemManager.CheckItemsCount(consumeItems) then
        XUiManager.TipText("EquipBreakItemNotEnough")
        return
    end

    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(
        self._Model:GetBreakthroughUseItemId(equipId),
        self._Model:GetBreakthroughUseMoney(equipId),
        1,
        function()
            self:Breakthrough(equipId)
        end,
        "EquipBreakCoinNotEnough")
    then
        return
    end

    local title = XUiHelper.GetText("EquipBreakthroughConfirmTiltle")
    local content = XUiHelper.GetText("EquipBreakthroughConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XNetwork.CallWithAutoHandleErrorCode("EquipBreakthroughRequest", {EquipId = equipId}, function(res)
            local equip = self:GetEquip(equipId)
            equip:BreakthroughOneTime()

            if equip:IsWearing() then
                local charIdDic = {}
                charIdDic[equip.CharacterId] = true
                XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, equipId)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, equipId)
        end)
    end)
end

-- 请求一键升级
function XEquipAgency:EquipOneKeyFeedRequest(equipId, targetBreakthrough, targetLevel, operations, cb)
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipQuick) then
        return
    end

    local req = { EquipId = equipId, TargetBreakthrough = targetBreakthrough, TargetLevel = targetLevel, OperationInfos = {}}

    --服务端要求数据结构
    for _, operation in ipairs(operations) do
        local data = {
            OperationType = operation.OperationType,
            UseItemIdList = {},
            UseItemCountList = {},
            UseEquipIdList = {}
        }
        if not XTool.IsTableEmpty(operation.UseItems) then
            for itemId, itemCount in pairs(operation.UseItems) do
                if itemCount > 0 then
                    table.insert(data.UseItemIdList, itemId)
                    table.insert(data.UseItemCountList, itemCount)
                end
            end
        end
        --构造装备列表
        if not XTool.IsTableEmpty(operation.UseEquipIdDic) then
            for equipId in pairs(operation.UseEquipIdDic) do
                table.insert(data.UseEquipIdList, equipId)
            end
        end
        table.insert(req.OperationInfos, data)
    end
    -- 拦截空操作
    if XTool.IsTableEmpty(req.OperationInfos) then
        return
    end

    XDataCenter.TaskManager.CloseSyncTasksEvent()
    XNetwork.Call("EquipOneKeyFeedRequest", req, function(res)
        XDataCenter.TaskManager.OpenSyncTasksEvent()
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            XLog.Error(XLog.Dump(req))
            return
        end

        local charIdDic = {}
        --更新装备数据
        local equip = self:GetEquip(equipId)
        equip:SetBreakthrough(res.Breakthrough)
        equip:SetLevel(res.Level)
        equip:SetExp(res.Exp)
        if equip:IsWearing() then
            charIdDic[equip.CharacterId] = true
        end

        self:TipEquipOperation(nil, XUiHelper.GetText("EquipMultiStrengthenSuc"))

        if cb then
            cb()
        end

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_QUICK_STRENGTHEN_NOTYFY, equipId)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
    end)
end

--- 请求武器/意识共鸣
function XEquipAgency:RequestEquipResonance(equipId, slots, characterId, useEquipId, useItemId, selectSkillIds, equipResonanceType, ignoreTip)
    local isTips = false
    local tipsTitle = nil
    local tipsContent = nil
    if useEquipId and not ignoreTip then
        local templateId = self:GetEquipTemplateId(useEquipId)
        local star = self:GetEquipStar(templateId)
        if star >= XEnumConst.EQUIP.CAN_NOT_AUTO_EAT_STAR then
            isTips = true
            tipsTitle = XUiHelper.GetText("EquipResonancePreciousTipTitle")
            tipsContent = XUiHelper.GetText("EquipResonancePreciousTipContent")
        end
    end

    if isTips then
        XUiManager.DialogTip(tipsTitle, tipsContent, XUiManager.DialogType.Normal, nil, function()
            self:CallEquipResonanceRequest(equipId, slots, characterId, useEquipId, useItemId, selectSkillIds, equipResonanceType)
        end)
    else
        self:CallEquipResonanceRequest(equipId, slots, characterId, useEquipId, useItemId, selectSkillIds, equipResonanceType)
    end
end

function XEquipAgency:CallEquipResonanceRequest(equipId, slots, characterId, useEquipId, useItemId, selectSkillIds, equipResonanceType)
    local req = { EquipId = equipId, Slots = slots, CharacterId = characterId, UseEquipId = useEquipId, 
        UseItemId = useItemId, SelectSkillIds = selectSkillIds, SelectType = equipResonanceType }

    XNetwork.CallWithAutoHandleErrorCode("EquipResonanceRequest", req, function(res)
        local equip = self:GetEquip(equipId)
        for i, resonanceData in ipairs(res.ResonanceDatas) do
            if equip:IsWeapon() then
                equip:Resonance(resonanceData, true)
            else
                equip:Resonance(resonanceData)
            end
        end
        --5星及以上的装备（包括武器、意识）共鸣操作成功之后，将该装备自动上锁
        if self:CanResonance(equipId) then
            equip:SetLock(true)
        end

        local charIdDic = {}
        if equip:IsWearing() then
            charIdDic[equip.CharacterId] = true
        end

        -- 更新角色数据
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, equipId, slots)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, equipId, slots)
    end)
end

-- 共鸣技能确认
function XEquipAgency:ResonanceConfirm(equipId, slot, isUse, cb)
    local equip = self:GetEquip(equipId)
    local unConfirmInfo = equip:GetResonanceUnConfirmInfo(slot) -- 未确认的共鸣信息
    if not unConfirmInfo then
        if cb then cb() end
        return
    end

    local req = {EquipId = equipId, Slot = slot, IsUse = isUse}
    XNetwork.CallWithAutoHandleErrorCode("EquipResonanceConfirmRequest", req, function(res)
        equip:ResonanceConfirm(slot, isUse)

        -- 更新角色数据
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end

        if cb then cb() end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, equipId, slot)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, equipId)
    end)
end

-- 请求超频
function XEquipAgency:Awake(equipId, slot, costType)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipAwake) then
        return
    end

    XNetwork.CallWithAutoHandleErrorCode("EquipAwakeRequest", {EquipId = equipId, Slot = slot, CostType = costType}, function(res)
        local equip = self:GetEquip(equipId)
        equip:SetAwake(slot)

        -- 更新角色数据
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, equipId, slot)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, equipId)
    end)
end

--- 请求快速超频
function XEquipAgency:RequestEquipQuickAwake(awakeInfos, cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipAwake) then
        return
    end
    
    local req = { EquipQuickAwakeInfos = awakeInfos }
    XNetwork.CallWithAutoHandleErrorCode("EquipQuickAwakeRequest", req, function(res)
        local charIdDic = {}
        for _, awakeInfo in ipairs(awakeInfos) do
            local equip = self:GetEquip(awakeInfo.EquipId)
            for _, slot in ipairs(awakeInfo.Slots) do
                equip:SetAwake(slot)
            end
            if equip:IsWearing() then
                charIdDic[equip.CharacterId] = true
            end
        end

        XMVCA.XCharacter:OnSyncCharacterEquipChange(charIdDic)
        self:TipEquipOperation(nil, XUiHelper.GetText("EquipMultiStrengthenSuc"))
        if cb then cb() end
    end)
end

-- 请求超限升级
function XEquipAgency:EquipWeaponOverrunLevelUpRequest(equipId, callback)
    local request = { EquipId = equipId }
    XNetwork.CallWithAutoHandleErrorCode("EquipWeaponOverrunLevelUpRequest", request, function(res)
        -- 刷新数据
        local equip = self:GetEquip(equipId)
        equip:SetOverrunData(res.WeaponOverrunData)
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end

        -- 升级1级时，自动上锁
        if res.WeaponOverrunData.Level == 1 and not equip.IsLock then
            self:SetLock(equipId, true)
        end

        -- 超限发生变化，发送事件
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY, equipId)
        
        if callback then
            callback()
        end
    end)
end

-- 请求超限额外意识解锁
function XEquipAgency:EquipWeaponActiveOverrunSuitRequest(equipId, suitId, callback)
    local request = { EquipId = equipId, SuitId = suitId }
    XNetwork.CallWithAutoHandleErrorCode("EquipWeaponActiveOverrunSuitRequest", request, function(res)
        -- 刷新数据
        local equip = self:GetEquip(equipId)
        equip:SetOverrunData(res.WeaponOverrunData)
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end

        if callback then
            callback()
        end
    end)
end

-- 请求超限切换意识选中
function XEquipAgency:EquipWeaponChoseOverrunSuitRequest(equipId, suitId, callback)
    local request = { EquipId = equipId, SuitId = suitId }
    XNetwork.CallWithAutoHandleErrorCode("EquipWeaponChoseOverrunSuitRequest", request, function(res)
        -- 刷新数据
        local equip = self:GetEquip(equipId)
        equip:SetOverrunData(res.WeaponOverrunData)
        if equip:IsWearing() then
            local charIdDic = {}
            charIdDic[equip.CharacterId] = true
            XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)
        end

        -- 超限发生变化，发送事件
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY, equipId)

        if callback then
            callback()
        end
    end)
end

-- 请求分解装备
function XEquipAgency:EquipDecompose(equipIds, cb)
    if not equipIds or #equipIds == 0 then
        return
    end

    local req = {EquipIds = equipIds}
    XDataCenter.TaskManager.CloseSyncTasksEvent()
    XNetwork.Call("EquipDecomposeRequest", req, function(res)
        XDataCenter.TaskManager.OpenSyncTasksEvent()
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local rewardGoodsList = res.RewardGoodsList
        if cb then
            cb(rewardGoodsList)
        end
    end)
end

-- 请求快速共鸣
function XEquipAgency:RequestEquipQuickResonance(equipIds, characterId, useItemId, slot, selectSkillId, selectType, cb)
    local req = {EquipIds = equipIds, CharacterId = characterId, UseItemId = useItemId, Slot = slot, SelectSkillId = selectSkillId, SelectType = selectType}
    XNetwork.CallWithAutoHandleErrorCode("EquipQuickResonanceChipRequest", req, function(res)
        self:TipEquipOperation(nil, XUiHelper.GetText("ResonanceSuccess"))

        local resonanceData = {
            ["CharacterId"] = characterId,
            ["Type"] = selectType,
            ["UseItemId"] = useItemId,
            ["IsUseEquip"] = false,
            ["TemplateId"] = selectSkillId,
            ["Slot"] = slot,
        }
        for _, id in pairs(res.SuccessEquipIds) do
            local equip = self:GetEquip(id)
            -- 更新共鸣数据
            equip:Resonance(resonanceData, true)

            -- 5星及以上的装备（包括武器、意识）共鸣操作成功之后，将该装备自动上锁
            equip:SetLock(true)
        end

        -- 更新角色数据
        local charIdDic = {}
        charIdDic[characterId] = true
        XMVCA:GetAgency(ModuleId.XCharacter):OnSyncCharacterEquipChange(charIdDic)

        if cb then cb() end
    end)
end

--- 请求上锁
function XEquipAgency:SetLock(equipId, isLock)
    if not equipId then
        XLog.Error("XEquipAgency:SetLock错误: 参数equipId不能为空")
        return
    end

    local req = {EquipId = equipId, IsLock = isLock}
    XNetwork.CallWithAutoHandleErrorCode("EquipUpdateLockRequest", req, function(res)
        local equip = self:GetEquip(equipId)
        equip:SetLock(isLock)

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, equipId, isLock)
        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, equipId, isLock)
    end)
end

function XEquipAgency:AwarenessTransform(suitId, site, usedIdList, cb)
    if not suitId then
        XLog.Error("XEquipAgency:AwarenessTransform错误: 参数suitId不能为空")
        return
    end

    local req = {SuitId = suitId, Site = site, UseIdList = usedIdList}
    XNetwork.CallWithAutoHandleErrorCode("EquipTransformChipRequest", req, function(res)
        if cb then
            cb(res.EquipData)
        end
    end)
end

--characterId:专属组合角色Id，通用组合为0
function XEquipAgency:EquipSuitPrefabSave(suitPrefabInfo, characterId)
    if not suitPrefabInfo then
        return
    end

    local name = suitPrefabInfo:GetName()
    if not name or name == "" then
        XUiManager.TipText("EquipSuitPrefabSaveNotName")
        return
    end

    local chipIds = suitPrefabInfo:GetEquipIds()
    if not next(chipIds) then
        XUiManager.TipText("EquipSuitPrefabSaveNotEquipIds")
        return
    end

    local req = {Name = name, ChipIds = chipIds, CharacterId = characterId}
    XNetwork.CallWithAutoHandleErrorCode("EquipAddChipGroupRequest", req, function(res)
        self._Model:SaveSuitPrefabInfo(res.ChipGroupData)
        XUiManager.TipText("EquipSuitPrefabSaveSuc")
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
    end)
end

function XEquipAgency:EquipSuitPrefabDelete(prefabIndex)
    local suitPrefabInfo = self:GetSuitPrefabInfo(prefabIndex)
    if not suitPrefabInfo then
        return
    end

    local req = {GroupId = suitPrefabInfo:GetGroupId()}
    XNetwork.CallWithAutoHandleErrorCode("EquipDeleteChipGroupRequest", req, function(res)
        self._Model:DeleteSuitPrefabInfo(prefabIndex)
        XUiManager.TipText("EquipSuitPrefabDeleteSuc")
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
    end)
end

function XEquipAgency:EquipSuitPrefabRename(prefabIndex, newName)
    local suitPrefabInfo = self:GetSuitPrefabInfo(prefabIndex)
    if not suitPrefabInfo then
        return
    end

    local equipGroupData = {
        GroupId = suitPrefabInfo:GetGroupId(),
        Name = newName,
        ChipIdList = suitPrefabInfo:GetEquipIds(),
        CharacterId = suitPrefabInfo:GetCharacterId()
    }
    local req = {GroupData = equipGroupData}

    XNetwork.CallWithAutoHandleErrorCode("EquipUpdateChipGroupRequest", req, function(res)
        suitPrefabInfo:UpdateData(equipGroupData)
        XUiManager.TipText("EquipSuitPrefabRenameSuc")
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
    end)
end

--装备意识回收请求
function XEquipAgency:EquipChipRecycleRequest(equipIds, cb)
    local req = {ChipIds = equipIds}
    XNetwork.CallWithAutoHandleErrorCode("EquipChipRecycleRequest", req, function(res)
        local rewardGoodsList = res.RewardGoodsList
        if cb then
            cb(rewardGoodsList)
        end
    end)
end

--装备意识设置自动回收请求
function XEquipAgency:EquipChipSiteAutoRecycleRequest(starList, days, cb)
    local req = {StarList = starList, Days = days}
    XNetwork.CallWithAutoHandleErrorCode("EquipChipSiteAutoRecycleRequest", req, function(res)
        self._Model:UpdateAwarenessRecycleInfo({RecycleStar = starList, Days = days})
        if cb then
            cb()
        end
    end)
end

--装备更新回收标志请求
function XEquipAgency:EquipUpdateRecycleRequest(equipId, isRecycle, cb)
    isRecycle = isRecycle and true or false
    local callFunc = function()
        local req = {EquipId = equipId, IsRecycle = isRecycle}
        XNetwork.Call("EquipUpdateRecycleRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local equip = self:GetEquip(equipId)
            equip:SetRecycle(isRecycle)

            if cb then
                cb()
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, equipId, isRecycle)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, equipId, isRecycle)
        end)
    end

    if isRecycle and self._Model:IsSetRecycleNeedConfirm(equipId) then
        local title = XUiHelper.GetText("EquipSetRecycleConfirmTitle")
        local content = XUiHelper.GetText("EquipSetRecycleConfirmContent")
        local days = self:GetRecycleSettingDays()
        local content2 = days > 0 and XUiHelper.GetText("EquipSetRecycleConfirmContentExtra", days) or
            XUiHelper.GetText("EquipSetRecycleConfirmContentExtraNegative")
        local hintInfo = {}
        hintInfo.SetHintCb = function(isSelect) 
            self._Model:SetRecycleCookie(isSelect) 
        end
        hintInfo.Status = self._Model:IsHaveRecycleCookie()
        XUiManager.DialogHintTip(title, content, content2, nil, callFunc, hintInfo)
    else
        callFunc()
    end
end
--============================================================== #endregion rpc ==============================================================




--============================================================== #region 协议数据 ==============================================================
---------------------------------------- #region 装备 ----------------------------------------
-- 获取装备的XEquip对象实例
function XEquipAgency:GetEquip(equipId)
    return self._Model:GetEquip(equipId)
end

-- 根据装备的配置表Id获取装备列表
function XEquipAgency:GetEquipsByTemplateId(templateId, isIgnoreWear)
    return self._Model:GetEquipsByTemplateId(templateId, isIgnoreWear)
end

function XEquipAgency:IsEquipExit(equipId)
    return self._Model:IsEquipExit(equipId)
end

-- 获取所有装备的XEquip对象实例
function XEquipAgency:GetEquipDic()
    return self._Model:GetEquipDic()
end

-- 获取装备的配置表Id
function XEquipAgency:GetEquipTemplateId(equipId)
    return self._Model:GetEquipTemplateId(equipId)
end

function XEquipAgency:GetEquipWearingCharacterId(equipId)
    return self._Model:GetEquipWearingCharacterId(equipId)
end

function XEquipAgency:IsWearing(equipId)
    return self._Model:IsWearing(equipId)
end

function XEquipAgency:IsEquipWearingByCharacterId(equipId, characterId)
    return self._Model:IsEquipWearingByCharacterId(equipId, characterId)
end

function XEquipAgency:IsLock(equipId)
    return self._Model:IsLock(equipId)
end

function XEquipAgency:GetEquipLevel(equipId)
    return self._Model:GetEquipLevel(equipId)
end

function XEquipAgency:IsMaxLevel(equipId)
    return self._Model:IsMaxLevel(equipId)
end

function XEquipAgency:IsMaxBreakthrough(equipId)
    return self._Model:IsMaxBreakthrough(equipId)
end

function XEquipAgency:IsReachBreakthroughLevel(equipId)
    return self._Model:IsReachBreakthroughLevel(equipId)
end

function XEquipAgency:IsMaxLevelAndBreakthrough(equipId)
    return self._Model:IsMaxLevelAndBreakthrough(equipId)
end

function XEquipAgency:CanBreakThrough(equipId)
    return self._Model:CanBreakThrough(equipId)
end

--- 获取成员对应部位的装备Id
---@param characterId number 成员Id
---@param site number 装备部位
function XEquipAgency:GetCharacterEquipId(characterId, site)
    return self._Model:GetCharacterEquipId(characterId, site)
end

--- 获取成员对应部位的装备实例
---@param characterId number 成员Id
---@param site number 装备部位
function XEquipAgency:GetCharacterEquip(characterId, site)
    return self._Model:GetCharacterEquip(characterId, site)
end

--- 获取成员身上的所有装备Id列表
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipAgency:GetCharacterEquipIds(characterId, isUseTempList)
    return self._Model:GetCharacterEquipIds(characterId, isUseTempList)
end

--- 获取成员身上的所有装备实例
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipAgency:GetCharacterEquips(characterId, isUseTempList)
    return self._Model:GetCharacterEquips(characterId, isUseTempList)
end

--- 获取成员的武器Id
---@param characterId number 成员Id
function XEquipAgency:GetCharacterWeaponId(characterId)
    return self._Model:GetCharacterWeaponId(characterId)
end

--- 获取成员的武器实例
---@param characterId number 成员Id
function XEquipAgency:GetCharacterWeapon(characterId)
    return self._Model:GetCharacterWeapon(characterId)
end

--- 获取成员的意识Id列表
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipAgency:GetCharacterAwarenessIds(characterId, isUseTempList)
    return self._Model:GetCharacterAwarenessIds(characterId, isUseTempList)
end

--- 获取成员穿戴的意识数量
---@param characterId number 成员Id
function XEquipAgency:GetCharacterAwarenessCnt(characterId)
    return self._Model:GetCharacterAwarenessCnt(characterId)
end

-- 获取装备的属性哈希表
function XEquipAgency:GetEquipAttrMap(equipId, preBreakthrough, preLevel)
    local attrMap = {}
    if not equipId then
        return attrMap
    end

    local equip = self:GetEquip(equipId)
    local attrs = XFightEquipManager.GetEquipAttribs(equip, preBreakthrough, preLevel)
    attrMap = self:ConstructEquipAttrMap(attrs)
    return attrMap
end

function XEquipAgency:ConstructEquipAttrMap(attrs, isIncludeZero, remainDigitTwo)
    local equipAttrMap = {}
    for _, attrIndex in ipairs(XEnumConst.EQUIP.ATTR_SORT_TYPE) do
        local value = attrs and attrs[attrIndex]

        --默认保留两位小数
        if not remainDigitTwo then
            value = value and FixToInt(value)
        else
            value = value and tonumber(string.format("%0.2f", FixToDouble(value)))
        end

        if isIncludeZero or value and value > 0 then
            local name = XAttribManager.GetAttribNameByIndex(attrIndex)
            table.insert(equipAttrMap, {AttrIndex = attrIndex, Name = name, Value = value or 0})
        end
    end

    return equipAttrMap
end

-- 获取角色穿戴的装备列表
function XEquipAgency:GetWearingEquipList(characterId)
    local equipList = {}
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        if equip.CharacterId == characterId then
            table.insert(equipList, equip)
        end
    end
    return equipList
end

-- 获取角色穿戴的意识列表
function XEquipAgency:GetWearingAwarenessList(characterId)
    local equipList = {}
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        if equip.CharacterId == characterId and equip:IsAwareness() then
            table.insert(equipList, equip)
        end
    end
    return equipList
end

--- 获取套装列表信息
--- @param equipList table 意识实体列表
--- @param weaponEquip table 武器实体
function XEquipAgency:GetWearingSuitInfoListByEquipListAndWeapon(equipList, weaponEquip)
    local suitInfoDic = {}
    local suitInfoList = {}
    local getSuitInfoFunc = function(suitId)
        local suitInfo = suitInfoDic[suitId]
        if not suitInfo then
            local suitName = self:GetSuitName(suitId)
            suitInfo = { SuitId = suitId, Name = suitName, Count = 0, IsOverrun = false }
            suitInfoDic[suitId] = suitInfo
            table.insert(suitInfoList, suitInfo)
        end
        return suitInfo
    end

    for _, equip in pairs(equipList) do
        local suitId = self:GetEquipSuitId(equip.TemplateId)
        local suitInfo = getSuitInfoFunc(suitId)
        suitInfo.Count = suitInfo.Count + 1
    end

    -- 武器超限
    if weaponEquip then
        local equip = weaponEquip
        if equip:CanOverrun() and equip:IsOverrunBlindMatch() then
            local overrunSuitId = equip:GetOverrunChoseSuit()
            if overrunSuitId ~= 0 then
                local suitInfo = getSuitInfoFunc(overrunSuitId)
                local skillDescs = self:GetEquipSuitSkillDescription(overrunSuitId)
                local curCnt = suitInfo.Count
                for addCnt = 1, XEnumConst.EQUIP.OVERRUN_ADD_SUIT_CNT do
                    if skillDescs[curCnt + addCnt]then
                        suitInfo.Count = curCnt + addCnt
                        suitInfo.IsOverrun = true
                    end
                end
            end
        end
    end

    table.sort(suitInfoList, function(a, b)
        -- 套装数量多的优先
        if a.Count ~= b.Count then
            return a.Count > b.Count
        end

        -- 非超限的优先
        if a.IsOverrun ~= b.IsOverrun then
            return not a.IsOverrun
        end

        -- 套装id大的优先
        return a.SuitId > b.SuitId
    end)

    return suitInfoList
end

-- 获取角色穿戴的套装列表信息
function XEquipAgency:GetWearingSuitInfoList(characterId)
    local suitInfoList = {}
    local equipList = self:GetWearingAwarenessList(characterId)

    -- 武器
    local equipWeapon = nil
    local usingWeaponId = self:GetCharacterWeaponId(characterId)
    if  XTool.IsNumberValid(usingWeaponId) then
        local equip = self:GetEquip(usingWeaponId)
        equipWeapon = equip
    end

    suitInfoList = self:GetWearingSuitInfoListByEquipListAndWeapon(equipList, equipWeapon)
    return suitInfoList
end

-- 是否是角色穿戴武器，激活超限所绑定的意识
function XEquipAgency:IsCharacterOverrunSuit(characterId, suitId)
    local usingWeaponId = self:GetCharacterWeaponId(characterId)
    if usingWeaponId ~= 0 then
        local usingEquip = self:GetEquip(usingWeaponId)
        local choseSuit = usingEquip:GetOverrunChoseSuit()
        return choseSuit == suitId
    end

    return false
end

function XEquipAgency:GetEquipStarByEquipId(equipId)
    local templateId = self:GetEquipTemplateId(equipId)
    local quality = self:GetEquipStar(templateId)
    return quality
end

function XEquipAgency:GetCharDetailEquipTemplate(templateId)
    local config = self._Model:GetEquipRecommend(templateId)
    return config
end

function XEquipAgency:GetEquipRecommendListByIds(ids)
    local list = {}
    for _, id in ipairs(ids) do
        local config = self:GetCharDetailEquipTemplate(id)
        if config then
            table.insert(list, config)
        end
    end
    local voteNumSort = XDataCenter.VoteManager.GetVoteNumSortFun()
    table.sort(list, voteNumSort)

    return list
end

--- 是否拥有这件装备
function XEquipAgency:IsOwnEquip(templateId)
    return self._Model:IsOwnEquip(templateId)
end

function XEquipAgency:GetEquipIdsBySuitId(suitId, site)
    return self._Model:GetEquipIdsBySuitId(suitId, site)
end

function XEquipAgency:GetEquipCountInSuit(suitId, site)
    return self._Model:GetEquipCountInSuit(suitId, site)
end

function XEquipAgency:GetEquipCount(templateId)
    return self._Model:GetEquipCount(templateId)
end

function XEquipAgency:GetFirstEquip(templateId)
    return self._Model:GetFirstEquip(templateId)
end

--- 获取装备的突破次数
function XEquipAgency:GetEquipBreakthroughTimes(equipId)
    return self._Model:GetEquipBreakthroughTimes(equipId)
end

--- 获取装备的共鸣次数
function XEquipAgency:GetEquipResonanceCount(equipId)
    return self._Model:GetEquipResonanceCount(equipId)
end

--- @desc 通过templateId获取背包中或目标角色身上的装备
function XEquipAgency:GetEnableEquipIdsByTemplateId(templateId, targetCharacterId)
    return self._Model:GetEnableEquipIdsByTemplateId(templateId, targetCharacterId)
end

--- @desc 目标装备是否可用（未被其他角色装备）
function XEquipAgency:IsEquipActive(templateId, characterId)
    return self._Model:IsEquipActive(templateId, characterId)
end

--- @desc: 获取所有武器equipId
function XEquipAgency:GetWeaponIds()
    return self._Model:GetWeaponIds()
end

function XEquipAgency:GetWeaponCount()
    return self._Model:GetWeaponCount()
end

--- @desc: 获取符合当前角色使用类型的所有武器equipId
function XEquipAgency:GetCanUseWeaponIds(characterId)
    return self._Model:GetCanUseWeaponIds(characterId)
end

--- @desc: 获取符合当前武器使用角色的所有templateId
function XEquipAgency:GetWeaponUserTemplateIds(weaponTemplateIds)
    return self._Model:GetWeaponUserTemplateIds(weaponTemplateIds)
end

--- @desc: 获取所有意识
function XEquipAgency:GetAwarenessIds(characterType)
    return self._Model:GetAwarenessIds(characterType)
end

function XEquipAgency:GetAwarenessCount(characterType)
    return self._Model:GetAwarenessCount(characterType)
end

function XEquipAgency:GetCanDecomposeWeaponIds()
    return self._Model:GetCanDecomposeWeaponIds()
end

function XEquipAgency:GetCanDecomposeAwarenessIdsBySuitId(suitId)
    return self._Model:GetCanDecomposeAwarenessIdsBySuitId(suitId)
end

function XEquipAgency:GetSuitIdsByStars(starCheckList)
    return self._Model:GetSuitIdsByStars(starCheckList)
end

function XEquipAgency:ConstructAwarenessStarToSiteToSuitIdsDic(characterType, IsGift)
    return self._Model:ConstructAwarenessStarToSiteToSuitIdsDic(characterType, IsGift)
end 

function XEquipAgency:ConstructAwarenessSiteToEquipIdsDic(characterType, IsGift)
    return self._Model:ConstructAwarenessSiteToEquipIdsDic(characterType, IsGift)
end

function XEquipAgency:ConstructAwarenessSuitIdToEquipIdsDic(characterType, IsGift)
    return self._Model:ConstructAwarenessSuitIdToEquipIdsDic(characterType, IsGift)
end

function XEquipAgency:GetCanEatEquipIds(equipId)
    return self._Model:GetCanEatEquipIds(equipId)
end

function XEquipAgency:GetCanEatItemIds(equipId)
    return self._Model:GetCanEatItemIds(equipId)
end

function XEquipAgency:GetResonanceSkillNum(equipId)
    return self._Model:GetResonanceSkillNum(equipId)
end

function XEquipAgency:GetResonanceSkillNumByTemplateId(templateId)
    return self._Model:GetResonanceSkillNumByTemplateId(templateId)
end

function XEquipAgency:GetResonanceSkillInfo(equipId, pos)
    return self._Model:GetResonanceSkillInfo(equipId, pos)
end

-- 修改后的GuessResonanceType方法，支持通过skillId和equipId推断共鸣类型
function XEquipAgency:GuessResonanceType(skillId, equipTemplateId)
    -- 1. 先通过装备ID获取装备实例及品质信息
    if equipTemplateId then
        local weaponQuality = self:GetEquipQuality(equipTemplateId)
        -- 非6星武器直接返回属性共鸣类型
        if weaponQuality and weaponQuality <= XEnumConst.EQUIP.MIN_RESONANCE_EQUIP_STAR_COUNT then
            return XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB
        end
    else
        XLog.Warning(string.format("GuessResonanceType: 无效的equipId %d", equipTemplateId or 0))
    end
    
    -- 2. 按类型依次匹配技能配置（优先级：武器技能 > 属性 > 角色技能）
    local resonanceTypeList = XEnumConst.EQUIP.RESONANCE_TYPE
    
    for _, resonanceType in ipairs(resonanceTypeList) do
        local config = self:GetResonanceSkillInfoByType(resonanceType, skillId)
        if config then
            return resonanceType
        end
    end
    
    return XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL -- 默认返回武器技能类型
end

-- 新增辅助函数，复用类型匹配逻辑（与GetResonanceSkillInfoByType对应）
function XEquipAgency:GetResonanceSkillInfoByType(resonanceType, skillId)
    if resonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB then
        return XAttribConfigs.GetAttribGroupCfgById(skillId, true)
    elseif resonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL then
        return XMVCA.XCharacter:GetCharacterSkillPoolSkillInfo(skillId, true)
    elseif resonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL then
        return XMVCA.XEquip:GetConfigWeaponSkill(skillId, true)
    end
    return nil
end

function XEquipAgency:GetResonanceSkillList(equipId)
    local list = {}
    for i = 1, self:GetResonanceSkillNum(equipId) do
        local skillInfo = self:GetResonanceSkillInfo(equipId, i)
        if skillInfo then
            table.insert(list, skillInfo.Id)
        else
            table.insert(list, 0)
        end
    end
    return list
end

-- 下标对应slot，空的不存
function XEquipAgency:GetResonanceSkillDic(equipId)
    local dic = {}
    for i = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local skillInfo = self:GetResonanceSkillInfo(equipId, i)
        dic[i] = skillInfo and skillInfo.Id
    end
    return dic
end

-- 获取装备共鸣预览技能
function XEquipAgency:GetResonancePreviewSkillInfoList(equipId, characterId, slot)
    local skillInfoList = {}
    local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
    local equip = self._Model:GetEquip(equipId)
    local resonanceCfg = self._Model:GetConfigEquipResonance(equip.TemplateId)

    if characterId then
        if equip:IsWeapon() then
            local poolId = resonanceCfg.WeaponSkillPoolId[slot]
            local skillIds = self._Model:GetWeaponSkillPoolSkillIds(poolId, characterId)
            for _, skillId in ipairs(skillIds) do
                local skillInfo = XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL, skillId)
                table.insert(skillInfoList, skillInfo)
            end
        else
            local skillPoolId = resonanceCfg.CharacterSkillPoolId[slot]
            local skillInfos = XMVCA.XCharacter:GetCharacterSkillPoolSkillInfos(skillPoolId, characterId)
            for _, v in ipairs(skillInfos) do
                local skillInfo = XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL, v.SkillId)
                table.insert(skillInfoList, skillInfo)
            end
        end
    end

    -- 属性技能
    local attrPoolId = resonanceCfg.AttribPoolId[slot]
    if attrPoolId then
        local attrInfos = XAttribConfigs.GetAttribGroupTemplateByPoolId(attrPoolId)
        local attribIdDic = {} -- 过滤重复AttribId，五星武器的共鸣技能
        for _, v in ipairs(attrInfos) do
            if not attribIdDic[v.AttribId] then
                local skillInfo = XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB, v.Id)
                table.insert(skillInfoList, skillInfo)
                attribIdDic[v.AttribId] = true
            end
        end
    end

    return skillInfoList
end

function XEquipAgency:GetSuitQuality(suitId)
    return self._Model:GetSuitQuality(suitId)
end

-- 获取套装最大数量
function XEquipAgency:GetSuitMaxCnt(suitId)
    local suitCfg = self._Model:GetConfigEquipSuit(suitId)
    local maxCnt = 0
    for i, des in pairs(suitCfg.SkillDescription) do
        if des and i > maxCnt then
            maxCnt = i
        end
    end
    return maxCnt
end

-- 装备是否适配角色类型
function XEquipAgency:IsFitCharacterType(equipTemplateId, charType)
    local fitCharType = self:GetEquipCharacterType(equipTemplateId)
    return fitCharType == XEnumConst.EQUIP.USER_TYPE.ALL or fitCharType == charType
end


--- 获取意识列表
---@param suitId number 指定套装Id
function XEquipAgency:GetAwarenessList(characterId, site, suitId)
    local awarenessList = {}
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        -- 筛选非狗粮、意识类型、适配角色类型、适配套装id
        if self:GetEquipType(equip.TemplateId) ~= XEnumConst.EQUIP.EQUIP_TYPE.FOOD 
        and equip:IsAwareness(site) 
        and self:IsFitCharacterType(equip.TemplateId, charType) 
        and (suitId == 0 or suitId == self._Model:GetEquipSuitId(equip.TemplateId)) then
            table.insert(awarenessList, equip)
        end
    end

    -- 套装排序优先级
    local priorityDic = {}
    local suitPriorityCfg = self:GetConfigCharacterSuitPriority(characterId)
    if suitPriorityCfg then
        for index, suitType in ipairs(suitPriorityCfg.PriorityType) do
            priorityDic[suitType] = math.maxinteger - index
        end
    end

    -- 排序
    table.sort(awarenessList, function(a, b)
        -- 穿戴在当前角色身上的意识优先
        local isCurCharA = a.CharacterId == characterId
        local isCurCharB = b.CharacterId == characterId
        if isCurCharA ~= isCurCharB then
            return isCurCharA
        end

        -- 无角色穿戴优先
        local isNotWearingA = not a:IsWearing()
        local isNotWearingB = not b:IsWearing()
        if isNotWearingA ~= isNotWearingB then
            return isNotWearingA
        end

        -- 有任一共鸣技能与当前角色绑定优先
        local isBindCurCharA = a:IsResonanceBindCharacter(characterId)
        local isBindCurCharB = b:IsResonanceBindCharacter(characterId)
        if isBindCurCharA ~= isBindCurCharB then
            return isBindCurCharA
        end

        -- 未共鸣过优先
        local isNotResonanceA = not a:IsResonance()
        local isNotResonanceB = not b:IsResonance()
        if isNotResonanceA ~= isNotResonanceB then
            return isNotResonanceA
        end

        -- 意识等级高的优先
        if a.Level ~= b.Level then
            return a.Level > b.Level
        end

        local suitIdA = self._Model:GetEquipSuitId(a.TemplateId)
        local suitIdB = self._Model:GetEquipSuitId(b.TemplateId)
        -- 专属套装优先
        if suitPriorityCfg and suitPriorityCfg.ExclusiveSuitId ~= 0 then
            local isExclusiveA = suitPriorityCfg.ExclusiveSuitId == suitIdA
            local isExclusiveB = suitPriorityCfg.ExclusiveSuitId == suitIdB
            if isExclusiveA ~= isExclusiveB then
                return isExclusiveA
            end
        end

        -- 根据意识套装优先级排序
        local suitTypeA = self:GetEquipSuitSuitType(suitIdA)
        local suitTypeB = self:GetEquipSuitSuitType(suitIdB)
        local priorityA = priorityDic[suitTypeA] or 100000
        local priorityB = priorityDic[suitTypeB] or 100000
        if priorityA ~= priorityB then
            return priorityA > priorityB
        end

        -- 按照意识套装ID从大到小排序
        return suitIdA > suitIdB
    end)
    return awarenessList
end

--- 获取意识列表
---@param suitId number 指定套装Id
---@param xTeamPrefab XTeamPrefab
function XEquipAgency:GetAwarenessListForTeamPrefab(characterId, site, suitId, xTeamPrefab, posInTeam)
    local awarenessList = {}
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        -- 筛选非狗粮、意识类型、适配角色类型、适配套装id
        if self:GetEquipType(equip.TemplateId) ~= XEnumConst.EQUIP.EQUIP_TYPE.FOOD 
        and equip:IsAwareness(site) 
        and self:IsFitCharacterType(equip.TemplateId, charType) 
        and (suitId == 0 or suitId == self._Model:GetEquipSuitId(equip.TemplateId)) then
            table.insert(awarenessList, equip)
        end
    end

    -- 套装排序优先级
    local priorityDic = {}
    local suitPriorityCfg = self:GetConfigCharacterSuitPriority(characterId)
    if suitPriorityCfg then
        for index, suitType in ipairs(suitPriorityCfg.PriorityType) do
            priorityDic[suitType] = math.maxinteger - index
        end
    end

    -- 排序
    table.sort(awarenessList, function(a, b)
        -- 当前在队伍预设的优先
        if xTeamPrefab and posInTeam then
            local isCurInTeamPosA = xTeamPrefab:GetPosByEquipId(a.Id) == posInTeam
            local isCurInTeamPosB = xTeamPrefab:GetPosByEquipId(b.Id) == posInTeam
            if isCurInTeamPosA ~= isCurInTeamPosB then
                return isCurInTeamPosA
            end
        end

        -- 无角色穿戴优先
        local isNotWearingA = not a:IsWearing()
        local isNotWearingB = not b:IsWearing()
        if isNotWearingA ~= isNotWearingB then
            return isNotWearingA
        end

        -- 有任一共鸣技能与当前角色绑定优先
        local isBindCurCharA = a:IsResonanceBindCharacter(characterId)
        local isBindCurCharB = b:IsResonanceBindCharacter(characterId)
        if isBindCurCharA ~= isBindCurCharB then
            return isBindCurCharA
        end

        -- 未共鸣过优先
        local isNotResonanceA = not a:IsResonance()
        local isNotResonanceB = not b:IsResonance()
        if isNotResonanceA ~= isNotResonanceB then
            return isNotResonanceA
        end

        -- 意识等级高的优先
        if a.Level ~= b.Level then
            return a.Level > b.Level
        end

        local suitIdA = self._Model:GetEquipSuitId(a.TemplateId)
        local suitIdB = self._Model:GetEquipSuitId(b.TemplateId)
        -- 专属套装优先
        if suitPriorityCfg and suitPriorityCfg.ExclusiveSuitId ~= 0 then
            local isExclusiveA = suitPriorityCfg.ExclusiveSuitId == suitIdA
            local isExclusiveB = suitPriorityCfg.ExclusiveSuitId == suitIdB
            if isExclusiveA ~= isExclusiveB then
                return isExclusiveA
            end
        end

        -- 根据意识套装优先级排序
        local suitTypeA = self:GetEquipSuitSuitType(suitIdA)
        local suitTypeB = self:GetEquipSuitSuitType(suitIdB)
        local priorityA = priorityDic[suitTypeA] or 100000
        local priorityB = priorityDic[suitTypeB] or 100000
        if priorityA ~= priorityB then
            return priorityA > priorityB
        end

        -- 按照意识套装ID从大到小排序
        return suitIdA > suitIdB
    end)
    return awarenessList
end

-- 获取意识套装列表，筛选适配角色 and 统计已有套装数量
function XEquipAgency:GetSuitInfoList(characterId, site)
    local suitInfoDic = {}
    local suitInfoList = {}
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        -- 筛选意识类型、适配角色类型
        if equip:IsAwareness(site) and self:IsFitCharacterType(equip.TemplateId, charType) then
            -- 筛选suitType不为0
            local suitId = self._Model:GetEquipSuitId(equip.TemplateId)
            local suitType = self:GetEquipSuitSuitType(suitId)
            if suitType ~= 0 then
                local suitInfo = suitInfoDic[suitId]
                if not suitInfo then
                    suitInfo = { SuitId = suitId, Count = 0}
                    suitInfoDic[suitId] = suitInfo
                    table.insert(suitInfoList, suitInfo)
                end
                suitInfo.Count = suitInfo.Count + 1
            end
        end
    end

    return suitInfoList
end

function XEquipAgency:GetConfigCharacterSuitPriority(id)
    return self._Model:GetConfigCharacterSuitPriority(id)
end

function XEquipAgency:GetSuitIdsByCharacterType(charType, minQuality, isFilterType0, isOverrun)
    return self._Model:GetSuitIdsByCharacterType(charType, minQuality, isFilterType0, isOverrun)
end

function XEquipAgency:GetWeaponResonanceSkillInfoBySkillId(equipId, pos)
    return self._Model:GetWeaponResonanceSkillInfoBySkillId(equipId, pos)
end

function XEquipAgency:GetResonanceSkillInfoByEquipData(equip, pos)
    return self._Model:GetResonanceSkillInfoByEquipData(equip, pos)
end

function XEquipAgency:GetResonanceBindCharacterId(equipId, pos)
    return self._Model:GetResonanceBindCharacterId(equipId, pos)
end

function XEquipAgency:GetResonanceBindCharacterIdByEquipData(equip, pos)
    return self._Model:GetResonanceBindCharacterIdByEquipData(equip, pos)
end

function XEquipAgency:GetEquipAddExp(equipId, count)
    return self._Model:GetEquipAddExp(equipId, count)
end

--- 根据意识id 获得对应的公约加成描述字符串
function XEquipAgency:GetEquipAwarenessOccupyHarmDesc(equipId, forceNum)
    return self._Model:GetEquipAwarenessOccupyHarmDesc(equipId, forceNum)
end

--- 狗粮
function XEquipAgency:IsEquipRecomendedToBeEat(strengthenEquipId, equipId, doNotLimitStar)
    return self._Model:IsEquipRecomendedToBeEat(strengthenEquipId, equipId, doNotLimitStar)
end

function XEquipAgency:CanResonance(equipId)
    return self._Model:CanResonance(equipId)
end

function XEquipAgency:CanResonanceByTemplateId(templateId)
    return self._Model:CanResonanceByTemplateId(templateId)
end

function XEquipAgency:CanResonanceBindCharacter(equipId)
    return self._Model:CanResonanceBindCharacter(equipId)
end

function XEquipAgency:CheckEquipPosResonanced(equipId, pos)
    return self._Model:CheckEquipPosResonanced(equipId, pos)
end

--装备是否共鸣过
function XEquipAgency:IsEquipResonanced(equipId)
    return self._Model:IsEquipResonanced(equipId)
end

function XEquipAgency:CheckEquipStarCanAwake(equipId)
    return self._Model:CheckEquipStarCanAwake(equipId)
end

function XEquipAgency:CheckEquipCanAwake(equipId, pos)
    return self._Model:CheckEquipCanAwake(equipId, pos)
end

function XEquipAgency:GetEquipAwakeNum(equipId)
    return self._Model:GetEquipAwakeNum(equipId)
end

function XEquipAgency:IsEquipPosAwaken(equipId, pos)
    return self._Model:IsEquipPosAwaken(equipId, pos)
end

function XEquipAgency:IsFiveStar(equipId)
    return self._Model:IsFiveStar(equipId)
end

function XEquipAgency:IsCharacterTypeFit(equipId, characterType)
    return self._Model:IsCharacterTypeFit(equipId, characterType)
end

function XEquipAgency:IsTypeEqual(equipId, equipType)
    return self._Model:IsTypeEqual(equipId, equipType)
end
---------------------------------------- #endregion 装备 ----------------------------------------


---------------------------------------- #region 意识组合 ----------------------------------------
function XEquipAgency:GetSuitPrefabIndexList(characterType)
    return self._Model:GetSuitPrefabIndexList(characterType)
end

function XEquipAgency:GetSuitPrefabInfo(index)
    return self._Model:GetSuitPrefabInfo(index)
end

function XEquipAgency:GetUnSavedSuitPrefabInfo(characterId)
    return self._Model:GetUnSavedSuitPrefabInfo(characterId)
end

function XEquipAgency:IsInSuitPrefab(equipId)
    return self._Model:IsInSuitPrefab(equipId)
end
---------------------------------------- #endregion 意识组合 ----------------------------------------


---------------------------------------- #region 装备回收 ----------------------------------------
function XEquipAgency:GetRecycleStarCheckDic()
    return self._Model:GetRecycleStarCheckDic()
end

function XEquipAgency:GetRecycleSettingDays()
    return self._Model:GetRecycleSettingDays()
end

function XEquipAgency:CheckRecycleInfoDifferent(starCheckDic, days)
    return self._Model:CheckRecycleInfoDifferent(starCheckDic, days)
end

--- 装备是否待回收
function XEquipAgency:IsRecycle(equipId)
    return self._Model:IsRecycle(equipId)
end

--- 装备是否可回收
function XEquipAgency:IsEquipCanRecycle(equipId)
    return self._Model:IsEquipCanRecycle(equipId)
end

function XEquipAgency:GetCanRecycleWeaponIds()
    return self._Model:GetCanRecycleWeaponIds()
end

function XEquipAgency:GetCanRecycleAwarenessIds(suitId)
    return self._Model:GetCanRecycleAwarenessIds(suitId)
end

function XEquipAgency:GetRecycleRewards(equipIds)
    return self._Model:GetRecycleRewards(equipIds)
end
---------------------------------------- #endregion 装备回收 ----------------------------------------
--============================================================== #endregion 协议数据 ==============================================================




--============================================================== #region Config ==============================================================
---------------------------------------- #region Equip ----------------------------------------
--- 获取装备配置表
--- @param templateId number 装备配置表Id
---@return XTableEquip
function XEquipAgency:GetConfigEquip(templateId)
    return self._Model:GetConfigEquip(templateId)
end

--- 检查id是否为装备
--- @param templateId number 装备配置表Id
function XEquipAgency:CheckTemplateIdIsEquip(templateId)
    return self._Model:CheckTemplateIdIsEquip(templateId)
end

--- 获取装备名称
--- @param templateId number 装备配置表Id
function XEquipAgency:GetEquipName(templateId)
    return self._Model:GetEquipName(templateId)
end

--- 获取装备部位
--- @param templateId number 装备配置表Id
function XEquipAgency:GetEquipSite(templateId)
    return self._Model:GetEquipSite(templateId)
end

function XEquipAgency:GetEquipSiteByEquipId(equipId)
    return self._Model:GetEquipSiteByEquipId(equipId)
end

function XEquipAgency:GetEquipSiteByEquip(equip)
    return self._Model:GetEquipSiteByEquip(equip)
end

function XEquipAgency:GetEquipType(templateId)
    return self._Model:GetEquipType(templateId)
end

function XEquipAgency:GetEquipQuality(templateId)
    return self._Model:GetEquipQuality(templateId)
end

--- 获取装备星级
--- @param templateId number 装备配置表Id
function XEquipAgency:GetEquipStar(templateId)
    return self._Model:GetEquipStar(templateId)
end

function XEquipAgency:GetEquipWeaponSkillId(templateId)
    return self._Model:GetEquipWeaponSkillId(templateId)
end

function XEquipAgency:GetEquipWeaponSkillInfo(templateId)
    return self._Model:GetEquipWeaponSkillInfo(templateId)
end

function XEquipAgency:GetEquipPriority(templateId)
    return self._Model:GetEquipPriority(templateId)
end

--专属角色Id
function XEquipAgency:GetEquipSpecialCharacterIdByEquipId(equipId)
    return self._Model:GetEquipSpecialCharacterIdByEquipId(equipId)
end

function XEquipAgency:GetEquipSuitIdByEquipId(equipId)
    return self._Model:GetEquipSuitIdByEquipId(equipId)
end

function XEquipAgency:GetEquipSuitId(templateId)
    return self._Model:GetEquipSuitId(templateId)
end

function XEquipAgency:GetEquipCharacterType(templateId)
    return self._Model:GetEquipCharacterType(templateId)
end

function XEquipAgency:GetEquipDescription(templateId)
    return self._Model:GetEquipDescription(templateId)
end

function XEquipAgency:GetEquipNeedFirstShow(templateId)
    return self._Model:GetEquipNeedFirstShow(templateId)
end

function XEquipAgency:GetEquipRecommendCharacterId(id)
    return self._Model:GetConfigEquip(id).RecommendCharacterId
end

--- 装备是否是武器
--- @param templateId number 装备配置表Id
function XEquipAgency:IsEquipWeapon(templateId)
    return self._Model:IsEquipWeapon(templateId)
end

--- 装备是否是意识
--- @param templateId number 装备配置表Id
--- @param site number 装备部位Id
function XEquipAgency:IsEquipAwareness(templateId, site)
    return self._Model:IsEquipAwareness(templateId, site)
end

--- 获取装备的品质图
function XEquipAgency:GetEquipQualityPath(templateId)
    return self._Model:GetEquipQualityPath(templateId)
end

--- 获取装备的背景图
function XEquipAgency:GetEquipBgPath(templateId)
    return self._Model:GetEquipBgPath(templateId)
end

function XEquipAgency:GetEquipClassifyByTemplateId(templateId)
    return self._Model:GetEquipClassifyByTemplateId(templateId)
end

function XEquipAgency:GetEquipClassifyByEquipId(equipId)
    return self._Model:GetEquipClassifyByEquipId(equipId)
end

---@return XEquip
function XEquipAgency:IsClassifyEqualByTemplateId(templateId, classify)
    return self._Model:IsClassifyEqualByTemplateId(templateId, classify)
end

function XEquipAgency:IsClassifyEqualByEquipId(equipId, classify)
    return self._Model:IsClassifyEqualByEquipId(equipId, classify)
end
---------------------------------------- #endregion Equip ----------------------------------------

---------------------------------------- #region EquipBreakthrough ----------------------------------------
-- 获取装备突破次数对应的配置表
function XEquipAgency:GetEquipBreakthroughCfg(templateId, times)
    return self._Model:GetEquipBreakthroughCfg(templateId, times)
end

function XEquipAgency:GetEquipBreakthroughCfgByEquipId(equipId)
    return self._Model:GetEquipBreakthroughCfgByEquipId(equipId)
end

function XEquipAgency:GetEquipNextBreakthroughCfgByEquipId(equipId)
    return self._Model:GetEquipNextBreakthroughCfgByEquipId(equipId)
end

--- 获取指定突破次数下最大等级限制
function XEquipAgency:GetEquipBreakthroughLevelLimit(templateId, times)
    return self._Model:GetEquipBreakthroughLevelLimit(templateId, times)
end

function XEquipAgency:GetEquipBreakthroughLevelLimitByEquipId(equipId)
    return self._Model:GetEquipBreakthroughLevelLimitByEquipId(equipId)
end

function XEquipAgency:GetEquipBreakthroughExp(equipId)
    return self._Model:GetEquipBreakthroughExp(equipId)
end

-- 获取装备的最高突破次数
--- @return number times 最高突破数
--- @return number levelLimit 最高等级
function XEquipAgency:GetEquipMaxBreakthrough(templateId)
    return self._Model:GetEquipMaxBreakthrough(templateId)
end

--- 获取装备突破次数对应图片
function XEquipAgency:GetEquipBreakThroughIcon(breakthroughTimes)
    return self._Model:GetEquipBreakThroughIcon(breakthroughTimes)
end

function XEquipAgency:GetEquipBreakThroughSmallIcon(breakthroughTimes)
    return self._Model:GetEquipBreakThroughSmallIcon(breakthroughTimes)
end

function XEquipAgency:GetEquipBreakThroughSmallIconByEquipId(equipId)
    return self._Model:GetEquipBreakThroughSmallIconByEquipId(equipId)
end

function XEquipAgency:GetEquipBreakThroughBigIcon(breakthroughTimes)
    return self._Model:GetEquipBreakThroughBigIcon(breakthroughTimes)
end
---------------------------------------- #endregion EquipBreakthrough ----------------------------------------

---------------------------------------- #region EquipSuit ----------------------------------------
--- 获取装备配置表
--- @param id number 套装Id
--- @return XTableEquipSuit
function XEquipAgency:GetConfigEquipSuit(id)
    return self._Model:GetConfigEquipSuit(id)
end

function XEquipAgency:GetEquipSuitIconPath(suitId)
    return self._Model:GetSuitIconPath(suitId)
end

function XEquipAgency:GetEquipSuitWaferBagPath(suitId)
    return self._Model:GetSuitWaferBagPath(suitId)
end

function XEquipAgency:GetEquipSuitClearIconPath(suitId)
    return self._Model:GetSuitClearIconPath(suitId)
end

function XEquipAgency:GetSuitName(suitId)
    return self._Model:GetSuitName(suitId)
end

function XEquipAgency:GetSuitDescription(suitId)
    return self._Model:GetSuitDescription(suitId)
end

function XEquipAgency:GetEquipSuitSkillEffect(id)
    return self._Model:GetConfigEquipSuit(id).SkillEffect
end

function XEquipAgency:GetEquipSuitSkillDescription(suitId)
    return self._Model:GetEquipSuitSkillDescription(suitId)
end

function XEquipAgency:GetEquipSuitSuitType(id)
    return self._Model:GetConfigEquipSuit(id).SuitType
end

function XEquipAgency:GetEquipSuitEquipType(id)
    return self._Model:GetConfigEquipSuit(id).EquipType
end

function XEquipAgency:GetEquipSuitRecomChar(id)
    return self._Model:GetConfigEquipSuit(id).RecommendCharacterId
end
--- 获取套装对应装备Id字典，key是装备的site位置
function XEquipAgency:GetSuitEquipIds(suitId)
    return self._Model:GetSuitEquipIds(suitId)
end

--- 获取套装对应装备Id列表
function XEquipAgency:GetSuitEquipIdList(suitId)
    return self._Model:GetSuitEquipIdList(suitId)
end

--- 获取套装内的一件装备Id
function XEquipAgency:GetSuitOneEquipId(suitId)
    return self._Model:GetSuitOneEquipId(suitId)
end

function XEquipAgency:GetSuitEquipCount(suitId)
    return self._Model:GetSuitEquipCount(suitId)
end

--- 获取套装对应星级
function XEquipAgency:GetSuitStar(suitId)
    return self._Model:GetSuitStar(suitId)
end

function XEquipAgency:GetSuitQualityIcon(suitId)
    return self._Model:GetSuitQualityIcon(suitId)
end

function XEquipAgency:GetSuitCharacterType(suitId)
    return self._Model:GetSuitCharacterType(suitId)
end

--- 获取最大套装数量
function XEquipAgency:GetMaxSuitCount()
    return self._Model:GetMaxSuitCount()
end

function XEquipAgency:IsDefaultSuitId(suitId)
    return self._Model:IsDefaultSuitId(suitId)
end

function XEquipAgency:GetDefaultSuitIdCount()
    return self._Model:GetDefaultSuitIdCount()
end
---------------------------------------- #endregion EquipSuit ----------------------------------------

function XEquipAgency:GetConfigEquipSuitEffect(id)
    return self._Model:GetConfigEquipSuitEffect(id)
end


---------------------------------------- #region EquipDecompose ----------------------------------------
--- 获取装备分解配置表
function XEquipAgency:GetEquipDecomposeCfg(templateId, breakthroughTimes)
    return self._Model:GetEquipDecomposeCfg(templateId, breakthroughTimes)
end

function XEquipAgency:GetDecomposeRewardEquipCount(equipId)
    return self._Model:GetDecomposeRewardEquipCount(equipId)
end

function XEquipAgency:GetDecomposeRewards(equipIds)
    return self._Model:GetDecomposeRewards(equipIds)
end
---------------------------------------- #endregion EquipDecompose ----------------------------------------


---------------------------------------- #region EatEquipCost ----------------------------------------
-- 获取强化吃装备消耗螺母
function XEquipAgency:GetEatEquipCostMoney(site, star)
    return self._Model:GetEatEquipCostMoney(site, star)
end
---------------------------------------- #endregion EatEquipCost ----------------------------------------


-- 获取装备共鸣配置
function XEquipAgency:GetConfigEquipResonance(templateId)
    return self._Model:GetConfigEquipResonance(templateId)
end

function XEquipAgency:GetResoanceIconPath(isAwaken)
    return self._Model:GetResoanceIconPath(isAwaken)
end


---------------------------------------- #region WeaponSkill ----------------------------------------
function XEquipAgency:GetConfigWeaponSkill(id, notTipError)
    return self._Model:GetConfigWeaponSkill(id, notTipError)
end

function XEquipAgency:GetWeaponSkillAbility(id)
    return self._Model:GetWeaponSkillAbility(id)
end
---------------------------------------- #endregion WeaponSkill ----------------------------------------


function XEquipAgency:GetWeaponSkillPoolSkillIds(poolId, characterId)
    return self._Model:GetWeaponSkillPoolSkillIds(poolId, characterId)
end


---------------------------------------- #region EquipAwake ----------------------------------------
function XEquipAgency:GetConfigEquipAwake(id)
    return self._Model:GetConfigEquipAwake(id)
end

function XEquipAgency:GetEquipAwakeCfgByEquipId(equipId)
    return self._Model:GetEquipAwakeCfgByEquipId(equipId)
end

function XEquipAgency:GetEquipAwakeSkillDesList(templateId, pos)
    return self._Model:GetEquipAwakeSkillDesList(templateId, pos)
end

-- 获取觉醒道具能够生效的意识列表
function XEquipAgency:GetAwakeItemApplicationScope(itemId)
    return self._Model:GetAwakeItemApplicationScope(itemId)
end

function XEquipAgency:GetAwakeSkillDesList(equipId, pos)
    return self._Model:GetAwakeSkillDesList(equipId, pos)
end

function XEquipAgency:GetAwakeSkillDesListByEquipData(equip, pos)
    return self._Model:GetAwakeSkillDesListByEquipData(equip, pos)
end
---------------------------------------- #endregion EquipAwake ----------------------------------------


---------------------------------------- #region EquipRes ----------------------------------------
--- 获取装备的资源配置
function XEquipAgency:GetEquipResConfig(templateId, breakthroughTimes)
    return self._Model:GetEquipResConfig(templateId, breakthroughTimes)
end

--- 获取立绘
function XEquipAgency:GetEquipLiHuiPath(templateId, breakthroughTimes)
    return self._Model:GetEquipLiHuiPath(templateId, breakthroughTimes)
end

--- 获取绘画者名称
function XEquipAgency:GetEquipPainterName(templateId, breakthroughTimes)
    return self._Model:GetEquipPainterName(templateId, breakthroughTimes)
end

--- 获取装备大图标
function XEquipAgency:GetEquipBigIconPath(templateId)
    return self._Model:GetEquipBigIconPath(templateId)
end

--- 获取装备在背包中显示图标
function XEquipAgency:GetEquipIconPath(templateId, breakthroughTimes)
    return self._Model:GetEquipIconPath(templateId, breakthroughTimes)
end

--- 获取武器模型Id
function XEquipAgency:GetWeaponResonanceModelId(case, templateId, resonanceCount)
    return self._Model:GetWeaponResonanceModelId(case, templateId, resonanceCount)
end

function XEquipAgency:GetWeaponModelCfgByEquipId(equipId, uiName)
    return self._Model:GetWeaponModelCfgByEquipId(equipId, uiName)
end

--- @desc: 获取装备模型配置列表
function XEquipAgency:GetWeaponModelCfg(templateId, uiName, breakthroughTimes, resonanceCount)
    return self._Model:GetWeaponModelCfg(templateId, uiName, breakthroughTimes, resonanceCount)
end

--- @desc: 获取武器模型id列表
function XEquipAgency:GetEquipModelIdListByFight(fightNpcData)
    return self._Model:GetEquipModelIdListByFight(fightNpcData)
end

--- @desc: 通过角色id获取武器模型名字列表
function XEquipAgency:GetEquipModelIdListByCharacterId(characterId, isDefault, weaponFashionId)
    return self._Model:GetEquipModelIdListByCharacterId(characterId, isDefault, weaponFashionId)
end

---------------------------------------- #endregion EquipRes ----------------------------------------


---------------------------------------- #region EquipModel ----------------------------------------

function XEquipAgency:GetWeaponEffectsByModelId(modelId)
    return self._Model:GetWeaponEffectsByModelId(modelId)
end

---@return XTableEquipModel
function XEquipAgency:GetConfigEquipModel(id)
    return self._Model:GetConfigEquipModel(id)
end

function XEquipAgency:GetEquipModelName(modelTransId, usage)
    return self._Model:GetEquipModelName(modelTransId, usage)
end

function XEquipAgency:GetEquipLowModelName(modelTransId, usage)
    return self._Model:GetEquipLowModelName(modelTransId, usage)
end

function XEquipAgency:GetEquipAnimController(modelTransId, usage)
    return self._Model:GetEquipAnimController(modelTransId, usage)
end

function XEquipAgency:GetEquipUiAnimStateName(modelTransId, usage)
    return self._Model:GetEquipUiAnimStateName(modelTransId, usage)
end

function XEquipAgency:GetEquipUiAnimCueId(modelTransId, usage)
    return self._Model:GetEquipUiAnimCueId(modelTransId, usage)
end

function XEquipAgency:GetEquipUiAnimDelay(modelTransId, usage)
    return self._Model:GetEquipUiAnimDelay(modelTransId, usage)
end

function XEquipAgency:GetEquipUiAutoRotateDelay(modelTransId, usage)
    return self._Model:GetEquipUiAutoRotateDelay(modelTransId, usage)
end

function XEquipAgency:GetWeaponResonanceEffectDelayByEquipId(equipId, resonanceCount)
    return self._Model:GetWeaponResonanceEffectDelayByEquipId(equipId, resonanceCount)
end

--- 获取一个武器所有的不同的模型列表
function XEquipAgency:GetWeaponModelCfgList(templateId, uiName, breakthroughTimes)
    return self._Model:GetWeaponModelCfgList(templateId, uiName, breakthroughTimes)
end

--- 获取装备模型id列表
function XEquipAgency:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
    return self._Model:GetWeaponEquipModelIdListByEquip(equip, weaponFashionId)
end

--- 获取装备模型id列表
function XEquipAgency:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthroughTimes)
    return self._Model:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthroughTimes)
end

---获取武器哈希
function XEquipAgency:GetEquipModelHash(modelTransId, usage)
    return self._Model:GetEquipModelHash(modelTransId, usage)
end

---------------------------------------- #endregion EquipModel ----------------------------------------


---------------------------------------- #region EquipModelTransform ----------------------------------------
function XEquipAgency:GetConfigEquipModelTransform(id)
    return self._Model:GetConfigEquipModelTransform(id)
end

--- 返回武器模型和位置配置（双枪只返回一把）
function XEquipAgency:GetEquipModelTransformCfg(templateId, uiName, resonanceCount, modelTransId, equipType)
    return self._Model:GetEquipModelTransformCfg(templateId, uiName, resonanceCount, modelTransId, equipType)
end
---------------------------------------- #endregion EquipModelTransform ----------------------------------------


---------------------------------------- #region EquipSkipId ----------------------------------------
function XEquipAgency:GetEquipSkipIds(templateId)
    local equipType = self:GetEquipClassifyByTemplateId(templateId)
    return self._Model:GetEquipSkipIds(equipType)
end
---------------------------------------- #endregion EquipSkipId ----------------------------------------


---------------------------------------- #region EquipAnim ----------------------------------------
function XEquipAgency:GetEquipAnimParams(id)
    return self._Model:GetEquipAnimParams(id)
end
---------------------------------------- #endregion EquipAnim ----------------------------------------


---------------------------------------- #region EquipModelShow ----------------------------------------
function XEquipAgency:GetEquipModelShowHideNodeName(modelId, UiName)
    return self._Model:GetEquipModelShowHideNodeName(modelId, UiName)
end
---------------------------------------- #endregion EquipModelShow ----------------------------------------


---------------------------------------- #region EquipResByFool ----------------------------------------
-- 获取愚人节装备资源
function XEquipAgency:GetConfigEquipResByFool(templateId)
    return self._Model:GetConfigEquipResByFool(templateId)
end

function XEquipAgency:GetFoolWeaponResonanceModelId(case, templateId, resonanceCount)
    return self._Model:GetFoolWeaponResonanceModelId(case, templateId, resonanceCount)
end
---------------------------------------- #endregion EquipResByFool ----------------------------------------



---------------------------------------- #region WeaponOverrun ----------------------------------------
-- 获取武器对应所有超限配置
function XEquipAgency:GetWeaponOverrunCfgsByTemplateId(templateId)
    return self._Model:GetWeaponOverrunCfgsByTemplateId(templateId)
end

-- 通过配置表Id判断能否超限
function XEquipAgency:CanOverrunByTemplateId(templateId)
    return self._Model:CanOverrunByTemplateId(templateId)
end

-- 获取武器超限意识绑定的配置表
function XEquipAgency:GetWeaponOverrunSuitCfgByTemplateId(templateId)
    return self._Model:GetWeaponOverrunSuitCfgByTemplateId(templateId)
end

--- 获取武器等级对应的UI显示
function XEquipAgency:GetConfigWeaponDeregulateUI(lv)
    return self._Model:GetConfigWeaponDeregulateUI(lv)
end
---------------------------------------- #endregion WeaponOverrun ----------------------------------------


---------------------------------------- #region LevelUpTemplate ----------------------------------------
function XEquipAgency:GetLevelUpCfg(templateId, times, level)
    return self._Model:GetLevelUpCfg(templateId, times, level)
end
---------------------------------------- #endregion LevelUpTemplate ----------------------------------------


---------------------------------------- #region EquipSignboard ----------------------------------------
function XEquipAgency:GetEquipAnimControllerBySignboard(characterId, fashionId, actionId)
    return self._Model:GetEquipAnimControllerBySignboard(characterId, fashionId, actionId)
end

function XEquipAgency:CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
    return self._Model:CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
end
---------------------------------------- #endregion EquipSignboard ----------------------------------------


---------------------------------------- #region EquipAnimReset -----------------------------------------
function XEquipAgency:GetEquipAnimIsReset(modelId)
    return self._Model:GetEquipAnimIsReset(modelId)
end
---------------------------------------- #endregion EquipAnimReset ----------------------------------------


function XEquipAgency:GetWeaponTypeIconPath(templateId)
    return self._Model:GetWeaponTypeIconPath(templateId)
end

function XEquipAgency:GetMaxWeaponCount()
    return self._Model:GetMaxWeaponCount()
end

function XEquipAgency:GetMaxAwarenessCount()
    return self._Model:GetMaxAwarenessCount()
end

function XEquipAgency:GetEquipExpInheritPercent()
    return self._Model:GetEquipExpInheritPercent()
end

function XEquipAgency:GetEquipRecycleItemPercent()
    return self._Model:GetEquipRecycleItemPercent()
end

function XEquipAgency:GetMinResonanceBindStar()
    return self._Model:GetMinResonanceBindStar()
end

function XEquipAgency:GetMinAwakeStar()
    return self._Model:GetMinAwakeStar()
end

function XEquipAgency:GetSuitPrefabNumMax()
    return self._Model:GetSuitPrefabNumMax()
end

function XEquipAgency:GetEquipSuitCharacterPrefabMaxNum()
    return self._Model:GetEquipSuitCharacterPrefabMaxNum()
end
--============================================================== #endregion Config ==============================================================




--============================================================== #region Open UI ==============================================================

-- 初始化成员界面的装备面板
---@return XUiPanelEquipV2P6
function XEquipAgency:InitPanelEquipV2P6(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("PanelEquipV2P6")
    local equipUi = parentTransform:LoadPrefab(path)
    -- local cacheComp = parentTransform:GetComponent(typeof(CS.XUiCachePrefab))
    -- local equipUi = CS.UnityEngine.Object.Instantiate(cacheComp.go, parentTransform)
    local XUiPanelEquipV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiPanelEquipV2P6")
    local panelEquipV2P6 = XUiPanelEquipV2P6.New(equipUi, parentUiProxy, ...)
    return panelEquipV2P6
end

-- 初始化成员界面的预设装备面板
---@return XUiPanelEquipV2P6
function XEquipAgency:InitPanelEquipTeamPrefab(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("PanelEquipTeamPrefab")
    local equipUi = parentTransform:LoadPrefab(path)
    local XUiPanelTeamPrefabEquip = require("XUi/XUiTeamPrefab/Grid/XUiPanelTeamPrefabEquip")
    local panelEquip = XUiPanelTeamPrefabEquip.New(equipUi, parentUiProxy, ...)
    return panelEquip
end

---@return XUiPanelCharInfoWithEquip
function XEquipAgency:InitPanelCharInfoWithEquip(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("PanelCharInfoWithEquip")
    local equipUi = parentTransform:LoadPrefab(path, true, false)
    local XUiPanelCharInfoWithEquip = require("XUi/XUiCharacterV2P6/Grid/XUiPanelCharInfoWithEquip")
    local panel = XUiPanelCharInfoWithEquip.New(equipUi, parentUiProxy, ...)
    return panel
end

---@return XUiPanelCharInfoWithEquipOther
function XEquipAgency:InitPanelCharInfoWithEquipOther(parentTransform, parentUiProxy, ...)
    local path = CS.XGame.ClientConfig:GetString("PanelCharInfoWithEquip")
    local equipUi = parentTransform:LoadPrefab(path, true, false)
    local XUiPanelCharInfoWithEquipOther = require("XUi/XUiCharacterV2P6/Grid/XUiPanelCharInfoWithEquipOther")
    local panel = XUiPanelCharInfoWithEquipOther.New(equipUi, parentUiProxy, ...)
    return panel
end

-- 打开详情界面
function XEquipAgency:OpenUiEquipDetail(equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, isShowExtendPanel)
    XLuaUiManager.Open("UiEquipDetailChildV2P6", equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, isShowExtendPanel)
end

-- 打开武器替换界面
function XEquipAgency:OpenUiEquipReplace(characterId, closecallback, notShowStrengthenBtn)
    XLuaUiManager.Open("UiEquipReplaceV2P6", characterId, closecallback, notShowStrengthenBtn)
end

-- 打开意识替换界面
function XEquipAgency:OpenUiEquipAwarenessReplace(characterId, equipSite, notShowStrengthenBtn)
    XLuaUiManager.Open("UiEquipAwarenessReplaceV2P6", characterId, equipSite, notShowStrengthenBtn)
end

-- 打开预览界面
function XEquipAgency:OpenUiEquipPreview(equipTemplateId)
    XLuaUiManager.Open("UiEquipPreviewV2P6", equipTemplateId)
end

-- 打开装备意识界面
function XEquipAgency:OpenUiEquipAwareness(characterId)
    XLuaUiManager.Open("UiEquipAwarenessV2P6", characterId)
end

-- 打开操作成功提示界面
function XEquipAgency:TipEquipOperation(equipId, changeTxt, closeCb, setMask)
    local uiName = "UiEquipCanBreakthroughTip"
    if XLuaUiManager.IsUiShow(uiName) then
        XLuaUiManager.Remove(uiName)
    end
    XLuaUiManager.Open(uiName, equipId, changeTxt, closeCb, setMask)
end

--============================================================== #endregion Open UI ==============================================================




--============================================================== #region 其他 ==============================================================
---------------------------------------- #region 超上限拦截检测 ----------------------------------------
--- 武器意识拦截检测
function XEquipAgency:CheckBoxOverLimitOfDraw()
    return self._Model:CheckBoxOverLimitOfDraw()
end

--- 意识拦截检测
function XEquipAgency:CheckBoxOverLimitOfGetAwareness()
    return self._Model:CheckBoxOverLimitOfGetAwareness()
end

--- 武器意识拦截检测
function XEquipAgency:GetMaxCountOfBoxOverLimit(EquipId, MaxCount, Count)
    return self._Model:GetMaxCountOfBoxOverLimit(EquipId, MaxCount, Count)
end

--- 武器意识拦截检测
function XEquipAgency:ShowBoxOverLimitText()
    return self._Model:ShowBoxOverLimitText()
end

function XEquipAgency:CheckMaxCount(equipType, count)
    return self._Model:CheckMaxCount(equipType, count)
end

function XEquipAgency:CheckBagCount(count, equipType)
    return self._Model:CheckBagCount(count, equipType)
end
---------------------------------------- #endregion 超上限拦截检测 ----------------------------------------


---------------------------------------- #region 排序 ----------------------------------------
function XEquipAgency:SortEquipIdListByPriorType(equipIdList, priorSortType)
    return self._Model:SortEquipIdListByPriorType(equipIdList, priorSortType)
end
---------------------------------------- #endregion 超上限拦截检测 ----------------------------------------


---------------------------------------- #region 战斗力 ----------------------------------------
function XEquipAgency:GetCharacterEquipsSkillAbility(characterId)
    return self._Model:GetCharacterEquipsSkillAbility(characterId)
end

function XEquipAgency:GetEquipSkillAbilityOther(character, equipList)
    return self._Model:GetEquipSkillAbilityOther(character, equipList)
end

--- 计算装备战斗力（不包含角色共鸣相关）
function XEquipAgency:GetEquipAbility(characterId)
    return self._Model:GetEquipAbility(characterId)
end
---------------------------------------- #endregion 战斗力 ----------------------------------------


---------------------------------------- #region 属性 ----------------------------------------
function XEquipAgency:GetEquipAttrMapByEquipData(equip)
    return self._Model:GetEquipAttrMapByEquipData(equip)
end

function XEquipAgency:GetTemplateEquipAttrMap(templateId, preLevel)
    return self._Model:GetTemplateEquipAttrMap(templateId, preLevel)
end

--构造装备属性字典
function XEquipAgency:ConstructTemplateEquipAttrMap(templateId, breakthroughTimes, level)
    return self._Model:ConstructTemplateEquipAttrMap(templateId, breakthroughTimes, level)
end

--构造装备提升属性字典
function XEquipAgency:ConstructTemplateEquipPromotedAttrMap(templateId, breakthroughTimes)
    return self._Model:ConstructTemplateEquipPromotedAttrMap(templateId, breakthroughTimes)
end

function XEquipAgency:GetAwarenessMergeAttrMap(equipIds)
    return self._Model:GetAwarenessMergeAttrMap(equipIds)
end
---------------------------------------- #endregion 属性 ----------------------------------------


---------------------------------------- #region 意识套装 ----------------------------------------
function XEquipAgency:GetSuitActiveSkillDescInfoList(wearingAwarenessIds, characterId)
    return self._Model:GetSuitActiveSkillDescInfoList(wearingAwarenessIds, characterId)
end

function XEquipAgency:GetActiveSuitEquipsCount(characterId, suitId)
    return self._Model:GetActiveSuitEquipsCount(characterId, suitId)
end

function XEquipAgency:GetSuitActiveSkillDesList(suitId, count, isOverrun, isAddOverrunTips)
    return self._Model:GetSuitActiveSkillDesList(suitId, count, isOverrun, isAddOverrunTips)
end

function XEquipAgency:GetSuitFilterProvider(Text, suitId)
    local suitCfg = self._Model:GetConfigEquipSuit(suitId)
    local equipTypeStr = suitCfg.EquipType
    local equipTypes = {}
    if equipTypeStr then
        local equipTypeGroup = string.Split(equipTypeStr, "|")
        for _, k in pairs(equipTypeGroup) do
            equipTypes[tonumber(k)] = true
        end
    end

    local recommendCharacterIdStr = self:GetEquipSuitRecomChar(suitId)
    local recomChars = {}
    if recommendCharacterIdStr then
        local recomCharsGroup = string.Split(recommendCharacterIdStr, "|")
        for _, k in pairs(recomCharsGroup) do
            table.insert(recomChars, tonumber(k))
        end
    end
    local result = {
        text =Text,
        icon = self._Model:GetSuitIconPath(suitId),
        description = suitCfg.Description,
        suitQualityIcon = self._Model:GetSuitQualityIcon(suitId),
        equipType = equipTypes,
        recomCharIds = recomChars
    }
   return result
    
end
--============================================================== #endregion 其他 ==============================================================

return XEquipAgency