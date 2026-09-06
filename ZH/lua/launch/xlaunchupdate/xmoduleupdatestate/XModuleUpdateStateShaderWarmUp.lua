----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateShaderWarmUp.lua
-- description: 模块更新 - Shader 预热
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateShaderWarmUp : XModuleUpdateStateBase
local XModuleUpdateStateShaderWarmUp = XLaunchConst.CreateMetaTable("XModuleUpdateStateShaderWarmUp", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateShaderWarmUp:OnEnter()
    if not CS.XRemoteConfig.IsShaderWarmUp then
        self:OnFinish()
        return
    end
    local shaderTable = self.UpdateManager.ShaderTable
    if not shaderTable or not next(shaderTable) then
        self:OnFinish()
        return
    end

    self:_DownloadShaderAbFiles()
end

function XModuleUpdateStateShaderWarmUp:_DownloadShaderAbFiles()
    self._cnt = 0
    self._size = 0
    self._shaderabMap = {}

    local localIndexTable = self.UpdateManager.LocalIndexTable
    local XFileInfoSizeIndex = XLaunchConst.XFileInfoSizeIndex
    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    local XFileInfoVersionIndex = XLaunchConst.XFileInfoVersionIndex
    for fileName, newInfo in pairs(self.UpdateManager.ShaderTable) do
        local oldInfo = localIndexTable[fileName]
        if not oldInfo then
            self._shaderabMap[fileName] = newInfo
            local size = newInfo[XFileInfoSizeIndex]
            self._cnt = self._cnt + 1
            self._size = self._size + size
            self.UpdateManager:RemoveDownloadPatchMap(fileName)
        else
            local newSha1 = newInfo[XFileInfoSha1Index]
            local newVersion = newInfo[XFileInfoVersionIndex]
            local oldSha1 = oldInfo[XFileInfoSha1Index]
            local oldVersion = oldInfo[XFileInfoVersionIndex]
            if newVersion ~= oldVersion or newSha1 ~= oldSha1 then
                self._shaderabMap[fileName] = newInfo
                local size = newInfo[XFileInfoSizeIndex]
                self._cnt = self._cnt + 1
                self._size = self._size + size
                self.UpdateManager:RemoveDownloadPatchMap(fileName)
            end
        end
    end

    if next(self._shaderabMap) == nil then
        self:_InitResData()
        return
    end

    CS.UnityEngine.PlayerPrefs.SetInt(XLaunchConst.ShaderWarmUpKey, 1)
    self.UpdateManager:StartProfile("DownloadShaderAbFiles")
    self.UpdateManager:DownloadABFiles(
        self._shaderabMap, 
        function()
            local cost = self.UpdateManager:EndProfile("DownloadShaderAbFiles")
            local dict = {
                ["version"] = CS.XRemoteConfig.DocumentVersion,
                ["cnt"] = self._cnt,
                ["size"] = self._size,
                ["mode"] = "shader_warm_up_download",
                ["time_cost"] = cost,
            }
            self.UpdateManager:DoRecord(dict, "80040", "UpdateModuleShaderWarmUp")
            self:_InitResData()
        end, true)
end

function XModuleUpdateStateShaderWarmUp:_InitResData()
    local CsResourcePathClass = CS.XResourcePath
    local XFileInfoNameIndex = XLaunchConst.XFileInfoNameIndex
    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    local externalKey = "External"
    local isExternal = false

    -- 资源关系初始化
    local indexTable = self.UpdateManager.ShaderTable
    local urlTable = {}
    local externalTable = {}
    for fileName, info in pairs(indexTable) do
        local extName = info[XFileInfoNameIndex]
        isExternal = XLaunchConst.StartsWith(extName, externalKey)

        local sha1 = info[XFileInfoSha1Index]
        local resType
        if self.UpdateManager:IsInnerResource(fileName, sha1) then
            resType = ResourcePathType.Application
        else
            resType = ResourcePathType.Document
        end

        local resourcePath = CsResourcePathClass()
        resourcePath.DocumentType = resType
        resourcePath.MatrixType = ResourceTypeToIntDic.matrix
        resourcePath.ResourceName = fileName
        if not isExternal then
            urlTable[fileName] = resourcePath
        else
            externalTable[extName] = resourcePath
        end
    end

    if urlTable and CS.XResourceManager.SetFileUrlList then
        CS.XResourceManager.SetFileUrlList(urlTable)
    end

    if externalTable and CS.XResourceManager.SetExternalUrlTable then
        CS.XResourceManager.SetExternalUrlTable(externalTable)
    end

    local CsApplication = CS.XApplication
    local isEditorOrStandalone = self.ModuleUpdateInfo.IsEditorOrStandalone
    if not isEditorOrStandalone or CsApplication.Mode == CS.XMode.Release then
        CS.XResourceManager.SetFileDelegate()
        CS.XResourceManager.ResolveBundleManifest("matrixmanifest")
        self.UpdateManager.InitResourceManagerManifest = true
    end
    self:StartShaderWarmUp()
end

function XModuleUpdateStateShaderWarmUp:StartShaderWarmUp(isSkip)
    CS.XGameEventManager.Instance:Notify(XLaunchConst.EVENT_SHADER_WARM_UP, isSkip)
    self:OnFinish()
end

return XModuleUpdateStateShaderWarmUp
