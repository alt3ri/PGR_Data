---@class XUiPanelPhotographSceneChange : XUiNode
local XUiPanelPhotographSceneChange = XClass(XUiNode, "XUiPanelPhotographSceneChange")

local Auto = 0
local Day_Full = 1
local Night_Low = 2

function XUiPanelPhotographSceneChange:OnStart()
    self._SceneChangeBtns = { self.BtnSceneChange1, self.BtnSceneChange2, self.BtnSceneChange3 }
    self.BtnSceneChange1:AddEventListener(handler(self, self.OnBtnSceneChange1Click))
    self.BtnSceneChange2:AddEventListener(handler(self, self.OnBtnSceneChange2Click))
    self.BtnSceneChange3:AddEventListener(handler(self, self.OnBtnSceneChange3Click))
end

function XUiPanelPhotographSceneChange:UpdateSceneChangeBtn()
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local type = XPhotographConfigs.GetBackgroundTypeById(sceneId)
    if type == XPhotographConfigs.BackGroundType.Date or type == XPhotographConfigs.BackGroundType.PowerSaved then
        local ops = XMVCA.XSwitchableScene:GetSetting(sceneId)
        local op = ops[1]
        for i, btn in ipairs(self._SceneChangeBtns) do
            btn.gameObject:SetActiveEx(i - 1 == op)
        end
    else
        for i, btn in ipairs(self._SceneChangeBtns) do
            btn.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelPhotographSceneChange:SetUpdateBatteryMode(func)
    self._UpdateBatteryMode = func
end

function XUiPanelPhotographSceneChange:SwitchSceneMode(index)
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    XMVCA.XSwitchableScene:SetSceneSetting(sceneId, index)
    self:UpdateSceneChangeBtn()
    if self._UpdateBatteryMode then
        self._UpdateBatteryMode()
    end
end

function XUiPanelPhotographSceneChange:OnBtnSceneChange1Click()
    self:SwitchSceneMode(Day_Full)
end

function XUiPanelPhotographSceneChange:OnBtnSceneChange2Click()
    self:SwitchSceneMode(Night_Low)
end

function XUiPanelPhotographSceneChange:OnBtnSceneChange3Click()
    self:SwitchSceneMode(Auto)
end

return XUiPanelPhotographSceneChange
