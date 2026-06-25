local XUiGridChallengeTab = XClass(nil, "XUiGridChallengeTab")

function XUiGridChallengeTab:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridChallengeTab:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridChallengeTab:AutoInitUi()
    self.PanelTabUnSelect = self.Transform:Find("PanelTabUnSelect")
    self.ImgUnSelect = self.Transform:Find("PanelTabUnSelect/ImgUnSelect"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.TxtUnSelectTitle = self.Transform:Find("PanelTabUnSelect/TxtUnSelectTitle"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.PanelTabSelect = self.Transform:Find("PanelTabSelect")
    self.ImgSelect = self.Transform:Find("PanelTabSelect/ImgSelect"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.TxtSelectTitle = self.Transform:Find("PanelTabSelect/TxtSelectTitle"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.PanelTabLock = self.Transform:Find("PanelTabLock")
    self.ImgUnSelect = self.Transform:Find("PanelTabLock/ImgUnSelect"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.ImgLock = self.Transform:Find("PanelTabLock/ImgLock"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.TxtLockTitleA = self.Transform:Find("PanelTabLock/TxtLockTitle"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.ImgNewCheckPoint = self.Transform:Find("ImgNewCheckPoint"):GetComponent(typeof(CS.UnityEngine.UI.Image))
end

function XUiGridChallengeTab:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridChallengeTab:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridChallengeTab:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridChallengeTab:AutoAddListener()
end
-- auto

function XUiGridChallengeTab:UpdateDefaultViews()
    self.PanelTabUnSelect.gameObject:SetActive(false)
    self.PanelTabSelect.gameObject:SetActive(true)
    self.PanelTabLock.gameObject:SetActive(false)
    self.ImgNewCheckPoint.gameObject:SetActive(false)
    self.TxtSelectTitle.text = CS.XTextManager.GetText("PrequelChallangeTab")
end

return XUiGridChallengeTab
