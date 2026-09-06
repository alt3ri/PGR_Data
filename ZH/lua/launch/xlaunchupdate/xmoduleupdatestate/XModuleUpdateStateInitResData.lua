----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitResData.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsResourcePathClass = CS.XResourcePath
local CsApplication = CS.XApplication

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitResData : XModuleUpdateStateBase
local XModuleUpdateStateInitResData = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitResData", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitResData:OnEnter()
    local XFileInfoNameIndex = XLaunchConst.XFileInfoNameIndex
    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    local resFileType = self.UpdateManager.ResFileType
    local isLaunch = resFileType == RES_FILE_TYPE.LAUNCH_MODULE
    local externalKey = "External"
    local buildKey = "Build"
    local isExternal = false

    -- 资源关系初始化
    local indexTable = self.UpdateManager:GetTargetIndexMap()
    local urlTable = {}
    local externalTable = {}
    for fileName, info in pairs(indexTable) do
        local extName = info[XFileInfoNameIndex]
        if not isLaunch and not XLaunchConst.IsNilOrEmpty(extName) then
            isExternal = XLaunchConst.StartsWith(extName, externalKey)
        else
            isExternal = false
        end

        local sha1 = info[XFileInfoSha1Index]
        local resType
        if self.UpdateManager:IsInnerResource(fileName, sha1) then
            resType = ResourcePathType.Application
        else
            resType = ResourcePathType.Document
        end

        local resourcePath = CsResourcePathClass()
        resourcePath.DocumentType = resType
        resourcePath.MatrixType = ResourceTypeToIntDic[resFileType]
        resourcePath.ResourceName = fileName
        if not isExternal then
            -- local isBuild = XLaunchConst.StartsWith(extName, buildKey)
            -- if isBuild then
            --     urlTable[extName] = resourcePath
            -- else
            --     urlTable[fileName] = resourcePath
            -- end
            urlTable[fileName] = resourcePath
            -- CS.XLog.Debug(string.format("InitResData urlTable: %s, ResourceName %s, DocumentType %s, MatrixType %s", assetPath, resourcePath.ResourceName, resourcePath.DocumentType, resourcePath.MatrixType))
        else
            externalTable[extName] = resourcePath
            -- CS.XLog.Debug(string.format("InitResData externalTable: %s, ResourceName %s, DocumentType %s, MatrixType %s", assetPath, resourcePath.ResourceName, resourcePath.DocumentType, resourcePath.MatrixType))
        end
    end

    if resFileType == RES_FILE_TYPE.LAUNCH_MODULE then
        self:ReloadLaunchModule(urlTable)
    else
        local XLaunchDlcManager = require("XLaunchDlcManager")
        XLaunchDlcManager.DoneDownloadInLaunch()

        self:LoadMatrixModule(urlTable, externalTable)
    end
end

function XModuleUpdateStateInitResData:ReloadLaunchModule(urlTable)
    if not self.ModuleUpdateInfo:IsUpdateMode() or self.UpdateManager.IsReloaded then
        -- CS.XResourceManager.Clear()
        CS.XResourceManager.ClearFileDelegate()
        CS.XLaunchManager.SetUrlTable(urlTable)
        -- CS.XLog.Debug("InitResData SetUrlTable")
        CS.XResourceManager.ResolveBundleManifest("launchmanifest")
        self:OnFinish()
        return
    end

    -- 释放所有资源，重新update不用调用其他逻辑
    CS.XUiManager.Instance:Clear()
    CS.XResourceManager.Clear()
    CS.XResourceManager.ClearAllLoadAssetBundle()
    CS.XResourceManager.ClearFileDelegate()
    CS.XLaunchManager.SetUrlTable(urlTable)
    -- CS.XLog.Debug("InitResData SetUrlTable reload")
    CS.XResourceManager.ResolveBundleManifest("launchmanifest")

    CS.XLaunchManager.InitLuaUIProxy(nil)
    CS.XScheduleManager.UnScheduleAll()
    CS.XGameEventManager.Instance:Clear()
    self.UpdateManager:Clear()
    CS.XGame.ReloadLaunchModule()
    -- self:OnAbort()
end

function XModuleUpdateStateInitResData:LoadMatrixModule(urlTable, extUrlTable)
    -- 云游戏只触发热更，触发完就结束
    if CS.XWLinkAgent.IsPatchOnly then
        CS.XWLinkAgent.PatchQuit(true)
        self:OnFinish()
        return
    end

    -- CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_LOADING)
    if urlTable and CS.XResourceManager.SetFileUrlList then
        -- CS.XResourceManager.SetFileUrlTable(urlTable)
        CS.XResourceManager.SetFileUrlList(urlTable)
        -- CS.XLog.Debug("InitResData SetFileUrlList")
    end

    if extUrlTable and CS.XResourceManager.SetExternalUrlTable then
        CS.XResourceManager.SetExternalUrlTable(extUrlTable)
        -- CS.XLog.Debug("InitResData SetExternalUrlTable")
    end

    local isEditorOrStandalone = self.ModuleUpdateInfo.IsEditorOrStandalone
    if not isEditorOrStandalone or CsApplication.Mode == CS.XMode.Release then
        if self.UpdateManager.InitResourceManagerManifest then
            -- 重新初始化新的Manifest
            CS.XResourceManager.ResolveBundleManifest("matrixmanifest")
        else
            CS.XResourceManager.SetFileDelegate()
            CS.XResourceManager.ResolveBundleManifest("matrixmanifest")
        end
    end
    self:OnFinish()
end

return XModuleUpdateStateInitResData
