--- 意识图鉴的子control
---@class XAwarenessArchiveControl: XControl
---@field private _Model XArchiveModel
---@field private _MainControl XArchiveControl
local XAwarenessArchiveControl = XClass(XControl, 'XAwarenessArchiveControl')

function XAwarenessArchiveControl:OnInit()

end

function XAwarenessArchiveControl:AddAgencyEvent()

end

function XAwarenessArchiveControl:RemoveAgencyEvent()

end

function XAwarenessArchiveControl:OnRelease()

end

function XAwarenessArchiveControl:GetAwarenessCollectRate()
    local sumNum = self._Model.ArchiveAwarenessData:GetAwarenessSumCollectNum()
    if sumNum == 0 then
        return 0
    end
    local haveNum = 0
    for id, _ in pairs(self._Model.ArchiveAwarenessData:GetAwarenessServerData()) do
        local cfg = XMVCA.XEquip:GetConfigEquip(id)
        if cfg and self._Model.ArchiveAwarenessData:CheckAwarenessSuitInShowTime(cfg.SuitId) then
            haveNum = haveNum + 1
        end
    end
    return self._MainControl:GetPercent(haveNum * 100 / sumNum)
end

--region ---------- 服务端请求处理相关 ---------->>>

--- 请求解锁指定意识类型下的意识设定
function XAwarenessArchiveControl:HandleCanUnlockAwarenessSettingByGetType(type)
    local isHaveNew = self:IsHaveNewAwarenessSettingByGetType(type)
    if not isHaveNew then return end
    local groupDataList = self._Model.ArchiveAwarenessData:GetAwarenessTypeToGroupDatas(type)
    if groupDataList then
        local newSettingIdList
        local requestIdList = {}
        for _, groupData in ipairs(groupDataList) do
            newSettingIdList = self._Model.ArchiveAwarenessData:GetNewAwarenessSettingIdListById(groupData.Id)
            if newSettingIdList then
                for _, id in ipairs(newSettingIdList) do
                    table.insert(requestIdList, id)
                end
            end
        end

        if not XTool.IsTableEmpty(requestIdList) then
            XMVCA.XArchive.AwarenessArchiveCom:RequestUnlockAwarenessSetting(requestIdList)
        end
    end
end

--- 请求解锁可解锁的意识套装
function XAwarenessArchiveControl:HandleCanUnlockAwarenessSuit()
    local isHaveNew = XMVCA.XArchive.AwarenessArchiveCom:IsHaveNewAwarenessSuit()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model.ArchiveAwarenessData:GetAwarenessSuitToAwarenessCountDic()) do
            if XMVCA.XArchive.AwarenessArchiveCom:IsNewAwarenessSuit(id) then
                table.insert(idList, id)
            end
        end

        if not XTool.IsTableEmpty(idList) then
            XMVCA.XArchive.AwarenessArchiveCom:RequestUnlockAwarenessSuit(idList)
        end
    end
end

--- 根据意识类型解锁可解锁的意识套装
function XAwarenessArchiveControl:HandleCanUnlockAwarenessSuitByGetType(type)
    local isHaveNew = self:IsHaveNewAwarenessSuitByGetType(type)
    if isHaveNew then
        local groupDataList = self._Model.ArchiveAwarenessData:GetAwarenessTypeToGroupDatas(type)
        if groupDataList then
            local newSettingId
            local requestIdList = {}
            for _, groupData in ipairs(groupDataList) do
                newSettingId = groupData.Id
                if XMVCA.XArchive.AwarenessArchiveCom:IsNewAwarenessSuit(newSettingId) then
                    table.insert(requestIdList, newSettingId)
                end
            end

            if not XTool.IsTableEmpty(requestIdList) then
                XMVCA.XArchive.AwarenessArchiveCom:RequestUnlockAwarenessSuit(requestIdList)
            end
        end
    end
end

--- 解锁所有可解锁的意识设定
function XAwarenessArchiveControl:HandleCanUnlockAwarenessSetting()
    local isHaveNew = XMVCA.XArchive.AwarenessArchiveCom:IsHaveNewAwarenessSetting()
    if isHaveNew then
        local idList = {}
        for id, _ in pairs(self._Model.ArchiveAwarenessData:GetAwarenessSettingCanUnlockDic()) do
            table.insert(idList, id)
        end

        if not XTool.IsTableEmpty(idList) then
            XMVCA.XArchive.AwarenessArchiveCom:RequestUnlockAwarenessSetting(idList)
        end
    end
end

--endregion<<<-------------------------

--region ---------- 红点 ---------->>>

-- 某个意识类型下是否有意识套装新解锁
function XAwarenessArchiveControl:IsHaveNewAwarenessSuitByGetType(type)
    return self._Model.ArchiveAwarenessData:GetNewAwarenessSuitByGetType(type) > 0
end

function XAwarenessArchiveControl:IsAwarenessSettingOpen(settingId)
    return self._Model.ArchiveAwarenessData:GetAwarenessSettingUnlockServerDataById(settingId) or self._Model.ArchiveAwarenessData:GetAwarenessSettingCanUnlockById(settingId)
end

-- 某个意识套装是否存在新解锁的意识设定
function XAwarenessArchiveControl:GetNewAwarenessSettingIdList(suitId)
    return self._Model.ArchiveAwarenessData:GetNewAwarenessSettingIdListById(suitId)
end

-- 某个意识类型下是否有新解锁的意识设定
function XAwarenessArchiveControl:IsHaveNewAwarenessSettingByGetType(type)
    return self._Model.ArchiveAwarenessData:GetNewAwarenessSettingByGetType(type) > 0
end

--endregion <<<----------------------

--region ---------- 配置表相关 ---------->>>

function XAwarenessArchiveControl:GetAwarenessGroupTypeCfgs()
    return self._Model:GetArchiveAwarenessGroupType()
end

function XAwarenessArchiveControl:GetAwarenessSuitInfoIconPath(suitId)
    return self._Model:GetArchiveAwarenessGroup()[suitId].IconPath
end

function XAwarenessArchiveControl:GetAwarenessSettingType(id)
    return self._Model:GetAwarenessSetting()[id].Type
end

function XAwarenessArchiveControl:GetAwarenessSuitIdBySettingId(id)
    return self._Model:GetAwarenessSetting()[id].SuitId
end

function XAwarenessArchiveControl:GetAwarenessTypeToGroupDatas(groupType)
    return self._Model.ArchiveAwarenessData:GetAwarenessTypeToGroupDatas(groupType)
end

--endregion <<<--------------------------

return XAwarenessArchiveControl