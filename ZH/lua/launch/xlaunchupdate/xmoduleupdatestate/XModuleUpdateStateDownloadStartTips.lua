----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateDownloadStartTips.lua
-- description: 模块更新 - 下载前统计tips
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateDownloadStartTips : XModuleUpdateStateBase
local XModuleUpdateStateDownloadStartTips = XLaunchConst.CreateMetaTable("XModuleUpdateStateDownloadStartTips", XModuleUpdateStateBase)

function XModuleUpdateStateDownloadStartTips:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated() and not CS.XInfo.IsCloudGame
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateDownloadStartTips:OnEnter()
    local updateSize = self.UpdateManager:GetTotalDownloadSize()
    if updateSize <= 0 then
        self:OnFinish()
        return
    end

    XLaunchConst.BeforeDownloadTips(updateSize, function() self:OnFinish() end)
end

return XModuleUpdateStateDownloadStartTips
