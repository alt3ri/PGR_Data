---@class XScenePanelDropDown: XUiNode
---@field protected _Control
---@field Parent
local XScenePanelDropDown = XClass(XUiNode, "XScenePanelDropDown")
local Dropdown = CS.UnityEngine.UI.Dropdown

function XScenePanelDropDown:OnStart(dropDateHandler, dropPowerHandler, dropGyroHandler, dropEnvMusicHandler)
    ---下拉列表
    local op1 = XMVCA.XSwitchableScene:GetClientConfig("DropData")
    local op2 = XMVCA.XSwitchableScene:GetClientConfig("DropPower")
    local op4 = XMVCA.XSwitchableScene:GetClientConfig("DropGyro")
    
    self:InitDrop(self.DropDate, op1, dropDateHandler)
    self:InitDrop(self.DropPower, op2, dropPowerHandler)
    self:InitDrop(self.DropGyro, op4, dropGyroHandler)

    XUiHelper.RegisterClickEvent(self, self.DropEnvMusic, dropEnvMusicHandler)
end

---@param comp XUiComponent.XUiDropdown
---@param words string[]
function XScenePanelDropDown:InitDrop(comp, words, callBack)
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
    local mode = XDataCenter.UiPcManager.GetUiPcMode()

    self.DropDate.gameObject:SetActiveEx(type == XPhotographConfigs.BackGroundType.Date)
    self.DropPower.gameObject:SetActiveEx(type == XPhotographConfigs.BackGroundType.PowerSaved)
    self.DropGyro.gameObject:SetActiveEx(type == XPhotographConfigs.BackGroundType.Gyro)
    self.PanelTip.gameObject:SetActiveEx(type == XPhotographConfigs.BackGroundType.Gyro)

    if type == XPhotographConfigs.BackGroundType.Date then
        self.DropDate.value = ops[1]
    elseif type == XPhotographConfigs.BackGroundType.PowerSaved then
        self.DropPower.value = ops[1]
    elseif type == XPhotographConfigs.BackGroundType.Gyro then
        self.DropGyro.value = ops[3]

        -- 根据不同模式显示陀螺仪操作提示
        local tips = XMVCA.XSwitchableScene:GetCfgSwitchableSceneSettingsTipsById(sceneId)

        self.TxtTip.text = tips
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