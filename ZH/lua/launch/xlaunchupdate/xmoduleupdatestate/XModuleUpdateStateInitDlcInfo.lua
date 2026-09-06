----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitDlcInfo.lua
-- description: 模块更新 - 初始化分包信息
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitDlcInfo : XModuleUpdateStateBase
local XModuleUpdateStateInitDlcInfo = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitDlcInfo", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitDlcInfo:OnEnter()
    local dlcIndexTable = self.UpdateManager.NewVersionDlcIndexTable
    if not dlcIndexTable or not next(dlcIndexTable) then
        self:OnFinish()
        return
    end

    -- 初始化
    local XLaunchDlcManager = require("XLaunchDlcManager")
    XLaunchDlcManager.InitResTable(dlcIndexTable, self.UpdateManager:GetFileInfos())

    self:OnFinish()
end

return XModuleUpdateStateInitDlcInfo
