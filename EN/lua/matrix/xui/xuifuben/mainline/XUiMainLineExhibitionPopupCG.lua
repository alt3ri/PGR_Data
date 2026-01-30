---@class XUiMainLineExhibitionPopupCG:XLuaUi
local XUiMainLineExhibitionPopupCG = XLuaUiManager.Register(XLuaUi, "UiMainLineExhibitionPopupCG")

function XUiMainLineExhibitionPopupCG:OnAwake()
    self.CharacterGos = {}
    self:RegisterUiEvents()
end

function XUiMainLineExhibitionPopupCG:OnStart(chapterId, enableCb, disableCb)
    self.ChapterId = chapterId
    self.EnableCb = enableCb -- 激活界面的回调
    self.DisableCb = disableCb -- 关闭界面的回调
end

function XUiMainLineExhibitionPopupCG:OnEnable()
    self:Refresh()

    if self.EnableCb then
        self.EnableCb()
    end
end

function XUiMainLineExhibitionPopupCG:OnDisable()
    if self.DisableCb then
        self.DisableCb()
    end
end

function XUiMainLineExhibitionPopupCG:OnDestroy()
    self.CharacterGos = nil
    self.CharacterIds = nil
end

function XUiMainLineExhibitionPopupCG:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBgClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnGo, self.OnBtnGoClick)
    self:RegisterClickEvent(self.BtnIgnore, self.OnBtnIgnoreClick)
    self:RegisterClickEvent(self.GridChapter:GetObject("Button"), self.OnBtnChapterClick)
end

function XUiMainLineExhibitionPopupCG:OnBtnCloseClick()
    self:Close()
end

function XUiMainLineExhibitionPopupCG:OnBtnGoClick()
    local chapterId = self.ChapterId
    self:Close()
    XMVCA.XMainLine2:OpenExhibitionChapter(chapterId)
end

function XUiMainLineExhibitionPopupCG:OnBtnIgnoreClick()
    local isIgnore = XMVCA.XMainLine2:GetIsIgnoreUiExhibitionPopupChapter()
    XMVCA.XMainLine2:SetIgnoreUiExhibitionPopupChapter(not isIgnore)
    self:RefreshBtnIgnore()
end

function XUiMainLineExhibitionPopupCG:OnBtnChapterClick()
    local chapterId = self.ChapterId
    local stageIdStr = XMVCA.XMainLine2:GetClientConfigParams("NewbiePreChapterSkipCondition", 3)
    local stageId = tonumber(stageIdStr)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(stageId)
    self:Close()
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
            XMVCA.XMainLine2:OpenExhibitionChapter(chapterId)
        end)
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
            XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
                XMVCA.XMainLine2:OpenExhibitionChapter(chapterId)
            end)
        end)
    end
end

function XUiMainLineExhibitionPopupCG:Refresh()
    self:RefreshCG()
    self:RefreshBtnIgnore()
end

function XUiMainLineExhibitionPopupCG:RefreshBtnIgnore()
    local isIgnore = XMVCA.XMainLine2:GetIsIgnoreUiExhibitionPopupChapter()
    local btnState = isIgnore and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnIgnore:SetButtonState(btnState)
end

function XUiMainLineExhibitionPopupCG:RefreshCG()
    self.CharacterIds = self.CharacterIds or XMVCA.XMainLine2:GetClientConfigNumberArray('NewbiePreChapterCGLinkCharacterIds')
    local contentCharacter = self.GridChapter:GetObject("ContentCharacter")
    local gridHead = self.GridChapter:GetObject("GridHead")
    gridHead.gameObject:SetActiveEx(false)
    
    for _, go in pairs(self.CharacterGos) do
        go.gameObject:SetActiveEx(false)
    end

    for i, charId in ipairs(self.CharacterIds) do
        local charIndex = i
        local go = self.CharacterGos[i]
        if not go then
            go = XUiHelper.Instantiate(gridHead, contentCharacter)
            table.insert(self.CharacterGos, go)
            local button = go:GetComponent("XUiButton")
            XUiHelper.RegisterClickEvent(self, button, function()
                self:OnCharacterClick(charIndex)
            end, nil, true)
        end
        go.gameObject:SetActiveEx(true)
        local charUiObj = go:GetComponent("UiObject")
        local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(charId)
        charUiObj:GetObject("RImgHead"):SetRawImage(icon)
    end
end

function XUiMainLineExhibitionPopupCG:OnCharacterClick(charIndex)
    local characterId = self.CharacterIds[charIndex]
    self:Close()
    XMVCA.XPlotExhibition:OpenRoleDetail(characterId)
end

return XUiMainLineExhibitionPopupCG