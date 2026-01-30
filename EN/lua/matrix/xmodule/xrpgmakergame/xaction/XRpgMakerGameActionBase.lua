---@class XRpgMakerGameActionBase
---@field ActionType number Action类型
---@field _Scene XRpgMakerGameScene
---@field ActionData table
local XRpgMakerGameActionBase = XClass(nil, "XRpgMakerGameActionBase")

function XRpgMakerGameActionBase:Ctor(scene, actionData, completedCb)
    -- 基础类统一初始化
    self._Scene = scene
    self.ActionData = actionData
    self.ActionType = actionData.ActionType
    self.CompletedCb = completedCb -- Action执行完成回调
    
    -- 继承类初始化
    self:OnInit()
end

-- 执行
function XRpgMakerGameActionBase:Execute()
    self:Complete()
end

-- 完成
function XRpgMakerGameActionBase:Complete()
    -- 执行回调
    if self.CompletedCb then
        self.CompletedCb()
    end
    
    -- 释放
    self._Scene = nil
    self.ActionData = nil
    self:OnRelease()
end

-- 继承类初始化
function XRpgMakerGameActionBase:OnInit()

end

-- 继承类释放
function XRpgMakerGameActionBase:OnRelease()
    
end

return XRpgMakerGameActionBase