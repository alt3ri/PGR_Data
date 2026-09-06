----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitRemoteIndex.lua
-- description: 模块更新 - 初始化远程Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsLog = CS.XLog
local CsFile = CS.System.IO.File

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitRemoteIndex : XModuleUpdateStateBase
---@field private _FinishCallback function
---@field private _FailCallback function
local XModuleUpdateStateInitRemoteIndex = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitRemoteIndex", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.Init
function XModuleUpdateStateInitRemoteIndex:Init()
    self._FinishCallback = function()
        -- 每次回调时重新获取路径，避免 FinishTask 重置后闭包持有旧版本路径
        local curDownloadIndexPath = self.ModuleUpdateInfo:GetDownloadIndexPath()
        local normalIndexTable, dlcIndexTable, shaderABList, baseABList = self.UpdateManager:LoadIndexTable(curDownloadIndexPath, true)
        if not normalIndexTable then
            if CsFile.Exists(curDownloadIndexPath) then
                CsFile.Delete(curDownloadIndexPath)
            end
            self:OnEnter()
            return
        end
        self.UpdateManager.NewVersionDlcIndexTable = dlcIndexTable
        self.UpdateManager.ShaderABList = shaderABList
        self.UpdateManager.BaseABList = baseABList
        self.UpdateManager:SetUpdateCheckTable(normalIndexTable)
        self.UpdateManager:SetTargetIndexMap(normalIndexTable)

        -- 更新流程才写临时版本
        if self.UpdateManager:IsUpdateMode() then
            self.ModuleUpdateInfo:SetTempVersionCache(self.ModuleUpdateInfo:GetNewVersion())
        end

        self:OnFinish()
    end
end

function XModuleUpdateStateInitRemoteIndex:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated()
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitRemoteIndex:OnEnter()
    local newVersion = self.ModuleUpdateInfo:GetNewVersion()
    if not newVersion then
        self:OnFinish()
        return
    end
    local ResFileType = self.UpdateManager.ResFileType
    -- 下载目录下找新的Index
    local downloadIndexPath = self.ModuleUpdateInfo:GetDownloadIndexPath()
    local newVersionIndexExist = CsFile.Exists(downloadIndexPath)
    CsLog.Debug(string.format("[Download] CheckIndexFile:%s, documentFileExist:%s", 
        ResFileType, tostring(newVersionIndexExist)))

    -- 存在就直接用，不存在就下载
    if newVersionIndexExist then
        self._FinishCallback()
    else
        local uriPrefixStr = self.ModuleUpdateInfo:GetNewIndexUrl()
        local addTaskFunc = function(group)
            group:AddTask(uriPrefixStr, downloadIndexPath, self.ModuleUpdateInfo:GetIndexSize(), self.ModuleUpdateInfo:GetSha1())
        end
        self.UpdateManager:DownloadFiles(addTaskFunc, self._FinishCallback, 
            nil, nil, true)
    end
end

return XModuleUpdateStateInitRemoteIndex
