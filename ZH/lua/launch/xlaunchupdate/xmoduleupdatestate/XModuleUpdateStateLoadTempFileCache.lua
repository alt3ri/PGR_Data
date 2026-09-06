----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateLoadTempFileCache.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

local CsFile = CS.System.IO.File

---@class XModuleUpdateStateLoadTempFileCache : XModuleUpdateStateBase
local XModuleUpdateStateLoadTempFileCache = XLaunchConst.CreateMetaTable("XModuleUpdateStateLoadTempFileCache", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateLoadTempFileCache:OnEnter()
    self.ModuleUpdateInfo:ReadTempVersionCache()
    if not self.ModuleUpdateInfo:IsTempVersion() then
        self:OnAbort()
        return
    end

    -- 清理缓存目录
    self.ModuleUpdateInfo:DeleteLogCacheDir()
    self.ModuleUpdateInfo:DeleteCachePatchDir()
    self.ModuleUpdateInfo:CreateCacheDir()

    local abPath = self.ModuleUpdateInfo:GetDownloadAbFilePath()
    local localFileList = CS.XFileTool.GetFileNames(abPath)
    if localFileList.Count <= 0 then
        self:OnAbort()
        return
    end
    local fileCache = {}
    for i = 0, localFileList.Count - 1 do
        local fileName = localFileList[i]
        fileCache[fileName] = true
    end
    self.UpdateManager.TempDeleteCache = fileCache
    self:OnFinish()
end

return XModuleUpdateStateLoadTempFileCache
