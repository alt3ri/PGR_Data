---@class XUiBountyChallengePopupBossDetail : XLuaUi
---@field _Control XBountyChallengeControl
---@field Video XVideoPlayerBase
local XUiBountyChallengePopupBossDetail = XLuaUiManager.Register(XLuaUi, "UiBountyChallengePopupBossDetail")

function XUiBountyChallengePopupBossDetail:OnAwake()
    self:BindExitBtns(self.BtnTanchuangCloseBig)
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnClickLeft)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnClickRight)
    --self.Video = XLuaVideoManager.LoadVideoPlayerUguiWithPrefab(self.PanelVideo)
    --self.Video.IsLooping = true
    self._PageGrids = { self.GameObject }
end

function XUiBountyChallengePopupBossDetail:OnStart(detail)
    if not detail then
        detail = self._Control:GetUiBossDetail()
        detail.Index = 1
        self._IsFromControl = true
    else
        self._IsFromControl = false
    end

    self._Detail = detail
    self._OpenTime = XTime.GetServerNowTimestamp()
end

function XUiBountyChallengePopupBossDetail:OnEnable()
    self:Update()
end

function XUiBountyChallengePopupBossDetail:OnDisable()
    if self._OpenTime and self._Detail then
        local duration = XTime.GetServerNowTimestamp() - self._OpenTime
        local bossId = self._Detail.BossId or 0
        local type = self._IsFromControl and "BossDetail" or "TargetSkill"
        local dict = {
            boss_id = bossId,
            duration = duration,
            type = type
        }
        CS.XRecord.Record(dict, "1000027", "BountyChallengeCheckDetail")
    end
end

function XUiBountyChallengePopupBossDetail:Update()
    self:UpdateDetail()
    self:UpdateArrowVisible()
    self:UpdatePage()
end

function XUiBountyChallengePopupBossDetail:UpdateDetail()
    local index = self._Detail.Index
    local data = self._Detail.List[index]
    if data then
        self.TxtDesc.text = data.Desc
        if self.Video then
            if data.VideoConfigId then
                self.Video:SetInfoByVideoId(data.VideoConfigId)
                self.Video:RePlay()
            end
        end
    end

    self.TxtName.text = self._Detail.Names[index]
end

function XUiBountyChallengePopupBossDetail:OnClickLeft()
    local index = math.max(self._Detail.Index - 1, 1)
    if index == self._Detail.Index then
        return
    end
    self._Detail.Index = index
    self:UpdateDetail()
    self:UpdateArrowVisible()
    self:UpdatePage()
end

function XUiBountyChallengePopupBossDetail:OnClickRight()
    local index = math.min(self._Detail.Index + 1, #self._Detail.List)
    if index == self._Detail.Index then
        return
    end
    self._Detail.Index = index
    self:UpdateDetail()
    self:UpdateArrowVisible()
    self:UpdatePage()
end

function XUiBountyChallengePopupBossDetail:UpdateArrowVisible()
    if self._Detail.Index == 1 then
        self.BtnLeft:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnLeft:SetButtonState(CS.UiButtonState.Normal)
    end
    if self._Detail.Index == #self._Detail.List then
        self.BtnRight:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnRight:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBountyChallengePopupBossDetail:UpdatePage()
    local pageAmount = #self._Detail.List
    for i = 1, pageAmount do
        local grid = self._PageGrids[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.GameObject, self.GameObject.transform.parent)
            self._PageGrids[i] = grid
        end
        grid.gameObject:SetActive(i <= pageAmount)

        if i == self._Detail.Index then
            grid:Find("On").gameObject:SetActiveEx(true)
            grid:Find("Off").gameObject:SetActiveEx(false)
        else
            grid:Find("On").gameObject:SetActiveEx(false)
            grid:Find("Off").gameObject:SetActiveEx(true)
        end
    end
end

return XUiBountyChallengePopupBossDetail