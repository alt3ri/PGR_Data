----------------------------------------------------------------------------------------------------
-- XModuleUpdateInfo.lua
-- description: 模块更新信息 Launch和Matrix模块
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsInfo = CS.XInfo
local CsFile = CS.System.IO.File
local CsDirectory = CS.System.IO.Directory
local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs
local CsRemoteConfig = CS.XRemoteConfig
local LuaStringFormat = string.format

---@class XModuleUpdateInfo
---@field ResFileType string 模块类型 RES_FILE_TYPE.LAUNCH_MODULE or RES_FILE_TYPE.MATRIX_FILE
---@field AppVersion string app版本
---@field NewVersion string 远端版本
---@field OldVersion string 当前版本
---@field TempVersion string 临时版本
---@field Sha1 string 远端索引文件的sha1值
---@field IndexSize number 远端索引文件大小
---@field ApplicationFilePath string 应用文件路径
---@field DocumentFilePath string 文档文件路径
---@field DownloadFilePath string 下载文件路径
---@field PreloadFilePath string 预下载文件路径
---@field ApplicationIndex string 应用索引路径
---@field DocumentIndex string 文档索引路径
---@field DownloadIndex string 下载索引路径
---@field MODULE_VERSION_KEY string 模块的本地缓冲Key
---@field DocumentUrl string 远端url
local XModuleUpdateInfo = XLaunchConst.CreateMetaTable("XModuleUpdateInfo")

local TestOldVersion
local TestNewVersion
-- TestOldVersion = "1552833"
-- TestNewVersion = "1554298"
-- TestNewVersion = "1570040"

function XModuleUpdateInfo:_InitLaunchInfo()
    self.MODULE_VERSION_KEY = "LAUNCH_MODULE_VERSION"
    self.OldVersion = TestOldVersion or UnityPlayerPrefs.GetString(self.MODULE_VERSION_KEY, self.AppVersion)
    self.NewVersion = TestNewVersion or XLaunchConst.LeastLaunchVersion
    if XLaunchConst.ForceUpdate then
        self.Sha1 = ""
        self.IndexSize = -1
        self._IsSkipUpdate = false
    else
        self.Sha1 = CsRemoteConfig.LaunchIndexSha1 or ""
        self.IndexSize = CsRemoteConfig.LaunchIndexSize or -1
        self._IsSkipUpdate = self.AppVersion == CsRemoteConfig.LaunchModuleVersion
    end
end

function XModuleUpdateInfo:_InitMatrixInfo()
    self.MODULE_VERSION_KEY = "DOCUMENT_VERSION"
    self.OldVersion = TestOldVersion or UnityPlayerPrefs.GetString(self.MODULE_VERSION_KEY, self.AppVersion)
    self.NewVersion = TestNewVersion or XLaunchConst.LeastVersionFile
    if XLaunchConst.ForceUpdate then
        self.Sha1 = ""
        self.IndexSize = -1
        self._IsSkipUpdate = false
    else
        self.Sha1 = CsRemoteConfig.IndexSha1 or ""
        self.IndexSize = CsRemoteConfig.IndexSize or -1
        self._IsSkipUpdate = self.AppVersion == CsRemoteConfig.DocumentVersion
    end
end

function XModuleUpdateInfo:_InitEmptyInfo()
    self.OldVersion = ""
    self.NewVersion = ""
    self.Sha1 = ""
    self.IndexSize = -2
end

-- 初始化
function XModuleUpdateInfo:Init(resFileType)
    self.ResFileType = resFileType
    self.AppVersion = CsInfo.Version

    self.PatchedList = {}
    local patchedList = XLaunchConst.PatchedList or {}
    for i = 1, #patchedList do
        local v = tonumber(patchedList[i])
        if v then
            self.PatchedList[v] = true
        end
    end

    self.MaxVersionOrder = 0
    self.VersionOrder = {}
    local versionOrder = XLaunchConst.VersionOrder or {}
    for i = 1, #versionOrder do
        local v = tonumber(versionOrder[i])
        if v then
            self.VersionOrder[v] = i
            self.MaxVersionOrder = self.MaxVersionOrder + 1
        end
    end
    self.Client2Cdn = XLaunchConst.Client2Cdn
    self.VersionPath = XLaunchConst.VersionPath

    if resFileType == RES_FILE_TYPE.LAUNCH_MODULE then
        self:_InitLaunchInfo()
    elseif resFileType == RES_FILE_TYPE.MATRIX_FILE then
        self:_InitMatrixInfo()

        if CsRemoteConfig.PreloadEnable == 1 then
            self._PreloadStartSvnVersion = CsRemoteConfig.DocumentSvnVersion
            if self._PreloadStartSvnVersion then
                self._PreloadStartIndex = self:GetSvnVersionIndex(self._PreloadStartSvnVersion)
            end
            self._PreloadEndSvnVersion = CsRemoteConfig.PreloadSvnVersion
            if self._PreloadEndSvnVersion then
                self._PreloadEndIndex = self:GetSvnVersionIndex(self._PreloadEndSvnVersion)
            end
            CS.XLog.Debug(LuaStringFormat("XModuleUpdateInfo[Init]:resFileType:%s, self._PreloadStartSvnVersion:%s, self._PreloadEndSvnVersion:%s", 
                resFileType, self._PreloadStartSvnVersion, self._PreloadEndSvnVersion))
        end
    else
        self:_InitEmptyInfo()
    end
    self.OldVersion = tonumber(self.OldVersion)
    self.NewVersion = tonumber(self.NewVersion)

    -- 奇怪的设定
    if self.Sha1 == "empty" then
        self.Sha1 = ""
    end
    self._IsVersionChanged = self.OldVersion ~= self.NewVersion and self.NewVersion ~= nil
    self._IsUpdateMode = self._IsVersionChanged

    local platformInfo = XLaunchUpdatePlatform.GetPlatformInfo()
    self.IsEditorOrStandalone = platformInfo.IsEditorOrStandalone
    -- 目录
    self.ApplicationFilePath = platformInfo.ApplicationFilePath
    self.DocumentFilePath = platformInfo.DocumentFilePath
    self.DownloadFilePath = platformInfo.DownloadFilePath
    self.PreloadFilePath = platformInfo.PreloadFilePath
    self.DownloadZipFilePath = LuaStringFormat("%s/zip", platformInfo.DownloadFilePath)

    -- index路径
    self.ApplicationIndex = LuaStringFormat("%s/%s/index", self.ApplicationFilePath, self.ResFileType)
    self.DocumentIndex = LuaStringFormat("%s/%s/index", self.DocumentFilePath, self.ResFileType)
    self.DownloadIndex = LuaStringFormat("%s/%s/index", self.DownloadFilePath, self.ResFileType)
    self.DocumentUrl = platformInfo.DocumentUrl
    self.DocumentUrlWithoutKey = platformInfo.DocumentUrlWithoutKey

    -- 测试log
    -- self:Log()
end

function XModuleUpdateInfo:Log()
    local logStr = LuaStringFormat("AppVersion: %s, resFileType: %s\
OldVersion: %s, NewVersion: %s\
_IsVersionChanged: %s",
        tostring(self.AppVersion), tostring(self.ResFileType),
        tostring(self.OldVersion), tostring(self:GetNewVersion()),
        tostring(self._IsVersionChanged))
    CS.XLog.Debug(logStr)
end

-- 是不是Doc更新模块
function XModuleUpdateInfo:IsMatrixUpdate()
    return self.ResFileType == RES_FILE_TYPE.MATRIX_FILE
end

-- 是否是zip更新版本
function XModuleUpdateInfo:IsZipPatchVersion()
    -- return TestNewVersion == "1506277"
    return self.PatchedList[self.OldVersion]
end

-- 是否是zip更新版本
function XModuleUpdateInfo:GetSvnVersionIndex(version)
    return self.VersionOrder[version] or self.VersionOrder[tonumber(version)]
end

-- OldLaunchModuleVersion OldDocVersion
---@return string 旧的模块版本
function XModuleUpdateInfo:GetOldVersion()
    return self.OldVersion
end

-- GetNewLaunchModuleVersion - NewLaunchModuleVersion NewDocVersion
---@return string 新的模块版本
function XModuleUpdateInfo:GetNewVersion(isNotCache)
    return self.NewVersion
end

-- 设置本地缓存的版本号
function XModuleUpdateInfo:SetTempVersion(tempVersion)
    self.TempVersion = tonumber(tempVersion)
    self.CacheFilePath = nil
    self.CacheFilePatchPath = nil
end

-- 获取本地缓存的版本号
function XModuleUpdateInfo:GetTempVersion()
    return self.TempVersion
end

-- 是否是临时版本
---@return boolean 是否是临时版本
function XModuleUpdateInfo:IsTempVersion()
    return self.TempVersion and self.TempVersion ~= self.NewVersion
end

-- 是否是更新模式
---@return boolean 是否是更新模式流程缓存
function XModuleUpdateInfo:IsUpdateMode()
    if self._IsSkipUpdate or XLaunchConst.IsUpdateClose then return false end
    return self._IsUpdateMode
end

-- HasLaunchModuleUpdated - IsLaunchModuleUpdated IsDocUpdated
-- @return boolean 模块是否更新，是否更新到最新版本
function XModuleUpdateInfo:HasUpdated()
    if self._IsSkipUpdate or XLaunchConst.IsUpdateClose then return false end
    return self._IsVersionChanged
end

-- 设置更新状态
function XModuleUpdateInfo:SetUpdateStatue(isNeedUpdate)
    if self._IsSkipUpdate or XLaunchConst.IsUpdateClose then return end
    self._IsVersionChanged = isNeedUpdate
    if isNeedUpdate then
        self._IsUpdateMode = true
    end
end

-- @return string 模块索引文件的Sha1值
function XModuleUpdateInfo:GetSha1()
    return self.Sha1
end

-- @return number 模块索引文件的大小
function XModuleUpdateInfo:GetIndexSize()
    return self.IndexSize
end

-- @return string 模块下载文件的路径
function XModuleUpdateInfo:GetDownloadFilePathWithName(filename)
    return LuaStringFormat("%s/%s", self:GetDownloadFilePath(), filename)
end

-- zipfilePath
function XModuleUpdateInfo:GetDownloadZipFilePathWithName(filename)
    return LuaStringFormat("%s/%s", self.DownloadZipFilePath, filename)
end

-- 设置是否是预下载状态
function XModuleUpdateInfo:SetPredownloadStatus(stateId)
    self._PredownloadType = stateId
end

-- 是否是预下载状态
function XModuleUpdateInfo:IsPredownloadMergeStatus()
    return self._PredownloadType == XLaunchConst.PredownloadType.Merge
end

function XModuleUpdateInfo:IsPredownloadDownloadStatus()
    return self._PredownloadType == XLaunchConst.PredownloadType.Download
end

-- 是否是预下载状态
function XModuleUpdateInfo:IsPredownloadStatus()
    return self._PredownloadType ~= nil
end

-- 获取预下载目录
function XModuleUpdateInfo:GetPreloadFilePath()
    return self.PreloadFilePath
end

-- @return string 模块预下载文件路径
function XModuleUpdateInfo:GetPredownloadPathWithName(filename)
    return LuaStringFormat("%s/%s/%s", self.PreloadFilePath, self.ResFileType, filename)
end

-- @return string 模块下载文件的路径
function XModuleUpdateInfo:GetPredownloadAbPath()
    return self:GetPredownloadPathWithName(XLaunchConst.AB_Directory_Name)
end

function XModuleUpdateInfo:GetPredownloadPatchPath()
    return self:GetPredownloadPathWithName(XLaunchConst.Patch_Directory_Name)
end

-- @return string 模块下载文件的路径
function XModuleUpdateInfo:GetMergePatchFilePath()
    if self:IsPredownloadStatus() then
        return self:GetPredownloadPatchPath()
    end
    return self:GetDownloadPatchFilePath()
end

-- @return string 模块预下载文件路径
function XModuleUpdateInfo:GetDownloadPathWithName(filename)
    return LuaStringFormat("%s/%s/%s", self:GetDownloadFilePath(), self.ResFileType, filename)
end

-- @return string 模块下载AB文件的路径
function XModuleUpdateInfo:GetDownloadAbFilePath()
    return self:GetDownloadPathWithName(XLaunchConst.AB_Directory_Name)
end

function XModuleUpdateInfo:GetDownloadPatchFilePath()
    return self:GetDownloadPathWithName(XLaunchConst.Patch_Directory_Name)
end

-- @return string 模块索引文件的下载地址
function XModuleUpdateInfo:GetNewIndexUrl()
    return LuaStringFormat("%s/%s/%s/index", self:GetUrlBase(), self:GetNewVersion(), self.ResFileType)
end

-- @return string 模块Zip文件的下载路径
function XModuleUpdateInfo:GetZipPathParentUrl(filename)
    return LuaStringFormat("%s/%s/%s/PatchZip/%s", self:GetUrlBase(), self:GetNewVersion(), self.OldVersion, filename)
end

-- @return string 模块索引文件的下载路径
function XModuleUpdateInfo:GetDownloadIndexPath()
    return self:GetDownloadIndexVersionPath(self:GetNewVersion())
end

function XModuleUpdateInfo:GetDownloadIndexVersionPath(version)
    return LuaStringFormat("%s_%s", self.DownloadIndex, version)
end

-- @return string 远端基础地址
function XModuleUpdateInfo:GetUrlBase()
    return self.DocumentUrl
end

-- @return string 本地资源目录(包内路径)
function XModuleUpdateInfo:GetApplicationFilePath()
    return self.ApplicationFilePath
end

-- @return string 本地资源目录(包内路径) + 文件类型
function XModuleUpdateInfo:GetApplicationFilePathWithType()
    return LuaStringFormat("%s/%s", self.ApplicationFilePath, self.ResFileType)
end

-- @return string 远端基础地址，不包含CDN Key
function XModuleUpdateInfo:GetUrlByVersion(version, isPredownload)
    if not self._ErrorCache then self._ErrorCache = {} end
    if not self.Client2Cdn then
        local notInitKey = "notInitCDNKey"
        local isError = self._ErrorCache[notInitKey]
        if not isError then
            self._ErrorCache[notInitKey] = true
            CS.XLog.Warning("XModuleUpdateInfo:GetUrlByVersion Client2Cdn is nil")
        end
        return self.DocumentUrl
    end
    if not self.VersionPath then
        local notInitKey = "notInitCDNKey"
        local isError = self._ErrorCache[notInitKey]
        if not isError then
            self._ErrorCache[notInitKey] = true
            CS.XLog.Warning("XModuleUpdateInfo:GetUrlByVersion VersionPath is nil")
        end
        return self.DocumentUrl
    end

    local info = self.VersionPath[version]
    if not info then
        info = self.VersionPath[tostring(version)]
        if info then
            self.VersionPath[version] = info
        else
            if not isPredownload then
                local isError = self._ErrorCache[version]
                if not isError then
                    CS.XLog.Error("XModuleUpdateInfo:GetUrlByVersion VersionPath version not found: " .. tostring(version))
                    self._ErrorCache[version] = true
                end
            end
            return self.DocumentUrl
        end
    end

    local client2cdn = self.Client2Cdn[version]
    if not client2cdn then
        client2cdn = self.Client2Cdn[tostring(version)]
        if client2cdn then
            self.Client2Cdn[version] = client2cdn
        else
            if not isPredownload then
                local isError = self._ErrorCache[version]
                if not isError then
                    CS.XLog.Error("XModuleUpdateInfo:GetUrlByVersion Client2Cdn version not found: " .. tostring(version))
                    self._ErrorCache[version] = true
                end
            end
            return self.DocumentUrl
        end
    end

    if not self._UrlVersionCache then self._UrlVersionCache = {} end
    local url = self._UrlVersionCache[info.version]
    if not url then
        local key = info.key
        if XLaunchConst.IsNilOrEmpty(key) then
            for _, versionInfo in pairs(self.VersionPath) do
                if versionInfo.version == info.version and not XLaunchConst.IsNilOrEmpty(versionInfo.key) then
                    key = versionInfo.key
                    break
                end
            end
        end
        if XLaunchConst.IsNilOrEmpty(key) then
            url = self.DocumentUrl
            self._UrlVersionCache[info.version] = url
        else
            url = LuaStringFormat(self.DocumentUrlWithoutKey, key, client2cdn.KuroGameIdentifier, info.version)
            self._UrlVersionCache[info.version] = url
        end
    end
    return url
end

function XModuleUpdateInfo:IsNeedDownloadVersion(version)
    if not version then
        CS.XLog.Error("XModuleUpdateInfo:IsNeedDownloadVersion version is nil")
        return false
    end
    if not self._IsDownloadVersionCache then self._IsDownloadVersionCache = {} end
    local isNeedDownload = self._IsDownloadVersionCache[version]
    if isNeedDownload ~= nil then return isNeedDownload end

    if not self._PreloadStartIndex or not self._PreloadEndIndex then
        isNeedDownload = true
        self._IsDownloadVersionCache[version] = isNeedDownload
        return isNeedDownload
    end
    local index = self:GetSvnVersionIndex(version)
    if not index then
        isNeedDownload = true
        self._IsDownloadVersionCache[version] = isNeedDownload
        return isNeedDownload
    end

    if self:IsPredownloadStatus() then
        isNeedDownload = index >= self._PreloadStartIndex and index <= self._PreloadEndIndex
    else
        isNeedDownload = index < self._PreloadStartIndex or index > self._PreloadEndIndex
    end
    self._IsDownloadVersionCache[version] = isNeedDownload
    return isNeedDownload
end

-- @return string 本地下载目录
function XModuleUpdateInfo:GetDownloadZipFilePath()
    return self.DownloadZipFilePath
end

-- @return string 本地下载目录
function XModuleUpdateInfo:GetDownloadFilePath()
    return self.DownloadFilePath
end

-- 设置模块的LastBuildInfo
function XModuleUpdateInfo:SetLastBuildInfo(buildInfo)
    self.LastBuildInfo = buildInfo
end

-- 获取版本信息
function XModuleUpdateInfo:GetLastBuildInfo()
    return self.LastBuildInfo
end

-- @return string 本地Doc目录
function XModuleUpdateInfo:GetDocumentFilePath()
    return self.DocumentFilePath
end

function XModuleUpdateInfo:GetDocumentFilePathWithResType()
    return LuaStringFormat("%s/%s", self:GetDocumentFilePath(), self.ResFileType)
end

-- 是否有ZipPatch
function XModuleUpdateInfo:HasZipPatch()
    return self._HasZipPatch
end

-- 设置ZipPatch状态
function XModuleUpdateInfo:SetZipPatchStatue(hasZipPatch)
    self._HasZipPatch = hasZipPatch
end

-- 获取缓存文件路径
function XModuleUpdateInfo:GetCacheFilePath()
    if not self.CacheFilePath then
        if self:IsPredownloadDownloadStatus() then
            self.CacheFilePath = LuaStringFormat("%s/%s.cache",
                self.PreloadFilePath,
                self.ResFileType)
        else
            self.CacheFilePath = LuaStringFormat("%s/%s.cache",
                self:GetDownloadLogPath(),
                self.ResFileType)
        end
    end
    return self.CacheFilePath
end

function XModuleUpdateInfo:GetCacheFilePatchPath()
    if not self.CacheFilePatchPath then
        if self:IsPredownloadDownloadStatus() then
            self.CacheFilePatchPath = LuaStringFormat("%s/patch_%s.cache",
                self.PreloadFilePath,
                self.ResFileType)
        else
            self.CacheFilePatchPath = LuaStringFormat("%s/patch_%s.cache",
                self:GetDownloadLogPath(),
                self.ResFileType)
        end
    end
    return self.CacheFilePatchPath
end

function XModuleUpdateInfo:GetPatchInfoPath(oldVersion, newVersion)
    return LuaStringFormat("%s/%s_%s.json", self:GetDownloadInfoPath(), oldVersion, newVersion)
end

function XModuleUpdateInfo:GetDownloadInfoPath()
    return LuaStringFormat("%s/info/%s", self:GetDownloadFilePath(), self.ResFileType)
end

function XModuleUpdateInfo:GetDownloadLogPath()
    return LuaStringFormat("%s/log", self:GetDownloadFilePath())
end

-- 获取模块的版本信息
function XModuleUpdateInfo:IsMergePredownloadVersion()
    if not CsDirectory.Exists(self:GetPreloadFilePath()) then
        return false
    end
    if not self._PreloadEndIndex then return false end
    if not XLaunchConst.PredownloadMergeTest and CsRemoteConfig.PreloadMoveCount <= 0 then return false end
    local currentVersionOrder = self:GetSvnVersionIndex(self:GetNewVersion())
    return currentVersionOrder >= self._PreloadEndIndex
end

function XModuleUpdateInfo:GetPreloadIndexUrl()
    local startUrl = LuaStringFormat("%s/%s/%s/index", self.DocumentUrl, self._PreloadStartSvnVersion, self.ResFileType)
    local endUrl = LuaStringFormat("%s/%s/%s/index", self.DocumentUrl, self._PreloadEndSvnVersion, self.ResFileType)
    return startUrl, endUrl
end

function XModuleUpdateInfo:GetPreloadIndexStartPath()
    return LuaStringFormat("%s/%s/start_index", self.PreloadFilePath, self.ResFileType)
end

function XModuleUpdateInfo:GetPreloadIndexEndPath()
    return LuaStringFormat("%s/%s/end_index", self.PreloadFilePath, self.ResFileType)
end

-- UpdateLaunchVersion
--- 更新版本内容，写入版本到本地缓冲
function XModuleUpdateInfo:UpdateVersion()
    self.OldVersion = self:GetNewVersion() or ""
    UnityPlayerPrefs.SetString(self.MODULE_VERSION_KEY, self.OldVersion)
    UnityPlayerPrefs.Save()
end

-- 获取临时版本Key
function XModuleUpdateInfo:GetLastVersionKey()
    if not self._LastVersionKey then
        self._LastVersionKey = LuaStringFormat("LastVersion_%s", self.ResFileType)
    end
    return self._LastVersionKey
end

-- 读取临时版本缓存
function XModuleUpdateInfo:ReadTempVersionCache()
    local tempVersion = UnityPlayerPrefs.GetString(self:GetLastVersionKey())
    if tonumber(tempVersion) == self.NewVersion then return end
    self:SetTempVersion(tempVersion)
end

-- 设置临时版本
---@param version string? 版本号
function XModuleUpdateInfo:SetTempVersionCache(version)
    UnityPlayerPrefs.SetString(self:GetLastVersionKey(), version)
    UnityPlayerPrefs.Save()
end

-- 删除临时版本缓存
function XModuleUpdateInfo:DeleteTempVersionCache()
    UnityPlayerPrefs.DeleteKey(self:GetLastVersionKey())
    UnityPlayerPrefs.Save()
end

-- 获取App版本文件名
function XModuleUpdateInfo:GetAppVersionFirstOpenFileName()
    return LuaStringFormat("%s/%s_%s", self.DocumentFilePath, self.ResFileType, self.AppVersion)
end

-- 创建缓存目录
function XModuleUpdateInfo:CreateCacheDir()
    local logDir = self:GetDownloadLogPath()
    if not CsDirectory.Exists(logDir) then
        CsDirectory.CreateDirectory(logDir)
    end

    local infoDir = self:GetDownloadInfoPath()
    if not CsDirectory.Exists(infoDir) then
        CsDirectory.CreateDirectory(infoDir)
    end
end

-- 删除缓存目录
function XModuleUpdateInfo:DeleteLogCacheDir()
    local logDir = self:GetDownloadLogPath()
    if CsDirectory.Exists(logDir) then
        CsDirectory.Delete(logDir, true)
    end
end

-- 删除缓存目录
function XModuleUpdateInfo:DeleteLogCacheFile()
    xpcall(function()
        -- 清理cache
        local cacheFilePath = self:GetCacheFilePath()
        if CsFile.Exists(cacheFilePath) then
            CsFile.Delete(cacheFilePath)
        end

        -- 清理cache patch
        local cacheFilePatchPath = self:GetCacheFilePatchPath()
        if CsFile.Exists(cacheFilePatchPath) then
            CsFile.Delete(cacheFilePatchPath)
        end
    end, function(err)
        CS.XLog.Error(err)
    end)
end

-- 删除下载的patch缓存目录
function XModuleUpdateInfo:DeleteCachePatchDir()
    -- patch目录清理
    local patchFilePath = self:GetDownloadPatchFilePath()
    if CsDirectory.Exists(patchFilePath) then
        CsDirectory.Delete(patchFilePath, true)
    end
end

-- 删除下载的AB缓存目录
function XModuleUpdateInfo:DeleteCacheABDir()
    -- 清理
    local CsDirectory = CS.System.IO.Directory
    -- ab目录清理
    local abFilePath = self:GetDownloadAbFilePath()
    if CsDirectory.Exists(abFilePath) then
        CsDirectory.Delete(abFilePath, true)
    end
end

-- 删除缓存目录
function XModuleUpdateInfo:DeleteAllCache()
    -- 清理
    self:DeleteCacheABDir()
    self:DeleteCachePatchDir()
    self:DeleteLogCacheFile()
end

return XModuleUpdateInfo
