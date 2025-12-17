---@class XUiRiftFightLayerSelect:XLuaUi 大秘境关卡选择界面
---@field _Control XRiftControl
local XUiRiftFightLayerSelect = XLuaUiManager.Register(XLuaUi, "UiRiftFightLayerSelect")

local ItemIds = {
    XDataCenter.ItemManager.ItemId.RiftGold,
    XDataCenter.ItemManager.ItemId.RiftGold3
}

function XUiRiftFightLayerSelect:OnAwake()
    ---@type XUiGridRiftStage[]
    self._Grids = {}

    self:BindHelpBtn(self.BtnHelp, "RiftHelp")
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnTaskClick) -- 任务按钮
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnAttribute, self.OnBtnAttributeClick)
    self:RegisterClickEvent(self.BtnPluginBag, self.OnBtnPluginBagClick)
    self:RegisterClickEvent(self.BtnCharacter, self.OnBtnCharacterClick)
    self.BtnAttributeRedEventId = XRedPointManager.AddRedPointEvent(self.BtnAttribute, self.OnCheckAttribute, self, { XRedPointConditions.Types.CONDITION_RIFT_ATTRIBUTE })
end

function XUiRiftFightLayerSelect:OnStart(chapterId)
    -- 从战斗回来 会先执行OnResume再OnStart
    self:UpdateChapter(self.ChapterId or chapterId)

    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end, nil, 0)
end

function XUiRiftFightLayerSelect:OnEnable()
    self:UpdateView()

    -- 检测区域是否全部通关 弹提示
    self.Chapter:CheckFirstPassAndOpenTipFun(function(nextChapterId)
        self._Control:SetAutoOpenChapterDetail(nextChapterId)
        self:Close()
    end)
end

function XUiRiftFightLayerSelect:OnDestroy()
    self:StopProgressTween()
    XRedPointManager.RemoveRedPointEvent(self.BtnAttributeRedEventId)
    self._Control:SetFirstPassChapterTrigger(nil) -- 关闭界面时清掉标记 防止从主界面进入时打开前往下一章弹框（只会在战斗结束后出现）
end

function XUiRiftFightLayerSelect:OnReleaseInst()
    return self.ChapterId
end

function XUiRiftFightLayerSelect:OnResume(chapterId)
    self:UpdateChapter(chapterId)
    self:UpdateView()
end

function XUiRiftFightLayerSelect:UpdateChapter(chapterId)
    self.ChapterId = chapterId
    ---@type XRiftChapter
    self.Chapter = self._Control:GetEntityChapterById(chapterId)
    
    self.BtnAttribute:SetNameByGroup(0, self._Control:GetFuncUnlockById(XEnumConst.Rift.FuncUnlockId.Plugin).Desc)
end

function XUiRiftFightLayerSelect:UpdateView()
    self:PlayAvg()
    self:Refresh()
    self:PlayProgressTween()
    self.BtnCharacter:ShowReddot(self._Control:GetCharacterRedPoint())
    if not self.AssetActivityPanel then
        self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
    end
end

function XUiRiftFightLayerSelect:PlayAvg()
    local startStoryId = self.Chapter:GetConfig().StartStoryId
    local startAvgId = XTool.IsNumberValid(startStoryId) and self._Control:GetRiftStoryById(startStoryId).AvgId or nil
    local endStoryId = self.Chapter:GetConfig().EndStoryId
    local endAvgId = XTool.IsNumberValid(endStoryId) and self._Control:GetRiftStoryById(endStoryId).AvgId or nil

    local startKey = string.format("RiftStory_%s_%s", startStoryId, XPlayer.Id)
    local endKey = string.format("RiftStory_%s_%s", endStoryId, XPlayer.Id)

    if not XSaveTool.GetData(startKey) and XTool.IsNumberValid(startAvgId) then
        XDataCenter.MovieManager.PlayMovie(startAvgId, function()
            XSaveTool.SaveData(startKey, true)
            XDataCenter.GuideManager.CheckGuideOpen()    -- 触发引导
        end, nil, nil, false)
    end

    local chapter, layer = self._Control:GetCurrPlayingChapter()
    -- 刚进入下一章节时 chapter是新的 但是layer是上一关挑战关的 所以这里判断下chapter是否一致 避免这种情况
    if layer and layer:IsChallenge() and layer:CheckFirstPassed() and chapter:GetChapterId() == layer:GetConfig().ChapterId then
        if not XSaveTool.GetData(endKey) and XTool.IsNumberValid(endAvgId) then
            XDataCenter.MovieManager.PlayMovie(endAvgId, function()
                XSaveTool.SaveData(endKey, true)
                XDataCenter.GuideManager.CheckGuideOpen()    -- 触发引导
            end, nil, nil, false)
        end
    end
end

function XUiRiftFightLayerSelect:Refresh()
    self:RefreshUiShow()
    self:RefreshStageList()
    local isShowRed = self._Control:CheckTaskCanReward()
    self.BtnShop:ShowReddot(isShowRed)
end

function XUiRiftFightLayerSelect:RefreshUiShow()
    -- 属性加点按钮
    local isUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    self.BtnAttribute:SetDisable(not isUnlock)
    -- 商店按钮
    XRedPointManager.Check(self.BtnAttributeRedEventId)
    local isShopRed = self._Control:IsShopRed()
    self.BtnShop:ShowReddot(isShopRed)
    -- 插件背包按钮
    local isPluginRed = self._Control:IsPluginBagRed()
    self.BtnPluginBag:ShowReddot(isPluginRed)
end

function XUiRiftFightLayerSelect:RefreshStageList()
    local resourceList = self.Chapter:GetAllFightLayersOrderList()
    local count = #resourceList
    local nodeIdx = 1
    local isEndless = self.Chapter:IsEndless()

    self.GridStage.gameObject:SetActiveEx(not isEndless)
    self.GridStageChallenge.gameObject:SetActiveEx(true)

    for i, fightLayer in ipairs(resourceList) do
        local grid = self._Grids[i]
        if not grid then
            local parent
            if isEndless then
                parent = self["StageEndless" .. nodeIdx]
            else
                if i == #resourceList then
                    parent = self.Stage5 --最后一关放在Stage5的位置上（居中）
                else
                    parent = self["Stage" .. nodeIdx]
                end
            end
            if not parent then
                goto CONTINUE
            end
            local go
            if i == 1 and not isEndless then -- 无尽关使用挑战关样式
                go = self.GridStage
                go:SetParent(parent, false)
            elseif i == count then
                go = self.GridStageChallenge -- 最后一关必定是挑战关
                go:SetParent(parent, false)
            else
                go = XUiHelper.Instantiate(self.GridStage, parent)
            end
            go.localPosition = CS.UnityEngine.Vector3.zero
            grid = require("XUi/XUiRift/Grid/XUiGridRiftStage").New(go, self)
            self._Grids[i] = grid
        end
        grid:Init(fightLayer, i)
        grid:Update()
        :: CONTINUE ::
        nodeIdx = nodeIdx + 1
    end
end

function XUiRiftFightLayerSelect:PlayProgressTween()
    for _, grid in pairs(self._Grids) do
        grid:PlayProgressTween()
    end
end

function XUiRiftFightLayerSelect:StopProgressTween()
    for _, grid in pairs(self._Grids) do
        grid:StopProgressTween()
    end
end

function XUiRiftFightLayerSelect:OnGridFightLayerSelected(fightLayer)
    -- 进入战斗层，记录进入打个卡
    if self._CurrSelectFightLayer ~= fightLayer then
        self._CurrSelectFightLayer = fightLayer
        --self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
    end
    self:Refresh()
end

function XUiRiftFightLayerSelect:OnBtnAttributeClick()
    local isUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    if isUnlock then
        XLuaUiManager.Open("UiRiftAttribute")
    else
        local funcUnlockCfg = self._Control:GetFuncUnlockById(XEnumConst.Rift.FuncUnlockId.Attribute)
        XUiManager.TipError(funcUnlockCfg.Desc)
    end
end

function XUiRiftFightLayerSelect:OnBtnCharacterClick()
    XLuaUiManager.Open("UiRiftCharacter", nil, nil, nil, true)
end

function XUiRiftFightLayerSelect:OnBtnPluginBagClick()
    XLuaUiManager.Open("UiRiftPluginBag")
end

function XUiRiftFightLayerSelect:OnBtnTaskClick()
    --self._Control:OpenUiShop()
    XLuaUiManager.Open("UiRiftTask")
end

function XUiRiftFightLayerSelect:OnCheckAttribute(count)
    self.BtnAttribute:ShowReddot(count >= 0)
end

function XUiRiftFightLayerSelect:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiRiftFightLayerSelect