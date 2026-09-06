----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitPackageIndex.lua
-- description: 模块更新 - 初始化包内Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitPackageIndex : XModuleUpdateStateBase
local XModuleUpdateStateInitPackageIndex = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitPackageIndex", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitPackageIndex:OnEnter()
    -- 包内index
    local packageIndexTable, _ = self.UpdateManager:LoadIndexTable(self.ModuleUpdateInfo.ApplicationIndex, true)
    -- 包体内判断
    self.UpdateManager.PackageIndexTable = packageIndexTable
    self.UpdateManager:SetUpdateCheckTable(packageIndexTable)
    self.UpdateManager:SetTargetIndexMap(packageIndexTable)

    self:OnFinish()
end

return XModuleUpdateStateInitPackageIndex
