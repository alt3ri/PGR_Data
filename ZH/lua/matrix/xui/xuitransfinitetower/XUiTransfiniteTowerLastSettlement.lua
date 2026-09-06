local XUiGridLastSettleMember = require("XUi/XUiTransfiniteTower/Grid/XUiGridLastSettleMember")

---@class XUiTransfiniteTowerLastSettlement : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field TxtTitleMVP UnityEngine.UI.Text
---@field TxtChangeMVP UnityEngine.UI.Text
---@field PanelMembers UnityEngine.RectTransform
---@field GridMemberMVP UnityEngine.RectTransform
---@field PanelPlayer UnityEngine.RectTransform
---@field Head UnityEngine.RectTransform
---@field TxtPlayerName UnityEngine.UI.Text
---@field BtnComfirm XUiComponent.XUiButton
---@field BtnPagePrev XUiComponent.XUiButton
---@field BtnPageNext XUiComponent.XUiButton
---@field BtnSwitch XUiComponent.XUiButton
local XUiTransfiniteTowerLastSettlement = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerLastSettlement")

-- 常规池格子数（每页），prefab 固定 GridMember1~20
local NORMAL_GRID_COUNT = 20
-- 5 项通关统计节点名（顺序即展示顺序）
local StatsGridNames = {
    "GridLastStatsMember",       -- 出战队员数
    "GridLastStatsPower",        -- 累计战力
    "GridLastStatsClearedStage", -- 通关层数
    "GridLastStatsTime",         -- 总用时
    "GridLastStatsRank",         -- 总排名（可能有 New 标）
}

function XUiTransfiniteTowerLastSettlement:OnAwake()
    self:InitMemberGrids()
    self:InitStatsGrids()
    self:RegisterButtonEvent()
end

---@param towerCfgId number
---@param playerId number 传入则为「查看他人记录」只读模式（隐藏 MVP 切换 / 排名新高标）
function XUiTransfiniteTowerLastSettlement:OnStart(towerCfgId, playerId)
    self._TowerCfgId = towerCfgId
    self._PlayerId = playerId
    self._IsReadOnly = playerId ~= nil
end

function XUiTransfiniteTowerLastSettlement:OnEnable()
    -- 只读模式无 MVP 切换，无需监听切换事件
    if not self._IsReadOnly then
        XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_TOWER_MVP_CHANGE, self.OnMvpChange, self)
    end
    self:Refresh()
end

function XUiTransfiniteTowerLastSettlement:OnDisable()
    if not self._IsReadOnly then
        XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_TOWER_MVP_CHANGE, self.OnMvpChange, self)
    end
end

---MVP 切换成功后重拉数据，交换展示
function XUiTransfiniteTowerLastSettlement:OnMvpChange()
    self:RefreshMembers()
    self:RefreshMvpMember()
end

---点击 BtnSwitch：打开 MVP 切换弹窗
function XUiTransfiniteTowerLastSettlement:OnBtnSwitchClick()
    self._Control:OpenSwitchMvpPopup(self._TowerCfgId)
end

--region 初始化

function XUiTransfiniteTowerLastSettlement:InitMemberGrids()
    ---@type XUiGridLastSettleMember[]
    self._MemberGrids = {}
    for i = 1, NORMAL_GRID_COUNT do
        local node = self["GridMember" .. i]
        self._MemberGrids[i] = XUiGridLastSettleMember.New(node, self)
    end
    ---@type XUiGridLastSettleMember
    self._MvpGrid = XUiGridLastSettleMember.New(self.GridMemberMVP, self)
    self._MvpGrid:SetIsMvp(true)
end

function XUiTransfiniteTowerLastSettlement:InitStatsGrids()
    -- 5 项统计不写 grid 类，展开一次缓存内部节点（注入后数字节点统一为 TxtNum）
    self._StatsUis = {}
    for i = 1, #StatsGridNames do
        self._StatsUis[i] = XTool.InitUiObjectByUi({}, self[StatsGridNames[i]])
    end
end

function XUiTransfiniteTowerLastSettlement:RegisterButtonEvent()
    self.BtnComfirm:AddEventListener(handler(self, self.OnBtnComfirmClick))
    self.BtnPagePrev:AddEventListener(handler(self, self.OnBtnPagePrevClick))
    self.BtnPageNext:AddEventListener(handler(self, self.OnBtnPageNextClick))
    self.BtnSwitch:AddEventListener(handler(self, self.OnBtnSwitchClick))
end

--endregion

--region 刷新

function XUiTransfiniteTowerLastSettlement:Refresh()
    self:RefreshMode()
    self:RefreshTitle()
    self:RefreshMembers()
    self:RefreshMvpMember()
    self:RefreshPlayer()
    self:RefreshStats()
end

---按模式控制 MVP 切换相关元素显隐（只读模式隐藏）
function XUiTransfiniteTowerLastSettlement:RefreshMode()
    local canSwitch = not self._IsReadOnly
    self.TxtChangeMVP.gameObject:SetActiveEx(canSwitch)
    self.BtnSwitch.gameObject:SetActiveEx(canSwitch)
end

function XUiTransfiniteTowerLastSettlement:RefreshTitle()
    self.TxtTitleMVP.text = XUiHelper.GetText("TransfiniteTowerLastSettleTitle")
    if not self._IsReadOnly then
        self.TxtChangeMVP.text = XUiHelper.GetText("TransfiniteTowerChangeMvpTip")
    end
end

function XUiTransfiniteTowerLastSettlement:RefreshMembers()
    self._MemberList = self._Control:GetLastSettleMemberList(self._TowerCfgId, self._PlayerId) or table.empty
    self._TotalPage = math.max(1, math.ceil(#self._MemberList / NORMAL_GRID_COUNT))
    self._CurPage = 1
    self:RefreshMemberPage()
end

---按当前页填 20 个常规格（超出补空）
function XUiTransfiniteTowerLastSettlement:RefreshMemberPage()
    local startIdx = (self._CurPage - 1) * NORMAL_GRID_COUNT
    for i = 1, NORMAL_GRID_COUNT do
        self._MemberGrids[i]:Refresh(self._MemberList[startIdx + i])
    end
    self:RefreshPageButtons()
end

function XUiTransfiniteTowerLastSettlement:RefreshMvpMember()
    local mvpData = self._Control:GetLastSettleMvpMember(self._TowerCfgId, self._PlayerId)
    self._MvpGrid:Refresh(mvpData)
end

---仅当常规队员超过一页（>20）时显示翻页按钮；首页禁 Prev、末页禁 Next
function XUiTransfiniteTowerLastSettlement:RefreshPageButtons()
    local needPage = #self._MemberList > NORMAL_GRID_COUNT
    self.BtnPagePrev.gameObject:SetActiveEx(needPage)
    self.BtnPageNext.gameObject:SetActiveEx(needPage)
    if not needPage then
        return
    end
    self.BtnPagePrev:SetButtonState(self._CurPage <= 1 and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.BtnPageNext:SetButtonState(self._CurPage >= self._TotalPage and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiTransfiniteTowerLastSettlement:RefreshPlayer()
    if self._IsReadOnly then
        -- 他人记录：显示对方玩家信息
        local info = self._Control:GetOthersPlayerInfo(self._PlayerId)
        XUiPlayerHead.InitPortrait(info.HeadPortraitId, info.HeadFrameId, self.Head)
        self.TxtPlayerName.text = info.Name
    else
        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
        self.TxtPlayerName.text = XPlayer.Name
    end
end

function XUiTransfiniteTowerLastSettlement:RefreshStats()
    local stats = self._Control:GetLastSettleStats(self._TowerCfgId, self._PlayerId) or table.empty
    self._StatsUis[1].TxtNum.text = stats.MemberCount or ""
    self._StatsUis[2].TxtNum.text = stats.TotalPower or ""
    self._StatsUis[3].TxtNum.text = stats.ClearedStage or ""
    self._StatsUis[4].TxtNum.text = XUiHelper.GetTime(stats.TotalTime or 0, XUiHelper.TimeFormatType.MINUTE_SECOND)
    -- 排名：-1=未更新、0=未上榜、>0=具体名次；超过 1000 名按百分比显
    local rank = stats.Rank or -1
    local totalCount = stats.TotalCount or 0
    local rankText
    if rank > 1000 and totalCount > 0 then
        local percent = math.floor(rank * 100 / totalCount)
        rankText = percent .. "%"
    elseif rank > 0 then
        rankText = rank
    elseif rank == 0 then
        rankText = XUiHelper.GetText("TransfiniteTowerNotRanked")
    else
        rankText = XUiHelper.GetText("TransfiniteTowerRankNotUpdated")
    end
    self._StatsUis[5].TxtNum.text = rankText
    -- 仅排名 Grid 有新高标（最后一项）；只读模式（查看他人记录）不显示新高标
    local rankUi = self._StatsUis[#self._StatsUis]
    rankUi.ImgNew.gameObject:SetActiveEx(not self._IsReadOnly and stats.IsRankNew == true)
end

--endregion

--region 按钮回调

function XUiTransfiniteTowerLastSettlement:OnBtnComfirmClick()
    self:Close()
end

function XUiTransfiniteTowerLastSettlement:OnBtnPagePrevClick()
    if self._CurPage <= 1 then
        return
    end
    self._CurPage = self._CurPage - 1
    self:RefreshMemberPage()
end

function XUiTransfiniteTowerLastSettlement:OnBtnPageNextClick()
    if self._CurPage >= self._TotalPage then
        return
    end
    self._CurPage = self._CurPage + 1
    self:RefreshMemberPage()
end

--endregion

return XUiTransfiniteTowerLastSettlement
