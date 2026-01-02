local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiGachaBiankaStageLine : XLuaUi 剧情关界面(用的 festivalActivity 表)
---@field _Scene XUiPanelGachaBiankaScene
local XUiGachaBiankaStageLine = XLuaUiManager.Register(XLuaUi, "UiGachaBianka402StageLine")

function XUiGachaBiankaStageLine:OnAwake()
    self._LastOpenStage = nil
    self._StageGroup = {}
    self._IsFirstOpenGachaMain = true --第一次打开卡池主界面需要播入场动画
    ---@type XUiGridGachaStageItem[]
    self._Stages = {}
    self:InitButton()
end

function XUiGachaBiankaStageLine:OnStart(gachaId)
    self._GachaId = gachaId
    ---@type XTableGacha
    self._GachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)
    self._ChapterId = self._GachaCfg.FestivalActivityId
    self._ChapterTemplate = XFestivalActivityConfig.GetFestivalById(self._ChapterId)
    self._Scene = require("XUi/XUiGachaBianka/Grid/XUiPanelGachaBiankaScene").New(self.Transform, self)
end

function XUiGachaBiankaStageLine:OnEnable()
    self._Scene:Init3DSceneInfo()
    self:SetUiData()
    self:MoveIntoStage(self._LastOpenStage or 1) -- 自动定位

    local updateTime = XTime.GetSeverTomorrowFreshTime()
    XSaveTool.SaveData("GachaStoryRedPoint", updateTime)

    local timeId = self._GachaCfg.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if not isClose then
            local time = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
            self.TxtDay.text = XUiHelper.GetText("GachaBiankaTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
        end
    end, nil, 0)

    self._Scene:PlayEnterStageLine()
    self._Scene:PlayEnableStory()
end

function XUiGachaBiankaStageLine:OnDisable()
    for _, stage in pairs(self._Stages) do
        stage:Close()
    end
end

function XUiGachaBiankaStageLine:InitButton()
    self.SceneBtnBack:AddEventListener(handler(self, self.Close))
    self.SceneBtnMainUi:AddEventListener(function()
        XLuaUiManager.RunMain()
    end)
end

function XUiGachaBiankaStageLine:SetUiData()
    -- 初始化prefab组件
    local chapterGameObject = self.PanelChapter:LoadPrefab(self._ChapterTemplate.FubenPrefab)
    local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self._StageIds = self._ChapterTemplate.StageId
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 界面信息
    self:SwitchFestivalBg(self._ChapterTemplate)
    -- 加载特效
    self:LoadEffect(self._ChapterTemplate.EffectUrl)
    self.TxtChapterName.text = self._ChapterTemplate.Name
    self.TxtChapter.text = (self._ChapterId >= 10) and self._ChapterId or string.format("0%d", self._ChapterId)
    local itemId = XDataCenter.ItemManager.ItemId
    if self.PanelAsset then
        if not self.AssetPanel then
            self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.FreeGem, itemId.ActionPoint, itemId.Coin)
        end
    end
    -- 注册点击事件
    self.BtnSet:AddEventListener(handler(self, self.OnBtnSetClick))
    self.BtnGacha:AddEventListener(handler(self, self.OnGotoGacha))
end

function XUiGachaBiankaStageLine:HandleStages()
    for i = 1, #self._StageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiGachaBiankaStageLine:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        self._StageGroup[i] = itemStage
        if not self._Stages[i] then
            self._Stages[i] = require("XUi/XUiGachaBianka/Grid/XUiGridGachaBiankaStageItem").New(itemStage, self)
        end
        self._Stages[i]:Open()
        self._Stages[i]:UpdateNode(i, self._ChapterTemplate.Id, self._StageIds[i])
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #self._StageIds + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        extraStage.gameObject:SetActiveEx(false)
        indexStage = indexStage + 1
        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiGachaBiankaStageLine:HandleStageLines()
    self._FestivalStageLine = {}
    for i = 1, #self._StageIds do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiGachaBiankaStageLine:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self._FestivalStageLine[i] = itemLine
    end

    -- 隐藏多余组件
    local indexLine = #self._FestivalStageLine
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(false)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 背景
function XUiGachaBiankaStageLine:SwitchFestivalBg()
    self.RImgFestivalBg.gameObject:SetActiveEx(false)
end

-- 加载特效
function XUiGachaBiankaStageLine:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

-- 更新刷新
function XUiGachaBiankaStageLine:RefreshFestivalNodes()
    if not self._ChapterTemplate or not self._StageIds then
        return
    end
    for i = 1, #self._StageIds do
        self._Stages[i]:UpdateNode(i, self._ChapterTemplate.Id, self._StageIds[i])
    end
    self:UpdateNodeLines()
    -- 移动至ListView正确的位置
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end
end

-- 更新节点线条
function XUiGachaBiankaStageLine:UpdateNodeLines()
    if not self._ChapterTemplate or not self._StageIds then
        return
    end
    local stageLength = #self._StageIds
    for i = 1, stageLength do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self._StageIds[i])
        local isOpen = stageInfo.IsOpen
        self:SetStageLineActive(i, isOpen)
        if isOpen then
            self._LastOpenStage = i
        end
    end
end

function XUiGachaBiankaStageLine:SetStageLineActive(index, isActive)
    if self._FestivalStageLine[index] then
        self._FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 通过Stage调用的接口
function XUiGachaBiankaStageLine:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiGachaBianka402StageDetail", stageId)
end

-- 选中关卡描边效果
function XUiGachaBiankaStageLine:UpdateNodesSelect(stageId)
    local stageIds = self._StageIds
    for i = 1, #stageIds do
        if self._Stages[i] then
            self._Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiGachaBiankaStageLine:ClearNodesSelect()
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end
-- 通过Stage调用的接口结束

function XUiGachaBiankaStageLine:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then
        return
    end
    self.PanelStageList.movementType = moveMentType
end

function XUiGachaBiankaStageLine:MoveIntoStage(stageIndex)
    local gridRect = self._StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left = 100

    if diffX > CS.XResolutionManager.OriginWidth / 2 - left then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x - left
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        end)
    end
end

function XUiGachaBiankaStageLine:OnGotoGacha()
    if XLuaUiManager.IsUiLoad("UiGachaBianka402Main") then
        self:Close()
    else
        XLuaUiManager.Open("UiGachaBianka402Main", self._GachaId, self._IsFirstOpenGachaMain, true)
        self._IsFirstOpenGachaMain = false
    end
end

function XUiGachaBiankaStageLine:OnBtnSetClick()
    XLuaUiManager.Open("UiSet")
end

return XUiGachaBiankaStageLine