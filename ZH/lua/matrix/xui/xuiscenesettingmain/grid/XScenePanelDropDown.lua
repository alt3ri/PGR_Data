---@class XScenePanelDropDown: XUiNode
---@field protected _Control
---@field Parent
local XScenePanelDropDown = XClass(XUiNode, "XScenePanelDropDown")
local Dropdown = CS.UnityEngine.UI.Dropdown

function XScenePanelDropDown:OnStart(dropDateHandler, dropPowerHandler, dropGyroHandler, dropEnvMusicHandler, dropSceneMusicHandler)
    ---下拉列表
    local op1 = XMVCA.XSwitchableScene:GetClientConfig("DropData")
    local op2 = XMVCA.XSwitchableScene:GetClientConfig("DropPower")
    local op4 = XMVCA.XSwitchableScene:GetClientConfig("DropGyro")
    local op5 = XMVCA.XMusicScene:GetClientConfigValues("DropMusic")
    
    self:InitDrop(self.DropDate, op1, dropDateHandler)
    self:InitDrop(self.DropPower, op2, dropPowerHandler)
    self:InitDrop(self.DropGyro, op4, dropGyroHandler)
    self:InitDrop(self.DropMusic, op5, dropSceneMusicHandler)

    XUiHelper.RegisterClickEvent(self, self.DropEnvMusic, dropEnvMusicHandler)
end

---@param comp XUiComponent.XUiDropdown
---@param words string[]
function XScenePanelDropDown:InitDrop(comp, words, callBack)
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
    comp.onValueChanged:AddListener(callBack)
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
        self:SetDropValue(self.DropDate, ops[1])
    elseif type == XPhotographConfigs.BackGroundType.PowerSaved then
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
        node.value = value
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