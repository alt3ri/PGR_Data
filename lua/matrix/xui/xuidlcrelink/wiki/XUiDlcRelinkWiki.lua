local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiDlcRelinkWiki : XLuaUi 百科全书
---@field _Control XDlcRelinkControl
local XUiDlcRelinkWiki = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEncyclopedia")

function XUiDlcRelinkWiki:OnAwake()
    self.BtnLeft:AddEventListener(handler(self, self.OnBtnLeftClick))
    self.BtnRight:AddEventListener(handler(self, self.OnBtnRightClick))
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiDlcRelinkWiki:OnStart()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollTitleTab)
    self.DynamicTable:SetProxy(require("XUi/XUiDlcRelink/Wiki/XUiGridWikiTab"), self)
    self.DynamicTable:SetDelegate(self)
    self.WikiItem.gameObject:SetActiveEx(false)

    self:InitWikiData()
    self:ShowTab()
end

function XUiDlcRelinkWiki:OnEnable()

end

function XUiDlcRelinkWiki:OnDestroy()
    self:StopVideo()
end

function XUiDlcRelinkWiki:InitWikiData()
    self._TabTypes = {}
    ---@type table<number,XTableDlcRelinkWiki[]>
    self._WikiDict = {}
    ---@type XTableDlcRelinkWiki[]
    self._AllWiki = {}

    local datas = self._Control:GetWikiConfigs()
    for _, v in pairs(datas) do
        table.insert(self._AllWiki, v)
    end
    table.sort(self._AllWiki, function(a, b)
        return a.Id < b.Id
    end)

    for _, v in ipairs(self._AllWiki) do
        if not self._WikiDict[v.Type] then
            self._WikiDict[v.Type] = {}
        end
        table.insert(self._WikiDict[v.Type], v)
        if not self._TabTypes[v.Type] then
            self._TabTypes[v.Type] = v.Type
        end
    end

    table.sort(self._TabTypes)
    --默认选中第一个
    self._CurWiki = self._AllWiki[1]
end

function XUiDlcRelinkWiki:ShowTab()
    local i = 1
    local tabs = { self.BtnTabAll }
    for _, tabType in pairs(self._TabTypes) do
        local normalIcon = self._Control:GetClientConfig("WikiTypeTabNormalIcon", tabType)
        local selectIcon = self._Control:GetClientConfig("WikiTypeTabSelectIcon", tabType)
        local btn = i == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.BtnTab.transform.parent)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, btn)
        if string.IsNilOrEmpty(normalIcon) or string.IsNilOrEmpty(selectIcon) then
            XLog.Error(string.format("百科全书不存在类型【%s】对应的页签图标配置", tabType))
        else
            self:SetUiSprite(uiObject.ImgIconNormal, normalIcon)
            self:SetUiSprite(uiObject.ImgIconPress, normalIcon)
            self:SetUiSprite(uiObject.ImgIconSelect, selectIcon)
        end
        table.insert(tabs, btn)
        i = i + 1
    end
    self.PanelTab:Init(tabs, function(index)
        self:OnSelectTab(index)
    end)
    self.PanelTab:SelectIndex(1)
end

function XUiDlcRelinkWiki:OnSelectTab(index)
    local datas = {}
    if index == 1 then
        datas = self._AllWiki
    else
        datas = self._WikiDict[index - 1] --第一个按钮是【全部】
    end
    self.DynamicTable:SetDataSource(datas)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiGridWikiTab
function XUiDlcRelinkWiki:OnDynamicTableEvent(event, index, grid)
    local wiki = self.DynamicTable:GetData(index)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateData(wiki)
        grid:UpdateSelect(self._CurWiki.Id)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectWiki(wiki)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:SelectWiki(self._CurWiki)
    end
end

---@param wiki XTableDlcRelinkWiki
function XUiDlcRelinkWiki:SelectWiki(wiki)
    ---@type XUiGridWikiTab[]
    local grids = self.DynamicTable:GetGrids()
    for _, v in pairs(grids) do
        v:UpdateSelect(wiki.Id)
        if v._Wiki.Id == wiki.Id then
            v:OnClick()
        end
    end
    self:ShowWikiDetail(wiki)
end

---@param wiki XTableDlcRelinkWiki
function XUiDlcRelinkWiki:ShowWikiDetail(wiki)
    self._CurPage = 1
    self._CurWiki = wiki
    self._TotalPage = #wiki.Desc
    self.BtnLeft.gameObject:SetActiveEx(self._TotalPage > 1)
    self.BtnRight.gameObject:SetActiveEx(self._TotalPage > 1)
    self._GridDots = {}
    if self._TotalPage <= 1 then
        self.PanelDot.gameObject:SetActiveEx(false)
    else
        self.PanelDot.gameObject:SetActiveEx(true)
        XUiHelper.RefreshCustomizedList(self.PanelDot, self.GridDot, self._TotalPage, function(index, go)
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, go)
            self._GridDots[index] = uiObject
        end)
    end
    self:UpdateWikiDetail()
end

function XUiDlcRelinkWiki:OnBtnLeftClick()
    if self._CurPage <= 1 then
        self._CurPage = self._TotalPage
    else
        self._CurPage = self._CurPage - 1
    end
    self:UpdateWikiDetail()
end

function XUiDlcRelinkWiki:OnBtnRightClick()
    if self._CurPage >= self._TotalPage then
        self._CurPage = 1
    else
        self._CurPage = self._CurPage + 1
    end
    self:UpdateWikiDetail()
end

function XUiDlcRelinkWiki:UpdateWikiDetail()
    self.TxtTeachDescription.text = XUiHelper.ReplaceTextNewLine(self._CurWiki.Desc[self._CurPage])
    local videoConfigId = self._CurWiki.VideoConfigIds[self._CurPage]
    if not XTool.IsNumberValid(videoConfigId) then
        self:StopVideo()
        local img = self._CurWiki.ImageUrl[self._CurPage]
        if string.IsNilOrEmpty(img) then
            self.VisualImage.gameObject:SetActiveEx(false)
        else
            self.VisualImage.gameObject:SetActiveEx(true)
            self.VisualImage:SetRawImage(img)
        end
    else
        self:PlayVideo(videoConfigId)
        self.VisualImage.gameObject:SetActiveEx(false)
    end
    for i, v in pairs(self._GridDots) do
        v.ImgOff.gameObject:SetActiveEx(i ~= self._CurPage)
        v.ImgOn.gameObject:SetActiveEx(i == self._CurPage)
    end
end

function XUiDlcRelinkWiki:PlayVideo(videoConfigId)
    if not XTool.IsNumberValid(videoConfigId) then
        self.VideoMask.gameObject:SetActiveEx(false)
        return
    end

    self.VideoMask.gameObject:SetActiveEx(true)
    self.Video:SetInfoByVideoId(videoConfigId)
    self.Video:RePlay()
end

function XUiDlcRelinkWiki:StopVideo()
    if self.Video then
        self.Video:Stop()
        self.VideoMask.gameObject:SetActiveEx(false)
    end
end

return XUiDlcRelinkWiki
