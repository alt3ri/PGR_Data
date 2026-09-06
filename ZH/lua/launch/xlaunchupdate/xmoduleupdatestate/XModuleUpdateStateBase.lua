----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateBase.lua
-- description: 模块更新状态基类
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

---@class XModuleUpdateStateBase
---@field UpdateManager XModuleUpdateManager
---@field ModuleUpdateInfo XModuleUpdateInfo
---@field _isFinish boolean
local XModuleUpdateStateBase = XLaunchConst.CreateMetaTable("XModuleUpdateStateBase")

--- 构造接口
---@param updateManager XModuleUpdateManager
function XModuleUpdateStateBase:Ctor(updateManager)
    self._isFinish = false
    self.UpdateManager = updateManager
    self.ModuleUpdateInfo = updateManager.ModuleUpdateInfo
    self:Init()
end

-- 初始化
function XModuleUpdateStateBase:Init()
end

function XModuleUpdateStateBase:OnEnterWithCheck()
    self._isAbort = false
    self._isFinish = false
    if self:IsEnter() then
        self:OnEnter()
    else
        self:OnFinish()
    end
end

--- 判断是否进入状态 默认返回true
--- @return boolean
function XModuleUpdateStateBase:IsEnter()
    return true
end

-- 进入状态
function XModuleUpdateStateBase:OnEnter()
end

-- 退出状态
function XModuleUpdateStateBase:OnExit()
end

-- 内部调用完成状态
function XModuleUpdateStateBase:OnFinish()
    if self._isAbort then return end
    if self._isFinish then return end
    self._isFinish = true
    self.UpdateManager:NextState()
end

-- 内部调用终止状态、直接完成
function XModuleUpdateStateBase:OnAbort()
    self._isAbort = true
    self.UpdateManager:FinishTask(true)
end

return XModuleUpdateStateBase
