local XUiGridDlcRelinkPlayerRank = require("XUi/XUiDlcRelink/Rank/XUiGridDlcRelinkPlayerRank")
---@class XUiDlcRelinkRank : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelBtnGroup XUiButtonGroup
local XUiDlcRelinkRank = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkRank")

function XUiDlcRelinkRank:OnAwake()
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    self.PanelMyRank.gameObject:SetActiveEx(false)
    self.PlayerRank.gameObject:SetActiveEx(false)
    self.BtnTabBoss.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkRank:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self:InitBtnTab()
    self:InitDynamicTable()
end

function XUiDlcRelinkRank:OnEnable()
    self.Super.OnEnable(self)
    self.PanelBtnGroup:SelectIndex(1)
end

function XUiDlcRelinkRank:OnDisable()
    self.Super.OnDisable(self)
end

function XUiDlcRelinkRank:InitBtnTab()
    self.LevelIdList = self._Control:GetRankLevelIds()
    local btnTabList = {}
    for index, levelId in ipairs(self.LevelIdList) do
        local btn = XUiHelper.Instantiate(self.BtnTabBoss, self.PanelBtnGroup.transform)
        btn.gameObject:SetActiveEx(true)
        local chapterId = self._Control:GetLevelChapterId(levelId)
        local chapterName = self._Control:GetChapterName(chapterId)
        local levelName = self._Control:GetLevelName(levelId)
        btn:SetNameByGroup(0, string.format("%s-%s", levelName, chapterName))
        btnTabList[index] = btn
    end
    self.PanelBtnGroup:Init(btnTabList, handler(self, self.OnBtnTabClick))
end

function XUiDlcRelinkRank:OnBtnTabClick(index)
    local levelId = self.LevelIdList[index]
    if not XTool.IsNumberValid(levelId) then
        return
    end

    self._Control:RequestQueryRank(levelId, function()
        self:SetupDynamicTable()
        self:OpenMyRank()
    end)
end

function XUiDlcRelinkRank:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkPlayerRank, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkRank:SetupDynamicTable()
    self.RankInfos = self._Control:GetQueryRankTeamInfos()
    local isEmpty = XTool.IsTableEmpty(self.RankInfos)
    self.PanelNoRank.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        return
    end
    self.DynamicTable:SetDataSource(self.RankInfos)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridDlcRelinkPlayerRank
function XUiDlcRelinkRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RankInfos[index], index, false)
    end
end

function XUiDlcRelinkRank:OpenMyRank()
    if not self.PanelMyRankUi then
        ---@type XUiGridDlcRelinkPlayerRank
        self.PanelMyRankUi = XUiGridDlcRelinkPlayerRank.New(self.PanelMyRank, self)
    end

    local isEmpty = XTool.IsTableEmpty(self.RankInfos)
    if isEmpty then
        self.PanelMyRankUi:Close()
        return
    end

    local myRankInfo = self._Control:GetQueryRankMyTeamInfo()
    local myRank = self._Control:GetQueryRankMyRank()
    self.PanelMyRankUi:Open()
    self.PanelMyRankUi:Refresh(myRankInfo, myRank, true)
end

function XUiDlcRelinkRank:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiDlcRelinkRank:OnBtnBackClick()
    self:Close()
end

function XUiDlcRelinkRank:OnBtnMainUiClick()
    self._Control:CommonRunMainUiHandle()
end

return XUiDlcRelinkRank
