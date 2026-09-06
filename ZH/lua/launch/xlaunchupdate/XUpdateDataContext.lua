----------------------------------------------------------------------------------------------------
-- XUpdateDataContext.lua
-- description: 模块更新数据容器，管理索引表、文件信息、下载列表及大小统计
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsLog = CS.XLog
local CsFile = CS.System.IO.File
local StringFormat = string.format

local XFileInfoSizeIndex = XLaunchConst.XFileInfoSizeIndex

local XLaunchDlcManager = require("XLaunchDlcManager")
require("XLaunchCommon/XMessagePack")

---@class XPatchInfo
---@field FileName string 文件名
---@field OldVersion string 旧版本号
---@field NewVersion string 新版本号
---@field Size number 大小
---@field Sha1 string SHA1值

---@class XUpdateDataContext
---@field New fun(...): XUpdateDataContext 创建对象
---@field _BaseDownloadSize number 基础下载大小
---@field _TotalDownloadSize number 总下载大小
---@field _TotalABFileSize number 总文件大小
---@field _PatchFileCount number Patch文件数量
---@field _PathToInfo table<string, CS.XFileInfo> 路径到文件信息映射
---@field _NeedDownloadAbMap table<string, CS.XFileInfo> 需要下载的AB文件映射
---@field _NeedDownloadPatchMap table<string, XPatchInfo> 需要下载的Patch文件映射
local XUpdateDataContext = XLaunchConst.CreateMetaTable("XUpdateDataContext")

function XUpdateDataContext:Ctor()
    self._BaseDownloadSize = 0
    self._TotalDownloadSize = 0
    self._TotalABFileSize = 0
    self._AbFileCount = 0
    self._PatchFileCount = 0
    self._NeedDownloadPatchMap = {}
    self._NeedDownloadAbMap = {}
    self._NeedPatchMap = {}
end

-- region Index 读写

-- 读取Index文件
---@param indexPath string Index文件路径
---@param isDlcBuild? boolean 是否是DLC构建
---@return table<string, CS.XFileInfo>|nil indexTable
---@return table<string, CS.XFileInfo>|nil dlcIndexTable
function XUpdateDataContext:LoadIndexTable(indexPath, isDlcBuild)
    if CS.XResourceManager.NeedLaunchTest and not CsFile.Exists(indexPath) then return {} end

    CsLog.Debug(StringFormat("[Download] LoadIndexTable: %s", indexPath))
    local assetBundle = CS.UnityEngine.AssetBundle.LoadFromFile(indexPath)
    if assetBundle and assetBundle:Exist() then
        local assetName = assetBundle:GetAllAssetNames()[0]
        local asset = assetBundle:LoadAsset(assetName, typeof(CS.UnityEngine.TextAsset))
        local indexFile = XMessagePack.Decode(asset.bytes)
        assetBundle:Unload(true)
        if isDlcBuild then
            return indexFile[1], indexFile[2], indexFile[4], indexFile[5]
        else
            return indexFile[1]
        end
    end
    return nil
end

-- endregion

-- region PathToInfo

-- 初始化路径到文件信息映射
-- @param indexMap table<string, CS.XFileInfo> 索引表
function XUpdateDataContext:SetFileInfo(indexMap)
    self._PathToInfo = indexMap
end

---@param fileName string
---@return CS.XFileInfo|nil
function XUpdateDataContext:GetFileInfoByPath(fileName)
    return self._PathToInfo[fileName]
end

---@return table<string, CS.XFileInfo>
function XUpdateDataContext:GetFileInfos()
    return self._PathToInfo
end

-- endregion

-- 获取asset是不是基础包
---@param fileName string
---@return boolean
function XUpdateDataContext:IsBaseAsset(fileName)
    return not XLaunchDlcManager.IsDlcAsset(fileName)
        or XLaunchDlcManager.IsNecessaryAsset(fileName)
        or self:IsBaseRelative(fileName)
end

-- region DownloadAbMap

-- 获取下载Ab列表
---@return table<string, CS.XFileInfo>
function XUpdateDataContext:GetDownloadABMap()
    return self._NeedDownloadAbMap
end

-- 清空下载Ab列表
function XUpdateDataContext:ClearDownloadABMap()
    self._NeedDownloadAbMap = {}
end

-- 添加下载Ab列表
---@param fileName string
function XUpdateDataContext:AddDownloadABMap(fileName, skipCheck)
    if self._NeedDownloadAbMap[fileName] then return end

    local info = self:GetFileInfoByPath(fileName)
    -- 下载过了就跳过
    if not skipCheck and self:IsDownloadFile(fileName) then return end

    -- 缓存
    self._NeedDownloadAbMap[fileName] = info

    -- 大小计算
    local size = info[XFileInfoSizeIndex]
    self._TotalDownloadSize = self._TotalDownloadSize + size
    if self:IsBaseAsset(fileName) then
        self._BaseDownloadSize = self._BaseDownloadSize + size
    end
    self._TotalABFileSize = self._TotalABFileSize + size
    self._AbFileCount = self._AbFileCount + 1
end

-- 删除下载Ab列表（基础包不会移除）
---@param fileName string
function XUpdateDataContext:RemoveDownloadABMap(fileName)
    local info = self._NeedDownloadAbMap[fileName]
    if not info then return end

    self._NeedDownloadAbMap[fileName] = nil

    -- 减去下载大小
    local size = info[XFileInfoSizeIndex]
    self._TotalDownloadSize = self._TotalDownloadSize - size
    if self:IsBaseAsset(fileName) then
        self._BaseDownloadSize = self._BaseDownloadSize - size
    end
    self._TotalABFileSize = self._TotalABFileSize - size
    self._AbFileCount = self._AbFileCount - 1
end

-- endregion

-- region DownloadPatchMap

-- 获取下载Patch列表
---@return table<string, XPatchInfo>
function XUpdateDataContext:GetDownloadPatchMap()
    return self._NeedDownloadPatchMap
end

function XUpdateDataContext:GetPatchMap()
    return self._NeedPatchMap
end

-- 添加下载Patch列表
---@param fileName string
---@param info table
function XUpdateDataContext:AddDownloadPatchMap(fileName, info)
    local infoDetail = self:GetFileInfoByPath(fileName)
    local isDownloaded = self:IsDownloadFile(fileName .. ".patch")

    if not isDownloaded and not self._NeedDownloadPatchMap[fileName] then
        self._NeedDownloadPatchMap[fileName] = info
        -- Patch 文件大小在构建列表时未知，暂不计入下载总量
        local size = info.Size
        self._TotalDownloadSize = self._TotalDownloadSize + size
        if self:IsBaseAsset(fileName) then
            self._BaseDownloadSize = self._BaseDownloadSize + size
        end

        -- ab size(下载后应用需要的空间)
        local size = infoDetail[XFileInfoSizeIndex]
        self._TotalABFileSize = self._TotalABFileSize + size
        self._PatchFileCount = self._PatchFileCount + 1
    end

    local isPatched = self:IsPatchFile(fileName)
    if not isPatched and not self._NeedPatchMap[fileName] then
        self._NeedPatchMap[fileName] = info
    end
end

-- 删除下载Patch列表
---@param fileName string
function XUpdateDataContext:RemoveDownloadPatchMap(fileName)
    self._NeedPatchMap[fileName] = nil

    local info = self._NeedDownloadPatchMap[fileName]
    if not info then return end

    local size = info.Size
    self._TotalDownloadSize = self._TotalDownloadSize - size
    if self:IsBaseAsset(fileName) then
        self._BaseDownloadSize = self._BaseDownloadSize - size
    end
    self._NeedDownloadPatchMap[fileName] = nil

    local info = self:GetFileInfoByPath(fileName)
    local size = info[XFileInfoSizeIndex]
    self._TotalABFileSize = self._TotalABFileSize - size
    self._PatchFileCount = self._PatchFileCount - 1
end

-- endregion

-- region 大小统计

-- 获取基础包下载大小
---@return number
function XUpdateDataContext:GetBaseDownloadSize()
    return self._BaseDownloadSize
end

-- 获取全量包下载大小
---@return number
function XUpdateDataContext:GetTotalDownloadSize()
    return self._TotalDownloadSize
end

-- 获取下载所需的Ab文件大小（patch下载也要统计合并后的文件大小）
---@return number
function XUpdateDataContext:GetTotalABFileSize()
    return self._TotalABFileSize
end

-- 获取Patch文件数量
---@return number
function XUpdateDataContext:GetPatchFileCount()
    return self._PatchFileCount
end

function XUpdateDataContext:SetUpdateCheckTable(checkTable)
    self._UpdateCheckTable = checkTable
end

function XUpdateDataContext:GetUpdateCheckTable()
    return self._UpdateCheckTable
end

function XUpdateDataContext:IsBaseRelative(fileName)
    if not self._UpdateCheckTable then return false end
    return self._UpdateCheckTable[fileName]
end

-- endregion

-- region 下载缓存

-- 读取下载缓存
---@param cacheFilePath string 缓存文件路径
function XUpdateDataContext:ReadDownloadCache()
    self._DownloadCount = 0
    self._DownloadCache = {}
    if not self._CacheFilePath or not CsFile.Exists(self._CacheFilePath) then
        return
    end
    local content = XLaunchConst.ReadAllText(self._CacheFilePath)
    local contentList = XLaunchConst.Split(content, "\n")
    for _, name in ipairs(contentList) do
        self._DownloadCount = self._DownloadCount + 1
        self._DownloadCache[name] = true
    end
end

-- 写入下载缓存
---@param finishName string 下载完成的文件名
function XUpdateDataContext:WriteDownloadCache(finishName)
    XLaunchDlcManager.WriteDownloadCache(finishName, true)
    if not self._DownloadCache then
        self._DownloadCache = {}
        self._DownloadCount = 0
    end
    local fileName = XLaunchConst.GetFileName(finishName)
    if self._DownloadCache[fileName] then
        return
    end
    self._DownloadCount = self._DownloadCount + 1
    self._DownloadCache[fileName] = true
    XLaunchConst.WriteAllText(self._CacheFilePath, fileName .. "\n", "a")
end


---@param cacheFilePath string 缓存文件路径
function XUpdateDataContext:ReadPatchCache()
    self._PatchCache = {}
    if not self._CacheFilePatchPath or not CsFile.Exists(self._CacheFilePatchPath) then
        return
    end
    local content = XLaunchConst.ReadAllText(self._CacheFilePatchPath)
    local contentList = XLaunchConst.Split(content, "\n")
    for _, name in ipairs(contentList) do
        self._PatchCache[name] = true
    end
end

-- 写入下载缓存
---@param finishName string 下载完成的文件名
function XUpdateDataContext:WritePatchCache(finishName)
    if not self._PatchCache then
        self._PatchCache = {}
    end
    local fileName = XLaunchConst.GetFileName(finishName)
    if self._PatchCache[fileName] then return end

    self._PatchCache[fileName] = true
    XLaunchConst.WriteAllText(self._CacheFilePatchPath, fileName .. "\n", "a")
end

-- 获取下载缓存数量
---@return number
function XUpdateDataContext:GetDownloadCacheCount()
    return self._DownloadCount or 0
end

-- 设置缓存文件路径
---@param path string
function XUpdateDataContext:SetCacheFilePath(moduleUpdateInfo)
    self._CacheFilePath = moduleUpdateInfo:GetCacheFilePath()
    self._CacheFilePatchPath = moduleUpdateInfo:GetCacheFilePatchPath()
end

-- 判断是否已下载过该文件
---@param fileName string
---@return boolean
function XUpdateDataContext:IsDownloadFile(fileName)
    if not self._DownloadCache then return false end
    return self._DownloadCache[fileName]
end

-- 判断是否已下载过该patch文件
function XUpdateDataContext:IsPatchFile(fileName)
    if not self._PatchCache then return false end
    return self._PatchCache[fileName]
end

-- 清除所有缓存
function XUpdateDataContext:ClearCache()
    xpcall(function()
        -- 删除缓存文件
        if self._CacheFilePath and CsFile.Exists(self._CacheFilePath) then
            CsFile.Delete(self._CacheFilePath)
        end

        -- 删除补丁缓存文件
        if self._CacheFilePatchPath and CsFile.Exists(self._CacheFilePatchPath) then
            CsFile.Delete(self._CacheFilePatchPath)
        end
    end, function(err)
        CsLog.Error(err)
    end)
end

-- endregion

-- 清理数据
function XUpdateDataContext:Clear()
    self._DownloadCache = nil
    self._PatchCache = nil

    self._PathToInfo = nil
    self._NeedDownloadPatchMap = {}
    self._NeedDownloadAbMap = {}
    self._NeedPatchMap = {}
    self._BaseDownloadSize = 0
    self._TotalDownloadSize = 0
    self._TotalABFileSize = 0
    self._AbFileCount = 0
    self._PatchFileCount = 0
end

return XUpdateDataContext
