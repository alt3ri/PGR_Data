----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateInitFileInfo.lua
-- description: 模块更新 - 获取文件info文件
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateInitFileInfo : XModuleUpdateStateBase
local XModuleUpdateStateInitFileInfo = XLaunchConst.CreateMetaTable("XModuleUpdateStateInitFileInfo", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateInitFileInfo:OnEnter()
    local shaderTable = {}
    local baseTable = {}
    local isMatrixUpdate = self.ModuleUpdateInfo:IsMatrixUpdate()
    if isMatrixUpdate then
        local shaderFileMap = {}
        local baseFileMap = {}
        local shaderABList = self.UpdateManager.ShaderABList
        if shaderABList then
            for _, fileName in pairs(shaderABList) do
                shaderFileMap[fileName] = true
            end
        end

        local baseABList = self.UpdateManager.BaseABList
        if baseABList then
            for _, fileName in pairs(baseABList) do
                baseFileMap[fileName] = true
            end
        end

        local tableMap = self.UpdateManager:GetTargetIndexMap()
        for fileName, info in pairs(tableMap) do
            if isMatrixUpdate then
                if shaderFileMap[fileName] then
                    shaderTable[fileName] = info
                end
                if baseFileMap[fileName] then
                    baseTable[fileName] = info
                end
            end
        end
    end

    self.UpdateManager.ShaderTable = shaderTable
    self.UpdateManager:SetUpdateCheckTable(baseTable)
    self:OnFinish()
end

return XModuleUpdateStateInitFileInfo
