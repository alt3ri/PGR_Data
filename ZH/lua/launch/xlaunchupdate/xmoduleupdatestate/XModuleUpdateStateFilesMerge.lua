----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateFilesMerge.lua
-- description: 模块更新 - Patch文件合并
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsTool = CS.XTool
local CsApplication = CS.XApplication
local CsDirectory = CS.System.IO.Directory

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateFilesMerge : XModuleUpdateStateBase
local XModuleUpdateStateFilesMerge = XLaunchConst.CreateMetaTable("XModuleUpdateStateFilesMerge", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnFinish
function XModuleUpdateStateFilesMerge:Init()
    self._MoveFailCallback = function() self:OnEnter() end
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateFilesMerge:OnEnter()
    local DownloadAbPath = self.ModuleUpdateInfo:GetDownloadAbFilePath()
    if not CsDirectory.Exists(DownloadAbPath) then
        self:OnFinish()
        return
    end

    local totalCount = self.UpdateManager:GetDownloadCacheCount()
    if totalCount <= 0 then
        self:OnFinish()
        return
    end

    local isShowProgress = RES_FILE_TYPE.LAUNCH_MODULE ~= self.UpdateManager.ResFileType
    local DocumentFilePath = self.ModuleUpdateInfo:GetDocumentFilePath()
    local DocumentDir = string.format("%s/%s", DocumentFilePath, self.UpdateManager.ResFileType)
    if not CsDirectory.Exists(DocumentDir) then
        CsDirectory.CreateDirectory(DocumentDir)
    end
    if isShowProgress then
        CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalCount, false, CsApplication.GetText("FileManage") .. "(%d/%d)") -- 解压资源
    end
    
    self.UpdateManager:StartProfile("FilesMerge")
    local moveHelper = CS.XFileMoveHelper(DownloadAbPath, DocumentDir, true)
    CsTool.WaitCoroutinePerFrame(moveHelper, function(isComplete)
        if isComplete then
            if moveHelper.HasError then
                XLaunchConst.ShowStartErrorDialog("MovePreloadError", self._MoveFailCallback)
            else
                if isShowProgress then
                    self.UpdateManager:UpdateProgress(1)
                end
                CsDirectory.Delete(DownloadAbPath, true)
                self.UpdateManager:EndProfile("FilesMerge")
                self:OnFinish()
            end
        else
            if isShowProgress then
                local progress = moveHelper.Progress
                self.UpdateManager:UpdateProgress(progress)
            end
        end
    end)
end

return XModuleUpdateStateFilesMerge
