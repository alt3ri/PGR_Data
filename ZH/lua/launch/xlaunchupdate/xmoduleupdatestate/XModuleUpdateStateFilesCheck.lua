----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateFilesCheck.lua
-- description: 模块更新 - 文件检查
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

local CsTool = CS.XTool
local CsApplication = CS.XApplication
local CsGameEventManager = CS.XGameEventManager
local CsEventId = CS.XEventId
local CsLog = CS.XLog
local CsFileVerifier = CS.XHaruDownloader.XFileVerifier
local StringFormat = string.format
local MathMin = math.min
local Pairs = pairs
local ToString = tostring

local VERIFY_THREAD_COUNT = 7

---@class XModuleUpdateStateFilesCheck : XModuleUpdateStateBase
local XModuleUpdateStateFilesCheck = XLaunchConst.CreateMetaTable("XModuleUpdateStateFilesCheck", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateFilesCheck:OnEnter()
    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    local XFileInfoSizeIndex = XLaunchConst.XFileInfoSizeIndex
    local indexTable = self.UpdateManager:GetUpdateCheckTable()
    if not indexTable then
        self:OnFinish()
        return
    end

    local allDlcAsset = self.UpdateManager.ResAssetTable
    local verifier = CsFileVerifier()
    local totalCount = 0
    -- local documentDir = self.ModuleUpdateInfo:GetDocumentFilePathWithResType()

    for fileName, info in Pairs(indexTable) do
        local sha1 = info[XFileInfoSha1Index]
        local dlcNeedDownload = allDlcAsset[fileName]
        local needCheck = not self.UpdateManager:IsInnerResource(fileName, sha1) and (dlcNeedDownload == nil or dlcNeedDownload)
        if needCheck then
            local size = info[XFileInfoSizeIndex]
            verifier:AddTask(fileName, size)--, sha1)
            totalCount = totalCount + 1
        end
    end

    if totalCount <= 0 then
        verifier:Clear()
        self:OnFinish()
        return
    end

    verifier:SetRootDirectory(self.ModuleUpdateInfo:GetDocumentFilePathWithResType())
    CsGameEventManager.Instance:Notify(CsEventId.EVENT_LAUNCH_START_DOWNLOAD, totalCount, false, CsApplication.GetText("Verifying"))
    self.UpdateManager:UpdateProgress(0)
    verifier:Start(VERIFY_THREAD_COUNT)

    CsTool.WaitCoroutinePerFrame(verifier, function(isComplete)
        if isComplete then
            if verifier.HasError then
                CsLog.Error(StringFormat("[FilesCheck] file verifier error:%s", ToString(verifier.ErrorInfo)))
            else
                local invalidFileNames = verifier:GetInvalidFileNames()
                local map = {}
                for i = 0, invalidFileNames.Length - 1 do
                    local fileName = invalidFileNames[i]
                    map[fileName] = true
                end
                self.UpdateManager:SetMarkFileMap(map)
            end

            self.UpdateManager:UpdateProgress(1)
            verifier:Clear()
            self:OnFinish()
        else
            self.UpdateManager:UpdateProgress(MathMin(1, verifier.Progress))
        end
    end)
end

return XModuleUpdateStateFilesCheck
