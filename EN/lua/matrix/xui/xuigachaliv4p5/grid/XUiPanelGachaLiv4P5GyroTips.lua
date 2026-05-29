--- 卡池界面陀螺仪使用提示
---@class XUiPanelGachaLiv4P5GyroTips: XUiNode
---@field protected _Control
---@field Parent
local XUiPanelGachaLiv4P5GyroTips = XClass(XUiNode, "XUiPanelGachaLiv4P5GyroTips")

function XUiPanelGachaLiv4P5GyroTips:OnStart(gachaId, sceneId)
    self.BtnTips:AddEventListener(handler(self, self.OnBtnClickEvent))

    self.SceneId = sceneId
    self.GachaId = gachaId
    local cfg = XGachaConfigs.GetConfigGachaSceneInteractById(gachaId)

    if cfg then
        -- 按钮文本
        self.BtnTips:SetNameByGroup(0, cfg.TipsPanelContent)
    end

    -- 详情
    if self.Text then
        local tips = XMVCA.XSwitchableScene:GetCfgSwitchableSceneSettingsTipsById(sceneId)
        
        self.Text.text = tips
    end

    -- 首次进入界面初始化时自动播一次
    self:PlayAnimation("Enable")
end

function XUiPanelGachaLiv4P5GyroTips:OnDisable()
    self.PanelTips.gameObject:SetActiveEx(false)

    if self.Mask then
        self.Mask.gameObject:SetActiveEx(false)
    end
end

function XUiPanelGachaLiv4P5GyroTips:OnBtnClickEvent()
    self:PlayAnimation("Enable")
end

return XUiPanelGachaLiv4P5GyroTips