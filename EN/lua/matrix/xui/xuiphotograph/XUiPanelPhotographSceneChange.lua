---@class XUiPanelPhotographSceneChange : XUiNode
local XUiPanelPhotographSceneChange = XClass(XUiNode, "XUiPanelPhotographSceneChange")

local Auto = 0
local Day_Full = 1
local Night_Low = 2
local Open = XEnumConst.SwitchableScene.Setting.Open
local Close = XEnumConst.SwitchableScene.Setting.Close
local Normal = XEnumConst.MusicScene.Mode.Normal
local Music = XEnumConst.MusicScene.Mode.Music

function XUiPanelPhotographSceneChange:OnStart()
    self._SceneChangeBtns = { self.BtnSceneChange1, self.BtnSceneChange2, self.BtnSceneChange3 }
    self.BtnSceneChange1:AddEventListener(handler(self, self.OnBtnSceneChange1Click))
    self.BtnSceneChange2:AddEventListener(handler(self, self.OnBtnSceneChange2Click))
    self.BtnSceneChange3:AddEventListener(handler(self, self.OnBtnSceneChange3Click))
end

function XUiPanelPhotographSceneChange:GetType()
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    return XPhotographConfigs.GetBackgroundTypeById(sceneId)
end

function XUiPanelPhotographSceneChange:UpdateSceneChangeBtn()
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    local type = XPhotographConfigs.GetBackgroundTypeById(sceneId)
    if type == XPhotographConfigs.BackGroundType.Date or type == XPhotographConfigs.BackGroundType.PowerSaved then
        --自动、开、关
        local op = XMVCA.XSwitchableScene:GetSceneSetting(sceneId)
        for i, btn in ipairs(self._SceneChangeBtns) do
            btn.gameObject:SetActiveEx(i - 1 == op)
        end
    elseif type == XPhotographConfigs.BackGroundType.Gyro then
        --开、关
        local op = XMVCA.XSwitchableScene:GetGyroSetting(sceneId)
        self.BtnSceneChange1.gameObject:SetActiveEx(op == Close)
        self.BtnSceneChange2.gameObject:SetActiveEx(false)
        self.BtnSceneChange3.gameObject:SetActiveEx(op == Open)
    elseif type == XPhotographConfigs.BackGroundType.Music then
        --开、关
        local mode = XMVCA.XMusicScene:GetCurPlayMode(sceneId)
        self.BtnSceneChange2.gameObject:SetActiveEx(mode == Normal)
        self.BtnSceneChange3.gameObject:SetActiveEx(mode == Music)
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

function XUiPanelPhotographSceneChange:SwitchGyroModel(index)
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    XMVCA.XSwitchableScene:SetGyroSetting(sceneId, index)
    self:UpdateSceneChangeBtn()
end

function XUiPanelPhotographSceneChange:SwitchMusicMode(mode)
    local sceneId = XDataCenter.PhotographManager.GetCurSelectSceneId()
    XMVCA.XMusicScene:UpdateMusicSceneMode(sceneId, mode)
    self:UpdateSceneChangeBtn()
end

function XUiPanelPhotographSceneChange:OnBtnSceneChange1Click()
    if self:GetType() == XPhotographConfigs.BackGroundType.Gyro then
        self:SwitchGyroModel(Open)
    else
        self:SwitchSceneMode(Day_Full)
    end
end

function XUiPanelPhotographSceneChange:OnBtnSceneChange2Click()
    local sceneType = self:GetType()
    if sceneType == XPhotographConfigs.BackGroundType.Gyro then
        return
    elseif sceneType == XPhotographConfigs.BackGroundType.Music then
        self:SwitchMusicMode(Music)
    else
        self:SwitchSceneMode(Night_Low)
    end
end

function XUiPanelPhotographSceneChange:OnBtnSceneChange3Click()
    local sceneType = self:GetType()
    if sceneType == XPhotographConfigs.BackGroundType.Gyro then
        self:SwitchGyroModel(Close)
    elseif sceneType == XPhotographConfigs.BackGroundType.Music then
        self:SwitchMusicMode(Normal)
    else
        self:SwitchSceneMode(Auto)
    end
end

return XUiPanelPhotographSceneChange
