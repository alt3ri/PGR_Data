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
end

function XUiPanelGachaLiv4P5GyroTips:OnDestroy()
    self:_StopDelayCall()
end

function XUiPanelGachaLiv4P5GyroTips:OnBtnClickEvent()
    self:_StopDelayCall()
    
    --todo 临时逻辑，后面动画介入后再调整
    self._IsOpen = not self._IsOpen

    if self._IsOpen then
        self.PanelTips.gameObject:SetActiveEx(true)
        self._DelayCallTimeId = XScheduleManager.ScheduleOnce(function()
            self.PanelTips.gameObject:SetActiveEx(false)
        end, 5 * XScheduleManager.SECOND)
    else
        self.PanelTips.gameObject:SetActiveEx(false)
    end
end

function XUiPanelGachaLiv4P5GyroTips:_StopDelayCall()
    if self._DelayCallTimeId then
        XScheduleManager.UnSchedule(self._DelayCallTimeId)
        self._DelayCallTimeId = nil
    end
end

return XUiPanelGachaLiv4P5GyroTips