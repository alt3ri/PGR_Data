----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateListDlc.lua
-- description: 模块更新 - 整理Dlc文件列表（移除不需要下载的ResId）
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateListDlc : XModuleUpdateStateBase
local XModuleUpdateStateListDlc = XLaunchConst.CreateMetaTable("XModuleUpdateStateListDlc", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateListDlc:OnEnter()
    local allDlcAsset = self.UpdateManager.ResAssetTable
    if self.ModuleUpdateInfo:HasUpdated() and allDlcAsset and next(allDlcAsset) then
        for fileName, needDownload in pairs(allDlcAsset) do
            if not needDownload and not self.UpdateManager:IsBaseRelative(fileName) then
                self.UpdateManager:RemoveDownloadABMap(fileName)
                self.UpdateManager:RemoveDownloadPatchMap(fileName)
            end
        end
    end
    self:OnFinish()
end

return XModuleUpdateStateListDlc
