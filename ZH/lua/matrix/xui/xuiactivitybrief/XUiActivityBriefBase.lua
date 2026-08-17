local XActivityBrieIsOpen = require("XUi/XUiActivityBrief/XActivityBrieIsOpen")
--[[    活动界面的功能相关和各版本的界面临时代码写在这里
    XUiActivityBriefRefreshButton.lua：活动按钮相关的代码（按钮的点击、刷新，红点显示、跳转）
    XActivityBrieIsOpen.lua：管理各按钮的开放条件与显示日期的代码
    XActivityBrieButton.lua：按钮的交互逻辑代码
]]
---@class XUiActivityBriefBase : XLuaUi
local XUiActivityBriefBase = XLuaUiManager.Register(XLuaUi, "UiActivityBriefBase")
local OpMovieId = CS.XGame.ClientConfig:GetInt("ActivityBriefMovie")
local XUiActivityBriefRefreshButton = require("XUi/XUiActivityBrief/XUiActivityBriefRefreshButton")

local Vector2 = CS.UnityEngine.Vector2

function XUiActivityBriefBase:OnAwake()
    self:AutoAddListener()
end

function XUiActivityBriefBase:OnStart(type)
    self.IsFromMain = true
    self.PanelType = type or XActivityBriefConfigs.PanelType.Main
    ---@type Spine.Unity.SkeletonAnimation[]|Spine.Unity.SkeletonGraphic[]
    self.LoadSpineObjListDir = {}
    ---@type Spine.Unity.SkeletonAnimation[]|Spine.Unity.SkeletonGraphic[]
    self.UiSpineObjListDir = table.empty
    ---@type XUiActivityBriefRefreshButton
    self.UiActivityBriefRefreshButton = XUiActivityBriefRefreshButton.New(self, self.PanelType)
    self.BgType = XActivityBriefConfigs.GetActivityBgType(self.PanelType)

    -- 加载界面
    self:Refresh()

    -- 播放入场动画
    if self.PanelType == XActivityBriefConfigs.PanelType.Main then
        local firstOpen = XDataCenter.ActivityBriefManager.IsShowEnterAni(self.PanelType)
        if firstOpen then
            if OpMovieId ~= 0 then
                self:PlayMovie(function()
                    self:PlaySpecialEnterAnim(function() self:OnEnterAnimFinished() end)
                end)
            else
                self:PlaySpecialEnterAnim(function() self:OnEnterAnimFinished() end)
            end
        else
            self:PlayEnterAnim(function() self:OnEnterAnimFinished() end)
        end
    end
end

---入场动画播完后的统一收尾：串接标题过渡 → 刷新按钮奖励动画 → 按钮解锁动画播完再弹生命树章节弹窗(避免打断)
function XUiActivityBriefBase:OnEnterAnimFinished()
    -- 解除对 BGM 差分动画的屏蔽；入场期间 BGM 光标若已跨到差分动画则切缓存对齐。非 Spine 背景 _SpineEntering 恒为假，此块跳过
    if self._SpineEntering then
        self._SpineEntering = false
        if not string.IsNilOrEmpty(self.CurBgmDiffAnimName) then
            self:_PlayBgmDiffAnim(self.CurBgmDiffAnimName)
        end
    end
    self:PlayTitleExChangeIfNeeded()
    self.UiActivityBriefRefreshButton:RefreshButtonsWithRewardAnimation()
    self.UiActivityBriefRefreshButton:CheckBtnUnlockAnim(function()
        XMVCA.XLifeTree:CheckOpenUiLifeTreeChapterUnlockCurVersion()
    end)
end

function XUiActivityBriefBase:OnEnable()
    local firstOpen = XDataCenter.ActivityBriefManager.IsShowEnterAni(self.PanelType)
    if firstOpen then
        XDataCenter.ActivityBriefManager.SetDontShowEnterAni(self.PanelType)
    else
        if not self.IsFromMain and self.PanelType == XActivityBriefConfigs.PanelType.Main then
            -- 避免跳转玩法界面后有进入剧情Ui等会造成程序Ui容器清空的情况返回活动面板主界面后动画播放不正确
            -- AnimEnable2不在播放状态且播放时长小于总时长
            if self.AnimEnable2.state ~= CS.Playable.PlayState.Playing and self.AnimEnable2.time <= self.AnimEnable2.duration then
                self.AnimEnable2:Play()
                self.AnimEnable2.time = self.AnimEnable2.duration
            end
            self:PlayLoopAnim()
        end
    end
    self.IsFromMain = false
    self.UiActivityBriefRefreshButton:Refresh()
    self.UiActivityBriefRefreshButton:RefreshButtonsWithRewardAnimation()

    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
    end
    self._TimerId = XScheduleManager.ScheduleForeverEx(handler(self, self.TimeUpdate), 1000)
end

function XUiActivityBriefBase:OnDisable()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
    end
    self:StopVideoSound()
    self.UiActivityBriefRefreshButton:OnDisable()
end

function XUiActivityBriefBase:OnDestroy()
    self:RemoveBgmSpineSync()
end


--region 监听事件

function XUiActivityBriefBase:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnBackSecond, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnMainUiSecond, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnVideo, self.OnClickBtnVideo)
    self:RegisterClickEvent(self.BtnNotice, self.OnClickBtnDetail)
    self:RegisterClickEvent(self.BtnNoticeSecond, self.OnClickBtnDetail)
    if self.BtnShield then
        self:RegisterClickEvent(self.BtnShield, self.OnClickSkip)
    end
end

function XUiActivityBriefBase:OnBtnBackClick()
    self:Close()
end

function XUiActivityBriefBase:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiActivityBriefBase:OnClickBtnDetail()
    -- 离开面板收不到 Marker，先停掉差分音效但保留缓存，返回时恢复
    self:StopBgmDiffSound(true)
    XLuaUiManager.Open("UiWelfare")
end

function XUiActivityBriefBase:OnClickBtnVideo()
    self:PlayMovie(function()
        self:PlayAnimationWithMask("AnimEnable2")
    end)
end

--endregion


--region 通用函数

function XUiActivityBriefBase:TimeUpdate()
    self:RefreshActivityTag()
end

function XUiActivityBriefBase:PlayMovie(cbFunc)
    --此处不用self:SetActive, 由于self:SetActive会把uiModel的也隐藏导致无法播放下面的动画
    self.GameObject:SetActiveEx(false)

    XLuaVideoManager.PlayUiVideo(OpMovieId, function()
        self.GameObject:SetActiveEx(true)
        if cbFunc then
            cbFunc()
        end
    end)
end

function XUiActivityBriefBase:Refresh()
    self:RefreshDefaultSkipBtn()
    self:RefreshTitles()
    if self.BgType == XActivityBriefConfigs.BgType.Spine then
        self:RefreshSpinePanel()
    elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
        self:RefreshScene()
    elseif self.BgType == XActivityBriefConfigs.BgType.Video then
        self:RefreshVideoPanel()
    end
end

---刷新两组标题(副标题 SubTitle、特效标题 FxTitle)：按 TitleDiffCondition 互斥显隐 state1/state2
function XUiActivityBriefBase:RefreshTitles()
    local conditionId = XActivityBriefConfigs.GetTitleDiffCondition(self.PanelType)
    local isPassed = XTool.IsNumberValid(conditionId) and XConditionManager.CheckCondition(conditionId)
    -- 切到 state2 且本期未播过时才需过渡(每期一次)，播放延后到入场后串接(见 PlayTitleExChangeIfNeeded)。
    -- 仅 Main 播入场动画并走 OnEnterAnimFinished 消费此标记；副面板不播入场，若也置标记会把标题锁死在 state1，故只对 Main 置
    self._NeedPlayTitleEx = self.PanelType == XActivityBriefConfigs.PanelType.Main
        and isPassed and not XDataCenter.ActivityBriefManager.GetTitleExChangePlayed(self.PanelType)
    if self._NeedPlayTitleEx then
        -- 待播过渡：先保持起始态(显示 state1)，避免入场动画期间两组标题同时显示
        self:_SetDiffTitleActive(self.SubTitle1, self.SubTitle2, false)
        self:_SetDiffTitleActive(self.FxTitle1, self.FxTitle2, false)
    else
        self:_SetDiffTitleActive(self.SubTitle1, self.SubTitle2, isPassed)
        self:_SetDiffTitleActive(self.FxTitle1, self.FxTitle2, isPassed)
    end
end

---入场动画播完后调用：串接播过渡 AnimTitleExChange(每期一次)。
---与入场动画共用同一 UiProxy director，排在其后播避免被顶掉。
function XUiActivityBriefBase:PlayTitleExChangeIfNeeded()
    if not self._NeedPlayTitleEx then
        return
    end
    self._NeedPlayTitleEx = false
    -- 过渡需 state1、state2 同时显示才能演出切换，播完回调再恢复互斥显隐(显示 state2)
    self:_SetDiffTitleActive(self.SubTitle1, self.SubTitle2, nil)
    self:_SetDiffTitleActive(self.FxTitle1, self.FxTitle2, nil)
    self:PlayAnimation("AnimTitleExChange", function()
        self:_SetDiffTitleActive(self.SubTitle1, self.SubTitle2, true)
        self:_SetDiffTitleActive(self.FxTitle1, self.FxTitle2, true)
        -- 标记「已播」放在完成回调内：若 prefab 缺 AnimTitleExChange 致 cb 不触发，则不标记，下次进入重试，避免标题永久卡在双显
        XDataCenter.ActivityBriefManager.SetTitleExChangePlayed(self.PanelType)
    end)
end

---设置两个标题控件的显隐：false 显示 obj1(state1)；true 显示 obj2(state2)；nil 两者都显示(供过渡动画使用)
function XUiActivityBriefBase:_SetDiffTitleActive(obj1, obj2, isPassed)
    if XTool.UObjIsNil(obj1) and XTool.UObjIsNil(obj2) then
        return
    end
    if not XTool.UObjIsNil(obj1) then
        obj1.gameObject:SetActiveEx(isPassed == nil or not isPassed)
    end
    if not XTool.UObjIsNil(obj2) then
        obj2.gameObject:SetActiveEx(isPassed == nil or isPassed)
    end
end

function XUiActivityBriefBase:RefreshDefaultSkipBtn()
    if self.BtnShield then
        if XDataCenter.ActivityBriefManager.GetIsSkipAnim(self.PanelType) then
            self.BtnShield.ButtonState = CS.UiButtonState.Select
        else
            self.BtnShield.ButtonState = CS.UiButtonState.Normal
        end
    end
end

function XUiActivityBriefBase:OnClickSkip()
    local isSkip = XDataCenter.ActivityBriefManager.GetIsSkipAnim(self.PanelType)
    XDataCenter.ActivityBriefManager.SetIsSkipAnim(self.PanelType, not isSkip)
    self:RefreshDefaultSkipBtn()
end

---特殊入场动画播放(特殊入场 + 循环动画)
function XUiActivityBriefBase:PlaySpecialEnterAnim(cb)
    self:PlayAnimationWithMask("AnimEnable2", cb)
    if self.BgType == XActivityBriefConfigs.BgType.Spine then
        self:PlaySpineSpecialEnterAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.TimeLine then
        self:PlayTimelineSpecialEnterAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
        self:PlaySceneSpecialEnterAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Video then
        self:PlayVideoSpecialEnterAnim()
    end
    XDataCenter.ActivityBriefManager.SetDontShowEnterAni(self.PanelType)
end

---入场动画播放(普通入场 + 循环动画)
function XUiActivityBriefBase:PlayEnterAnim(cb)
    local isPlayAnim = true
    -- 跳过不播放
    if XDataCenter.ActivityBriefManager.GetIsSkipAnim(self.PanelType) then
        isPlayAnim = false
    else
        -- 第一次总是播放
        if XDataCenter.ActivityBriefManager.CheckIsFirstReadedAnim(self.PanelType) then
            isPlayAnim = true
        end
    end

    if isPlayAnim then
        if self.BgType == XActivityBriefConfigs.BgType.Spine then
            self:PlayAnimationWithMask("AnimEnable2", cb)
            self:PlaySpineEnterAnim()
        elseif self.BgType == XActivityBriefConfigs.BgType.TimeLine then
            self:PlayAnimationWithMask("AnimEnable2", cb)
            self:PlayTimelineEnterAnim()
        elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
            self:PlayAnimationWithMask("AnimEnable2", cb)
            self:PlaySceneEnterAnim()
        elseif self.BgType == XActivityBriefConfigs.BgType.Video then
            -- 注意：此分支未透传 cb，入场动画播完不会触发 cb（含按钮解锁动画、生命树弹窗检测）。
            -- 属历史遗留，Video 类型主面板上次使用为 2022-10~11，此后一直是 Spine，故暂不修复。
            -- 若未来主面板重新配成 Video(BgType=3)，需给 PlayVideoEnterAnim 补 cb 透传。
            self:PlayVideoEnterAnim()
        end
    else
        self:PlayLoopAnim(cb)
    end
    XDataCenter.ActivityBriefManager.SetDontShowEnterAni(self.PanelType)
end

function XUiActivityBriefBase:PlayLoopAnim(cb)
    self:PlayAnimationWithMask("AnimEnable1", cb)
    if self.BgType == XActivityBriefConfigs.BgType.Spine then
        self:PlaySpineLoopAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.TimeLine then
        self:PlayTimelineLoopAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
        self:PlaySceneLoopAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Video then
        self:PlayVideoLoopAnim()
    end
end

---特殊动画需求,可能插入与各处，由需求而定
function XUiActivityBriefBase:PlaySpecialAnim()
    --v2.3 有个按钮的图片优化需要由动效动画
    --self:PlayAnimation("UiLoop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end

--endregion


--region Spine背景相关
function XUiActivityBriefBase:RefreshSpinePanel()
    self:SetVideoPanelActive(false)
    if self.PanelType == XActivityBriefConfigs.PanelType.Main then
        self.PanelActivity1.gameObject:SetActiveEx(true)
        self.PanelActivity2.gameObject:SetActiveEx(false)
        self.PanelActivityInfo1.gameObject:SetActiveEx(true)
        self.PanelActivityInfo2.gameObject:SetActiveEx(false)
    elseif self.PanelType == XActivityBriefConfigs.PanelType.Second then
        self.PanelActivity1.gameObject:SetActiveEx(false)
        self.PanelActivity2.gameObject:SetActiveEx(true)
        self.PanelActivityInfo1.gameObject:SetActiveEx(false)
        self.PanelActivityInfo2.gameObject:SetActiveEx(true)
    end
    self:SpineAutoFit()
end

function XUiActivityBriefBase:InitSpineObj()
    if self.BgType ~= XActivityBriefConfigs.BgType.Spine then
        return
    end
    -- 重赋可写真表(init 为只读 table.empty)，兼作重复调用时清空防累积
    self.UiSpineObjListDir = {}
    for i = 1, 3 do
        local spinePanelName = "PanelSpine"..i
        if self[spinePanelName] and not XTool.UObjIsNil(self[spinePanelName]) then
            local SkeletonAnimationCSArray = self[spinePanelName].transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
            local SkeletonGraphicCSArray = self[spinePanelName].transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
            if SkeletonAnimationCSArray.Length ~= 0 or SkeletonGraphicCSArray.Length ~= 0 then
                local spineObjList = {}
                for j = 0, SkeletonAnimationCSArray.Length - 1, 1 do
                    spineObjList[#spineObjList + 1] = SkeletonAnimationCSArray[j]
                end
                for j = 0, SkeletonGraphicCSArray.Length - 1, 1 do
                    spineObjList[#spineObjList + 1] = SkeletonGraphicCSArray[j]
                end
                if not XTool.IsTableEmpty(spineObjList) then
                    self.UiSpineObjListDir[#self.UiSpineObjListDir + 1] = spineObjList
                end
            end
        end
    end
end

---设置Spine背景显隐
function XUiActivityBriefBase:SetSpinePanelActive(active)
    self.PanelActivity1.gameObject:SetActiveEx(active)
    self.PanelActivity2.gameObject:SetActiveEx(active)
end

---返回加载的动态骨骼组(因为可能存在加载多个SkeletonAnimation集合成的一个预制体，所以返回的是table)
function XUiActivityBriefBase:LoadSpine(transform, index)
    -- 根据主副面板加载动画
    local path = XActivityBriefConfigs.GetSpinePathByType(self.PanelType, index)
    if not string.IsNilOrEmpty(path) then
        transform.gameObject:SetActiveEx(true)
        local spine = transform:LoadSpinePrefab(path)
        local obj = spine:GetComponent("SkeletonAnimation")
        if not obj or XTool.UObjIsNil(obj) then
            obj = spine:GetComponent("SkeletonGraphic")
        end
        local spines = {}
        -- 收集所有的spine控件
        if not XTool.UObjIsNil(obj) then
            table.insert(spines, obj)
        else
            local objList = spine.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
            if objList.Length == 0 then
                objList = spine.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
            end
            for i = 0, objList.Length - 1, 1 do
                table.insert(spines, objList[i])
            end
        end
        return spines
    end
end

---spine动画底边对齐适配
function XUiActivityBriefBase:SpineAutoFit()
    local transform = self.ActivitySpineLogin
    if XTool.UObjIsNil(transform) then return end
    local rate = transform.localScale.y / 60
    transform.anchoredPosition = Vector2(transform.anchoredPosition.x, transform.anchoredPosition.y * rate)
end

---spine对象播放动画
function XUiActivityBriefBase:_PlaySpineObjAnimation(spineObject, fromAnim, toAnim)
    if XTool.UObjIsNil(spineObject) then return end

    -- 判断Spine是否存在动画轨道
    local isHaveFrom = fromAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(fromAnim)
    local isHaveTo = toAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(toAnim)
    if isHaveFrom then
        --Delegate += 操作Lua写法
        local cb
        cb = function(track)
            if track.Animation.Name == fromAnim and isHaveTo then
                spineObject.AnimationState:SetAnimation(0, toAnim, true)
                spineObject.AnimationState:Complete('-', cb)
            end
        end
        spineObject.AnimationState:Complete('+', cb)
        -- 没有toAnim则fromAnim循环
        spineObject.AnimationState:SetAnimation(0, fromAnim, not isHaveTo)
    elseif isHaveTo then
        spineObject.AnimationState:SetAnimation(0, toAnim, true)
    end
end

---Spine对象组播放动画
function XUiActivityBriefBase:_PlaySpineAnimation(fromAnim, toAnim)
    if self.PanelType ~= XActivityBriefConfigs.PanelType.Main then
        return
    end
    -- 全屏 UI 覆盖时 XLoadSpinePrefab 会销毁并重建 spine 子对象，旧引用会失效，故每次播放前重采集
    self:InitSpineObj()
    -- 根据配置遍历播放
    for index, _ in pairs(XActivityBriefConfigs.GetSpinePathList(self.PanelType)) do
        local spineObjName = "PanelSpine"..(index + #self.UiSpineObjListDir)
        if not XTool.UObjIsNil(self[spineObjName]) then
            self.LoadSpineObjListDir[index] = self:LoadSpine(self[spineObjName], index)
            for _, spineObj in pairs(self.LoadSpineObjListDir[index]) do
                if toAnim then
                    self:_PlaySpineObjAnimation(spineObj, fromAnim, toAnim)
                else
                    self:_PlaySpineObjAnimation(spineObj, fromAnim)
                end
            end
        end
    end
    for _, uiSpineObjList in pairs(self.UiSpineObjListDir) do
        for _, uiSpineObj in ipairs(uiSpineObjList) do
            if toAnim then
                self:_PlaySpineObjAnimation(uiSpineObj, fromAnim, toAnim)
            else
                self:_PlaySpineObjAnimation(uiSpineObj, fromAnim)
            end
        end
    end
    -- 背景 spine 已加载，接入 BGM 标签回调驱动差分动画
    self:InitBgmSpineSync()
end

---Spine特殊入场动画
function XUiActivityBriefBase:PlaySpineSpecialEnterAnim()
    -- 标记入场中：屏蔽 BGM 差分动画覆盖，避免 enter 被开场 Marker 打断(见 _PlayBgmDiffAnim)
    self._SpineEntering = true
    local enterName = XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType)
    local loopName = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:_PlaySpineAnimation(enterName, loopName)
end

---Spine入场动画
function XUiActivityBriefBase:PlaySpineEnterAnim()
    -- 标记入场中：屏蔽 BGM 差分动画覆盖，避免 enter 被开场 Marker 打断(见 _PlayBgmDiffAnim)
    self._SpineEntering = true
    local enterName = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    local loopName = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:_PlaySpineAnimation(enterName, loopName)
end

---Spine循环动画
function XUiActivityBriefBase:PlaySpineLoopAnim()
    -- 隐藏期间越过的 Marker 事件会积压到返回时才回调，返回优先恢复上次差分动画，避免退回默认 Loop；
    -- 若确有积压事件，其回调会覆盖此处缓存，保证最终状态与 BGM 光标一致
    local loopName = self.CurBgmDiffAnimName
    if string.IsNilOrEmpty(loopName) then
        loopName = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    end
    self:_PlaySpineAnimation(loopName)
    -- 差分音效同理据缓存恢复，无缓存则维持静音
    if XTool.IsNumberValid(self.CacheBgmDiffSoundCueId) then
        self:_PlayBgmDiffSound(self.CacheBgmDiffSoundCueId)
    end
end

--endregion


--region BGM标签驱动Spine差分

---获取面板上的 XAudioCueEventListener(prefab 已挂好并配置好 CueIds)并注册 Sequence 回调，只注册一次
function XUiActivityBriefBase:InitBgmSpineSync()
    if self.PanelType ~= XActivityBriefConfigs.PanelType.Main then
        return
    end
    if self.BgmSpineListener then
        return
    end
    local listener = self.GameObject:GetComponentInChildren(typeof(CS.XAudioCueEventListener), true)
    if XTool.UObjIsNil(listener) then
        return
    end
    self.BgmSpineListener = listener
    self.BgmSpineCb = function(info, audioInfo)
        self:OnBgmSequenceEvent(info, audioInfo)
    end
    listener:AddSequenceListener(self.BgmSpineCb)
end

---BGM 播放光标运行到 Marker 时触发：按标签切换背景 spine 差分动画与差分音效
function XUiActivityBriefBase:OnBgmSequenceEvent(info, _)
    local tag = info and info.tag
    -- tag 命中配置 SpineDiffTag 则播对齐的 SpineDiffAnimName 差分动画；
    -- 未命中(含 tag 为空/未配置)回落到默认循环动画 LoopAnimName
    local animName = XActivityBriefConfigs.GetSpineDiffAnimNameByTag(self.PanelType, tag)
    if string.IsNilOrEmpty(animName) then
        animName = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    end
    if not string.IsNilOrEmpty(animName) then
        self:_PlayBgmDiffAnim(animName)
    end

    -- 音效差分复用同一套 tag：命中且配置了有效 cueId 则切换；未命中则停掉当前音效(音效无默认值，不回落)
    local cueId = XActivityBriefConfigs.GetSpineDiffSoundCueIdByTag(self.PanelType, tag)
    if XTool.IsNumberValid(cueId) then
        self:_PlayBgmDiffSound(cueId)
    else
        self:StopBgmDiffSound()
    end
end

---对已加载的所有背景 spine 切换到差分动画并循环(_PlaySpineObjAnimation 内部会判断该 spine 是否存在此动画)
function XUiActivityBriefBase:_PlayBgmDiffAnim(animName)
    self.CurBgmDiffAnimName = animName
    -- 入场中：只记差分态缓存，不覆盖轨道 0，避免打断 enter；入场完成后由 OnEnterAnimFinished 按缓存对齐
    if self._SpineEntering then
        return
    end
    for _, spineList in pairs(self.LoadSpineObjListDir) do
        for _, spineObj in pairs(spineList) do
            self:_PlaySpineObjAnimation(spineObj, animName)
        end
    end
    for _, spineList in pairs(self.UiSpineObjListDir) do
        for _, spineObj in ipairs(spineList) do
            self:_PlaySpineObjAnimation(spineObj, animName)
        end
    end
end

---切换差分音效：同一时刻只保留一个差分音效，切新音效前先停掉上一个(相同 cueId 不重复触发)
function XUiActivityBriefBase:_PlayBgmDiffSound(cueId)
    -- 缓存差分态，供离开面板返回时恢复
    self.CacheBgmDiffSoundCueId = cueId
    if self.CurBgmDiffSoundCueId == cueId then
        return
    end
    if XTool.IsNumberValid(self.CurBgmDiffSoundCueId) then
        XLuaAudioManager.StopAudioByCueId(self.CurBgmDiffSoundCueId)
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    self.CurBgmDiffSoundCueId = cueId
end

---停掉当前差分音效。keepCache=true 保留缓存(离开面板返回后恢复)，否则一并清空(未命中/销毁)
function XUiActivityBriefBase:StopBgmDiffSound(keepCache)
    if XTool.IsNumberValid(self.CurBgmDiffSoundCueId) then
        XLuaAudioManager.StopAudioByCueId(self.CurBgmDiffSoundCueId)
        self.CurBgmDiffSoundCueId = nil
    end
    if not keepCache then
        self.CacheBgmDiffSoundCueId = nil
    end
end

---解绑 Sequence 回调，避免面板销毁后回调仍持有 self
function XUiActivityBriefBase:RemoveBgmSpineSync()
    if self.BgmSpineListener and self.BgmSpineCb and not XTool.UObjIsNil(self.BgmSpineListener) then
        self.BgmSpineListener:RemoveSequenceListener(self.BgmSpineCb)
    end
    self.BgmSpineListener = nil
    self.BgmSpineCb = nil
    -- 停掉正在播放的差分音效，避免面板销毁后音效残留
    self:StopBgmDiffSound()
end

--endregion


--region TimeLine背景相关 - (动画说之后可以用TimeLine控制Spine，因此预留此块功能)

function XUiActivityBriefBase:RefreshTimelineBg()
    self:SetSpinePanelActive(false)
    self:SetVideoPanelActive(false)

    self.PanelActivityInfo1.gameObject:SetActiveEx(self.PanelType == XActivityBriefConfigs.PanelType.Main)
    self.PanelActivityInfo2.gameObject:SetActiveEx(not (self.PanelType == XActivityBriefConfigs.PanelType.Main))
end

---播放TimeLine背景入场动画
function XUiActivityBriefBase:PlayTimelineSpecialEnterAnim()
    local specialEnterAnim = XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType)
    local loopAnim = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:PlayAnimationWithMask(specialEnterAnim, function ()
        self:PlayAnimation(loopAnim)
    end)
end

---播放TimeLine背景入场动画
function XUiActivityBriefBase:PlayTimelineEnterAnim()
    local enterAnim = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    local loopAnim = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    if string.IsNilOrEmpty(enterAnim) then
        self:PlayAnimation(loopAnim)
    else
        self:PlayAnimationWithMask(enterAnim, function ()
            self:PlayAnimation(loopAnim)
        end)
    end
end

function XUiActivityBriefBase:PlayTimelineLoopAnim()
    local loopAnim = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:PlayAnimation(loopAnim)
end

--endregion


--region Scene背景相关

function XUiActivityBriefBase:RefreshScene()
    self:SetSpinePanelActive(false)
    self:SetVideoPanelActive(false)
    -- 加载3D场景
    self:LoadUiScene(XDataCenter.ActivityBriefManager.GetActivityMain3DBg(self.PanelType), XActivityBriefConfigs.GetMain3DBgModelPath(self.PanelType), nil, false)

    --self:SetGameObject()

    self.PanelActivityInfo1.gameObject:SetActiveEx(self.PanelType == XActivityBriefConfigs.PanelType.Main)
    self.PanelActivityInfo2.gameObject:SetActiveEx(not (self.PanelType == XActivityBriefConfigs.PanelType.Main))
end

---播放3D场景预设上的Timeline
function XUiActivityBriefBase:ScenePlayTimelineAnim(animName, cbFunc)
    local root = self.UiModelGo.transform
    local transform = root:FindTransform(animName)

    if transform then
        transform:PlayTimelineAnimation(cbFunc)
    end
end

---播放3D场景入场动画
function XUiActivityBriefBase:PlaySceneSpecialEnterAnim()
    self:ScenePlayTimelineAnim(
        XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType),
        function() self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType)) end)
end

---播放3D场景入场动画
function XUiActivityBriefBase:PlaySceneEnterAnim()
    local enterAnim = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    if string.IsNilOrEmpty(enterAnim) then
        self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
    else
        self:ScenePlayTimelineAnim(
            XActivityBriefConfigs.GetEnterAnimName(self.PanelType),
            function() self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType)) end)
    end
end

---播放3D场景入场动画
function XUiActivityBriefBase:PlaySceneLoopAnim()
    self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
end

--endregion


--region 视频背景相关

function XUiActivityBriefBase:RefreshVideoPanel()
    self:SetSpinePanelActive(false)
    self:SetVideoPanelActive(true)
end

function XUiActivityBriefBase:SetVideoPanelActive(active)
    if self.VideoPlayerEnter then
        self.VideoPlayerEnter.gameObject:SetActive(active)
    end
    if self.VideoPlayerLoop then
        self.VideoPlayerLoop.gameObject:SetActive(active)
    end
end

function XUiActivityBriefBase:PlayVideo(isLoop, videoUrl, cbFunc)
    self.VideoPlayerEnter.gameObject:SetActive(not isLoop)
    self:PlayVideoSound(isLoop)
    if not isLoop then
        self.VideoPlayerEnter:SetVideoFromRelateUrl(videoUrl)
        self.VideoPlayerEnter:Prepare()

        -- 加载Loop视频动画防止动画衔接时存在一帧黑屏
        self.VideoPlayerLoop:SetVideoFromRelateUrl(XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
        self.VideoPlayerLoop:Prepare()
        self.VideoPlayerLoop:Pause()

        if cbFunc then
            local cb
            cb = function ()
                cbFunc()
                self.VideoPlayerEnter.ActionEnded = nil
                self.VideoPlayerEnter.gameObject:SetActive(false)
            end
            self.VideoPlayerEnter.ActionEnded = cb
        end
    else
        if self.VideoPlayerLoop.VideoPlayerInst.player:IsPaused() then
            self.VideoPlayerLoop:Resume()
        elseif self.VideoPlayerLoop:IsPlaying() then    -- 跳转玩法后返回动画重播
            self.VideoPlayerLoop:Stop()
            self.VideoPlayerLoop:SetVideoFromRelateUrl(videoUrl)
            self.VideoPlayerLoop:Prepare()
            XScheduleManager.ScheduleOnce(function ()
                self.VideoPlayerLoop:Play()
            end, 0)
        else    -- 既没有特殊入场也没有入场
            self.VideoPlayerLoop:SetVideoFromRelateUrl(videoUrl)
            self.VideoPlayerLoop:Prepare()
        end
    end
end

---播放视频音效
function XUiActivityBriefBase:PlayVideoSound(isLoop)
    local enterCueId = XActivityBriefConfigs.GetVideoEnterSoundCueId(self.PanelType)
    local loopCurId = XActivityBriefConfigs.GetVideoLoopSoundCueId(self.PanelType)
    if isLoop then
        if XTool.IsNumberValid(loopCurId) then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, loopCurId)
        end
    else
        if XTool.IsNumberValid(enterCueId) then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, enterCueId)
        end
    end
end

function XUiActivityBriefBase:StopVideoSound()
    local enterCueId = XActivityBriefConfigs.GetVideoEnterSoundCueId(self.PanelType)
    local loopCurId = XActivityBriefConfigs.GetVideoLoopSoundCueId(self.PanelType)
    if XTool.IsNumberValid(loopCurId) then XLuaAudioManager.StopAudioByCueId(loopCurId) end
    if XTool.IsNumberValid(enterCueId) then XLuaAudioManager.StopAudioByCueId(enterCueId) end
end

---播放视频入场动画
function XUiActivityBriefBase:PlayVideoSpecialEnterAnim()
    self:PlayVideo(
        false,
        XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType),
        function() self:PlayVideo(true, XActivityBriefConfigs.GetLoopAnimName(self.PanelType)) end)
end

---播放视频入场动画
function XUiActivityBriefBase:PlayVideoEnterAnim()
    local enterAnim = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    if string.IsNilOrEmpty(enterAnim) then
        self:PlayVideoLoopAnim()
    else
        self:RefreshDefaultSkipBtn()
        self:PlayAnimationWithMask("AnimEnableLong")
        self:PlayVideo(
            false,
            XActivityBriefConfigs.GetEnterAnimName(self.PanelType),
            function() self:PlayVideoLoopAnim() end)
    end
end

function XUiActivityBriefBase:PlayVideoLoopAnim()
    self:PlayVideo(true, XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
end

--endregion

function XUiActivityBriefBase:RefreshActivityTag()
    self.UiActivityBriefRefreshButton:RefreshActivityTag()
end