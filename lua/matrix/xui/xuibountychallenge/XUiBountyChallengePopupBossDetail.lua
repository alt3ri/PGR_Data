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

function XUiBountyChallengePopupBossDetail:OnStart()
    local detail = self._Control:GetUiBossDetail()
    detail.Index = 1
end

function XUiBountyChallengePopupBossDetail:OnEnable()
    self:Update()
end

function XUiBountyChallengePopupBossDetail:OnDisable()

end

function XUiBountyChallengePopupBossDetail:Update()
    local detail = self._Control:GetUiBossDetail()
    self.TxtName.text = detail.Name
    self:UpdateDetail()
    self:UpdateArrowVisible()
    self:UpdatePage()
end

function XUiBountyChallengePopupBossDetail:UpdateDetail()
    local detail = self._Control:GetUiBossDetail()
    local index = detail.Index
    local data = detail.List[index]
    if data then
        self.TxtDesc.text = data.Desc
        if self.Video then
            if data.VideoConfigId then
                self.Video:SetInfoByVideoId(data.VideoConfigId)
                self.Video:RePlay()
            end
        end
    end
end

function XUiBountyChallengePopupBossDetail:OnClickLeft()
    local detail = self._Control:GetUiBossDetail()
    local index = math.max(detail.Index - 1, 1)
    if index == detail.Index then
        return
    end
    detail.Index = index
    self:UpdateDetail()
    self:UpdateArrowVisible()
    self:UpdatePage()
end

function XUiBountyChallengePopupBossDetail:OnClickRight()
    local detail = self._Control:GetUiBossDetail()
    local index = math.min(detail.Index + 1, #detail.List)
    if index == detail.Index then
        return
    end
    detail.Index = index
    self:UpdateDetail()
    self:UpdateArrowVisible()
    self:UpdatePage()
end

function XUiBountyChallengePopupBossDetail:UpdateArrowVisible()
    local detail = self._Control:GetUiBossDetail()
    if detail.Index == 1 then
        self.BtnLeft:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnLeft:SetButtonState(CS.UiButtonState.Normal)
    end
    if detail.Index == #detail.List then
        self.BtnRight:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnRight:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBountyChallengePopupBossDetail:UpdatePage()
    local detail = self._Control:GetUiBossDetail()
    local pageAmount = #detail.List
    for i = 1, pageAmount do
        local grid = self._PageGrids[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.GameObject, self.GameObject.transform.parent)
            self._PageGrids[i] = grid
        end
        grid.gameObject:SetActive(i <= pageAmount)

        if i == detail.Index then
            grid:Find("On").gameObject:SetActiveEx(true)
            grid:Find("Off").gameObject:SetActiveEx(false)
        else
            grid:Find("On").gameObject:SetActiveEx(false)
            grid:Find("Off").gameObject:SetActiveEx(true)
        end
    end
end

return XUiBountyChallengePopupBossDetail