----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitDlcAsset.lua
-- description: 模块更新 - 整理Dlc文件列表（移除不需要下载的ResId）
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitDlcAsset : XModuleUpdateStateBase
local XModuleUpdateStateInitDlcAsset = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitDlcAsset", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitDlcAsset:OnEnter()
    local XLaunchDlcManager = require("XLaunchDlcManager")
    -- 剔除
    local dlcIndexTable = self.UpdateManager.NewVersionDlcIndexTable
    if dlcIndexTable and next(dlcIndexTable) then
        local allDlcAsset = self.UpdateManager.ResAssetTable
        -- 获取所有Dlc资源，记录需要下载的
        -- 不能直接用resid直接移除，因为不同ResId会有交集
        for resId, resTable in pairs(dlcIndexTable) do
            local needDownload = XLaunchDlcManager.NeedDownloadByResId(resId)
            for _, fileName in pairs(resTable) do
                if not allDlcAsset[fileName] then
                    allDlcAsset[fileName] = needDownload
                end
            end
        end
    end
    self:OnFinish()
end

return XModuleUpdateStateInitDlcAsset
