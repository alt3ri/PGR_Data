----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitLocalIndex.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsFile = CS.System.IO.File
local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitLocalIndex : XModuleUpdateStateBase
local XModuleUpdateStateInitLocalIndex = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitLocalIndex", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitLocalIndex:OnEnter()
    -- log
    CS.XLog.Debug(
        string.format("[XModuleUpdateStateInitLocalIndex] OnEnter %s %s -> %s, %s", 
        self.ModuleUpdateInfo.ResFileType, 
        self.ModuleUpdateInfo.OldVersion, 
        self.ModuleUpdateInfo.NewVersion,
        self.ModuleUpdateInfo:GetTempVersion())
    )

    -- 先获取持久化目录Index
    local indexPath = self.ModuleUpdateInfo.DocumentIndex
    local normalIndexTable, dlcIndexTable, shaderABList, baseABList
    if CsFile.Exists(indexPath) then
        normalIndexTable, dlcIndexTable, shaderABList, baseABList = self.UpdateManager:LoadIndexTable(indexPath, true)
        self.UpdateManager.NewVersionDlcIndexTable = dlcIndexTable
        self.UpdateManager.ShaderABList = shaderABList
        self.UpdateManager.BaseABList = baseABList
        self.UpdateManager:SetUpdateCheckTable(normalIndexTable)
        self.UpdateManager:SetTargetIndexMap(normalIndexTable)
    else
        normalIndexTable = {}
        self.ModuleUpdateInfo:SetUpdateStatue(true)
    end

    -- 更新需要
    self.UpdateManager.LocalIndexTable = normalIndexTable
    self:OnFinish()
end

return XModuleUpdateStateInitLocalIndex
