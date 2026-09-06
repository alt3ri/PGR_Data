----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitPreIndexStart.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsFile = CS.System.IO.File

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitPreIndexStart : XModuleUpdateStateBase
local XModuleUpdateStateInitPreIndexStart = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitPreIndexStart", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitPreIndexStart:OnEnter()
    local preindexStartPath = self.ModuleUpdateInfo:GetPreloadIndexStartPath()
    -- 先获取持久化目录Index
    if CsFile.Exists(preindexStartPath) then
        local normalIndexTable = self.UpdateManager:LoadIndexTable(preindexStartPath, false)
        self.UpdateManager.LocalIndexTable = normalIndexTable
        self:OnFinish()
    else
        self:OnAbort()
    end
end

return XModuleUpdateStateInitPreIndexStart
