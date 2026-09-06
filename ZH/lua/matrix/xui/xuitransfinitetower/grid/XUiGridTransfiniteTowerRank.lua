---@class XUiGridTransfiniteTowerRank : XUiNode
---@field private _Control XTransfiniteTowerControl
---@field TxtRank UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TxtStage UnityEngine.UI.Text
---@field TxtTime UnityEngine.UI.Text
---@field Head UnityEngine.RectTransform
---@field StandIcon UnityEngine.UI.RawImage
---@field ImgTeamBg UnityEngine.RectTransform
---@field BtnDetail XUiComponent.XUiButton
---@field BtnHead XUiComponent.XUiButton
local XUiGridTransfiniteTowerRank = XClass(XUiNode, "XUiGridTransfiniteTowerRank")

function XUiGridTransfiniteTowerRank:OnStart()
    self.BtnDetail:AddEventListener(handler(self, self.OnBtnDetailClick))
    self.BtnHead:AddEventListener(handler(self, self.OnBtnHeadClick))
    self:PlayAnimation()
end

function XUiGridTransfiniteTowerRank:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    self.GridRankEnable:PlayTimelineAnimation()
end

function XUiGridTransfiniteTowerRank:OnBtnDetailClick()
    -- 跳转他人结算记录（只读模式）
    if not XTool.IsNumberValid(self._PlayerId) then
        return
    end
    self._Control:OpenOthersLastSettlement(self._TowerCfgId, self._PlayerId)
end

function XUiGridTransfiniteTowerRank:OnBtnHeadClick()
    -- 待做：查看玩家信息（需求未要求，暂留空）
end

---刷新排名条目
---@param data table { PlayerId, TowerCfgId, Name, Head, Frame, Stage, UseTime, MvpFightId }
---@param index number 排名从1开始
function XUiGridTransfiniteTowerRank:Refresh(data, index)
    self._PlayerId = data.PlayerId
    self._TowerCfgId = data.TowerCfgId

    local name, head, frame = data.Name, data.Head, data.Frame
    if data.PlayerId == XPlayer.Id then
        name = XPlayer.Name
        head = XPlayer.CurrHeadPortraitId
        frame = XPlayer.CurrHeadFrameId
    end

    self.TxtName.text = name
    self.TxtStage.text = data.Stage
    self.TxtTime.text = XUiHelper.GetTime(data.UseTime, XUiHelper.TimeFormatType.BIG_LAYOUT)

    local rank = data.Rank or index
    if rank > 1000 and data.TotalCount and data.TotalCount > 0 then
        local percent = math.floor(rank * 100 / data.TotalCount)
        self.TxtRank.text = percent .. "%"
    elseif index == 1 then
        self.TxtRank.text = XUiHelper.GetText("Rank1Color", index)
    elseif index == 2 then
        self.TxtRank.text = XUiHelper.GetText("Rank2Color", index)
    elseif index == 3 then
        self.TxtRank.text = XUiHelper.GetText("Rank3Color", index)
    else
        self.TxtRank.text = XUiHelper.GetText("RankOtherColor", index)
    end

    XUiPlayerHead.InitPortrait(head, frame, self.Head)
    local icon = self._Control:GetFightHeadIcon(data.MvpFightId)
    self.StandIcon.gameObject:SetActiveEx(icon ~= nil)
    if icon then
        self.StandIcon:SetRawImage(icon)
    end
end

return XUiGridTransfiniteTowerRank
