local XUiNewFuben = XLuaUiManager.Register(XLuaUi, "UiNewFuben")

function XUiNewFuben:OnAwake()
    self.IsRebackFight = true 
    self.FubenManagerEx = XDataCenter.FubenManagerEx
    ---@type XTableFubenTabConfig[]
    self.MainUiTabConfigs = self.FubenManagerEx.GetMainUiTabConfigs()
    -- 提审服屏蔽主线外的关卡
    if XUiManager.IsHideFunc then
        local result = {}
        for k, v in pairs(self.MainUiTabConfigs) do
            if v.UiParentName == "PanelMainLineRoot" then
                table.insert(result, v)
            end
        end
        self.MainUiTabConfigs = result
    end
    self.ChildPanelInfoDic = {}
    self.TimerId = nil
    self.SelectedIndex = nil
    self.MainUiFirstIndexArgsDic = {}
    self.IsInited = false
    self.RefreshTimeId = XFubenConfigs.GetMainPanelTimeId()
    self:RegisterUiEvents()
end

function XUiNewFuben:OnStart(chapterType, secondIndex, ...)
    if chapterType then -- 根据chapterType检测要打开的子界面，不传默认打开第一个
        local firstTag, secondTagIndex = XDataCenter.FubenManagerEx.GetTagConfigByChapterType(chapterType)
        if firstTag and not self:GetMainUiFirstIndexArgs(firstTag) then
            self.SelectedIndex = firstTag
            if secondTagIndex then
                self:SetMainUiFirstIndexArgs(firstTag, secondIndex or secondTagIndex, ...)
            else
                self:SetMainUiFirstIndexArgs(firstTag, secondIndex, ...)
            end
        end
    end
    
    -- 初始化下方页签按钮
    self:InitBottomTabs()
end

function XUiNewFuben:TimeUpdate()
    local currentPanel = self.ChildPanelInfoDic[self.PanelTabGroup.CurSelectId]
    if currentPanel and currentPanel.InstanceProxy and currentPanel.InstanceProxy.TimeUpdate then
        currentPanel.InstanceProxy:TimeUpdate()
    end
    self:RefreshBg()
end

function XUiNewFuben:OnEnable()
    -- 刷新按钮红点
    local childPanelInfo = nil
    ---@type XUiComponent.XUiButton
    local btnTab = nil
    for i = 1, self.PanelTabGroup.TabBtnList.Count do
        childPanelInfo = self:GetChildPanelInfo(i)
        btnTab = self.PanelTabGroup:GetButtonByIndex(i)
        
        if childPanelInfo and childPanelInfo.Proxy.CheckHasRedPoint and not (btnTab.ButtonState == CS.UiButtonState.Disable) then
            btnTab:ShowReddot(childPanelInfo.Proxy.CheckHasRedPoint(childPanelInfo))
        else
            btnTab:ShowReddot(false)
        end
    end
    -- 刷新活动界面需要用到的背景图，会覆盖其他二级标签的背景图
    self.RImgFestivalBg:SetRawImage(XFubenConfigs.GetMainFestivalBg())
    self:RefreshBg()
    self:InitBg()
    self:OnChildPanelEnable()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
    end
    self.TimerId = XScheduleManager.ScheduleForeverEx(handler(self, self.TimeUpdate), 1000, 1000)
end

function XUiNewFuben:OnChildPanelEnable()
    local currentPanel = self.ChildPanelInfoDic[self.PanelTabGroup.CurSelectId]
    if currentPanel and currentPanel.InstanceProxy and currentPanel.InstanceProxy.OnEnable then
        currentPanel.InstanceProxy:OnEnable()
    end
end

function XUiNewFuben:OnChildPanelDisable()
    local currentPanel = self.ChildPanelInfoDic[self.PanelTabGroup.CurSelectId]
    if currentPanel and currentPanel.InstanceProxy and currentPanel.InstanceProxy.OnDisable then
        currentPanel.InstanceProxy:OnDisable()
    end
end

function XUiNewFuben:OnDisable()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
    end
    self:OnChildPanelDisable()
end

function XUiNewFuben:OnDestroy()
    for _, panel in pairs(self.ChildPanelInfoDic) do
        if panel and panel.InstanceProxy and panel.InstanceProxy.OnDestroy then
            panel.InstanceProxy:OnDestroy()
        end
    end
end

--######################## 私有方法 ########################

function XUiNewFuben:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiNewFuben:InitBottomTabs()
    local buttons = {}
    local firstUnlockIndex = nil
    local isCurSelectIndexUnlock = true
    local unlockCount = 0
    
    XUiHelper.RefreshCustomizedList(self.PanelTabGroup.transform, self.BtnTab, #self.MainUiTabConfigs, function(index, go)
        local button = go:GetComponent("XUiButton")
        local config = self.MainUiTabConfigs[index]
        go.name = "BtnTab"..config.UiParentName
        button:SetNameByGroup(0, config.Name)
        button:SetRawImage(config.IconPath)
        
        local isSecondUnLock = self.FubenManagerEx.CheckHasOpenByFirstTagId(index)
        local isSelfUnlock = not XTool.IsNumberValidEx(config.UnlockCondition) or XConditionManager.CheckCondition(config.UnlockCondition)
        
        local isRealUnlock = isSecondUnLock and isSelfUnlock
        
        button:SetDisable(not isRealUnlock)
        table.insert(buttons, button)

        if isRealUnlock then
            if not firstUnlockIndex then
                firstUnlockIndex = index
            end

            unlockCount = unlockCount + 1
        end

        if isCurSelectIndexUnlock == index then
            isCurSelectIndexUnlock = isRealUnlock
        end
    end)
    self.PanelTabGroup:Init(buttons, function(index) self:OnBtnBottomTabClicked(index) end)
    if XUiManager.IsHideFunc then
        self.SelectedIndex = nil
    else
        -- 如果选择的页签没有解锁，或者未选择特定页签，则使用从左到右顺位第一个已解锁的页签
        if not isCurSelectIndexUnlock or not self.SelectedIndex then
            self.SelectedIndex = firstUnlockIndex
        end 
    end
    
    self.PanelTabGroup:SelectIndex(self.SelectedIndex or 1)

    -- 如果只有一个页签解锁了，那么隐藏底部栏
    if unlockCount <= 1 then
        self.PanelBottom.gameObject:SetActiveEx(false)
    end
end

-- 刷新战斗面板每期活动图
function XUiNewFuben:RefreshBg()
    if XUiManager.IsHideFunc then
        return
    end

    local inTime = XFunctionManager.CheckInTimeByTimeId(self.RefreshTimeId)
    if self.BgNone then -- 防打包
        self.BgNone.gameObject:SetActiveEx(not inTime)
    end
    if self.BgSpine then
        self.BgSpine.gameObject:SetActiveEx(inTime and not XFubenConfigs.GetIsMainHaveVideoBg())
    end
    if self.BgVideo then
        self.BgVideo.gameObject:SetActiveEx(inTime and XFubenConfigs.GetIsMainHaveVideoBg())
    end
end

function XUiNewFuben:InitBg()
    if XUiManager.IsHideFunc then
        return
    end

    -- v2.0 支持视频背景
    if XFubenConfigs.GetIsMainHaveVideoBg() and self.VideoPlayer then
        self.VideoPlayer:SetVideoFromRelateUrl(XFubenConfigs.GetMainVideoBgUrl())
        self.VideoPlayer:Prepare()
    end
    -- v1.31 支持3D场景
    if XFubenConfigs.GetIsMainHave3DBg() then
        self:LoadUiScene(XFubenConfigs.GetMain3DBgPrefab(), XFubenConfigs.GetMain3DCameraPrefab(), nil, false)
    end
end

-- 根据二级标签切换底板背景图
function XUiNewFuben:ChangeBgBySecondTag(bgPath)
    if not bgPath then
        self.RImgMainStoryBg.gameObject:SetActiveEx(false)
        return
    end
    self.RImgMainStoryBg:SetRawImage(bgPath)
    self.RImgMainStoryBg.gameObject:SetActiveEx(true)
end

-- 刷新背景图
function XUiNewFuben:ShowOrHideBgByConfig(config)
    self.Bg.gameObject:SetActiveEx(config.UiParentName == "PanelMain")
    self.RImgMainStoryBg.gameObject:SetActiveEx(config.UiParentName ~= "PanelMain")
    self.BgNewCommonBai.gameObject:SetActiveEx(config.UiParentName ~= "PanelMain")
end

function XUiNewFuben:OnBtnBottomTabClicked(index)
    if not self.IsRebackFight and self.SelectedIndex == index then -- 从战斗返回时会强行调用这个，如果这里return调的话就会不播放动画导致一片空白
        return 
    end
    self.IsRebackFight = false
    
    local config = self.MainUiTabConfigs[index]

    if not self.FubenManagerEx.CheckHasOpenByFirstTagId(index) then -- 如果没开放
        XUiManager.TipError(config.ConditionDesc)
        return
    end

    if XTool.IsNumberValidEx(config.UnlockCondition) then
        local isPass, desc = XConditionManager.CheckCondition(config.UnlockCondition)

        if not isPass then
            XUiManager.TipError(desc)
            return
        end
    end

    local childPanelData = self:GetChildPanelInfo(index)
    self:ShowOrHideBgByConfig(childPanelData)
    if childPanelData == nil then return end
    -- 隐藏其他的子面板
    for key, data in pairs(self.ChildPanelInfoDic) do
        data.UiParent.gameObject:SetActiveEx(key == index)
        if key ~= index and data.InstanceProxy and data.InstanceProxy.OnDisable then
            data.InstanceProxy:OnDisable()
        end
    end
    -- 加载子面板实体
    local instanceGo = childPanelData.InstanceGo
    if instanceGo == nil and not string.IsNilOrEmpty(childPanelData.AssetPath) then
        instanceGo = childPanelData.UiParent:LoadPrefab(childPanelData.AssetPath)
        childPanelData.InstanceGo = instanceGo
    end
    -- 加载子面板代理
    local instanceProxy = childPanelData.InstanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.Proxy.New(instanceGo, self, childPanelData)
        childPanelData.InstanceProxy = instanceProxy
        if CheckClassSuper(instanceProxy, XSignalData) then
            instanceProxy:ConnectSignal("SetMainUiFirstIndexArgs", self, self.SetMainUiFirstIndexArgs)
        end
    end
    instanceProxy:SetData(index, self:GetMainUiFirstIndexArgs(index))
    if self.IsInited then
        self:OnChildPanelEnable()
    end
    self.IsInited = true
    self.SelectedIndex = index
    XDataCenter.GuideManager.CheckGuideOpen()
end

function XUiNewFuben:GetChildPanelInfo(index)
    local result = self.ChildPanelInfoDic[index]
    if result == nil then 
        local config = XTool.Clone(self.MainUiTabConfigs[index])
        if config == nil then return nil end
        if config.UiParentName == nil then
            config.UiParent = self.PanelContent
        else
            config.UiParent = self[config.UiParentName]
        end
        config.Proxy = require(config.ProxyPath)
        self.ChildPanelInfoDic[index] = config
        result = config
    end
    return result
end

function XUiNewFuben:SetOperationActive(value)
    self.PanelBottom.gameObject:SetActiveEx(value)
    self.BtnBack.gameObject:SetActiveEx(value)
    self.BtnMainUi.gameObject:SetActiveEx(value)
end

function XUiNewFuben:SetMainUiFirstIndexArgs(firstIndex, ...)
    self.MainUiFirstIndexArgsDic[firstIndex] = { ... }
end

function XUiNewFuben:GetMainUiFirstIndexArgs(firstIndex)
    local result = self.MainUiFirstIndexArgsDic[firstIndex]
    if result then
        return table.unpack(result)
    end
end

-- 记录作战前底部页签选择的Id
function XUiNewFuben:OnReleaseInst()
    return { 
        SelectedIndex = self.SelectedIndex,
        MainUiFirstIndexArgsDic = self.MainUiFirstIndexArgsDic
    }
end

function XUiNewFuben:OnResume(data)
    if XLuaUiManager.IsUiLoad("UiMain")  then  -- 如果是从uimain打开  
        return
    end

    data = data or {}
    self.IsRebackFight = true    -- 是否从战斗结束后打开的
    self.SelectedIndex = data.SelectedIndex or 1
    self.MainUiFirstIndexArgsDic = data.MainUiFirstIndexArgsDic or {}
end

return XUiNewFuben