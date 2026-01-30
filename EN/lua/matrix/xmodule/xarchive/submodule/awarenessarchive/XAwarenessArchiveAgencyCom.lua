--- 意识图鉴的Agency组件
---@class XAwarenessArchiveAgencyCom
---@field private _OwnerAgency XArchiveAgency
---@field private _Model XArchiveModel
local XAwarenessArchiveAgencyCom = XClass(nil, 'XAwarenessArchiveAgencyCom')

function XAwarenessArchiveAgencyCom:Ctor(agency, model)
    self._OwnerAgency = agency
    self._Model = model
end

function XAwarenessArchiveAgencyCom:Release()
    self._OwnerAgency = nil
    self._Model = nil
end

function XAwarenessArchiveAgencyCom:UpdateAwarenessDataFromLoginNotify(data)
    self._Model.ArchiveAwarenessData:UpdateAwarenessSuitUnlockServerData(data.AwarenessUnlockIds)
    self._Model.ArchiveAwarenessData:UpdateAwarenessSettingUnlockServerData(data.AwarenessSettings)
end 


--region ---------- 配置表相关 ---------->>>

function XAwarenessArchiveAgencyCom:GetAwarenessSuitInfoGetType(suitId)
    return self._Model:GetArchiveAwarenessGroup()[suitId].Type
end

-- 意识设定或故事
function XAwarenessArchiveAgencyCom:GetAwarenessSettingList(id, settingType, ignoreSort)
    local list = {}
    local settingDataList = self._Model.ArchiveAwarenessData:GetAwarenessSuitIdToSettingListDic()[id]
    if settingDataList then
        if not settingType or settingType == XEnumConst.Archive.SettingType.All then
            list = settingDataList
        else
            for _, settingData in pairs(settingDataList) do
                if settingData.Type == settingType then
                    table.insert(list, settingData)
                end
            end
        end
    else
        XLog.ErrorTableDataNotFound("XArchiveAgency:GetAwarenessSettingList", "配置表项", "Share/Archive/AwarenessSetting.tab", "id", tostring(id))
    end

    if ignoreSort then
        return list
    end
    
    return self._Model:SortByOrder(list)
end

function XAwarenessArchiveAgencyCom:GetAwarenessGroupTypes()
    local list = {}
    for _, type in pairs(self._Model:GetArchiveAwarenessGroupType()) do
        table.insert(list, type)
    end
    return self._Model:SortByOrder(list)
end

--endregion <<<--------------------------

function XAwarenessArchiveAgencyCom:IsAwarenessGet(templateId)
    return self._Model.ArchiveAwarenessData:GetAwarenessServerDataById(templateId) ~= nil
end

--region ---------- 红点相关 ---------->>>

function XAwarenessArchiveAgencyCom:IsNewAwarenessSuit(suitId)
    local isNew = false
    if not self._Model.ArchiveAwarenessData:GetAwarenessSuitUnlockServerDataById(suitId) and self._Model.ArchiveAwarenessData:GetAwarenessSuitToAwarenessCountDic()[suitId] then
        isNew = true
    end
    return isNew
end

function XAwarenessArchiveAgencyCom:IsHaveNewAwarenessSuit()
    return self._Model.ArchiveAwarenessData:GetAwarenessSuitTotalRedPointCount() > 0
end

-- 意识设定是否有红点
function XAwarenessArchiveAgencyCom:IsNewAwarenessSetting(suitId)
    local newSettingList = self._Model.ArchiveAwarenessData:GetNewAwarenessSettingIdListById(suitId)
    if newSettingList and #newSettingList > 0 then
        return true
    end
    return false
end

-- 意识图鉴是否有红点
function XAwarenessArchiveAgencyCom:IsHaveNewAwarenessSetting()
    return self._Model.ArchiveAwarenessData:GetAwarenessSettingTotalRedPointCount() > 0
end

function XAwarenessArchiveAgencyCom:GetAwarenessCountBySuitId(suitId)
    return self._Model.ArchiveAwarenessData:GetAwarenessSuitToAwarenessCountDic()[suitId] or 0
end

function XAwarenessArchiveAgencyCom:CreateRedPointCountDic()
    -- 初始化意识套装红点计数
    for id, _ in pairs(self._Model.ArchiveAwarenessData:GetAwarenessSuitToAwarenessCountDic()) do
        --- 遍历已拥有的意识套装信息，如果没有标记为已解锁，且已经显示出来了，则需要显示红点
        if not self._Model.ArchiveAwarenessData:GetAwarenessSuitUnlockServerDataById(id) and self._Model.ArchiveAwarenessData:CheckAwarenessSuitInShowTime(id) then
            self._Model.ArchiveAwarenessData:SetAwarenessSuitNewGetReddot(id)
        end
    end

    -- 初始化意识设定红点计数
    for suitId, _ in pairs(self._Model:GetArchiveAwarenessGroup()) do
        -- 只有意识套装显示了，才初始化它的设定红点
        if self._Model.ArchiveAwarenessData:CheckAwarenessSuitInShowTime(suitId) then
            local settingDataList = self:GetAwarenessSettingList(suitId)
            for _, settingData in ipairs(settingDataList) do
                local settingId = settingData.Id
                if not self._Model.ArchiveAwarenessData:GetAwarenessSettingUnlockServerDataById(settingId) and XConditionManager.CheckCondition(settingData.Condition, suitId) then
                    self._Model.ArchiveAwarenessData:SetAwarenessSettingNewGetReddot(settingId)
                end
            end
        end
    end
end

--endregion <<<-----------------------

--region ---------- 服务端协议 ---------->>>

function XAwarenessArchiveAgencyCom:RequestUnlockAwarenessSuit(idList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveAwarenessRequest, {Ids = idList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        self._Model.ArchiveAwarenessData:ClearAwarenessSuitReddotBySuitIds(res.SuccessIds)
    end)
end

function XAwarenessArchiveAgencyCom:RequestUnlockAwarenessSetting(settingIdList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockAwarenessSettingRequest, {Ids = settingIdList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        
        self._Model.ArchiveAwarenessData:ClearAwarenessSettingReddotBySettingIds(res.SuccessIds)
    end)
end
--endregion

return XAwarenessArchiveAgencyCom