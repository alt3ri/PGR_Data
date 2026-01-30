local XUiPanelMainLineRoot = XClass(XSignalData, "XUiPanelMainLineRoot")

--######################## 静态方法 BEGIN ########################

function XUiPanelMainLineRoot.CheckHasRedPoint()
    return XDataCenter.FubenManagerEx.GetMainLineManager():ExCheckIsShowRedPoint()
end

--######################## 静态方法 END ########################

function XUiPanelMainLineRoot:Ctor(ui, root, panelData)
    panelData.UiParent.gameObject:SetActiveEx(true)
    self.RootUi = root
    self.Params = panelData.Params
    XUiHelper.InitUiClass(self, panelData.UiParent)

    self:RegisterUiEvents()
end

function XUiPanelMainLineRoot:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, self.OnBtnSwitchClick, nil, true)
end

function XUiPanelMainLineRoot:OnBtnSwitchClick()
    self.IsOpenExhibition = not self.IsOpenExhibition
    XMVCA.XMainLine2:SetOpenExhibition(self.IsOpenExhibition)
    
    if self.IsOpenExhibition then
        self:OpenPanelMainLineExhibition()
    else
        self:OpenPanelMainLine()
    end
    self:RefreshBtnSwitch()

    -- 埋点
    local dict = {}
    dict["is_new"] = self.IsOpenExhibition and 1 or 0
    CS.XRecord.Record(dict, "200021", "MainlineExhibitionSwitch")
end

function XUiPanelMainLineRoot:OnEnable()
    if self.IsOpenExhibition and self.UiPanelMainLineExhibition then
        self.UiPanelMainLineExhibition:OnEnable()
    elseif self.UiPanelMainLine then
        self.UiPanelMainLine:OnEnable()
    end
end

function XUiPanelMainLineRoot:OnDisable()
    self:CloseCurrentPanel()
end

function XUiPanelMainLineRoot:OnDestroy()
    if self.UiPanelMainLineExhibition then
        self.UiPanelMainLineExhibition:OnDestroy()
    end
    if self.UiPanelMainLine then
        self.UiPanelMainLine:OnDestroy()
    end
end


function XUiPanelMainLineRoot:SetData(firstTagId, groupIndex, chapterIndex)
    self.FirstTagId = firstTagId
    self.CurrentGroupId = groupIndex
    self.CurrentChapterIndex = chapterIndex
    self.IsOpenExhibition = XMVCA.XMainLine2:GetIsOpenExhibition()

    -- 打开当前面板
    if self.IsOpenExhibition then
        self:OpenPanelMainLineExhibition()
    else
        self:OpenPanelMainLine()
    end
    self:RefreshBtnSwitch()
end

-- 刷新切换按钮
function XUiPanelMainLineRoot:RefreshBtnSwitch()
    -- 提审包只显示旧主线
    if XUiManager.IsHideFunc then
        self.BtnSwitch.gameObject:SetActiveEx(false)
    end
    self.BtnSwitch:ActiveTextByGroup(0, self.IsOpenExhibition)
    self.BtnSwitch:ActiveTextByGroup(1, not self.IsOpenExhibition)
end

-- 打开主线时间轴
function XUiPanelMainLineRoot:OpenPanelMainLineExhibition()
    self:CloseCurrentPanel()
    self.PanelMainLineExhibition.gameObject:SetActiveEx(self.IsOpenExhibition)
    self.PanelMainLine.gameObject:SetActiveEx(not self.IsOpenExhibition)
    
    if not self.UiPanelMainLineExhibition then
        local ui = self.PanelMainLineExhibition.gameObject:LoadPrefab(self.Params[1])
        XUiHelper.SetCanvasesSortingOrder(ui.transform)
        ui.transform:SetAsFirstSibling()
        self.UiPanelMainLineExhibition = require("XUi/XUiFuben/MainLine/XUiPanelMainLineExhibition").New(ui, self.RootUi)
        self.UiPanelMainLineExhibition:SetData(self.FirstTagId, self.CurrentGroupId, self.CurrentChapterIndex)
    end
    self.UiPanelMainLineExhibition:OnEnable()
    self.CurrentPanel = self.UiPanelMainLineExhibition
end

-- 打开旧主线界面
function XUiPanelMainLineRoot:OpenPanelMainLine()
    self:CloseCurrentPanel()
    self.PanelMainLineExhibition.gameObject:SetActiveEx(self.IsOpenExhibition)
    self.PanelMainLine.gameObject:SetActiveEx(not self.IsOpenExhibition)
    
    if not self.UiPanelMainLine then
        local ui = self.PanelMainLine.gameObject:LoadPrefab(self.Params[2])
        XUiHelper.SetCanvasesSortingOrder(ui.transform)
        self.UiPanelMainLine = require("XUi/XUiFuben/MainLine/XUiPanelMainLine").New(ui, self.RootUi)
        self.UiPanelMainLine:SetData(self.FirstTagId, self.CurrentGroupId, self.CurrentChapterIndex)
    end
    self.UiPanelMainLine:OnEnable()
    self.CurrentPanel = self.UiPanelMainLine
end

-- 关闭当前面板
function XUiPanelMainLineRoot:CloseCurrentPanel()
    if self.CurrentPanel and self.CurrentPanel.IsEnable then
        self.CurrentPanel:OnDisable()
    end
end

return XUiPanelMainLineRoot