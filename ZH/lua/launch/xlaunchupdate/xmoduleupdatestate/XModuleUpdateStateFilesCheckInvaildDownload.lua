----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateFilesCheckInvaildDownload.lua
-- description: 模块更新 - 校验下载
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateFilesCheckInvaildDownload : XModuleUpdateStateBase
local XModuleUpdateStateFilesCheckInvaildDownload = XLaunchConst.CreateMetaTable("XModuleUpdateStateFilesCheckInvaildDownload", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateFilesCheckInvaildDownload:OnEnter()
    local invalidAssetPaths = self.UpdateManager:GetMarkFileMap()
    if invalidAssetPaths and next(invalidAssetPaths) then
        for fileName, _ in pairs(invalidAssetPaths) do
            -- CS.XLog.Warning(string.format("[FilesCheck] invalid file fileName:%s", fileName))
            self.UpdateManager:AddDownloadABMap(fileName, true)
        end
    end
    self:OnFinish()
end

return XModuleUpdateStateFilesCheckInvaildDownload
