local XUiGridLastSettleMember = require("XUi/XUiTransfiniteTower/Grid/XUiGridLastSettleMember")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiTransfiniteTowerSwitchMvpPopup : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field GridMemberMVP UnityEngine.RectTransform
---@field GridMember UnityEngine.RectTransform
---@field ScrollView UnityEngine.RectTransform
---@field TxtStageName UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
---@field BtnConfirm XUiComponent.XUiButton
---@field BtnCancel XUiComponent.XUiButton
local XUiTransfiniteTowerSwitchMvpPopup = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerSwitchMvpPopup")

-- 排序时的当前 MVP 出战 id，供下方 comparator 读取（避免每次排序新建闭包）
local SortMvpFightId = nil
local function SortCandidate(a, b)
    if a.FightId == SortMvpFightId then
        return true
    end
    if b.FightId == SortMvpFightId then
        return false
    end
    if a.Quality ~= b.Quality then
        return a.Quality > b.Quality
    end
    if a.Power ~= b.Power then
        return a.Power > b.Power
    end
    if a.Priority ~= b.Priority then
        return a.Priority < b.Priority
    end
    return a.FightId < b.FightId
end

function XUiTransfiniteTowerSwitchMvpPopup:OnAwake()
    self:InitMvpGrid()
    self:InitDynamicTable()
    self:RegisterButtonEvent()
end

function XUiTransfiniteTowerSwitchMvpPopup:OnStart(towerCfgId)
    self._TowerCfgId = towerCfgId
end

function XUiTransfiniteTowerSwitchMvpPopup:OnEnable()
    self:Refresh()
end

--region 初始化

function XUiTransfiniteTowerSwitchMvpPopup:InitMvpGrid()
    -- 左侧 MVP 展示格（切换时展示选中的角色，用半身像）
    ---@type XUiGridLastSettleMember
    self._MvpGrid = XUiGridLastSettleMember.New(self.GridMemberMVP, self)
    self._MvpGrid:SetIsMvp(true)
end

function XUiTransfiniteTowerSwitchMvpPopup:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.ScrollView.gameObject)
    self._DynamicTable:SetProxy(XUiGridLastSettleMember, self)
    self._DynamicTable:SetDelegate(self)
    self.GridMember.gameObject:SetActiveEx(false)
end

function XUiTransfiniteTowerSwitchMvpPopup:RegisterButtonEvent()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnCancel:AddEventListener(handler(self, self.Close))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

--endregion

--region 刷新

function XUiTransfiniteTowerSwitchMvpPopup:Refresh()
    -- 候选列表就是结算的出战角色快照（当前 MVP 本来就在其中，不要重复插入）
    local mvpData = self._Control:GetLastSettleMvpMember(self._TowerCfgId)
    local mvpFightId = mvpData and not mvpData.IsEmpty and mvpData.FightId or nil
    local list = {}
    -- 候选列表要含当前 MVP（它排第一位），故不排除
    for _, m in ipairs(self._Control:GetLastSettleMemberList(self._TowerCfgId, nil, false) or table.empty) do
        if not m.IsEmpty then
            m.IsCurrentMvp = m.FightId == mvpFightId
            list[#list + 1] = m
        end
    end
    -- 排序：当前 MVP 永远第一位；其余按品阶从高到低
    SortMvpFightId = mvpFightId
    table.sort(list, SortCandidate)
    self._CandidateList = list

    self._SelectedFightId = mvpFightId
    self._MvpGrid:Refresh(mvpData)

    self._DynamicTable:SetDataSource(self._CandidateList)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiTransfiniteTowerSwitchMvpPopup:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._CandidateList[index]
        grid:Refresh(data)
        grid:SetSelect(data and data.FightId == self._SelectedFightId)
    end
end

---点击右侧候选角色：更新选中态 + 左侧 MVP 格切换展示
function XUiTransfiniteTowerSwitchMvpPopup:OnCandidateClick(grid, data)
    if not data or data.IsEmpty then
        return
    end
    self._SelectedFightId = data.FightId
    self._MvpGrid:Refresh(data)
    self:RefreshCandidateSelect()
end

---刷新所有候选格的选中态
function XUiTransfiniteTowerSwitchMvpPopup:RefreshCandidateSelect()
    local grids = self._DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        local data = grid:GetData()
        grid:SetSelect(data and data.FightId == self._SelectedFightId)
    end
end

--endregion

--region 按钮回调

function XUiTransfiniteTowerSwitchMvpPopup:OnBtnConfirmClick()
    self._Control:RequestSwitchMvp(self._TowerCfgId, self._SelectedFightId, handler(self, self.OnSwitchSuccess))
end

function XUiTransfiniteTowerSwitchMvpPopup:OnSwitchSuccess()
    XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerSwitchMvpSuccessTip"))
    self:Close()
end

--endregion

return XUiTransfiniteTowerSwitchMvpPopup
