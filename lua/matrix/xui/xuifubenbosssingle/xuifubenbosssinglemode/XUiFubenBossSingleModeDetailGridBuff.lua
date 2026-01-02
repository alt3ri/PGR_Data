local XUiFubenBossSingleModeDetailGridHead = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeDetailGridHead")
local XUiFubenBossSingleModeDetailGridSelectableFeature = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeDetailGridSelectableFeature")

---@class XUiFubenBossSingleModeDetailGridBuff : XUiNode
---@field PanelDetail UnityEngine.RectTransform
---@field TxtValue UnityEngine.UI.Text
---@field TxtMax UnityEngine.UI.Text
---@field BtnBuff XUiComponent.XUiButton
---@field PanelScoring UnityEngine.RectTransform
---@field ImgTriangleBg UnityEngine.UI.Image
---@field ImgBuffIcon UnityEngine.UI.RawImage
---@field TxtBuffName UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field GridCharacter UnityEngine.RectTransform
---@field TxtNone UnityEngine.UI.Text
---@field BtnTongBlack XUiComponent.XUiButton
---@field ListCharacter UnityEngine.RectTransform
---@field TxtTime UnityEngine.UI.Text
---@field TxtTimeDesc UnityEngine.UI.Text
---@field PanelTime UnityEngine.RectTransform
---@field TxtScoreRate UnityEngine.UI.Text  -- v4.2 新增：讨伐值倍率显示
---@field PanelFeatureSelectable UnityEngine.RectTransform  -- v4.2 新增：可选择词缀面板
---@field ListSelectableFeature UnityEngine.RectTransform  -- v4.2 新增：可选择词缀列表
---@field GridSelectableFeature UnityEngine.RectTransform  -- v4.2 新增：可选择词缀Grid模板
---@field PanelScoreRate UnityEngine.RectTransform  -- v4.2 新增：战斗倍率面板（控制显隐）
---@field TxtTotalScoreRate UnityEngine.UI.Text  -- v4.2 新增：总讨伐值倍率显示
---@field _Control XFubenBossSingleControl
---@field Parent XUiFubenBossSingleModeDetail
local XUiFubenBossSingleModeDetailGridBuff = XClass(XUiNode, "XUiFubenBossSingleModeDetailGridBuff")

-- region 生命周期

function XUiFubenBossSingleModeDetailGridBuff:OnStart()
    self:_InitUi()
    self:_InitAnimation()
    ---@type XBossSingleFeature
    self._Feature = nil
    self._RecordTimer = nil
    self._RecordEndTime = nil
    self._IsDetailOpen = false
    self._Index = 0
    ---@type XUiFubenBossSingleModeDetailGridHead[]
    self._GridHeadUiList = {}
    ---@type XUiFubenBossSingleModeDetailGridSelectableFeature[]
    self._GridSelectableFeatureUiList = {}
    ---@type table<number, boolean> 记录选中的可选词缀（key为featureId，value为是否选中）
    self._SelectedSelectableFeatures = {}

    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleModeDetailGridBuff:OnDisable()
    self:_StopRecordTimer()
end

-- endregion

---@param feature XBossSingleFeature
---@param index number
---@param featureGroupId number
function XUiFubenBossSingleModeDetailGridBuff:Refresh(feature, index, featureGroupId)
    if not feature or not XTool.IsNumberValid(index) then
        return
    end

    self._Feature = feature
    self._Index = index
    self._FeatureGroupId = featureGroupId
    self.ImgBuffIcon:SetRawImage(feature:GetIcon())
    self.ImgTriangleBg.gameObject:SetActiveEx(false)
    self.TxtBuffName.text = feature:GetName()
    self.TxtDetail.text = feature:GetDesc()
    self.TxtValue.text = feature:GetScore()
    self.TxtMax.text = "/" .. feature:GetTotalScore()
    self.PanelScoring.gameObject:SetActiveEx(feature:GetIsRecording())
    
    -- v4.2 新增：显示讨伐值倍率
    if self.TxtScoreRate then
        local scoreRate = feature:GetScoreRate()
        self.TxtScoreRate.text = string.format("x%.1f", scoreRate)
    end

    self:_RefreshRecordTime(index == 1)
end

function XUiFubenBossSingleModeDetailGridBuff:SetDetailActive(isActive)
    self:_PlayDetailAnimation(isActive)
    self._IsDetailOpen = isActive
    if isActive then
        self:_RefreshCharacterList()
        self.BtnBuff:SetButtonState(CS.UiButtonState.Select)
        -- v4.2 新增：显示该feature对应的可选词缀
        self:_RefreshSelectableFeatures()
    else
        for _, gridHead in pairs(self._GridHeadUiList) do
            gridHead:Close()
        end
        self.BtnBuff:SetButtonState(CS.UiButtonState.Normal)
        self.BtnBuff.TempState = CS.UiButtonState.Normal
        -- v4.2 新增：隐藏可选词缀UI
        self:_HideSelectableFeatureUI()
    end
end

function XUiFubenBossSingleModeDetailGridBuff:PlayBuffAnimation(isOpen, isDetailOpen)
    if isOpen then
        self:_PlayAnimation(self._BuffBigAnimation, function()
            self:SetDetailActive(isDetailOpen)
        end)
    else
        self:SetDetailActive(isDetailOpen)
        self:_PlayAnimation(self._BuffSmallAnimation)
    end
end

-- region 按钮事件

function XUiFubenBossSingleModeDetailGridBuff:OnBtnBuffClick()
    if self._IsDetailOpen then
        self.Parent:ChangeCamera(false)
    else
        self.Parent:ChangeBuffGrid(self._Index)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:OnBtnTongBlackClick()
    if self._Feature then
        local stageId = self._Feature:GetStageId()

        self.Parent:ChangeCamera(false)
        self.Parent:SetIsNeedResetAnimation(true)
        self._Control:SetEnterBossInfo(self.Parent:GetBossId(), XEnumConst.BossSingle.LevelType.Challenge, self._Feature:GetFeatureId())
        self._Control:OnEnterChallengeFight()
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, nil, require(
            "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeBattleRoleRoom"))
    end
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleModeDetailGridBuff:_RegisterButtonClicks()
    XUiHelper.RegisterClickEvent(self, self.BtnBuff, self.OnBtnBuffClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick, true)
end

function XUiFubenBossSingleModeDetailGridBuff:_RefreshCharacterList()
    if self._Feature:GetIsCharacterEmpty() then
        self.TxtNone.gameObject:SetActiveEx(true)

        for _, gridHead in pairs(self._GridHeadUiList) do
            gridHead:Close()
        end
    else
        local characterIds = self._Feature:GetCharacterList()
        local count = self._Control:GetMaxTeamCharacterMember()

        self.TxtNone.gameObject:SetActiveEx(false)
        for i = 1, count do
            local girdHead = self._GridHeadUiList[i]
            local characterId = characterIds[i]

            if not girdHead then
                local grid = XUiHelper.Instantiate(self.GridCharacter, self.ListCharacter)

                girdHead = XUiFubenBossSingleModeDetailGridHead.New(grid, self)
                self._GridHeadUiList[i] = girdHead
            end

            girdHead:Open()
            girdHead:Refresh(characterId)
        end
        for i = count + 1, #self._GridHeadUiList do
            self._GridHeadUiList[i]:Close()
        end
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_RefreshRecordTime(isFirst)
    local bossSingle = self._Control:GetBossSingleData()
    local recordTime = bossSingle:GetBossSingleChallengeDeleteRecordTime()

    if XTool.IsNumberValid(recordTime) and isFirst then
        local endTime = recordTime + self._Control:GetChallengeRecordCD()
        local nowTime = XTime.GetServerNowTimestamp()
        local isShow = endTime > nowTime

        self.PanelTime.gameObject:SetActiveEx(isShow)
        if isShow then
            self.TxtTimeDesc.text = XUiHelper.GetText("BossSingleChallengeRecordCD")
            self._RecordEndTime = endTime - nowTime
            self:_RefreshTimer()
            if self._RecordEndTime >= 0 then
                self:_StartRecordTimer()
            end
        end
    else
        self.PanelTime.gameObject:SetActiveEx(false)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_InitUi()
    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleModeDetailGridBuff:_InitAnimation()
    local root = self.BtnBuff.transform
    local animationRoot = root:FindTransform("Animation")

    if animationRoot then
        self._BuffBigAnimation = animationRoot:FindTransform("BtnBuffBig")
        self._BuffSmallAnimation = animationRoot:FindTransform("BtnBuffSmall")
    end

    root = self.PanelDetail.transform
    animationRoot = root:FindTransform("Animation")

    if animationRoot then
        self._DetailEnableAnimation = animationRoot:FindTransform("PanelDetailEnable")
        self._DetailDisableAnimation = animationRoot:FindTransform("PanelDetailDisable")
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_PlayAnimation(animation, finishCallback)
    if animation then
        animation:PlayTimelineAnimation(finishCallback)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_PlayDetailAnimation(isOpen)
    if self._IsDetailOpen ~= isOpen then
        if isOpen then
            self.PanelDetail.gameObject:SetActiveEx(isOpen)
            self:_PlayAnimation(self._DetailEnableAnimation, function()
                self.Parent:SetIsBuffPlaying(false)
            end)
        else
            self.Parent:SetIsBuffPlaying(false)
            self.PanelDetail.gameObject:SetActiveEx(isOpen)
        end
    else
        self.Parent:SetIsBuffPlaying(false)
        self.PanelDetail.gameObject:SetActiveEx(isOpen)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_StartRecordTimer()
    self:_StopRecordTimer()

    if XTool.IsNumberValid(self._RecordEndTime) then
        self._RecordTimer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshTimer), XScheduleManager.SECOND)
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_StopRecordTimer()
    if self._RecordTimer then
        XScheduleManager.UnSchedule(self._RecordTimer)
        self._RecordTimer = nil
    end
end

function XUiFubenBossSingleModeDetailGridBuff:_RefreshTimer()
    self.TxtTime.text = XUiHelper.GetTime(self._RecordEndTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)

    self._RecordEndTime = self._RecordEndTime - 1
    if not XTool.IsNumberValid(self._RecordEndTime) or self._RecordEndTime <= 0 then
        self.PanelTime.gameObject:SetActiveEx(false)
        self._RecordEndTime = nil
        self:_StopRecordTimer()
    end
end

-- v4.2 新增：刷新可选词缀列表
function XUiFubenBossSingleModeDetailGridBuff:_RefreshSelectableFeatures()
    if not self._Feature then
        XLog.Error("[XUiFubenBossSingleModeDetailGridBuff] _Feature is nil")
        return
    end
    
    local featureId = self._Feature:GetFeatureId()
    -- v4.2 修正：根据featureGroupId和featureId获取对应的BuffGroupId
    local buffGroupId = XMVCA.XFubenBossSingle:GetBossSingleChallengeBuffGroupIdByFeatureId(self._FeatureGroupId, featureId)
    if not buffGroupId or buffGroupId <= 0 then
        -- 没有对应的可选词缀组，隐藏UI
        self:_HideSelectableFeatureUI()
        return
    end
    
    -- 获取对应的BuffGroup配置
    local buffFeatureIds = XMVCA.XFubenBossSingle:GetBossSingleChallengeBuffGroupBuffById(buffGroupId)
    if XTool.IsTableEmpty(buffFeatureIds) then
        XLog.Error("[XUiFubenBossSingleModeDetailGridBuff] buffFeatureIds is empty")
        self:_HideSelectableFeatureUI()
        return
    end
    
    -- 显示可选词缀UI
    if self.PanelFeatureSelectable then
        self.PanelFeatureSelectable.gameObject:SetActiveEx(true)
    end
    
    -- 显示战斗倍率面板（有可选feature时显示）
    if self.PanelScoreRate then
        self.PanelScoreRate.gameObject:SetActiveEx(true)
    end
    
    if not self.ListSelectableFeature or not self.GridSelectableFeature then
        XLog.Error("[XUiFubenBossSingleModeDetailGridBuff] ListSelectableFeature or GridSelectableFeature is nil")
        return
    end
    self.GridSelectableFeature.gameObject:SetActiveEx(false)
    
    -- 获取ChallengeData以创建Feature对象
    local challengeData = self._Control:GetBossSingleChallengeData()
    if not challengeData then
        XLog.Error("[XUiFubenBossSingleModeDetailGridBuff] challengeData is nil")
        return
    end
    
    local count = 0
    
    -- 遍历可选feature IDs，创建并显示
    for _, selectableFeatureId in ipairs(buffFeatureIds) do
        -- 从ChallengeData中查找对应的feature（可能不存在，需要创建）
        local selectableFeature = challengeData:GetFeatureById(selectableFeatureId)
        if not selectableFeature then
            -- 如果不存在，创建一个新的feature对象
            local stageId = self._Feature:GetStageId()
            local XBossSingleFeature = require("XModule/XFubenBossSingle/XData/XBossSingleFeature")
            selectableFeature = XBossSingleFeature.New(selectableFeatureId, stageId, {})
        end
        
        -- 检查是否为可选feature（type=2）
        if selectableFeature and selectableFeature:IsSelectable() then
            count = count + 1
            local gridSelectable = self._GridSelectableFeatureUiList[count]
            
            if not gridSelectable then
                local grid = XUiHelper.Instantiate(self.GridSelectableFeature, self.ListSelectableFeature)
                gridSelectable = XUiFubenBossSingleModeDetailGridSelectableFeature.New(grid, self)
                gridSelectable.Parent = self  -- 设置Parent为GridBuff
                self._GridSelectableFeatureUiList[count] = gridSelectable
            end
            
            gridSelectable:Open()
            gridSelectable:Refresh(selectableFeature)
            
            -- 从Model恢复选中状态（本次登录期间持久化）
            local buffFeatureId = self._Feature:GetFeatureId()
            local savedSelectedIds = self._Control:GetSelectedSelectableFeatureIds(buffFeatureId) or {}
            local isSelected = false
            for _, savedId in ipairs(savedSelectedIds) do
                if savedId == selectableFeatureId then
                    isSelected = true
                    break
                end
            end
            
            -- 同步到UI层的选中状态记录
            self._SelectedSelectableFeatures[selectableFeatureId] = isSelected or nil
            
            -- 恢复UI选中状态
            gridSelectable:SetSelected(isSelected)
        end
    end
    
    -- 关闭多余的Grid
    for i = count + 1, #self._GridSelectableFeatureUiList do
        self._GridSelectableFeatureUiList[i]:Close()
    end
    
    -- 刷新当前feature的倍率（只刷新自己的）
    self:_RefreshTotalScoreRate()
end

-- v4.2 新增：隐藏可选词缀UI
function XUiFubenBossSingleModeDetailGridBuff:_HideSelectableFeatureUI()
    if self.PanelFeatureSelectable then
        self.PanelFeatureSelectable.gameObject:SetActiveEx(false)
    end
    
    -- 隐藏战斗倍率面板（没有可选feature时隐藏）
    if self.PanelScoreRate then
        self.PanelScoreRate.gameObject:SetActiveEx(false)
    end
end

-- v4.2 新增：可选词缀选中状态改变回调
---@param feature XBossSingleFeature
---@param isSelected boolean
function XUiFubenBossSingleModeDetailGridBuff:OnSelectableFeatureChanged(feature, isSelected)
    if not feature then
        return
    end
    
    local selectableFeatureId = feature:GetFeatureId()
    -- 更新选中状态记录
    self._SelectedSelectableFeatures[selectableFeatureId] = isSelected or nil
    
    -- 同步到Model保存（跟随当前buff）
    if self._Feature then
        local buffFeatureId = self._Feature:GetFeatureId()
        if isSelected then
            self._Control:AddSelectedSelectableFeatureId(buffFeatureId, selectableFeatureId)
        else
            self._Control:RemoveSelectedSelectableFeatureId(buffFeatureId, selectableFeatureId)
        end
    end
    
    -- 实时计算并刷新当前feature的倍率（只刷新自己的）
    self:_RefreshTotalScoreRate()
end

-- v4.2 新增：计算并刷新当前feature的讨伐值倍率（当前feature + 它对应的可选feature）
-- 只在有可选feature时才刷新
function XUiFubenBossSingleModeDetailGridBuff:_RefreshTotalScoreRate()
    if not self._Feature then
        return
    end

    -- 检查是否有可选feature（v4.2 修正：根据featureGroupId和featureId获取BuffGroupId）
    local featureId = self._Feature:GetFeatureId()
    local buffGroupId = XMVCA.XFubenBossSingle:GetBossSingleChallengeBuffGroupIdByFeatureId(self._FeatureGroupId, featureId)
    if not buffGroupId or buffGroupId <= 0 then
        -- 没有可选feature，隐藏面板
        if self.PanelScoreRate then
            self.PanelScoreRate.gameObject:SetActiveEx(false)
        end
        return
    end

    -- 检查BuffGroup是否有Buff（可选feature列表）
    local buffFeatureIds = XMVCA.XFubenBossSingle:GetBossSingleChallengeBuffGroupBuffById(buffGroupId)
    if XTool.IsTableEmpty(buffFeatureIds) then
        -- 没有可选feature，隐藏面板
        if self.PanelScoreRate then
            self.PanelScoreRate.gameObject:SetActiveEx(false)
        end
        return
    end

    -- 有可选feature，显示面板并计算倍率
    if self.PanelScoreRate then
        self.PanelScoreRate.gameObject:SetActiveEx(true)
    end
    
    local totalRate = 0
    
    -- 1. 计算当前feature（type=1）的倍率
    totalRate = totalRate * self._Feature:GetScoreRate()
    
    -- 2. 计算当前feature对应的选中可选feature（type=2）的倍率
    for featureId, isSelected in pairs(self._SelectedSelectableFeatures) do
        if isSelected then
            -- 从配置中获取feature信息
            local featureConfig = XMVCA.XFubenBossSingle:GetFeatureConfigById(featureId)
            if featureConfig then
                local scoreRate = featureConfig.ScoreRate or 1
                totalRate = totalRate + scoreRate
            end
        end
    end
    
    -- 3. 显示当前feature的倍率（如果有UI组件）
    if self.TxtTotalScoreRate then
        self.TxtTotalScoreRate.text = string.format("+%.1f%%", totalRate / 100)
    end
end

-- endregion

return XUiFubenBossSingleModeDetailGridBuff
