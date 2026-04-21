---@class XSubPackageModel : XModel
---@field _SubpackageDict table<number, XSubpackage>
local XSubPackageModel = XClass(XModel, "XSubPackageModel")

local XSubpackage

local TableKey = {
    --分包分组
    SubPackageGroup = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.IntAll,
    },
    --分包
    SubPackage = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.IntAll,
    },
    --分包拦截检测
    SubPackageIntercept = {
        CacheType = XConfigUtil.CacheType.Temp,
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.IntAll,
    },
    StageIdToResIdList = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "StageId",
    },
    --涂装下载配置
    FashionDownloadConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "FashionId",
    },
    --下载预览控制配置
    UiDownloadPreviewControl = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.IntAll,
    },
    --玩法涂装关联配置
    FunctionIdFashionRelative = {
        CacheType = XConfigUtil.CacheType.Temp,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "FunctionId",
    },
    --章节涂装关联配置
    ChapterFashionRelative = {
        CacheType = XConfigUtil.CacheType.Temp,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "ChapterId",
    },
}

function XSubPackageModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("SubPackage", TableKey)

    self._SubpackageDict = {}
    
    self._ResourceDict = {}
    
    self.HasResIdCheckStoryId = {} -- 是否被检查过

    self._NecessarySubIds = nil --必要资源

    self._SubId2GroupId = {}
    
    self._ResId2PackageId = nil

    self._SubIntercept = nil

    self._IsDlcBuild = CS.XInfo.IsDlcBuild

    self._LaunchType = CS.XRemoteConfig.LaunchSelectType
end

function XSubPackageModel:ClearPrivate()
    self:ClearTemp()
end

function XSubPackageModel:ResetAll()
    self:ClearTemp()
end

function XSubPackageModel:ClearTemp()
    self._GroupIdList = nil
    self._NecessarySubIds = nil
    self._ResId2PackageId = nil
end

function XSubPackageModel:GetGroupIdList()
    if self._GroupIdList then
        return self._GroupIdList
    end

    local list = {}

    ---@type table<number, XTableSubPackageGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackageGroup)
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    table.sort(list, function(a, b)
        return a < b
    end)

    self._GroupIdList = list

    return list
end

function XSubPackageModel:InitSubIntercept()
    self._SubIntercept = {}
    ---@type table<number, XTableSubPackageIntercept>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackageIntercept)
    for _, template in pairs(templates) do
        if not self._SubIntercept[template.EntryType] then
            self._SubIntercept[template.EntryType] = {}
        end

        if not self._SubIntercept["ExtraSubPackageIds"] then
            self._SubIntercept["ExtraSubPackageIds"] = {}
        end

        if not self._SubIntercept["ExtraSubPackageIds"][template.EntryType] then
            self._SubIntercept["ExtraSubPackageIds"][template.EntryType] = {}
        end

        -- 新增：WeakSubPackageIds 维度
        if not self._SubIntercept["WeakSubPackageIds"] then
            self._SubIntercept["WeakSubPackageIds"] = {}
        end

        if not self._SubIntercept["WeakSubPackageIds"][template.EntryType] then
            self._SubIntercept["WeakSubPackageIds"][template.EntryType] = {}
        end

        if XTool.IsTableEmpty(template.Params) then
            self._SubIntercept[template.EntryType][0] = template.MainSubPackageId
        else
            for _, param in pairs(template.Params) do
                self._SubIntercept[template.EntryType][param] = template.MainSubPackageId
            end
        end

        if not XTool.IsTableEmpty(template.ExtraSubPackageIds) then
            self._SubIntercept["ExtraSubPackageIds"][template.EntryType][template.MainSubPackageId] = template.ExtraSubPackageIds
        end

        -- 新增：存储 WeakSubPackageIds
        if not XTool.IsTableEmpty(template.WeakSubPackageIds) then
            self._SubIntercept["WeakSubPackageIds"][template.EntryType][template.MainSubPackageId] = template.WeakSubPackageIds
        end
    end
end

--- 获取分包组配置
---@param groupId number 组Id
---@return XTableSubPackageGroup
--------------------------
function XSubPackageModel:GetGroupTemplate(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SubPackageGroup, groupId)
end

--- 获取分包配置
---@param subpackageId number
---@return XTableSubPackage
--------------------------
function XSubPackageModel:GetSubpackageTemplate(subpackageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SubPackage, subpackageId)
end

function XSubPackageModel:GetSubPackageName(subpackageId)
    local template = self:GetSubpackageTemplate(subpackageId)
    return template and template.Name or "???"
end

function XSubPackageModel:GetSubpackageIndex(subpackageId)
    local template = self:GetSubpackageTemplate(subpackageId)
    return template and template.Index or "???"
end

function XSubPackageModel:GetSubpackageDownloadTaskId(subpackageId)
    local template = self:GetSubpackageTemplate(subpackageId)
    return template and template.DownloadTaskId or "???"
end

function XSubPackageModel:GetStageIdToResIdList()
    return self._ConfigUtil:GetByTableKey(TableKey.StageIdToResIdList)
end

---@return XTableStageIdToResIdList[]
function XSubPackageModel:GetStageIdToResIdListConfigByStageId(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageIdToResIdList, stageId, true)
end

---@return XSubpackage
function XSubPackageModel:GetSubpackageItem(subpackageId)
    if not XTool.IsNumberValid(subpackageId) then return end

    local groupId = self:GetSubpackageGroupId(subpackageId)
    if not groupId then
        XLog.Warning("Could not found subpackageId = " .. tostring(subpackageId))
        return
    end
    local item = self._SubpackageDict[subpackageId]
    if not item then
        if not XSubpackage then
            XSubpackage = require("XModule/XSubPackage/XEntity/XSubpackage")
        end
        item = XSubpackage.New(subpackageId)
        self._SubpackageDict[subpackageId] = item
    end

    return item
end

function XSubPackageModel:GetSubpackageDict()
    return self._SubpackageDict
end

---@return XResource
function XSubPackageModel:GetResourceItem(resId)
    if not XTool.IsNumberValid(resId) then return end

    local item = self._ResourceDict[resId]
    if not item then
        local XResource = require("XModule/XSubPackage/XEntity/XResource")
        item = XResource.New(resId)
        self._ResourceDict[resId] = item
    end

    return item
end

function XSubPackageModel:ResolveComplete()
    for _, item in pairs(self._ResourceDict) do
        item:FileInitComplete()
    end

    for _, item in pairs(self._SubpackageDict) do
        item:FileInitComplete()
    end
end

function XSubPackageModel:InitSubpackage()
    ---@type table<number, XTableSubPackage>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackage)
    local nType = XEnumConst.SUBPACKAGE.SUBPACKAGE_TYPE.NECESSARY
    local list = {}
    local dict = {}
    for _, template in pairs(templates) do
        if template.Type == nType then
            table.insert(list, template.Id)
        end
        local resIds = template.ResIds
        for _, resId in pairs(resIds) do
            local lst = dict[resId]
            if not lst then
                lst = {}
                dict[resId] = lst
            end
            lst[#lst + 1] = template.Id
        end
    end

    table.sort(list, function(a, b)
        local templateA = self:GetSubpackageTemplate(a)
        local templateB = self:GetSubpackageTemplate(b)
        return templateA.Index < templateB.Index
    end)

    self._ResId2PackageId = dict
    self._NecessarySubIds = list
end

function XSubPackageModel:GetNecessarySubIds()
    if self._NecessarySubIds then
        return self._NecessarySubIds
    end
    self:InitSubpackage()

    return self._NecessarySubIds
end

-- [XSubPackageModel.lua] 新增方法
function XSubPackageModel:RemoveResCache(resId)
    -- 1. 从 Model 缓存中移除 (下次 GetResourceItem 会 New 一个新的)
    self._ResourceDict[resId] = nil

    -- 2. 通知所有包含该 Res 的 Subpackage 也移除引用
    local subIds = self:GetSubpackageIdByResId(resId)
    if subIds then
        for _, subId in ipairs(subIds) do
            local subItem = self._SubpackageDict[subId]
            if subItem then
                subItem:RemoveResCache(resId)
            end
        end
    end
end

function XSubPackageModel:GetSubpackageIdByResId(resId)
    if self._ResId2PackageId and self._ResId2PackageId[resId] then
        return self._ResId2PackageId[resId]
    end
    self:InitSubpackage()

    return self._ResId2PackageId[resId]
end

function XSubPackageModel:GetSubpackageGroupId(subpackageId)
    if not XTool.IsTableEmpty(self._SubId2GroupId) then
        return self._SubId2GroupId[subpackageId]
    end
    self._SubId2GroupId = {}

    ---@type table<number, XTableSubPackageGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackageGroup)
    for _, template in pairs(templates) do
        for _, subId in pairs(template.SubPackageId) do
            self._SubId2GroupId[subId] = template.Id
        end
    end

    return self._SubId2GroupId[subpackageId]
end

function XSubPackageModel:GetEntrySubpackageId(entryType, param)
    --不填，检测必要资源
    if not entryType then
        return XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY
    end
    param = param or 0
    if not self._SubIntercept then
        self:InitSubIntercept()
    end
    if not self._SubIntercept[entryType] then
        return XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.INVALID
    end
    local subId = self._SubIntercept[entryType][param]
    --未找到，检测必要资源
    if not subId then
        return XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY
    end

    return subId
end

--玩法入口依赖的所有Subpackage
function XSubPackageModel:GetAllSubpackageIds(entryType, param)
    local subId = self:GetEntrySubpackageId(entryType, param)
    -- XLog.Debug("SP/DN GetAllSubpackageIds 拿到 ", entryType,param,  subId)
    --不依赖分包
    if subId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.INVALID then
        return nil
    elseif subId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY then
        -- 必要资源SubPackageId
        local list = self:GetNecessarySubIds()

        -- XLog.Debug("SP/DN GetAllSubpackageIds 拿 NECESSARY ", entryType,param,  list)

        -- ExtraSubPackageIds 的作用是策划可以自定义配置不同的SubPackageId
        if entryType then
            local tempList = self._SubIntercept["ExtraSubPackageIds"][entryType]
            local extraSubPackageIds = tempList and tempList[subId] 

            -- XLog.Debug("SP/DN  GetAllSubpackageIds 追 NECESSARY", entryType,  extraSubPackageIds)

            if not XTool.IsTableEmpty(extraSubPackageIds) then
                for _, subpackageId in ipairs(extraSubPackageIds) do
                    list[#list + 1] = subpackageId
                end
            end
        end
        return list
    else
        -- 自定义的SubPackageId
        local template = self:GetSubpackageTemplate(subId)
        local list = { subId }
        for _, subpackageId in ipairs(template.PreIds or {}) do
            list[#list + 1] = subpackageId
        end

        -- XLog.Debug("SP/DN GetAllSubpackageIds 拿 普通 ", entryType,param,  list)

        if entryType then
            local tempList = self._SubIntercept["ExtraSubPackageIds"][entryType]
            local extraSubPackageIds = tempList and tempList[subId] 

            -- XLog.Debug("SP/DN  GetAllSubpackageIds 追 普通", entryType,  extraSubPackageIds)

            if not XTool.IsTableEmpty(extraSubPackageIds) then
                for _, subpackageId in ipairs(extraSubPackageIds) do
                    list[#list + 1] = subpackageId
                end
            end
        end

        return list
    end
end

--- 获取玩法入口的弱拦截SubPackageIds
--- 注意：不走GetEntrySubpackageId，因为MainSubPackageId=-1(INVALID)时仍可能配有WeakSubPackageIds
---@param entryType number 入口类型
---@param param number 附加参数
---@return table|nil 弱拦截subId列表
function XSubPackageModel:GetWeakSubpackageIds(entryType, param)
    if not entryType then
        return nil
    end
    if not self._SubIntercept then
        self:InitSubIntercept()
    end

    -- 直接用entryType+param查原始MainSubPackageId作为key
    if not self._SubIntercept[entryType] then
        return nil
    end
    param = param or 0
    local mainSubId = self._SubIntercept[entryType][param]
    if mainSubId == nil then
        -- param未命中，尝试用0作为默认key
        mainSubId = self._SubIntercept[entryType][0]
    end
    if mainSubId == nil then
        return nil
    end

    local weakDict = self._SubIntercept["WeakSubPackageIds"]
    if not weakDict or not weakDict[entryType] then
        return nil
    end

    return weakDict[entryType][mainSubId]
end

function XSubPackageModel:GetCookieKey(key)
    --资源只与包体有关，跟账号无关联
    return string.format("SUBPACKAGE_LOCAL_RECORD_%s", key)
end

function XSubPackageModel:GetWifiAutoSelect(groupId)
    local key = self:GetCookieKey("WIFI_SELECT" .. groupId)
    local data = XSaveTool.GetData(key)
    if not data then
        return false
    end
    return data
end

function XSubPackageModel:SaveWifiAutoSelect(groupId, value)
    local key = self:GetCookieKey("WIFI_SELECT" .. groupId)
    XSaveTool.SaveData(key, value)
end

--region 涂装分包配置

--- 获取涂装下载配置
---@param fashionId number 涂装Id
---@return XTableFashionDownloadConfig|nil
function XSubPackageModel:GetFashionDownloadConfig(fashionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionDownloadConfig, fashionId, true)
end

--- 获取所有涂装下载配置
---@return table<number, XTableFashionDownloadConfig>
function XSubPackageModel:GetAllFashionDownloadConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FashionDownloadConfig)
end

--endregion

--region 玩法涂装关联配置

--- 获取玩法涂装关联配置
---@param functionId number 玩法/功能Id
---@return XTableFunctionIdFashionRelative|nil
function XSubPackageModel:GetFunctionIdFashionRelativeConfig(functionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FunctionIdFashionRelative, functionId, true)
end

--- 获取章节涂装关联配置
---@param chapterId number 章节Id
---@return XTableChapterFashionRelative|nil
function XSubPackageModel:GetChapterFashionRelativeConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ChapterFashionRelative, chapterId, true)
end

--endregion

--region 下载预览控制配置

--- 获取下载预览控制配置
---@param id number 配置Id
---@return XTableUiDownloadPreviewControl|nil
function XSubPackageModel:GetDownloadPreviewControlConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.UiDownloadPreviewControl, id)
end

--- 获取所有下载预览控制配置
---@return table<number, XTableUiDownloadPreviewControl>
function XSubPackageModel:GetAllDownloadPreviewControlConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.UiDownloadPreviewControl)
end

--- 根据ResType获取下载预览控制配置
---@param resType number 资源类型枚举
---@return number|nil controlId
---@return XTableUiDownloadPreviewControl|nil config
function XSubPackageModel:GetControlConfigByResType(resType)
    local configs = self:GetAllDownloadPreviewControlConfigs()
    for id, config in pairs(configs) do
        if config.ResType == resType then
            return id, config
        end
    end
    return nil, nil
end

--- 获取Sub模式（ResType为空或0）的配表行，按Order升序排列
--- 约定：返回列表中第1个为强Sub选项，第2个为弱Sub选项
---@return table[] {Id=number, Config=XTableUiDownloadPreviewControl}
function XSubPackageModel:GetSortedSubModeConfigs()
    local configs = self:GetAllDownloadPreviewControlConfigs()
    local result = {}
    for id, config in pairs(configs) do
        if not XTool.IsNumberValid(config.ResType) or config.ResType == 0 then
            table.insert(result, {Id = id, Config = config})
        end
    end
    table.sort(result, function(a, b)
        return (a.Config.Order or 0) < (b.Config.Order or 0)
    end)
    return result
end

--endregion

return XSubPackageModel