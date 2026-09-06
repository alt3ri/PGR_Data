----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateFilesPreloadMove.lua
-- description: 模块更新 - Patch文件合并
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsTool = CS.XTool
local CsApplication = CS.XApplication
local CsDirectory = CS.System.IO.Directory

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateFilesPreloadMove : XModuleUpdateStateBase
local XModuleUpdateStateFilesPreloadMove = XLaunchConst.CreateMetaTable("XModuleUpdateStateFilesPreloadMove", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnFinish
function XModuleUpdateStateFilesPreloadMove:Init()
    self._MoveFailCallback = function() self:OnFinish() end
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateFilesPreloadMove:OnEnter()
    local abFilePath = self.ModuleUpdateInfo:GetPredownloadAbPath()
    if not CsDirectory.Exists(abFilePath) then
        self:OnFinish()
        return
    end

    local downloadAbPath = self.ModuleUpdateInfo:GetDownloadAbFilePath()
    if not CsDirectory.Exists(downloadAbPath) then
        CsDirectory.CreateDirectory(downloadAbPath)
    end

    local moveAbMap = self.UpdateManager:GetDownloadABMap()
    local paths = {}
    local count = 0
    for fileName, _ in pairs(moveAbMap) do
        local path = string.format("%s/%s", abFilePath, fileName)
        if XLaunchConst.FileExists(path) then
            count = count + 1
            paths[count] = path
        end
    end
    if count <= 0 then
        self:OnFinish()
        return
    end

    -- 应用预下载文件
    CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, self.UpdateManager:GetDownloadCacheCount(), false, CsApplication.GetText("FileManage") .. "(%d/%d)")

    local moveHelper = CS.XFileMoveHelper(downloadAbPath, true)
    moveHelper:SetFiles(paths)
    moveHelper:StartMoveFiles()
    CsTool.WaitCoroutinePerFrame(moveHelper, function(isComplete)
        if isComplete then
            if moveHelper.HasError then
                XLaunchConst.ShowStartErrorDialog("MovePreloadError", self._MoveFailCallback)
            else
                self.UpdateManager:UpdateProgress(1)
                CsDirectory.Delete(abFilePath, true)
                for _, value in pairs(paths) do
                    self.UpdateManager:WriteDownloadCache(value)
                end
                self:OnFinish()
            end
        else
            local progress = moveHelper.Progress
            self.UpdateManager:UpdateProgress(progress)
        end
    end)
end

return XModuleUpdateStateFilesPreloadMove
