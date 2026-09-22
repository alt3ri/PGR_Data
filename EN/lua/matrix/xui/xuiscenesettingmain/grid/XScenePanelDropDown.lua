---@class XScenePanelDropDown: XUiNode
---@field protected _Control
---@field Parent
local XScenePanelDropDown = XClass(XUiNode, "XScenePanelDropDown")
local Dropdown = CS.UnityEngine.UI.Dropdown

function XScenePanelDropDown:OnStart(dropDateHandler, dropPowerHandler, dropGyroHandler, dropEnvMusicHandler, dropSceneMusicHandler)
    ---下拉列表（昼夜/电量的默认文本，per-scene 自定义时按 SwitchDesc 覆盖档2/档3）
    self._DropDateWords = XMVCA.XSwitchableScene:GetClientConfig("DropData")
    self._DropPowerWords = XMVCA.XSwitchableScene:GetClientConfig("DropPower")
    local op4 = XMVCA.XSwitchableScene:GetClientConfig("DropGyro")
    local op5 = XMVCA.XMusicScene:GetClientConfigValues("DropMusic")

    self:InitDrop(self.DropDate, self._DropDateWords, dropDateHandler)
    self:InitDrop(self.DropPower, self._DropPowerWords, dropPowerHandler)
    self:InitDrop(self.DropGyro, op4, dropGyroHandler)
    self:InitDrop(self.DropMusic, op5, dropSceneMusicHandler)

    XUiHelper.RegisterClickEvent(self, self.DropEnvMusic, dropEnvMusicHandler)
end

---@param comp XUiComponent.XUiDropdown
---@param words string[]
function XScenePanelDropDown:SetDropOptions(comp, words)
    if not comp then
        return
    end
    comp:ClearOptions()
    for _, word in ipairs(words) do
        local op = Dropdown.OptionData()
        op.text = word
        comp.options:Add(op)
    end
    comp:RefreshShownValue()
end

---@param comp XUiComponent.XUiDropdown
---@param words string[]
function XScenePanelDropDown:InitDrop(comp, words, callBack)
    if not comp then
        return
    end
    self:SetDropOptions(comp, words)
    comp.onValueChanged:AddListener(callBack)
end

--- 用场景 SwitchDesc 覆盖下拉的档2/档3文本（档1"自动"保留全局默认），实现 per-scene 自定义
function XScenePanelDropDown:RefreshDropTextsBySwitchDesc(comp, baseWords, sceneId)
    if not comp or not baseWords then
        return
    end
    local words = {}
    for i, w in ipairs(baseWords) do
        words[i] = w
    end
    local switchDesc = XPhotographConfigs.GetBackgroundSwitchDescById(sceneId)
    if switchDesc then
        if not string.IsNilOrEmpty(switchDesc[1]) then
            words[2] = switchDesc[1]
        end
        if not string.IsNilOrEmpty(switchDesc[2]) then
            words[3] = switchDesc[2]
        end
    end
    self:SetDropOptions(comp, words)
end

function XScenePanelDropDown:Refresh(sceneId)
    local type = XPhotographConfigs.GetBackgroundTypeById(sceneId)
    local ops = XMVCA.XSwitchableScene:GetSetting(sceneId)

    self:SetDropVisible(self.DropDate, type == XPhotographConfigs.BackGroundType.Date)
    self:SetDropVisible(self.DropPower, type == XPhotographConfigs.BackGroundType.PowerSaved)
    self:SetDropVisible(self.DropGyro, type == XPhotographConfigs.BackGroundType.Gyro)
    self:SetDropVisible(self.DropMusic, type == XPhotographConfigs.BackGroundType.Music)
    self:SetDropVisible(self.PanelTip, type == XPhotographConfigs.BackGroundType.Gyro)

    if type == XPhotographConfigs.BackGroundType.Date then
        self:RefreshDropTextsBySwitchDesc(self.DropDate, self._DropDateWords, sceneId)
        self:SetDropValue(self.DropDate, ops[1])
    elseif type == XPhotographConfigs.BackGroundType.PowerSaved then
        self:RefreshDropTextsBySwitchDesc(self.DropPower, self._DropPowerWords, sceneId)
        self:SetDropValue(self.DropPower, ops[1])
    elseif type == XPhotographConfigs.BackGroundType.Gyro then
        self:SetDropValue(self.DropGyro, ops[3])

        -- 根据不同模式显示陀螺仪操作提示
        local tips = XMVCA.XSwitchableScene:GetCfgSwitchableSceneSettingsTipsById(sceneId)

        self.TxtTip.text = tips
    elseif type == XPhotographConfigs.BackGroundType.Music then
        self:SetDropValue(self.DropMusic, XMVCA.XMusicScene:GetCurPlayMode(sceneId) - 1)
    end
end

function XScenePanelDropDown:SetDropVisible(node, isVisible)
    if node then
        node.gameObject:SetActiveEx(isVisible)
    end
end

function XScenePanelDropDown:SetDropValue(node, value)
    if node then
        -- 程序化设值只更新显示，不触发 onValueChanged，避免回调把设置写回并反复广播事件造成闪屏
        node:SetValueWithoutNotify(value)
    end
end

function XScenePanelDropDown:GetDropMusicIsOn()
    return self.DropEnvMusic.isOn
end

function XScenePanelDropDown:SetDropMusicState(isOn)
    self.DropEnvMusic.isOn = isOn
end

function XScenePanelDropDown:SetDropMusicShow(isShow)
    self.DropEnvMusic.gameObject:SetActiveEx(isShow)
end

return XScenePanelDropDown