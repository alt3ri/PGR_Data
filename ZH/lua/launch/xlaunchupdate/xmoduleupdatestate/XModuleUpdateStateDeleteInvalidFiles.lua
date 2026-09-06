----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateDeleteInvalidFiles.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

local CsLog = CS.XLog
local CsTool = CS.XTool
local CsApplication = CS.XApplication
local CsGameEventManager = CS.XGameEventManager
local CsXFileDelete = CS.XHaruDownloader.XFileDelete
local CsEventId = CS.XEventId
local StringFormat = string.format
local MathMin = math.min

---@class XModuleUpdateStateDeleteInvalidFiles : XModuleUpdateStateBase
local XModuleUpdateStateDeleteInvalidFiles = XLaunchConst.CreateMetaTable("XModuleUpdateStateDeleteInvalidFiles", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateDeleteInvalidFiles:OnEnter()
    local deleteCache = self.UpdateManager.TempDeleteCache
    if not deleteCache or next(deleteCache) then
        self:OnFinish()
        return
    end

    local totalCount = 0
    local deleter = CsXFileDelete()
    deleter:SetRootPath(self.ModuleUpdateInfo:GetDownloadAbFilePath())
    for fileName, _ in pairs(deleteCache) do
        deleter:AddTask(fileName)
        totalCount = totalCount + 1
    end
    deleter:Start(4)

    CsGameEventManager.Instance:Notify(CsEventId.EVENT_LAUNCH_START_DOWNLOAD, totalCount, false, CsApplication.GetText("Verifying"))
    self.UpdateManager:UpdateProgress(0)
    CsTool.WaitCoroutinePerFrame(deleter, function(isComplete)
        if isComplete then
            if deleter.HasError then
                CsLog.Error(StringFormat("[DeleteInvalidFiles] file deleter error:%s", deleter.ErrorInfo))
            end

            self.UpdateManager:UpdateProgress(1)
            deleter:Clear()
            self:OnFinish()
        else
            self.UpdateManager:UpdateProgress(MathMin(1, deleter.Progress))
        end
    end)

    -- local CsFile = CS.System.IO.File
    -- local cacheFilePath = self.ModuleUpdateInfo:GetDownloadAbFilePath()
    -- for fileName, _ in pairs(deleteCache) do
    --     local file = string.format("%s/%s", cacheFilePath, fileName)
    --     if CsFile.Exists(file) then
    --         CsFile.Delete(file)
    --     --     CS.XLog.Debug("delete " .. file)
    --     -- else
    --     --     CS.XLog.Debug("file not exist " .. file)
    --     end
    -- end
    self.UpdateManager.TempDeleteCache = nil
    self:OnFinish()
end

return XModuleUpdateStateDeleteInvalidFiles
