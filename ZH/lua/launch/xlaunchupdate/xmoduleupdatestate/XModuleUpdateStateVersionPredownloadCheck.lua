----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateVersionPredownloadCheck.lua
-- description: 模块预下载
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateVersionPredownloadCheck : XModuleUpdateStateBase
local XModuleUpdateStateVersionPredownloadCheck = XLaunchConst.CreateMetaTable("XModuleUpdateStateVersionPredownloadCheck", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateVersionPredownloadCheck:OnEnter()
    -- 需要合并预下载
    if self.ModuleUpdateInfo:IsMergePredownloadVersion() then
        self:OnFinish()
    else
        self:OnAbort()
    end
end

return XModuleUpdateStateVersionPredownloadCheck
