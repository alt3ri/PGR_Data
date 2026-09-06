----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateMarkFiles.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateMarkFiles : XModuleUpdateStateBase
local XModuleUpdateStateMarkFiles = XLaunchConst.CreateMetaTable("XModuleUpdateStateMarkFiles", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateMarkFiles:OnEnter()
    local indexTable = self.UpdateManager:GetUpdateCheckTable()
    if not indexTable then
        self:OnFinish()
        return
    end

    local deleteCache = self.UpdateManager.TempDeleteCache
    local invalidAssetPaths = self.UpdateManager:GetMarkFileMap()
    for fileName, _ in pairs(indexTable) do
        if invalidAssetPaths[fileName] then
            deleteCache[fileName] = true
        else
            self.UpdateManager:WriteDownloadCache(fileName)
        end
    end
    self.UpdateManager.TempDeleteCache = deleteCache
    self:OnFinish()
end

return XModuleUpdateStateMarkFiles
