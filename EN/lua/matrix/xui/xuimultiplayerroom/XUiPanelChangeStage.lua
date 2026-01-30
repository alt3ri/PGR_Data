local XUiPanelChangeStage = XClass(nil, "XUiPanelChangeStage")

function XUiPanelChangeStage:Ctor(ui, offlineFlag)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridStageList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.GridStage.gameObject:SetActiveEx(false)
    self.OfflineFlag = offlineFlag
end

function XUiPanelChangeStage:AutoAddListener()
    self.BtnClose.CallBack = function() self:Hide() end
end

function XUiPanelChangeStage:Show(challengeId, callBack)
    self:Refresh(challengeId, callBack)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelChangeStage:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelChangeStage:Refresh(challengeId)
    for _, v in ipairs(self.GridStageList) do
        v.gameObject:SetActive(false)
    end
end

return XUiPanelChangeStage