local XUiBtnNewbieTaskTab = XClass(nil, "XUiBtnNewbieTaskTab")

function XUiBtnNewbieTaskTab:Ctor(ui, rootUi, tabInfos)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.TabInfos = tabInfos
    self:InitAutoScript()
    self:OnRefreshView()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiBtnNewbieTaskTab:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiBtnNewbieTaskTab:AutoInitUi()
    self.BtnNewbieTaskTab = self.Transform:GetComponent(typeof(CS.UnityEngine.UI.Button))
    self.ImgDefault = self.Transform:Find("ImgDefault"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.TxtDayDefault = self.Transform:Find("TxtDayDefault"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.ImgSelected = self.Transform:Find("ImgSelected"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.TxtDaySelected = self.Transform:Find("ImgSelected/TxtDaySelected"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.ImgReddot = self.Transform:Find("ImgReddot"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.ImgLock = self.Transform:Find("ImgLock"):GetComponent(typeof(CS.UnityEngine.UI.Image))
end

function XUiBtnNewbieTaskTab:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiBtnNewbieTaskTab:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiBtnNewbieTaskTab:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiBtnNewbieTaskTab:AutoAddListener()
    self:RegisterClickEvent(self.BtnNewbieTaskTab, self.OnBtnNewbieTaskTabClick)
end
-- auto

function XUiBtnNewbieTaskTab:OnBtnNewbieTaskTabClick()

end

function XUiBtnNewbieTaskTab:OnSelectDayTab(isSelect)
    self.ImgSelected.gameObject:SetActive(isSelect)
end

function XUiBtnNewbieTaskTab:OnRefreshView()
    self.TxtDayDefault.text = CS.XTextManager.GetText("NewbieDayTab1", self.TabInfos.OpenDay)
    self.TxtDaySelected.text = CS.XTextManager.GetText("NewbieDayTab1", self.TabInfos.OpenDay)
    local isCurrentLock = self:IsCurrentLock()
    self.ImgLock.gameObject:SetActive(isCurrentLock)
    if isCurrentLock then
        self.ImgReddot.gameObject:SetActive(false)
    else
        self.ImgReddot.gameObject:SetActive(XDataCenter.TaskManager.GetNewbiePlayTaskReddotByOpenDay(self.TabInfos.OpenDay))
    end
end

function XUiBtnNewbieTaskTab:IsCurrentLock()
    if XPlayer.NewPlayerTaskActiveDay == nil then return true end
    return self.TabInfos.OpenDay > XPlayer.NewPlayerTaskActiveDay
end

return XUiBtnNewbieTaskTab