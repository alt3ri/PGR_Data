local XUiGridDlcRelinkRole = require("XUi/XUiDlcRelink/Rank/XUiGridDlcRelinkRole")
---@class XUiGridDlcRelinkPlayerRank : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkPlayerRank = XClass(XUiNode, "XUiGridDlcRelinkPlayerRank")

function XUiGridDlcRelinkPlayerRank:OnStart()
    self.ImgRankSpecial.gameObject:SetActiveEx(false)
    self.GridRole.gameObject:SetActiveEx(false)

    ---@type XUiGridDlcRelinkRole[]
    self.GridRoleList = {}
end

---@param rankInfo XDlcRelinkRankTeamInfo 排名信息
---@param rank number 排名
---@param isShowRate boolean 是否显示比率
function XUiGridDlcRelinkPlayerRank:Refresh(rankInfo, rank, isShowRate)
    self.RankInfo = rankInfo
    self.Rank = rank
    self:RefreshRank(isShowRate)
    self:RefreshPassTime()
    self:RefreshRole()
end

-- 刷新排名
---@param isShowRate boolean 是否显示比率
function XUiGridDlcRelinkPlayerRank:RefreshRank(isShowRate)
    self.TxtRankNormal.gameObject:SetActiveEx(true)
    if self.Rank <= 0 then
        self.TxtRankNormal.text = self._Control:GetClientConfig("DefaultRankText")
        return
    end
    self.TxtRankNormal.text = isShowRate and self:CalculateRate() or tostring(self.Rank)
end

-- 计算比率 向上取整
function XUiGridDlcRelinkPlayerRank:CalculateRate()
    if self.Rank <= 0 then
        return "0"
    end
    if self.Rank <= 100 then
        return tostring(self.Rank)
    end
    local totalCount = self._Control:GetQueryRankTotalCount()
    if totalCount <= 0 then
        return "0"
    end
    local rate = math.ceil(self.Rank / totalCount * 100)
    return string.format("%s%%", math.min(rate, 100))
end

-- 刷新通关时间
function XUiGridDlcRelinkPlayerRank:RefreshPassTime()
    if not self.RankInfo or self.RankInfo.FinishTime <= 0 then
        self.TxtRankScore.text = "00:00:00"
        return
    end
    self.TxtRankScore.text = XUiHelper.GetTime(self.RankInfo.FinishTime, XUiHelper.TimeFormatType.DAY_HOUR)
end

-- 刷新角色
function XUiGridDlcRelinkPlayerRank:RefreshRole()
    if not self.RankInfo then
        self.PanelRole.gameObject:SetActiveEx(false)
        return
    end
    self.PanelRole.gameObject:SetActiveEx(true)
    local playerInfos = self.RankInfo.PlayerInfos or {}
    for index, playerInfo in ipairs(playerInfos) do
        local grid = self.GridRoleList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridRole, self.PanelRole)
            grid = XUiGridDlcRelinkRole.New(go, self)
            self.GridRoleList[index] = grid
        end
        grid:Open()
        grid:Refresh(playerInfo)
    end

    for i = #playerInfos + 1, #self.GridRoleList do
        local grid = self.GridRoleList[i]
        if grid then
            grid:Close()
        end
    end
end

return XUiGridDlcRelinkPlayerRank
