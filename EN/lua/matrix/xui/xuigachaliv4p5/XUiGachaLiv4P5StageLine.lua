local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiGachaLiv4P5StageLine : XLuaUi 剧情关界面(用的 festivalActivity 表)
---@field _Scene XUiPanelGachaLiv4P5Scene
local XUiGachaLiv4P5StageLine = XLuaUiManager.Register(XLuaUi, "UiGachaLifu405StageLine")

function XUiGachaLiv4P5StageLine:OnAwake()
    self._LastOpenStage = nil
    self._StageGroup = {}
    self._IsFirstOpenGachaMain = true --第一次打开卡池主界面需要播入场动画
    ---@type XUiGridGachaStageItem[]
    self._Stages = {}
    self:InitButton()
end

function XUiGachaLiv4P5StageLine:OnStart(gachaId)
    self._GachaId = gachaId
    ---@type XTableGacha
    self._GachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)
    self._ChapterId = self._GachaCfg.FestivalActivityId
    self._ChapterTemplate = XFestivalActivityConfig.GetFestivalById(self._ChapterId)
    self._Scene = require("XUi/XUiGachaLiv4P5/Grid/XUiPanelGachaLiv4P5Scene").New(self.Transform, self)
    ---@type XUiPanelSwitchableSceneAnim
    self._SwitchableScene = require("XUi/XUiSwitchableScene/XUiPanelSwitchableSceneAnim").New()

    self._SceneId = XGachaConfigs.GetClientConfigNumber('Liv4P5SceneId')

    -- 卡池剧情强制开启陀螺仪
    self._SwitchableScene:SetGyroEnabledOverride(true)
end

function XUiGachaLiv4P5StageLine:OnEnable()
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
    self._SwitchableScene:Play(self._SceneId, self.UiSceneInfo.Transform)
end

function XUiGachaLiv4P5StageLine:OnDisable()
    for _, stage in pairs(self._Stages) do
        stage:Close()
    end
    self._SwitchableScene:Stop()
end

function XUiGachaLiv4P5StageLine:OnDestory()
    self._SwitchableScene:OnDestory()
end

function XUiGachaLiv4P5StageLine:InitButton()
    self.SceneBtnBack:AddEventListener(handler(self, self.Close))
    self.SceneBtnMainUi:AddEventListener(function()
        XLuaUiManager.RunMain()
    end)
end

function XUiGachaLiv4P5StageLine:SetUiData()
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

function XUiGachaLiv4P5StageLine:HandleStages()
    for i = 1, #self._StageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiGachaLiv4P5StageLine:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        self._StageGroup[i] = itemStage
        if not self._Stages[i] then
            self._Stages[i] = require("XUi/XUiGachaLiv4P5/Grid/XUiGridGachaLiv4P5StageItem").New(itemStage, self)
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
    
    -- 启动动画播放
    if not XTool.IsTableEmpty(self._Stages) then
        local delay = XGachaConfigs.GetClientConfigNumber("Liv4P5StoryGridEnableAnimDelay", 1)
        local interval = XGachaConfigs.GetClientConfigNumber("Liv4P5StoryGridEnableAnimInterval", 1)
        local realDelay = delay
        
        for i, v in ipairs(self._Stages) do
            v:PreEnableAnim()
            v:PlayEnableAnim(realDelay)
            
            realDelay = realDelay + interval
        end
    end
end

function XUiGachaLiv4P5StageLine:HandleStageLines()
    self._FestivalStageLine = {}
    for i = 1, #self._StageIds do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiGachaLiv4P5StageLine:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self._FestivalStageLine[i] = itemLine
    end

    -- 隐藏/显示多余组件
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self._StageIds[#self._StageIds])
    local isAllOpen = stageInfo and stageInfo.IsOpen
    local indexLine = #self._FestivalStageLine
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(isAllOpen)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 背景
function XUiGachaLiv4P5StageLine:SwitchFestivalBg()
    self.RImgFestivalBg.gameObject:SetActiveEx(false)
end

-- 加载特效
function XUiGachaLiv4P5StageLine:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

-- 更新节点线条
function XUiGachaLiv4P5StageLine:UpdateNodeLines()
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

function XUiGachaLiv4P5StageLine:SetStageLineActive(index, isActive)
    if self._FestivalStageLine[index] then
        self._FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 通过Stage调用的接口
function XUiGachaLiv4P5StageLine:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiGachaLifu405StageDetail", stageId)
end

-- 选中关卡描边效果
function XUiGachaLiv4P5StageLine:UpdateNodesSelect(stageId)
    local stageIds = self._StageIds
    for i = 1, #stageIds do
        if self._Stages[i] then
            self._Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
-- TODO: 此处 self.FestivalStageIds / self.FestivalStages 疑似字段名错误，
--       实际定义为 self._StageIds / self._Stages，需与原始迁移版本核对后统一修正。
function XUiGachaLiv4P5StageLine:ClearNodesSelect()
    if not self.FestivalStageIds or not self.FestivalStages then
        return
    end
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end
-- 通过Stage调用的接口结束

function XUiGachaLiv4P5StageLine:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then
        return
    end
    self.PanelStageList.movementType = moveMentType
end

function XUiGachaLiv4P5StageLine:MoveIntoStage(stageIndex)
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

function XUiGachaLiv4P5StageLine:OnGotoGacha()
    if XLuaUiManager.IsUiLoad("UiGachaLifu405Main") then
        self:Close()
    else
        --v4.2优化：从活动打开剧情界面，再第一次进入研发界面时：如果【跳过剧情】则播AnimDisableStory，否则播AnimEnableLong
        local isSkip = XSaveTool.GetData("UiGachaLiv4P5")
        XLuaUiManager.Open("UiGachaLifu405Main", self._GachaId, self._IsFirstOpenGachaMain and not isSkip, true)
        self._IsFirstOpenGachaMain = false
    end
end

function XUiGachaLiv4P5StageLine:OnBtnSetClick()
    XLuaUiManager.Open("UiSet")
end

return XUiGachaLiv4P5StageLine