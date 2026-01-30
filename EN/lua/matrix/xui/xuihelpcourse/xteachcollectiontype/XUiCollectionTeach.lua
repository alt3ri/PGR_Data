local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiCollectionTeachGrid = require("XUi/XUiHelpCourse/XTeachCollectionType/XUiCollectionTeachGrid")
local XUiPopTeachContent = require("XUi/XUiHelpCourse/XTeachPopType/Common/XUiPopTeachContent")

---@class XUiCollectionTeach : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field TabBtnGroup XUiButtonGroup
---@field BtnTab XUiComponent.XUiButton
---@field InputField UnityEngine.UI.InputField
---@field BtnDelete XUiComponent.XUiButton
---@field PanelNothingLeft UnityEngine.RectTransform
---@field PanelNothingRight UnityEngine.RectTransform
---@field TeachGrid UnityEngine.RectTransform
---@field ScrollTitleTab UnityEngine.RectTransform
---@field PanelTeachContent UnityEngine.RectTransform
---@field SearchPanel UnityEngine.RectTransform
---@field BtnSearch XUiComponent.XUiButton
---@field _Control XHelpCourseControl
local XUiCollectionTeach = XLuaUiManager.Register(XLuaUi, "UiCollectionTeach")

function XUiCollectionTeach:OnAwake()
    self._TabList = {}
    self._TabIndexGroupMap = {}

    self._SelectTabIndex = 0
    self._SelectTeachIndex = 1

    self._SearchKey = ""

    ---@type XDynamicTableNormal
    self._DynamicTable = false
    ---@type XUiPopTeachContent
    self._ContentUi = XUiPopTeachContent.New(self.PanelTeachContent, self)

    self:_RegisterButtonClicks()
end

function XUiCollectionTeach:OnStart(config, cb, jumpIndex, closeCb)
    self.Config = config
    self.Cb = cb
    self.JumpIndex = jumpIndex
    self.CloseCb = closeCb
    
    self._DynamicTable = XDynamicTableNormal.New(self.ScrollTitleTab)

    self:_InitUi()
    self:_InitDynamicTable()
    self:_RefreshDynamicTable()
end

function XUiCollectionTeach:OnEnable()
    self:_RefreshTabReddot()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiCollectionTeach:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiCollectionTeach:OnDestroy()

end

function XUiCollectionTeach:ChangeSelect(index, teachId)
    if self._SelectTeachIndex ~= index then
        local grid = self._DynamicTable:GetGridByIndex(self._SelectTeachIndex)

        if grid then
            grid:SetIsSelect(false)
        end
    end

    if index ~= self._SelectTeachIndex then
        self.ContentQieHuan:PlayTimelineAnimation()
    end
    self._SelectTeachIndex = index
    self:_RefreshTeachContent(teachId)
    self:_RefreshTabReddot()
end

function XUiCollectionTeach:OnBtnBackClick()
    self:Close()
end

function XUiCollectionTeach:OnTabBtnGroupClick(index)
    if self._SelectTabIndex ~= index then
        if self._SelectTabIndex ~= 0 then
            self.QieHuan:PlayTimelineAnimation()
        end
        self._SelectTabIndex = index
        self._SearchKey = ""
        self:_RefreshDynamicTable()
    end
end

---@param grid XUiBigWorldTeachGrid
function XUiCollectionTeach:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local helpId = self._DynamicTable.DataSource[index]
        local config = XMVCA.XHelpCourse:GetHelpCourseCfgById(helpId)
        
        grid:Refresh(config, index, index == self._SelectTeachIndex, self._SearchKey)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local allUseGird = self._DynamicTable:GetGrids()
        for index, grid in pairs(allUseGird) do
            grid:PlayEnableAnimation(index)
        end
    end
end

function XUiCollectionTeach:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnBack.CallBack = Handler(self, self.OnBtnBackClick)
end

function XUiCollectionTeach:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_READ, self._RefreshTabReddot, self)
end

function XUiCollectionTeach:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_READ, self._RefreshTabReddot, self)
end

function XUiCollectionTeach:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiCollectionTeach:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiCollectionTeach:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiCollectionTeach:_InitDynamicTable()
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiCollectionTeachGrid, self)
end

function XUiCollectionTeach:_InitUi()
    self.TeachGrid.gameObject:SetActiveEx(false)
end

function XUiCollectionTeach:_RefreshDynamicTable()
    local subIds = self._Control:TryGetSubHelpCourseIdsById(self.Config.Id)

    if XTool.IsNumberValid(subIds) then
        self:_RefreshDynamicTableWithTeachs(subIds)
    else
        self:_SetTeachPanelActive(false)
    end
end

function XUiCollectionTeach:_RefreshTabReddot()
    for index, groupId in pairs(self._TabIndexGroupMap) do
        local tab = self._TabList[index]

        if tab then
            -- 目前没有红点
            tab:ShowReddot(false)
        end
    end
end

function XUiCollectionTeach:_RefreshDynamicTableWithTeachs(subIds)
    self._ContentUi:Open()
    self._DynamicTable:SetDataSource(subIds)
    self._DynamicTable:ReloadDataSync()
end

function XUiCollectionTeach:_RefreshTeachContent(teachId)
    self._ContentUi:Open()
    self._ContentUi:Refresh(XMVCA.XHelpCourse:GetHelpCourseCfgById(teachId))
end

return XUiCollectionTeach
