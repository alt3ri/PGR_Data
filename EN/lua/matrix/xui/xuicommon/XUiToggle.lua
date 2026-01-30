---@class XUiToggle : XUiNode
---@field On UnityEngine.GameObject On状态的GameObject
---@field Off UnityEngine.GameObject Off状态的GameObject
local XUiToggle = XClass(XUiNode, "XUiToggle")

-- 因为原本的XUiButton的toggle功能存在bug，而且不好修复，所以新增lua代理的XUiToggle组件，期待后续增加c#版本的XUiToggle组件
function XUiToggle:OnStart()
    -- 获取 XGoInputHandler 组件
    ---@type XGoInputHandler
    self._InputHandler = self.GameObject:GetComponent(typeof(CS.XGoInputHandler))
    if not self._InputHandler then
        XLog.Error("[XUiToggle] XGoInputHandler component not found on GameObject: " .. self.GameObject.name)
        return
    end
    
    -- 查找 On 和 Off 子对象
    self.On =  self.On or self.Transform:Find("On")
    self.Off = self.Off or self.Transform:Find("Off")
    
    if not self.On then
        XLog.Error("[XUiToggle] 'On' child GameObject not found")
    end
    if not self.Off then
        XLog.Error("[XUiToggle] 'Off' child GameObject not found")
    end
    
    -- 当前状态：true = On, false = Off
    self._IsOn = false
    
    -- 点击回调函数
    self._OnValueChanged = nil
    
    -- 添加点击监听
    self._InputHandler:AddPointerClickListener(function(eventData)
        self:OnClick()
    end)
end

--- 设置值改变回调
---@param callback fun(value: number) 回调函数，参数 value: 0 = On状态, 1 = Off状态
function XUiToggle:SetOnValueChanged(callback)
    self._OnValueChanged = callback
end

--- 点击事件处理
function XUiToggle:OnClick()
    -- 切换状态
    self._IsOn = not self._IsOn
    
    -- 更新显示
    self:UpdateDisplay()
    
    -- 触发回调（传递状态值：0 = On, 1 = Off）
    if self._OnValueChanged then
        local value = self._IsOn and 0 or 1
        self._OnValueChanged(value)
    end
end

--- 设置状态
---@param isOn boolean true = On状态, false = Off状态
function XUiToggle:SetToggleState(isOn)
    self._IsOn = isOn
    self:UpdateDisplay()
end

--- 更新显示
function XUiToggle:UpdateDisplay()
    if self.On then
        self.On.gameObject:SetActiveEx(self._IsOn)
    end
    if self.Off then
        self.Off.gameObject:SetActiveEx(not self._IsOn)
    end
end

--- 获取当前状态
---@return boolean true = On状态, false = Off状态
function XUiToggle:GetToggleState()
    return self._IsOn
end

--- 销毁
function XUiToggle:OnDestroy()
    if self._InputHandler then
        self._InputHandler:RemoveAllListeners()
        self._InputHandler = nil
    end
    self._OnValueChanged = nil
    self.On = nil
    self.Off = nil
end

return XUiToggle

