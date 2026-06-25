---@class XArchiveAgency : XAgency
---@field private _Model XArchiveModel
local XArchiveAgency = XClass(XAgency, "XArchiveAgency")
local tableInsert=table.insert

function XArchiveAgency:OnInit()
    ---@type XComicArchiveAgencyCom
    self.ComicArchiveCom = require('XModule/XArchive/SubModule/ComicArchive/XComicArchiveAgencyCom').New(self, self._Model)
    ---@type XCGArchiveAgencyCom
    self.CGArchiveCom = require('XModule/XArchive/SubModule/CGArchive/XCGArchiveAgencyCom').New(self, self._Model)
    ---@type XAwarenessArchiveAgencyCom
    self.AwarenessArchiveCom = require('XModule/XArchive/SubModule/AwarenessArchive/XAwarenessArchiveAgencyCom').New(self, self._Model)
    
    ---@type XMonsterArchiveAgency
    self.MonsterArchiveAgency = self:AddSubAgency(require("XModule/XArchive/SubModule/MonsterArchive/XMonsterArchiveAgency"))
end

function XArchiveAgency:InitRpc()
    XRpc.NotifyArchiveLoginData = function(data)
        self.MonsterArchiveAgency:OnNotifyArchiveLoginData(data)

        self:SetEquipServerData(data.Equips)

        self._Model:SetArchiveShowedCGList(data.UnlockCgs)
        self._Model:SetArchiveShowedStoryList(data.UnlockStoryDetails)--只保存通关的活动剧情ID，到了解禁事件后会被清除
        self._Model:SetUnlockPvDetails(data.UnlockPvDetails)

        self._Model:UpdateWeaponUnlockServerData(data.WeaponUnlockIds)
        self._Model:UpdateWeaponSettingUnlockServerData(data.WeaponSettings)
        self._Model:UpdateUnLockPartnerSettingDic(data.PartnerSettings)
        self._Model:UpdateUnLockPartnerDic(data.PartnerUnlockIds)
        self._Model:UpdateUnLockArchiveMailDict(data.UnlockMails)
        
        self.AwarenessArchiveCom:UpdateAwarenessDataFromLoginNotify(data)
        self.ComicArchiveCom:UpdateComicDataFromLoginNotify(data)

        self.MonsterArchiveAgency:UpdateMonsterData()
        self:CreateRedPointCountDicAll()

        XDataCenter.PartnerManager.UpdateAllPartnerStory()
        self:UpdateArchivePartnerList()
        self:UpdateArchivePartnerSettingList()
    end

    XRpc.NotifyArchiveMonsterRecord = handler(self.MonsterArchiveAgency, self.MonsterArchiveAgency.OnNotifyArchiveMonsterRecord)

    XRpc.NotifyArchiveCgs = function(data)
        self._Model:SetArchiveShowedCGList(data.UnlockCgs)
        self:SyncCGEntityUnlockState(data.UnlockCgs)
        self.CGArchiveCom:AddNewCGRedPoint(data.UnlockCgs)
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_CG)
    end

    XRpc.NotifyArchivePvDetails = function(data)
        self._Model:SetUnlockPvDetails(data.UnlockPvDetails) --这的UnlockPvDetails是个int
    end
    -----------------武器、意识相关------------------->>>
    XRpc.NotifyArchiveEquip = function(data)
        self:UpdateEquipServerData(data.Equips)
    end

    -----------------武器、意识相关-------------------<<<
    -----------------剧情相关------------------->>>
    XRpc.NotifyArchiveStoryDetails = function(data)
        self._Model:SetArchiveShowedStoryList(data.UnlockStoryDetails)
    end
    -----------------剧情相关-------------------<<<

    -----------------伙伴相关------------------->>>

    XRpc.NotifyArchivePartners = function(data)
        self._Model:UpdateUnLockPartnerDic(data.PartnerUnlockIds)
        self:UpdateArchivePartnerList()
    end

    XRpc.NotifyPartnerSettings = function(data)
        self._Model:UpdateUnLockPartnerSettingDic(data.PartnerSettings)
        self:UpdateArchivePartnerSettingList()
        XDataCenter.PartnerManager.UpdateAllPartnerStory()
    end
    -----------------伙伴相关-------------------<<<

    --region   ------------------邮件相关 start-------------------
    XRpc.NotifyArchiveMail = function(data)
        local id = data.UnlockArchiveMailId
        if XTool.IsNumberValid(id) then
            self._Model:UpdateUnLockArchiveMailDict({ id })
        end
    end
    --endregion------------------邮件相关 finish------------------
    
    XRpc.NotifyArchiveComics = handler(self.ComicArchiveCom, self.ComicArchiveCom.UpdateUnlockComicDataFromNewNotify)
end

function XArchiveAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XArchiveAgency:OnRelease()
    self.ComicArchiveCom:Release()
    self.ComicArchiveCom = nil

    self.CGArchiveCom:Release()
    self.CGArchiveCom = nil

    self.AwarenessArchiveCom:Release()
    self.AwarenessArchiveCom = nil
end

----------public start----------

--region --------------------------------伙伴图鉴相关------------------------------------------>>>

--endregion 

--region ------------配置表相关-------->>>


-- 武器设定或故事
function XArchiveAgency:GetWeaponSettingList(id, settingType)
    local list = {}
    local settingDataList = self._Model:GetWeaponTemplateIdToSettingListDic()[id]
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
    end
    return self._Model:SortByOrder(list)
end

function XArchiveAgency:GetShowedWeaponTypeList()
    return self._Model:GetShowedWeaponTypeList()
end

function XArchiveAgency:GetWeaponGroupByType(type)
    return self._Model:GetArchiveWeaponGroup()[type]
end

function XArchiveAgency:GetWeaponGroupName(type)
    return self._Model:GetArchiveWeaponGroup()[type].GroupName
end
function XArchiveAgency:GetArchiveStoryChapterConfigById(id)
    return self._Model:GetStoryChapter()[id]
end

function XArchiveAgency:GetArchiveStoryDetailConfigById(id)
    return self._Model:GetStoryDetail()[id]
end
-- NPC相关------------->>>
function XArchiveAgency:GetArchiveStoryNpcConfigById(id)
    return self._Model:GetStoryNpc()[id]
end

function XArchiveAgency:GetArchiveStoryNpcSettingConfigById(id)
    return self._Model:GetStoryNpcSetting()[id]
end
-- CG相关------------->>>
function XArchiveAgency:GetArchiveCGDetailConfigById(id)
    return self._Model:GetCGDetail()[id]
end

-- 邮件通讯相关------------->>>
function XArchiveAgency:GetArchiveMailsConfigById(id)
    return self._Model:GetArchiveMail()[id]
end

function XArchiveAgency:GetArchiveCommunicationsConfigById(id)
    return self._Model:GetCommunication()[id]
end
-- 伙伴相关------------->>>
function XArchiveAgency:GetPartnerSettingConfigById(id)
    if not self._Model:GetPartnerSetting()[id] then
        XLog.Error("Id is not exist in " .. "Share/Archive/PartnerSetting.tab" .. " id = " .. id)
        return
    end
    return self._Model:GetPartnerSetting()[id]
end

function XArchiveAgency:GetPartnerConfigById(id)
    if not self._Model:GetArchivePartner()[id] then
        XLog.Error("Id is not exist in " .. 'Client/Archive/ArchivePartner.tab' .. " id = " .. id)
        return
    end
    return self._Model:GetArchivePartner()[id]
end
--endregion

--region -------------------武器、意识部分------------------->>>
-- 武器相关
function XArchiveAgency:IsWeaponGet(templateId)
    return self._Model:GetArchiveWeaponServerDataById(templateId) ~= nil
end


-- 武器new标签
function XArchiveAgency:IsNewWeapon(templateId)
    local isNew = false
    if not self._Model:GetWeaponUnlockServerData(templateId) and self._Model:GetArchiveWeaponServerDataById(templateId) then
        isNew = true
    end

    return isNew
end


-- 武器图鉴是否有new标签
function XArchiveAgency:IsHaveNewWeapon()
    return self._Model:GetWeaponTotalRedPointCount() > 0
end

-- 武器图鉴是否有红点
function XArchiveAgency:IsNewWeaponSetting(templateId)
    local newSettingList = self._Model:GetNewWeaponSettingIdListById(templateId)
    if newSettingList and #newSettingList > 0 then
        return true
    end
    return false
end


-- 武器图鉴是否有红点
function XArchiveAgency:IsHaveNewWeaponSetting()
    return self._Model:GetWeaponSettingTotalRedPointCount() > 0
end

function XArchiveAgency:IsEquipGet(templateId)
    return self:IsWeaponGet(templateId) or self.AwarenessArchiveCom:IsAwarenessGet(templateId)
end

function XArchiveAgency:GetEquipLv(templateId)
    local data = self._Model:GetArchiveWeaponServerDataById(templateId) or self._Model.ArchiveAwarenessData:GetAwarenessServerDataById(templateId)
    return data and data.Level or 0
end

function XArchiveAgency:GetEquipBreakThroughTimes(templateId)
    local data = self._Model:GetArchiveWeaponServerDataById(templateId) or self._Model.ArchiveAwarenessData:GetAwarenessServerDataById(templateId)
    return data and data.Breakthrough or 0
end


-- 从服务端获取武器和意识相关数据
function XArchiveAgency:SetEquipServerData(equipData)
    self._Model.ArchiveAwarenessData:ClearAwarenessSuitToAwarenessCountDic()
    local templateId
    local suitId
    --只有在配置表中出现id才会记录在本地的serverData
    for _, data in ipairs(equipData) do
        templateId = data.Id
        if XMVCA.XEquip:IsEquipWeapon(templateId) and self._Model:GetWeaponTemplateIdToSettingListDic()[templateId] then
            self._Model:SetWeaponServerDataById(templateId,data)
        elseif XMVCA.XEquip:IsEquipAwareness(templateId) and self._Model.ArchiveAwarenessData:GetAwarenessShowedStatusDic()[templateId] then
            self._Model.ArchiveAwarenessData:SetAwarenessServerDataById(templateId,data)
            suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
            self._Model.ArchiveAwarenessData:AddAwarenessSuitToAwarenessCountById(suitId,1)
        end
    end
end

-- 从服务端获取武器和意识相关数据，并判断是否有新的武器或者意识
function XArchiveAgency:UpdateEquipServerData(equipData)
    local templateId
    --只有在配置表中出现id才会记录在本地的serverData
    local isNewWeaponSetting = false
    local isNewAwarenessSetting = false
    local weaponIdList
    local awarenessSuitIdList
    local suitId
    local weaponType
    local awarenessSuitGetType
    local settingDataList
    local settingId
    local conditionId
    local updateSuitIdDic
    for _, data in ipairs(equipData) do
        templateId = data.Id
        if XMVCA.XEquip:IsEquipWeapon(templateId) and self._Model:GetWeaponTemplateIdToSettingListDic()[templateId] then
            weaponType = XMVCA.XEquip:GetEquipType(templateId)
            if not self._Model:GetWeaponUnlockServerData(templateId) then
                weaponIdList = weaponIdList or {}
                tableInsert(weaponIdList, templateId)
                if not self._Model:GetArchiveWeaponServerDataById(templateId) then
                    self._Model:AddWeaponRedPointCountByType(weaponType,1)
                    self._Model:AddWeaponTotalRedPointCount(1)
                end
            end
            self._Model:SetWeaponServerDataById(templateId,data)
            settingDataList = self:GetWeaponSettingList(templateId)
            for _, settingData in ipairs(settingDataList) do
                settingId = settingData.Id
                conditionId = settingData.Condition
                if not self._Model:GetWeaponSettingUnlockServerDataById(settingId) then
                    if not self._Model:GetWeaponSettingCanUnlockById(settingId) and self:CheckConditions(conditionId, templateId) then
                        isNewWeaponSetting = true
                        self._Model:SetWeaponSettingCanUnlockById(settingId, true)
                        self._Model:InsertNewWeaponSettingIdsDicById(templateId,settingId)
                        self._Model:AddWeaponSettingRedPointCountByType(weaponType, 1)
                        self._Model:AddWeaponSettingTotalRedPointCount(1)
                    end
                end
            end

        elseif XMVCA.XEquip:IsEquipAwareness(templateId) and self._Model.ArchiveAwarenessData:GetAwarenessShowedStatusDic()[templateId] then
            suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
            updateSuitIdDic = updateSuitIdDic or {}
            updateSuitIdDic[suitId] = true
            if not self._Model.ArchiveAwarenessData:GetAwarenessServerDataById(templateId) then
                if not self._Model.ArchiveAwarenessData:GetAwarenessSuitToAwarenessCountById(suitId) and self._Model.ArchiveAwarenessData:CheckAwarenessSuitInShowTime(suitId) then
                    awarenessSuitIdList = awarenessSuitIdList or {}
                    tableInsert(awarenessSuitIdList, suitId)
                    self._Model.ArchiveAwarenessData:SetAwarenessSuitNewGetReddot(suitId)
                end
                self._Model.ArchiveAwarenessData:AddAwarenessSuitToAwarenessCountById(suitId,1)
            end

            self._Model.ArchiveAwarenessData:SetAwarenessServerDataById(templateId,data)
        end
    end

    if updateSuitIdDic then
        for tmpSuitId, _ in pairs(updateSuitIdDic) do
            if self._Model.ArchiveAwarenessData:CheckAwarenessSuitInShowTime(tmpSuitId) then
                settingDataList = self.AwarenessArchiveCom:GetAwarenessSettingList(tmpSuitId)
                for _, settingData in ipairs(settingDataList) do
                    settingId = settingData.Id
                    conditionId = settingData.Condition

                    if not self._Model.ArchiveAwarenessData:GetAwarenessSettingUnlockServerDataById(settingId) and
                            not self._Model.ArchiveAwarenessData:GetAwarenessSettingCanUnlockById(settingId) and
                            XConditionManager.CheckCondition(conditionId, tmpSuitId) then

                        isNewAwarenessSetting = true
                        self._Model.ArchiveAwarenessData:SetAwarenessSettingNewGetReddot(settingId)

                    end
                end
            end
        end
    end

    if weaponIdList then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_WEAPON, weaponIdList)
    end
    if isNewWeaponSetting then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING)
    end

    if awarenessSuitIdList then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT, awarenessSuitIdList)
    end
    if isNewAwarenessSetting then
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING)
    end
end

function XArchiveAgency:CreateRedPointCountDicAll()
    local weaponType
    for id, _ in pairs(self._Model:GetArchiveWeaponServerData()) do
        if not self._Model:GetWeaponUnlockServerData(id) then
            weaponType = XMVCA.XEquip:GetEquipType(id)
            if weaponType then
                self._Model:AddWeaponRedPointCountByType(weaponType, 1)
                self._Model:AddWeaponTotalRedPointCount(1)
            end
        end
    end

    local settingDataList
    local settingId
    for weaponId, _ in pairs(self._Model:GetWeaponTemplateIdToSettingListDic()) do
        settingDataList = self:GetWeaponSettingList(weaponId)
        for _, settingData in ipairs(settingDataList) do
            settingId = settingData.Id
            if not self._Model:GetWeaponSettingUnlockServerDataById(settingId) and self:CheckConditions(settingData.Condition, weaponId) then
                self._Model:SetWeaponSettingCanUnlockById(settingId, true)
                weaponType = XMVCA.XEquip:GetEquipType(weaponId)
                self._Model:InsertNewWeaponSettingIdsDicById(weaponId,settingId)
                self._Model:AddWeaponSettingRedPointCountByType(weaponType, 1)
                self._Model:AddWeaponSettingTotalRedPointCount(1)
            end
        end
    end

    self.AwarenessArchiveCom:CreateRedPointCountDic()
end

function XArchiveAgency:RequestUnlockWeapon(idList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockArchiveWeaponRequest, {Ids = idList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        local successIdList = res.SuccessIds
        if successIdList then
            local weaponType
            for _, id in ipairs(successIdList) do
                self._Model:SetWeaponUnlockServerDataById(id, true)
                weaponType = XMVCA.XEquip:GetEquipType(id)
                self._Model:SetWeaponRedPointCountByType(weaponType, self._Model:GetWeaponRedPointCountByType(weaponType) - 1)
            end
            self._Model:SetWeaponTotalRedPointCount(self._Model:GetWeaponTotalRedPointCount() - #successIdList)

            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON)
        end
    end)
end

function XArchiveAgency:RequestUnlockWeaponSetting(settingIdList)
    XNetwork.Call(XEnumConst.Archive.METHOD_NAME.UnlockWeaponSettingRequest, {Ids = settingIdList}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        local successIdList = res.SuccessIds
        if successIdList then
            local templateId
            local weaponType
            local newWeaponSettingIdList
            for _, id in ipairs(successIdList) do
                self._Model:SetWeaponSettingUnlockServerDataById(id, true)
                self._Model:SetWeaponSettingCanUnlockById(id, nil)
                templateId = self._Model:GetWeaponSetting()[id].EquipId
                weaponType = XMVCA.XEquip:GetEquipType(templateId)
                self._Model:SetWeaponSettingRedPointCountByType(weaponType, self._Model:GetNewWeaponSettingByWeaponType(weaponType) - 1)
                newWeaponSettingIdList = self._Model:GetNewWeaponSettingIdListById(templateId)
                if newWeaponSettingIdList then
                    for index, settingId in ipairs(newWeaponSettingIdList) do
                        if id == settingId then
                            table.remove(newWeaponSettingIdList, index)
                            break
                        end
                    end
                    if #newWeaponSettingIdList == 0 then
                        self._Model:SetNewWeaponSettingIdsDicById(templateId, nil)
                    end
                end
            end
            self._Model:SetWeaponSettingTotalRedPointCount(self._Model:GetWeaponSettingTotalRedPointCount() - #successIdList)

            XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING)
        end
    end)
end

--endregion

--region -------------剧情相关------------->>>

function XArchiveAgency:GetArchiveStoryDetailList(chapterId)--chapterId为空时不作为判断条件
    if chapterId then
        return self._Model:GetArchiveStoryDetailList()[chapterId] or {}
    end
    local list = {}
    local pairList = self._Model:GetArchiveStoryDetailList()
    if not XTool.IsTableEmpty(pairList) then
        for _,group in pairs(pairList) do
            for _,detail in pairs(group) do
                tableInsert(list,detail)
            end
        end
    end
    return self._Model:SortByOrder(list)
end
--endregion

--region -------------CG相关------------->>>

function XArchiveAgency:GetArchiveCgEntity(id)
    return self._Model:GetArchiveCGDetailData()[id]
end

function XArchiveAgency:SyncCGEntityUnlockState(unlockCgIds)
    if XTool.IsTableEmpty(unlockCgIds) then return end
    for _, cgId in pairs(unlockCgIds) do
        local entity = self._Model._ArchiveCGDetailData[cgId]
        if entity then
            entity.IsLock = false
            entity.LockDesc = ""
        end
    end
end

function XArchiveAgency:GetArchiveCGGroupList(isCustomLoading)
    local list = {}
    for _, group in pairs(self._Model:GetCGGroup()) do
        if isCustomLoading and XLoadingConfig.CheckCustomBlockGroup(group.Id) then
            goto CONTINUE
        end
        tableInsert(list, group)
        ::CONTINUE::
    end
    return self._Model:SortByOrder(list)
end

function XArchiveAgency:GetArchiveCGDetailList(group)--group为空时不作为判断条件，获取相应类型的图鉴CG列表
    if group then
        return self._Model:GetArchiveCGDetailList()[group] and self._Model:GetArchiveCGDetailList()[group] or {}
    end
    local list = {}
    for _,CGDetailGroup in pairs(self._Model:GetArchiveCGDetailList()) do
        for _,CGDetail in pairs(CGDetailGroup) do
            tableInsert(list,CGDetail)
        end
    end
    return self._Model:SortByOrder(list)
end
--endregion

--region --------------------------------伙伴图鉴相关------------------------------------------>>>

function XArchiveAgency:UpdateArchivePartnerList()--更新图鉴伙伴锁定状态（热路径，不触发 Entity 创建）
    for _, cfg in pairs(self._Model:GetArchivePartner()) do
        local isLock = not self._Model:GetPartnerUnLockById(cfg.Id)
        self._Model:SetPartnerLockState(cfg.Id, isLock)
    end
end

function XArchiveAgency:UpdateArchivePartnerSettingList()--更新图鉴伙伴设定锁定状态（热路径，不触发 Entity 创建）
    local partnerData = self._Model:GetRawArchivePartnerData()
    if XTool.IsTableEmpty(partnerData) then
        return
    end
    local unlockSettingDic = self._Model:GetPartnerUnLockSettingDic()
    for _, entity in pairs(partnerData) do
        entity:UpdateStoryAndSettingEntity(unlockSettingDic)
    end
end

function XArchiveAgency:CheckArchiveMailUnlock(archiveMailId)
    return self._Model:GetUnlockArchiveMailById(archiveMailId)
end

function XArchiveAgency:GetPartnerUnLockById(templateId)
    return self._Model:GetPartnerUnLockById(templateId)
end

function XArchiveAgency:GetPartnerSettingUnLockDic()
    return self._Model:GetPartnerUnLockSettingDic()
end

function XArchiveAgency:GetArchivePartnerSetting(partnerTemplateId,type)
    return self._Model:GetArchivePartnerSetting(partnerTemplateId,type)
end
--endregion

-- 打开图鉴接口，统一入口
function XArchiveAgency:OpenUiArchiveMain()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive) then
        return
    end
    --资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XLuaUiManager.Open("UiArchiveMain")
end

function XArchiveAgency:SortByOrder(list)
    return self._Model:SortByOrder(list)
end
----------public end----------

----------private start----------

function XArchiveAgency:CheckConditions(conditionIds,...)
    if not XTool.IsTableEmpty(conditionIds) then
        for i, v in pairs(conditionIds) do
            if XConditionManager.CheckCondition(v, ...) then
                return true
            end
        end
    end
    return false
end

----------private end----------

return XArchiveAgency