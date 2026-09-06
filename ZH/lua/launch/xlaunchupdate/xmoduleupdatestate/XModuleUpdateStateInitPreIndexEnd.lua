----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitPreIndexEnd.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsFile = CS.System.IO.File

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitPreIndexEnd : XModuleUpdateStateBase
local XModuleUpdateStateInitPreIndexEnd = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitPreIndexEnd", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitPreIndexEnd:OnEnter()
    local preindexEndPath = self.ModuleUpdateInfo:GetPreloadIndexEndPath()
    -- 先获取持久化目录Index
    if CsFile.Exists(preindexEndPath) then
        local normalIndexTable = self.UpdateManager:LoadIndexTable(preindexEndPath, false)
        self.UpdateManager.PreIndexTable = normalIndexTable
        self.UpdateManager:SetTargetIndexMap(normalIndexTable)
        self:OnFinish()
    else
        self:OnAbort()
    end
end

return XModuleUpdateStateInitPreIndexEnd
