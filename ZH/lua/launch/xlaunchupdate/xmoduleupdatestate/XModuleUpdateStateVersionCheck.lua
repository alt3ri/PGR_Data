----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateVersionCheck.lua
-- description: 模块更新版本检查状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateVersionCheck : XModuleUpdateStateBase
local XModuleUpdateStateVersionCheck = XLaunchConst.CreateMetaTable("XModuleUpdateStateVersionCheck", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateVersionCheck:OnEnter()
    if self._IsRead then
        self:OnFinish()
        return
    end
    CS.XHeroSdkAgent.ApplogEvent("Version_Checking_Start", "")

    -- launch 临时版本之间弃掉缓存
    if not self.ModuleUpdateInfo:IsMatrixUpdate() then
        self.ModuleUpdateInfo:ReadTempVersionCache()
        if self.ModuleUpdateInfo:IsTempVersion() then
            self.ModuleUpdateInfo:SetTempVersion()
            self.ModuleUpdateInfo:DeleteAllCache()
        end
    end

    self.ModuleUpdateInfo:CreateCacheDir()
    self._IsRead = true
    self:OnFinish()
end

return XModuleUpdateStateVersionCheck
