---@class XArchiveModel : XModel
local XArchiveModel = XClass(XModel, "XArchiveModel")

local ArchiveClientTableKey = {
    ArchiveWeaponGroup = { DirPath = XConfigUtil.DirectoryType.Client },
    ArchiveAwarenessGroup = { DirPath = XConfigUtil.DirectoryType.Client },
    ArchiveAwarenessGroupType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = 'GroupId', CacheType = XConfigUtil.CacheType.Private },
    ArchivePartner = { DirPath = XConfigUtil.DirectoryType.Client },
    ArchivePartnerGroup = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },

    ArchiveComicDetail = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id', CacheType = XConfigUtil.CacheType.Private },
}

local ArchiveShareTableKey = {
    Archive = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    AwarenessSetting = { DirPath = XConfigUtil.DirectoryType.Share },
    WeaponSetting = { DirPath = XConfigUtil.DirectoryType.Share },
    ArchiveMail = { DirPath = XConfigUtil.DirectoryType.Share },
    PartnerSetting = { DirPath = XConfigUtil.DirectoryType.Share }, -- 冷路径，但被XUiFashion等外部系统引用，暂不改Private

    ArchiveComicGroup = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id', CacheType = XConfigUtil.CacheType.Private },
    ArchiveComicChapter = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
}

local TablePathTable = {
    TABLE_TAG = "Share/Archive/Tag.tab",
    TABLE_CGDETAIL = "Share/Archive/CGDetail.tab",
    TABLE_STORYCHAPTER = "Share/Archive/StoryChapter.tab",
    TABLE_STORYNPC = "Share/Archive/StoryNpc.tab",
    TABLE_STORYNPCSETTING = "Share/Archive/StoryNpcSetting.tab",
    TABLE_CGGROUP = "Share/Archive/CGGroup.tab",
    TABLE_COMMUNICATION = "Share/Archive/Communication.tab",
    TABLE_EVENTDATEGROUP = "Share/Archive/EventDateGroup.tab",
    TABLE_PVGROUP = "Client/Archive/PVGroup.tab",
    TABLE_PVDETAIL = "Share/Archive/PVDetail.tab",
    TABLE_STORYDETAIL = "Share/Archive/StoryDetail.tab",
    TABLE_STORYGROUP = "Share/Archive/StoryGroup.tab",
}

local PrivateFuncMap = {}
local tableSort = table.sort
local tableInsert = table.insert

function XArchiveModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    --配置表定义
    self._ConfigUtil:InitConfigByTableKey('Archive', ArchiveClientTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('Archive', ArchiveShareTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfig({
        [TablePathTable.TABLE_TAG] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveTag, "Id", XConfigUtil.CacheType.Normal },
        [TablePathTable.TABLE_CGDETAIL] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveCGDetail, "Id", XConfigUtil.CacheType.Normal }, -- 冷路径，但被XUiPhotograph等外部系统引用，暂不改Private
        [TablePathTable.TABLE_STORYCHAPTER] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveStoryChapter, "Id", XConfigUtil.CacheType.Normal },
        [TablePathTable.TABLE_STORYNPC] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveStoryNpc, "Id", XConfigUtil.CacheType.Normal },
        [TablePathTable.TABLE_STORYNPCSETTING] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveStoryNpcSetting, "Id", XConfigUtil.CacheType.Normal },
        [TablePathTable.TABLE_CGGROUP] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveCGGroup, "Id", XConfigUtil.CacheType.Normal }, -- 冷路径，但被XUiPhotograph等外部系统引用，暂不改Private
        [TablePathTable.TABLE_COMMUNICATION] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveCommunication, "Id", XConfigUtil.CacheType.Normal },
        [TablePathTable.TABLE_EVENTDATEGROUP] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveEventDateGroup, "Id", XConfigUtil.CacheType.Private },
        [TablePathTable.TABLE_PVGROUP] = { XConfigUtil.ReadType.Int, XTable.XTableArchivePVGroup, "Id", XConfigUtil.CacheType.Private },
        [TablePathTable.TABLE_PVDETAIL] = { XConfigUtil.ReadType.Int, XTable.XTableArchivePVDetail, "Id", XConfigUtil.CacheType.Private },
        [TablePathTable.TABLE_STORYDETAIL] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveStoryDetail, "Id", XConfigUtil.CacheType.Normal }, -- 冷路径，但被XUiPhotograph等外部系统引用，暂不改Private
        [TablePathTable.TABLE_STORYGROUP] = { XConfigUtil.ReadType.Int, XTable.XTableArchiveStoryGroup, "Id", XConfigUtil.CacheType.Private },

    })
    PrivateFuncMap.InitOtherConfig(self)
    --二次配置数据
    PrivateFuncMap.InitSecondaryConfigs(self)
    --
    PrivateFuncMap.InitData(self)

    self:InitSubModuleData()
end

function XArchiveModel:ClearPrivate()
    --这里执行内部数据清理

end

function XArchiveModel:ResetAll()
    --这里执行重登数据清理
    PrivateFuncMap.InitSecondaryConfigs(self)
    PrivateFuncMap.InitData(self)
    self:ResetSubModuleData()
end

--- 初始化子系统的数据
function XArchiveModel:InitSubModuleData()
    ---@type XArchiveComicData
    self.ArchiveComicData = require('XModule/XArchive/Entity/XArchiveComicData').New(self)
    ---@type XArchiveCGData
    self.ArchiveCGData = require('XModule/XArchive/Entity/XArchiveCGData').New(self)
    ---@type XArchiveAwarenessData
    self.ArchiveAwarenessData = require('XModule/XArchive/Entity/XArchiveAwarenessData').New(self)

    ---@type XMonsterArchiveModel
    self.MonsterArchiveModel = self:AddSubModel(require("XModule/XArchive/SubModule/MonsterArchive/XMonsterArchiveModel"))
end

function XArchiveModel:ResetSubModuleData()
    self.ArchiveComicData:ResetData()
    self.ArchiveCGData:ResetData()
    self.ArchiveAwarenessData:ResetData()
end

--region ----------public start----------
function XArchiveModel:SortByOrder(list)
    tableSort(list, function(a, b)
        if a.Order then
            if a.Order == b.Order then
                return a.Id > b.Id
            else
                return a.Order < b.Order
            end
        else
            if a:GetOrder() == b:GetOrder() then
                return a:GetId() > b:GetId()
            else
                return a:GetOrder() < b:GetOrder()
            end
        end
    end)
    return list
end

function XArchiveModel:GetArchivePartnerSetting(partnerTemplateId, type)
    local settingList = self:GetArchivePartnerSettingList()[partnerTemplateId]
    if not settingList then
        XLog.Error("Id is not exist in Share/Archive/PartnerSetting.tab" .. " id = " .. partnerTemplateId)
        return
    end
    local setting = settingList[type]
    if not setting then
        return
    end
    return self:SortByOrder(setting)
end

function XArchiveModel:GetWeaponsCollectionSaveKey(type)
    return string.format("%d%s%d", XPlayer.Id, "ArchiveWeaponsCollection", type)
end

---------------------武器、意识------------------>>>
--region getter
function XArchiveModel:GetArchiveWeaponServerData()
    return self._ArchiveWeaponServerData
end

function XArchiveModel:GetArchiveWeaponServerDataById(templateId)
    return self._ArchiveWeaponServerData[templateId]
end

function XArchiveModel:GetWeaponRedPointCountByType(type)
    if self._ArchiveWeaponRedPointCountDic[type] then
        return self._ArchiveWeaponRedPointCountDic[type]
    else
        return 0
    end
end

function XArchiveModel:GetWeaponSettingUnlockServerDataById(settingId)
    return self._ArchiveWeaponSettingUnlockServerData[settingId] or false
end

function XArchiveModel:GetWeaponSettingCanUnlockDic()
    return self._ArchiveWeaponSettingCanUnlockDic
end

function XArchiveModel:GetWeaponSettingCanUnlockById(settingId)
    return self._ArchiveWeaponSettingCanUnlockDic[settingId] or false
end

function XArchiveModel:GetNewWeaponSettingIdListById(templateId)
    if self._ArchiveNewWeaponSettingIdsDic[templateId] then
        return self._ArchiveNewWeaponSettingIdsDic[templateId]
    end
end

function XArchiveModel:GetNewWeaponSettingByWeaponType(type)
    return self._ArchiveWeaponSettingRedPointCountDic[type] or 0
end

function XArchiveModel:GetWeaponTotalRedPointCount()
    return self._ArchiveWeaponTotalRedPointCount
end

function XArchiveModel:GetWeaponSettingTotalRedPointCount()
    return self._ArchiveWeaponSettingTotalRedPointCount
end

function XArchiveModel:GetWeaponUnlockServerData(templateId)
    return self._ArchiveWeaponUnlockServerData[templateId]
end
--endregion

--region setter
function XArchiveModel:SetWeaponTotalRedPointCount(count)
    self._ArchiveWeaponTotalRedPointCount = count
end

function XArchiveModel:AddWeaponTotalRedPointCount(adds)
    self._ArchiveWeaponTotalRedPointCount = self._ArchiveWeaponTotalRedPointCount + adds
end

function XArchiveModel:SetWeaponRedPointCountByType(weaponType, count)
    self._ArchiveWeaponRedPointCountDic[weaponType] = count
end

function XArchiveModel:AddWeaponRedPointCountByType(weaponType, adds)
    if type(self._ArchiveWeaponRedPointCountDic[weaponType]) ~= 'number' then
        self._ArchiveWeaponRedPointCountDic[weaponType] = 0
    end
    self._ArchiveWeaponRedPointCountDic[weaponType] = self._ArchiveWeaponRedPointCountDic[weaponType] + adds
end

function XArchiveModel:SetWeaponUnlockServerDataById(id, data)
    self._ArchiveWeaponUnlockServerData[id] = data
end

function XArchiveModel:SetWeaponSettingTotalRedPointCount(count)
    self._ArchiveWeaponSettingTotalRedPointCount = count
end

function XArchiveModel:AddWeaponSettingTotalRedPointCount(adds)
    self._ArchiveWeaponSettingTotalRedPointCount = self._ArchiveWeaponSettingTotalRedPointCount + adds
end

function XArchiveModel:SetNewWeaponSettingIdsDicById(templateId, data)
    self._ArchiveNewWeaponSettingIdsDic[templateId] = data
end

function XArchiveModel:InsertNewWeaponSettingIdsDicById(templateId, data)
    if not self._ArchiveNewWeaponSettingIdsDic[templateId] then
        self._ArchiveNewWeaponSettingIdsDic[templateId] = {}
    end
    table.insert(self._ArchiveNewWeaponSettingIdsDic[templateId], data)
end

function XArchiveModel:SetWeaponSettingRedPointCountByType(weaponType, count)
    self._ArchiveWeaponSettingRedPointCountDic[weaponType] = count
end

function XArchiveModel:AddWeaponSettingRedPointCountByType(weaponType, adds)
    if type(self._ArchiveWeaponSettingRedPointCountDic[weaponType]) ~= 'number' then
        self._ArchiveWeaponSettingRedPointCountDic[weaponType] = 0
    end
    self._ArchiveWeaponSettingRedPointCountDic[weaponType] = self._ArchiveWeaponSettingRedPointCountDic[weaponType] + adds
end

function XArchiveModel:SetWeaponSettingCanUnlockById(id, canUnLock)
    self._ArchiveWeaponSettingCanUnlockDic[id] = canUnLock
end

function XArchiveModel:SetWeaponSettingUnlockServerDataById(id, unLock)
    self._ArchiveWeaponSettingUnlockServerData[id] = unLock
end

function XArchiveModel:SetWeaponServerDataById(templateId, data)
    self._ArchiveWeaponServerData[templateId] = data
end

function XArchiveModel:UpdateWeaponUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._ArchiveWeaponUnlockServerData[id] = true
    end
end

function XArchiveModel:UpdateWeaponSettingUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self._ArchiveWeaponSettingUnlockServerData[id] = true
    end
end
--endregion
---------------------伙伴图鉴------------------>>>
--region getter
function XArchiveModel:GetPartnerListByGroup(group)
    if XTool.IsTableEmpty(self._ArchivePartnerList) then
        PrivateFuncMap.InitArchivePartnerList(self)
    end
    return self._ArchivePartnerList[group] or {}
end

function XArchiveModel:GetPartnerUnLockById(id)
    return self._PartnerUnLockDic[id]
end

function XArchiveModel:GetPartnerUnLockSettingDic()
    return self._PartnerUnLockSettingDic
end

--- 热路径写入 Partner 锁定缓存；若 Entity 已创建则同步写入
function XArchiveModel:SetPartnerLockState(templateId, isLock)
    self._PartnerLockState[templateId] = isLock
    local entity = self._ArchivePartnerData[templateId]
    if entity then
        entity:SetIsLock(isLock)
    end
end

--- 不触发懒加载，返回原始 Entity 字典（供热路径判断 Entity 是否已创建）
function XArchiveModel:GetRawArchivePartnerData()
    return self._ArchivePartnerData
end

--- 热路径：不触发 Entity 懒加载，直接用配置表 + 热数据统计 Partner 完成度
--- @param groupId number|nil  nil = 所有分组
--- @return number unlockCount, number totalCount
function XArchiveModel:GetPartnerCompletionCount(groupId)
    local total, unlocked = 0, 0
    for _, cfg in pairs(self:GetArchivePartner()) do
        if not groupId or cfg.GroupId == groupId then
            total = total + 1
            if self._PartnerUnLockDic[cfg.Id] then
                unlocked = unlocked + 1
            end
        end
    end
    return unlocked, total
end
--endregion

--region setter
function XArchiveModel:UpdateUnLockPartnerDic(dataList)
    for _, data in pairs(dataList) do
        if not self._PartnerUnLockDic[data] then
            self._PartnerUnLockDic[data] = data
        end
    end
end

function XArchiveModel:UpdateUnLockPartnerSettingDic(dataList)
    for _, data in pairs(dataList) do
        if not self._PartnerUnLockSettingDic[data] then
            self._PartnerUnLockSettingDic[data] = data
        end
    end
end
--endregion
---------------------剧情相关------------------>>>
--region getter
function XArchiveModel:GetShowedStoryListById(id)
    if self._ArchiveShowedStoryList[id] then
        return self._ArchiveShowedStoryList[id]
    end
end
--endregion

--region setter
function XArchiveModel:SetArchiveShowedStoryList(idList)
    if not XTool.IsTableEmpty(idList) then
        for _, id in pairs(idList) do
            self._ArchiveShowedStoryList[id] = id
        end
    end
end
--endregion
---------------------PV相关------------------>>>
--region getter
function XArchiveModel:GetUnlockPvDetailsById(pvDetailId)
    return self._UnlockPvDetails[pvDetailId]
end
--endregion

--region setter
function XArchiveModel:SetUnlockPvDetails(idList)
    if type(idList) ~= "table" then
        self._UnlockPvDetails[idList] = idList
        return
    end

    for _, id in pairs(idList) do
        self._UnlockPvDetails[id] = id
    end
end
--endregion
---------------------CG相关------------------>>>
--region getter
function XArchiveModel:GetShowedCGListById(CGId)
    return self._ArchiveShowedCGList[CGId]
end
--endregion

--region setter
function XArchiveModel:SetArchiveShowedCGList(idList)
    if not XTool.IsTableEmpty(idList) then
        for _, id in pairs(idList) do
            self._ArchiveShowedCGList[id] = id
        end
    end
end
--endregion
---------------------邮件相关----------------->>>
--region getter
function XArchiveModel:GetUnlockArchiveMailById(archiveMailId)
    return self._UnlockArchiveMails[archiveMailId] and true or false
end
--endregion

--region setter
function XArchiveModel:UpdateUnLockArchiveMailDict(dataList)
    if not XTool.IsTableEmpty(dataList) then
        for _, archiveMailId in pairs(dataList) do
            self._UnlockArchiveMails[archiveMailId] = true
        end
    end
end
--endregion

--endregion ----------public end----------

--region ----------private start----------

---初始化二次处理的配置数据
PrivateFuncMap.InitSecondaryConfigs = function(model)
    model._ArchiveTagAllList = {}
    model._ShowedWeaponTypeList = {}
    model._WeaponTemplateIdToSettingListDic = {}
    model._WeaponSumCollectNum = 0
    model._WeaponTypeToIdsDic = {}
    model._ArchiveStoryGroupAllList = {}

    model._ArchiveStoryChapterList = {}
    model._ArchiveStoryDetailList = {}
    model._ArchiveStoryNpcList = {}
    model._ArchiveStoryNpcSettingList = {}
    model._ArchiveCGDetailList = {}
    model._ArchiveCGDetailData = {}
    model._ArchiveMailList = {}
    model._ArchiveCommunicationList = {}
    model._ArchivePartnerList = {}
    model._ArchivePartnerSettingList = {}
    -- 热路径：Partner 锁定状态缓存，templateId → isLock（bool）
    model._PartnerLockState = {}
    -- 冷路径：templateId → PartnerEntity（供热路径更新时同步 Entity）
    model._ArchivePartnerData = {}
    model._ArchiveStoryChapterDic = {}

    model._IsInitPVDetail = false
    model._PVGroupIdToDetailIdList = {}
    model._PVDetailIdList = {}
end

PrivateFuncMap.InitData = function(model)
    model._ArchiveShowedCGList = {}
    model._ArchiveShowedStoryList = {}--只保存通关的活动关卡ID，到了解禁事件后会被清除

    model._PartnerUnLockDic = {}
    model._PartnerUnLockSettingDic = {}

    model._ArchiveStoryEvaluateList = {}
    model._ArchiveStoryMySelfEvaluateList = {}

    model._LastSyncStoryEvaluateTimes = {}
    -- 记录服务端武器数据，以TemplateId为键
    model._ArchiveWeaponServerData = {}
    -- 记录解锁的武器是否已读（解锁）（已读则无相关红点）
    model._ArchiveWeaponUnlockServerData = {}
    -- 记录服务端武器设定已读（解锁）数据，以SettingId为键
    model._ArchiveWeaponSettingUnlockServerData = {}
    -- 记录服务端PV解锁Id
    model._UnlockPvDetails = {}
    -- 记录解锁邮件图鉴
    model._UnlockArchiveMails = {}

    model._ArchiveWeaponRedPointCountDic = {}    --每个武器类型拥有的红点数量
    model._ArchiveWeaponTotalRedPointCount = 0   --武器图鉴拥有的红点数量

    model._ArchiveWeaponSettingCanUnlockDic = {} --武器设定可以解锁的
    model._ArchiveNewWeaponSettingIdsDic = {}  --武器id对应的新的武器设定ids
    model._ArchiveWeaponSettingRedPointCountDic = {} --每个武器类型下对应设定拥有的红点数量
    model._ArchiveWeaponSettingTotalRedPointCount = 0  --武器设定拥有的总红点数量

    --<<<红点相关
end

PrivateFuncMap.InitOtherConfig = function(model)
    model.SiteToBgPath = {
        [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath1"),
        [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.TWO] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath2"),
        [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.THREE] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath3"),
        [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.FOUR] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath4"),
        [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.FIVE] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath5"),
        [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.SIX] = CS.XGame.ClientConfig:GetString("ArchiveAwarenessSiteBgPath6"),
    }

    model.StarToQualityName = {
        [XEnumConst.Archive.EquipStarType.All] = CS.XTextManager.GetText("ArchiveAwarenessFliterAll"),
        [XEnumConst.Archive.EquipStarType.Two] = CS.XTextManager.GetText("ArchiveAwarenessFliterTwoStar"),
        [XEnumConst.Archive.EquipStarType.Three] = CS.XTextManager.GetText("ArchiveAwarenessFliterThreeStar"),
        [XEnumConst.Archive.EquipStarType.Four] = CS.XTextManager.GetText("ArchiveAwarenessFliterFourStar"),
        [XEnumConst.Archive.EquipStarType.Five] = CS.XTextManager.GetText("ArchiveAwarenessFliterFiveStar"),
        [XEnumConst.Archive.EquipStarType.Six] = CS.XTextManager.GetText("ArchiveAwarenessFliterSixStar"),
    }

    model.EvaluateOnForAll = CS.XGame.ClientConfig:GetInt("ArchiveEvaluateOnForAll")
end

PrivateFuncMap.InitArchiveStoryChapterList = function(model)
    local XArchiveStoryChapterEntity = require("XEntity/XArchive/XArchiveStoryChapterEntity")
    local storyChapters = model:GetStoryChapter()
    if not XTool.IsTableEmpty(storyChapters) then
        for _, chapter in pairs(storyChapters) do

            if not model._ArchiveStoryChapterList[chapter.GroupId] then
                model._ArchiveStoryChapterList[chapter.GroupId] = {}
            end

            local tmp = XArchiveStoryChapterEntity.New(chapter.Id)
            table.insert(model._ArchiveStoryChapterList[chapter.GroupId], tmp)

            model._ArchiveStoryChapterDic[chapter.Id] = tmp
        end
    end
    for _, group in pairs(model._ArchiveStoryChapterList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitArchiveStoryDetailAllList = function(model)
    local XArchiveStoryDetailEntity = require("XEntity/XArchive/XArchiveStoryDetailEntity")
    local storyDetails = model:GetStoryDetail()
    if not XTool.IsTableEmpty(storyDetails) then
        for _, detail in pairs(storyDetails) do

            if not model._ArchiveStoryDetailList[detail.ChapterId] then
                model._ArchiveStoryDetailList[detail.ChapterId] = {}
            end

            local tmp = XArchiveStoryDetailEntity.New(detail.Id)
            table.insert(model._ArchiveStoryDetailList[detail.ChapterId], tmp)
        end
    end
    for _, group in pairs(model._ArchiveStoryDetailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴Npc数据
PrivateFuncMap.InitArchiveStoryNpcAllList = function(model)
    local XArchiveNpcEntity = require("XEntity/XArchive/XArchiveNpcEntity")
    local storyNpcs = model:GetStoryNpc()
    if not XTool.IsTableEmpty(storyNpcs) then
        for _, npcCfg in pairs(storyNpcs) do

            local tmp = XArchiveNpcEntity.New(npcCfg.Id)
            table.insert(model._ArchiveStoryNpcList, tmp)
        end
    end
    model:SortByOrder(model._ArchiveStoryNpcList)
end

--创建图鉴NpcSetting数据
PrivateFuncMap.InitArchiveStoryNpcSettingAllList = function(model)
    local XArchiveNpcDetailEntity = require("XEntity/XArchive/XArchiveNpcDetailEntity")
    local storyNpcSettings = model:GetStoryNpcSetting()
    if not XTool.IsTableEmpty(storyNpcSettings) then
        for _, settingCfg in pairs(storyNpcSettings) do

            if not model._ArchiveStoryNpcSettingList[settingCfg.GroupId] then
                model._ArchiveStoryNpcSettingList[settingCfg.GroupId] = {}
            end

            if not model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] then
                model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type] = {}
            end

            local tmp = XArchiveNpcDetailEntity.New(settingCfg.Id)
            table.insert(model._ArchiveStoryNpcSettingList[settingCfg.GroupId][settingCfg.Type], tmp)
        end
    end
    for _, group in pairs(model._ArchiveStoryNpcSettingList) do
        for _, type in pairs(group) do
            model:SortByOrder(type)
        end
    end
end

--创建图鉴NpcSetting数据
PrivateFuncMap.InitArchiveCGAllList = function(model)
    local XArchiveCGEntity = require("XEntity/XArchive/XArchiveCGEntity")
    local cgDetails = model:GetCGDetail()
    if not XTool.IsTableEmpty(cgDetails) then
        for _, CGDetailCfg in pairs(cgDetails) do

            if not model._ArchiveCGDetailList[CGDetailCfg.GroupId] then
                model._ArchiveCGDetailList[CGDetailCfg.GroupId] = {}
            end

            local tmp = XArchiveCGEntity.New(CGDetailCfg.Id)
            if model._ArchiveShowedCGList[CGDetailCfg.Id] then
                tmp.IsLock = false
            else
                if CGDetailCfg.Condition ~= 0 then
                    _, tmp.LockDesc = XConditionManager.CheckCondition(CGDetailCfg.Condition)
                end
            end
            table.insert(model._ArchiveCGDetailList[CGDetailCfg.GroupId], tmp)
            model._ArchiveCGDetailData[CGDetailCfg.Id] = tmp
        end
    end
    for _, group in pairs(model._ArchiveCGDetailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴邮件数据
PrivateFuncMap.InitArchiveMailList = function(model)
    local XArchiveMailEntity = require("XEntity/XArchive/XArchiveMailEntity")
    local archiveMails = model:GetArchiveMail()
    if not XTool.IsTableEmpty(archiveMails) then
        for _, mailCfg in pairs(archiveMails) do
            if not model._ArchiveMailList[mailCfg.GroupId] then
                model._ArchiveMailList[mailCfg.GroupId] = {}
            end
            local tmp = XArchiveMailEntity.New(mailCfg.Id)
            table.insert(model._ArchiveMailList[mailCfg.GroupId], tmp)
        end
    end
    for _, group in pairs(model._ArchiveMailList) do
        model:SortByOrder(group)
    end
end

--创建图鉴通讯数据
PrivateFuncMap.InitArchiveCommunicationList = function(model)
    local XArchiveCommunicationEntity = require("XEntity/XArchive/XArchiveCommunicationEntity")
    local communications = model:GetCommunication()
    if not XTool.IsTableEmpty(communications) then
        for _, communicationCfg in pairs(communications) do

            if not model._ArchiveCommunicationList[communicationCfg.GroupId] then
                model._ArchiveCommunicationList[communicationCfg.GroupId] = {}
            end

            local tmp = XArchiveCommunicationEntity.New(communicationCfg.Id)
            table.insert(model._ArchiveCommunicationList[communicationCfg.GroupId], tmp)
        end
    end
    for _, group in pairs(model._ArchiveCommunicationList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitArchivePartnerSetting = function(model)
    local XArchivePartnerSettingEntity = require("XEntity/XArchive/XArchivePartnerSettingEntity")
    local detailCfg = model:GetPartnerSetting()
    if not XTool.IsTableEmpty(detailCfg) then
        for _, detail in pairs(detailCfg) do

            if not model._ArchivePartnerSettingList[detail.GroupId] then
                model._ArchivePartnerSettingList[detail.GroupId] = {}
            end

            if not model._ArchivePartnerSettingList[detail.GroupId][detail.Type] then
                model._ArchivePartnerSettingList[detail.GroupId][detail.Type] = {}
            end

            local tmp = XArchivePartnerSettingEntity.New(detail.Id)
            table.insert(model._ArchivePartnerSettingList[detail.GroupId][detail.Type], tmp)
        end
    end
    for _, group in pairs(model._ArchivePartnerSettingList) do
        for _, type in pairs(group) do
            model:SortByOrder(type)
        end
    end
end

--生成图鉴伙伴数据
PrivateFuncMap.InitArchivePartnerList = function(model)
    local XArchivePartnerEntity = require("XEntity/XArchive/XArchivePartnerEntity")
    local templateList = model:GetArchivePartner()
    if not XTool.IsTableEmpty(templateList) then
        for _, template in pairs(templateList) do
            if not model._ArchivePartnerList[template.GroupId] then
                model._ArchivePartnerList[template.GroupId] = {}
            end
            local entity = XArchivePartnerEntity.New(template.Id,
                    model:GetArchivePartnerSetting(template.Id, XEnumConst.Archive.PartnerSettingType.Story),
                    model:GetArchivePartnerSetting(template.Id, XEnumConst.Archive.PartnerSettingType.Setting))
            -- 同步热路径已计算的 Partner 锁定状态
            local isLock = model._PartnerLockState[template.Id]
            if isLock ~= nil then
                entity:SetIsLock(isLock)
            end
            -- 同步热路径已有的 Setting 解锁状态
            entity:UpdateStoryAndSettingEntity(model._PartnerUnLockSettingDic)
            table.insert(model._ArchivePartnerList[template.GroupId], entity)
            model._ArchivePartnerData[template.Id] = entity
        end
    end
    for _, group in pairs(model._ArchivePartnerList) do
        model:SortByOrder(group)
    end
end

PrivateFuncMap.InitPVDetail = function(model)
    if model._IsInitPVDetail then
        return
    end

    for id, v in pairs(model:GetPVDetail()) do
        if not model._PVGroupIdToDetailIdList[v.GroupId] then
            model._PVGroupIdToDetailIdList[v.GroupId] = {}
        end
        table.insert(model._PVGroupIdToDetailIdList[v.GroupId], id)
        table.insert(model._PVDetailIdList, id)
    end
    for _, idList in pairs(model._PVGroupIdToDetailIdList) do
        table.sort(idList, function(a, b)
            return a < b
        end)
    end

    model._IsInitPVDetail = true
end
--endregion ----------private end----------

--region ----------config start----------
--region 基础读表
function XArchiveModel:GetArchiveWeaponGroup()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchiveWeaponGroup)
end

function XArchiveModel:GetArchiveAwarenessGroup()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchiveAwarenessGroup)
end

function XArchiveModel:GetArchiveAwarenessGroupCfgById(suitId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArchiveClientTableKey.ArchiveAwarenessGroup, suitId)
end

function XArchiveModel:GetArchiveAwarenessGroupType()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchiveAwarenessGroupType)
end

function XArchiveModel:GetArchivePartner()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchivePartner)
end

function XArchiveModel:GetArchivePartnerGroup()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchivePartnerGroup)
end

function XArchiveModel:GetPVGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_PVGROUP)
end

function XArchiveModel:GetTag()
    return self._ConfigUtil:Get(TablePathTable.TABLE_TAG)
end

function XArchiveModel:GetArchive()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.Archive)
end

function XArchiveModel:GetArchiveMail()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.ArchiveMail)
end

function XArchiveModel:GetAwarenessSetting()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.AwarenessSetting)
end

function XArchiveModel:GetWeaponSetting()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.WeaponSetting)
end

function XArchiveModel:GetStoryGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYGROUP)
end

function XArchiveModel:GetStoryChapter()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYCHAPTER)
end

function XArchiveModel:GetStoryDetail()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYDETAIL)
end

function XArchiveModel:GetStoryNpc()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYNPC)
end

function XArchiveModel:GetStoryNpcSetting()
    return self._ConfigUtil:Get(TablePathTable.TABLE_STORYNPCSETTING)
end

function XArchiveModel:GetCGDetail()
    return self._ConfigUtil:Get(TablePathTable.TABLE_CGDETAIL)
end

function XArchiveModel:GetCGGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_CGGROUP)
end

function XArchiveModel:GetCommunication()
    return self._ConfigUtil:Get(TablePathTable.TABLE_COMMUNICATION)
end

function XArchiveModel:GetEventDateGroup()
    return self._ConfigUtil:Get(TablePathTable.TABLE_EVENTDATEGROUP)
end

function XArchiveModel:GetPartnerSetting()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.PartnerSetting)
end

function XArchiveModel:GetPVDetail()
    return self._ConfigUtil:Get(TablePathTable.TABLE_PVDETAIL)
end

function XArchiveModel:GetPVDetailById(id)
    if not self:GetPVDetail()[id] then
        XLog.Error("Id is not exist in Share/Archive/PVDetail.tab id = " .. id)
        return
    end
    return self:GetPVDetail()[id]
end

--- ComicGroup
function XArchiveModel:GetComicGroupCfgs()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.ArchiveComicGroup)
end

function XArchiveModel:GetComicGroupCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArchiveShareTableKey.ArchiveComicGroup, id)
end

--- ComicChapter

function XArchiveModel:GetComicChapterCfgs()
    return self._ConfigUtil:GetByTableKey(ArchiveShareTableKey.ArchiveComicChapter)
end

function XArchiveModel:GetComicChapterCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArchiveShareTableKey.ArchiveComicChapter, id)
end

--- ComicDetail

function XArchiveModel:GetComicDetailCfgs()
    return self._ConfigUtil:GetByTableKey(ArchiveClientTableKey.ArchiveComicDetail)
end

function XArchiveModel:GetComicDetailCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArchiveClientTableKey.ArchiveComicDetail, id)
end

--endregion

--region 二次配置
function XArchiveModel:GetArchiveTagAllList()
    if XTool.IsTableEmpty(self._ArchiveTagAllList) then
        local tags = self:GetTag()
        if not XTool.IsTableEmpty(tags) then
            for _, tag in pairs(tags) do
                for _, groupId in pairs(tag.TagGroupId) do
                    if not self._ArchiveTagAllList[groupId] then
                        self._ArchiveTagAllList[groupId] = {}
                    end
                    if tag.IsNotShow == 0 then
                        table.insert(self._ArchiveTagAllList[groupId], tag)
                    end
                end
            end
        end
        for _, v in pairs(self._ArchiveTagAllList) do
            self:SortByOrder(v)
        end
    end

    return self._ArchiveTagAllList
end

function XArchiveModel:GetShowedWeaponTypeList()
    if XTool.IsTableEmpty(self._ShowedWeaponTypeList) then
        local weaponGroupData = self:GetArchiveWeaponGroup()
        for _, group in pairs(weaponGroupData) do
            table.insert(self._ShowedWeaponTypeList, group.Id)
        end

        table.sort(self._ShowedWeaponTypeList, function(aType, bType)
            local aData = weaponGroupData[aType]
            local bData = weaponGroupData[bType]
            return aData.Order < bData.Order
        end)
    end

    return self._ShowedWeaponTypeList
end

function XArchiveModel:GetWeaponTemplateIdToSettingListDic()
    if XTool.IsTableEmpty(self._WeaponTemplateIdToSettingListDic) then
        local equipId
        for _, settingData in pairs(self:GetWeaponSetting()) do
            equipId = settingData.EquipId
            self._WeaponTemplateIdToSettingListDic[equipId] = self._WeaponTemplateIdToSettingListDic[equipId] or {}
            table.insert(self._WeaponTemplateIdToSettingListDic[equipId], settingData)
        end
    end

    return self._WeaponTemplateIdToSettingListDic
end

function XArchiveModel:GetWeaponSumCollectNum()
    if not XTool.IsNumberValid(self._WeaponSumCollectNum) then
        self._WeaponSumCollectNum = 0
        for _, _ in pairs(self:GetWeaponTemplateIdToSettingListDic()) do
            self._WeaponSumCollectNum = self._WeaponSumCollectNum + 1
        end
    end

    return self._WeaponSumCollectNum
end

function XArchiveModel:GetWeaponTypeToIdsDic()
    if XTool.IsTableEmpty(self._WeaponTypeToIdsDic) then
        for type, _ in pairs(self:GetArchiveWeaponGroup()) do
            self._WeaponTypeToIdsDic[type] = {}
        end

        local templateData
        local equipType
        for templateId, _ in pairs(self:GetWeaponTemplateIdToSettingListDic()) do
            templateData = XMVCA.XEquip:GetConfigEquip(templateId)
            equipType = templateData.Type
            if self._WeaponTypeToIdsDic[equipType] then
                table.insert(self._WeaponTypeToIdsDic[equipType], templateId)
            end
        end
    end

    return self._WeaponTypeToIdsDic
end

function XArchiveModel:GetArchiveStoryGroupAllList()
    if XTool.IsTableEmpty(self._ArchiveStoryGroupAllList) then
        local storyGroup = self:GetStoryGroup()
        if not XTool.IsTableEmpty(storyGroup) then
            for _, group in pairs(storyGroup) do
                table.insert(self._ArchiveStoryGroupAllList, group)
            end
        end
        self:SortByOrder(self._ArchiveStoryGroupAllList)
    end

    return self._ArchiveStoryGroupAllList
end

function XArchiveModel:GetArchiveStoryChapterList()
    if XTool.IsTableEmpty(self._ArchiveStoryChapterList) then
        PrivateFuncMap.InitArchiveStoryChapterList(self)
    end
    return self._ArchiveStoryChapterList
end

function XArchiveModel:GetArchiveStoryChapterDic()
    if XTool.IsTableEmpty(self._ArchiveStoryChapterDic) then
        PrivateFuncMap.InitArchiveStoryChapterList(self)
    end
    return self._ArchiveStoryChapterDic
end

function XArchiveModel:GetArchiveStoryDetailList()
    if XTool.IsTableEmpty(self._ArchiveStoryDetailList) then
        PrivateFuncMap.InitArchiveStoryDetailAllList(self)
    end
    return self._ArchiveStoryDetailList
end

function XArchiveModel:GetArchiveStoryNpcList()
    if XTool.IsTableEmpty(self._ArchiveStoryNpcList) then
        PrivateFuncMap.InitArchiveStoryNpcAllList(self)
    end
    return self._ArchiveStoryNpcList
end

function XArchiveModel:GetArchiveStoryNpcSettingList()
    if XTool.IsTableEmpty(self._ArchiveStoryNpcSettingList) then
        PrivateFuncMap.InitArchiveStoryNpcSettingAllList(self)
    end
    return self._ArchiveStoryNpcSettingList
end

function XArchiveModel:GetArchiveCGDetailList()
    if XTool.IsTableEmpty(self._ArchiveCGDetailList) then
        PrivateFuncMap.InitArchiveCGAllList(self)
    end
    return self._ArchiveCGDetailList
end

function XArchiveModel:GetArchiveCGDetailData()
    if XTool.IsTableEmpty(self._ArchiveCGDetailData) then
        PrivateFuncMap.InitArchiveCGAllList(self)
    end
    return self._ArchiveCGDetailData
end

--- 判断指定CG是否应产生红点，以及是否需要暂存（未到显示时间）
--- 不触发 Entity 懒加载，直接读配置表
--- @return boolean shouldShow, boolean isHide, number groupId
function XArchiveModel:CheckCGShouldShowRedPoint(cgId, nowTimestamp)
    local cfg = self:GetCGDetail()[cgId]
    if not cfg or cfg.IsShowRedPoint ~= 1 then
        return false, false, 0
    end
    local isHide = false
    if not string.IsNilOrEmpty(cfg.ShowTimeStr) then
        isHide = nowTimestamp < XTime.ParseToTimestamp(cfg.ShowTimeStr)
    end
    return true, isHide, cfg.GroupId
end

--- 热路径：不触发 Entity 懒加载，直接用配置表 + 热数据统计 CG 完成度
--- @return number unlockCount, number totalCount
function XArchiveModel:GetCGCompletionCount()
    local nowTime = XTime.GetServerNowTimestamp()
    local total, unlocked = 0, 0
    for id, cfg in pairs(self:GetCGDetail()) do
        if not string.IsNilOrEmpty(cfg.ShowTimeStr) then
            if nowTime < XTime.ParseToTimestamp(cfg.ShowTimeStr) then
                goto continue
            end
        end
        total = total + 1
        if self._ArchiveShowedCGList[id] then
            unlocked = unlocked + 1
        else
            local isUnlock = false
            local unLockTime = cfg.UnLockTime and XTime.ParseToTimestamp(cfg.UnLockTime) or 0
            local conditionId = cfg.Condition
            if not XTool.IsNumberValid(unLockTime) and not XTool.IsNumberValid(conditionId) then
                isUnlock = true
            else
                if XTool.IsNumberValid(unLockTime) and nowTime >= unLockTime then
                    isUnlock = true
                elseif XTool.IsNumberValid(conditionId) then
                    isUnlock = XConditionManager.CheckCondition(conditionId)
                end
            end
            if isUnlock then
                unlocked = unlocked + 1
            end
        end
        :: continue ::
    end
    return unlocked, total
end

function XArchiveModel:GetArchiveMailList()
    if XTool.IsTableEmpty(self._ArchiveMailList) then
        PrivateFuncMap.InitArchiveMailList(self)
    end
    return self._ArchiveMailList
end

function XArchiveModel:GetArchiveCommunicationList()
    if XTool.IsTableEmpty(self._ArchiveCommunicationList) then
        PrivateFuncMap.InitArchiveCommunicationList(self)
    end
    return self._ArchiveCommunicationList
end

function XArchiveModel:GetArchivePartnerList()
    if XTool.IsTableEmpty(self._ArchivePartnerList) then
        PrivateFuncMap.InitArchivePartnerList(self)
    end
    return self._ArchivePartnerList
end

function XArchiveModel:GetArchivePartnerSettingList()
    if XTool.IsTableEmpty(self._ArchivePartnerSettingList) then
        PrivateFuncMap.InitArchivePartnerSetting(self)
    end
    return self._ArchivePartnerSettingList
end

function XArchiveModel:GetPVDetailIdList(groupId)
    PrivateFuncMap.InitPVDetail(self)
    return groupId and self._PVGroupIdToDetailIdList[groupId] or self._PVDetailIdList
end
--endregion
--endregion ----------config end----------


return XArchiveModel