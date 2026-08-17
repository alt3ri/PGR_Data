local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiButton = require("XUi/XUiCommon/XUiButton")
local XUiCommonEnum = require("XUi/XUiCommon/XUiCommonEnum")
local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiRadioSignRMSStrip = require("XUi/XUiRadioSign/XUiRadioSignRMSStrip")

-- RMS 采样间隔时间（毫秒），从配置中获取，默认100ms
local RMS_SCHEDULE_INTERVAL = 100
local XAudioManager = CS.XAudioManager
local RangeType = {
    Normal = 0,     -- 普通范围类型，直接应用配置
    Transition = 1, -- 过渡类型，从左右两侧过渡到中间配置
}

-- 播放状态枚举
local PlayState = {
    Idle = 0,         -- 空闲状态
    PlayingCV = 1,    -- 正在播放CV
    PlayingVideo = 2, -- 正在播放Video
}

-- 奖励请求状态枚举
local RewardRequestState = {
    None = 0,      -- 未请求
    Pending = 1,   -- 请求中
    Completed = 2, -- 已完成
}

---@class XUiRadioSignMain : XLuaUi
---@field _Control XRadioSignControl
local XUiRadioSignMain = XLuaUiManager.Register(XLuaUi, "UiRadioSignMain")

function XUiRadioSignMain:OnAwake()
    self:RegisterClickEvent(self.BtnBack, function()
        self:TryShowPendingReward()
        self:Close()
    end, nil, true)
    self:RegisterClickEvent(self.BtnMainUi, function()
        self:TryShowPendingReward()
        self:Close()
    end, nil, true)

    ---@type XUiGridCommon
    self._GridReward = XUiGridCommon.New(self, self.Grid256New)

    ---@type CS.XUiComponent.XUiButtonRotation
    self._BtnKnob = self.BtnKnob
    self._BtnKnob.OnValueChanged = function(value)
        -- 如果还在 OnStart 阶段，不隐藏 ImageStart；否则视为用户手动操作
        local isUserAction = not self._IsInStart
        self:OnBtnKnobValueChanged(value, isUserAction)
    end
    -- 配置表中FM值的原始范围
    self._MinFm = 30
    self._MaxFm = 120
    -- 显示范围（转换为0-100）
    self._DisplayMinFm = 0
    self._DisplayMaxFm = 100
    self._StandTimerId = nil                           -- 停留定时器ID
    self._CurrentConfig = nil                          -- 当前停留的配置
    self._SubtitleTimerIds = {}                        -- 字幕定时器ID列表
    self._LightTimerId = nil                           -- 灯光定时器ID
    self._LightEffectStartTime = nil                   -- 灯光效果开始时间（毫秒）
    self._LightEffectInterval = nil                    -- 灯光点亮间隔（毫秒）
    self._LightEffectCount = 0                         -- 灯光总数
    self._LightEffectCurrentIndex = 0                  -- 当前已点亮的灯光索引
    self._PlayState = PlayState.Idle                   -- 播放状态
    -- 长按按钮组件
    self._BtnAddLongClick = nil                        -- BtnAdd长按组件
    self._BtnSubLongClick = nil                        -- BtnSub长按组件
    -- Press GameObject 引用
    self._BtnAddPress = nil                            -- BtnAdd的Press子对象
    self._BtnSubPress = nil                            -- BtnSub的Press子对象
    -- RMS 相关
    self._RMSScheduleId = nil                          -- RMS定时器ID
    self._PlayingAudioInfo = nil                       -- 当前播放的音频信息
    self._PlayingVideoContent = nil                    -- 当前播放视频的content配置
    self._RewardRequestState = RewardRequestState.None -- 奖励请求状态
    self._RewardRequestSuccess = false                 -- 奖励请求是否成功
    self._PendingRewardList = nil                      -- 延后显示的奖励列表
    self._RewardRequestCheckTimerId = nil              -- 奖励请求检查定时器ID
    -- 初始化标志
    self._IsInStart = false                            -- 是否在 OnStart 阶段，用于控制 ImageStart 的隐藏
    -- RMS 可视化组件
    self._RMSStrip1 = nil                              -- PanelStrip1 的 RMS 可视化组件（左声道）
    self._RMSStrip2 = nil                              -- PanelStrip2 的 RMS 可视化组件（右声道）

    ---@type CS.UnityEngine.Image[]
    self._ImgLights = { self.ImgLight1, self.ImgLight2, self.ImgLight3, self.ImgLight4, self.ImgLight5, self.ImgLight6,
        self.ImgLight7, self.ImgLight8 }

    -- 初始化所有灯光为关闭状态
    self:ResetLights()

    -- 默认隐藏字幕
    if self.TxtSubtitles and self.TxtSubtitles.gameObject then
        self.TxtSubtitles.gameObject:SetActiveEx(false)
    end

    -- 默认隐藏 SoundNoise 节点
    if self.SoundNoise then
        self:SetGameObjectActive(self.SoundNoise.gameObject, false)
    end

    -- 绑定BtnPlayAgain按钮
    if self.BtnPlayAgain then
        XUiHelper.RegisterClickEvent(self, self.BtnPlayAgain, self.OnBtnPlayAgainClick)
    end

    -- 初始化长按按钮组件
    self:InitLongClickButtons()

    -- 默认隐藏 BtnKnobDisable（视频播放时才显示）
    if self.BtnKnobDisable then
        self:SetGameObjectActive(self.BtnKnobDisable.gameObject, false)
    end

    -- 初始化 RMS 可视化组件
    if self.PanelStrip1 then
        self._RMSStrip1 = XUiRadioSignRMSStrip.New(self.PanelStrip1, self)
    end
    if self.PanelStrip2 then
        self._RMSStrip2 = XUiRadioSignRMSStrip.New(self.PanelStrip2, self)
    end

    -- 当前content配置（用于重新播放video）
    self._CurrentContentConfig = nil
end

---@param content XTableRadioSignContent
function XUiRadioSignMain:OnStart(content)
    -- 设置初始化标志，防止 SetValue 触发时隐藏 ImageStart
    self._IsInStart = true

    -- 如果没有传入content，使用默认content
    if not content then
        local contents = self._Control:GetContentConfigs()

        -- 将 contents 转换为数组并按 id 排序
        local sortedContents = {}
        for _, contentItem in pairs(contents) do
            table.insert(sortedContents, contentItem)
        end
        table.sort(sortedContents, function(a, b)
            return a.Id < b.Id
        end)

        -- 按 id 顺序遍历，找到第一个在时间范围内且未领奖的content
        for _, contentItem in ipairs(sortedContents) do
            local timeId = contentItem.TimeId
            if XFunctionManager.CheckInTimeByTimeId(timeId) then
                if not self._Control:IsRewardReceived(contentItem.Id) then
                    content = contentItem
                    break
                end
            end
        end

        -- 如果没有找到未领奖的，使用第一个
        if not content and #sortedContents > 0 then
            content = sortedContents[1]
        end
    end

    local defaultFM = content.DefaultFM
    -- 将配置表中的FM值转换为0-100范围，然后转换为0-1的value
    local displayFM = self:ConvertFmToRange(defaultFM)
    local value = (displayFM - self._DisplayMinFm) / (self._DisplayMaxFm - self._DisplayMinFm)
    self:OnBtnKnobValueChanged(value, false) -- false 表示初始化，不隐藏 ImageStart
    self.BtnKnob:SetValue(value)

    local btns = {}
    self._BtnList = {}
    local configsDict = self._Control:GetContentConfigs()

    -- 收集所有配置并按Id从小到大排序
    local configs = {}
    for _, config in pairs(configsDict) do
        table.insert(configs, config)
    end
    table.sort(configs, function(a, b)
        return (a.Id or 0) < (b.Id or 0)
    end)
    self._Configs = configs

    -- 初始化按钮列表
    for i, config in ipairs(configs) do
        local btn = XUiHelper.Instantiate(self.BtnTab, self.PanelTab.transform)
        local csButton = btn:GetComponent("XUiButton")
        local xBtn = XUiButton.New(csButton)
        -- PanelTab:Init 需要CS组件
        table.insert(btns, csButton)
        table.insert(self._BtnList, xBtn)
        xBtn:SetName(config.Tab)
        self:UpdateButtonState(xBtn, config)

        -- 记录当前content的索引
        if config == content then
            self._Index = i
        end
    end
    self.BtnTab.gameObject:SetActiveEx(false)

    self.PanelTab:Init(btns, function(index)
        self:OnBtnTabClick(index)
    end)

    -- 初始化时先调用 Update 来设置正确的状态（包括隐藏 ImgVideo）
    -- 注意：这里不调用 ResetAll，因为 ResetAll 会停止播放，而初始化时可能还没有播放
    -- 但是需要确保 ImgVideo 在初始化时被隐藏
    self:SetGameObjectActive(self.ImgVideo and self.ImgVideo.gameObject, false)
    self:SetGameObjectActive(self.ImgMask and self.ImgMask.gameObject, false)
    self:SetGameObjectActive(self.BtnPlayAgain and self.BtnPlayAgain.gameObject, false)

    -- 然后调用 Update 来设置正确的状态
    self:Update(self._Index)

    -- OnStart 结束，释放初始化标志
    self._IsInStart = false
end

function XUiRadioSignMain:OnBtnTabClick(index)
    -- 如果点击的是当前已选中的页签，不做反应
    if self._Index and self._Index == index then
        return
    end

    -- 检查按钮是否处于disable状态
    if self._BtnList and self._BtnList[index] and self._Configs and self._Configs[index] then
        local config = self._Configs[index]
        local timeId = config.TimeId
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        local isReceived = self._Control:IsRewardReceived(config.Id)
        local isPrevContentReceived = self:IsPrevContentReceived(config)

        -- 如果未激活且未领取，或者前一关未领取，按钮处于disable状态，不响应点击
        if not isReceived and (not isInTime or not isPrevContentReceived) then
            XUiManager.TipText("CommonNotOpen")
            return
        end
    end

    -- 先更新索引，确保后续的UpdateRewardUI使用正确的索引
    self._Index = index

    -- 切换Tab前，如果有待弹出的奖励列表，先弹出（必须在ResetAll之前，因为ResetAll会清理状态）
    self:TryShowPendingReward()

    -- 切换Tab时重置一切（包括停止视频播放）
    self:ResetAll()
    self:Update(index)
end

-- 清理所有定时器和资源（不清理长按按钮组件，它们在UI生命周期内持续存在）
function XUiRadioSignMain:CleanupAllTimers()
    -- 注意：长按按钮组件不在CleanupAllTimers中清理，因为它们在UI生命周期内持续存在
    -- 长按按钮组件的清理应该在OnDisable或OnDestroy中处理
    -- 注意：RMS不在CleanupAllTimers中停止，因为它在UI生命周期内持续播放
    -- RMS的停止应该在OnDisable中处理
    self:CancelStandTimer()
    self:CancelSubtitleTimers()
    self:CancelLightTimers()
    self:CancelRewardRequestCheckTimer()
end

-- 重置所有状态和资源
function XUiRadioSignMain:ResetAll()
    -- 停止播放
    if self._PlayState == PlayState.PlayingCV then
        self:StopCV()
    elseif self._PlayState == PlayState.PlayingVideo then
        self:StopVideo(nil)
    end

    -- 清理所有定时器
    self:CleanupAllTimers()

    -- 重置播放状态
    self._PlayState = PlayState.Idle
    self._PlayingAudioInfo = nil
    self._CurrentConfig = nil

    -- 恢复按钮旋转
    self:SetButtonRotationEnabled(true)

    -- 重置灯光
    self:ResetLights()

    -- 隐藏字幕
    if self.TxtSubtitles then
        self.TxtSubtitles.text = ""
        self:SetGameObjectActive(self.TxtSubtitles.gameObject, false)
    end

    -- 显示LineGroup
    self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, true)

    -- 确保ImgVideo在重置时被隐藏（只在领奖后显示）
    self:SetGameObjectActive(self.ImgVideo and self.ImgVideo.gameObject, false)

    -- 确保ImgMask和BtnPlayAgain在重置时被隐藏（只在领奖后显示）
    self:SetGameObjectActive(self.ImgMask and self.ImgMask.gameObject, false)
    self:SetGameObjectActive(self.BtnPlayAgain and self.BtnPlayAgain.gameObject, false)
end

function XUiRadioSignMain:OnEnable()
    -- 设置初始化标志，防止 SelectIndex 触发的 Update 中的 SetValue 隐藏 ImageStart
    self._IsInStart = true

    self.PanelTab:SelectIndex(self._Index)
    -- RMS在UI生命周期内持续播放，在OnEnable时开始
    self:PlayRMS()
    -- 如果长按按钮组件在OnDisable时被清理了，需要重新初始化
    self:InitLongClickButtons()

    -- OnEnable 结束，释放初始化标志
    self._IsInStart = false

    -- 检查引导，因为在连续弹窗的过程中，不会触发指引，所以这里只能手动触发
    XDataCenter.GuideManager.CheckGuideOpen()
end

function XUiRadioSignMain:OnDisable()
    -- 改到了点下按钮时，因为如果在这里才弹出，背景截图将会是黑色的
    -- 离开界面前，如果有待弹出的奖励列表，先弹出
    -- self:TryShowPendingReward()

    -- RMS在UI生命周期内持续播放，在OnDisable时停止
    self:StopRMS()
    self:CleanupAllTimers()
    self:StopVideo(nil)
    -- 清理长按按钮组件（UI禁用时清理）
    if self._BtnAddLongClick then
        self._BtnAddLongClick:Destroy()
        self._BtnAddLongClick = nil
    end
    if self._BtnSubLongClick then
        self._BtnSubLongClick:Destroy()
        self._BtnSubLongClick = nil
    end
end

function XUiRadioSignMain:OnDestroy()
    -- RMS在UI生命周期内持续播放，在OnDestroy时确保停止
    self:StopRMS()
    self:CleanupAllTimers()
    self:StopVideo(nil)

    -- 清理长按按钮组件（UI销毁时确保清理，OnDisable可能已经清理过了，这里做防御性检查）
    if self._BtnAddLongClick then
        self._BtnAddLongClick:Destroy()
        self._BtnAddLongClick = nil
    end
    if self._BtnSubLongClick then
        self._BtnSubLongClick:Destroy()
        self._BtnSubLongClick = nil
    end
    self._CurrentConfig = nil
end

function XUiRadioSignMain:Update(index)
    if not index then
        index = self._Index or 1
    else
        self._Index = index
    end
    local config = self._Configs[index]
    self.TxtTips.text = config.Tip

    -- 根据config的DefaultFM重置ImgMine位置
    local defaultFM = config.DefaultFM
    local displayFM = self:ConvertFmToRange(defaultFM)
    local value = (displayFM - self._DisplayMinFm) / (self._DisplayMaxFm - self._DisplayMinFm)

    -- 更新ImgMine位置
    self:SetImgMinePosition(value)

    -- 设置BtnKnob的值（不触发回调）
    if self.BtnKnob then
        self.BtnKnob:SetValue(value)
    end

    -- 清空所有范围
    self.LineGroup:ClearAllRanges()

    local rangeConfigs = self._Control:GetClientConfigsByGroupId(config.FmGroup)

    -- 预先查找并缓存prefab配置，避免在循环中重复查找
    local prefabConfigRange1 = self.LineGroup.transform:Find("LineConfig/LineConfig1/LineRange1"):GetComponent(
        "XRadioSignLine")
    local prefabConfigRange2 = self.LineGroup.transform:Find("LineConfig/LineConfig2/LineRange2"):GetComponent(
        "XRadioSignLine")
    local prefabConfigHit1 = self.LineGroup.transform:Find("LineConfig/LineConfig1/LineHit1"):GetComponent(
        "XRadioSignLine")
    local prefabConfigHit2 = self.LineGroup.transform:Find("LineConfig/LineConfig2/LineHit2"):GetComponent(
        "XRadioSignLine")

    for _, clientConfig in pairs(rangeConfigs) do
        -- 将每个配置分成三个范围区域：
        -- 1. 左侧过渡区：从模糊最小值(MinVagueFM)到精确最小值(MinPreciseFM)，使用过渡效果
        local minFm = self:ConvertFmToRange(clientConfig.MinVagueFM)
        local maxFm = self:ConvertFmToRange(clientConfig.MinPreciseFM)
        self.LineGroup:AddRangeToConfig(0, RangeType.Transition, minFm, maxFm, prefabConfigRange1)
        self.LineGroup:AddRangeToConfig(1, RangeType.Transition, minFm, maxFm, prefabConfigRange2)

        -- 2. 中间精确区：从精确最小值(MinPreciseFM)到精确最大值(MaxPreciseFM)，直接应用配置
        minFm = self:ConvertFmToRange(clientConfig.MinPreciseFM)
        maxFm = self:ConvertFmToRange(clientConfig.MaxPreciseFM)
        self.LineGroup:AddRangeToConfig(0, RangeType.Normal, minFm, maxFm, prefabConfigHit1)
        self.LineGroup:AddRangeToConfig(1, RangeType.Normal, minFm, maxFm, prefabConfigHit2)

        -- 3. 右侧过渡区：从精确最大值(MaxPreciseFM)到模糊最大值(MaxVagueFM)，使用过渡效果
        minFm = self:ConvertFmToRange(clientConfig.MaxPreciseFM)
        maxFm = self:ConvertFmToRange(clientConfig.MaxVagueFM)
        self.LineGroup:AddRangeToConfig(0, RangeType.Transition, minFm, maxFm, prefabConfigRange1)
        self.LineGroup:AddRangeToConfig(1, RangeType.Transition, minFm, maxFm, prefabConfigRange2)
    end
    self._RangeConfigs = rangeConfigs

    local rewardId = config.RewardId
    if rewardId and rewardId ~= 0 then
        local rewards = XRewardManager.GetRewardList(rewardId)
        if rewards and #rewards > 0 then
            self._GridReward:Refresh(rewards[1])
        end
    end

    local isReceived = self._Control:IsRewardReceived(config.Id)
    if isReceived then
        self._GridReward:SetReceived(true)
    else
        self._GridReward:SetReceived(false)
    end

    -- 保存当前content配置
    self._CurrentContentConfig = config

    -- 更新已领奖状态的UI
    self:UpdateReceivedRewardUI(isReceived, config)
end

-- 设置GameObject的激活状态（安全封装）
---@param gameObject CS.UnityEngine.GameObject
---@param active boolean
function XUiRadioSignMain:SetGameObjectActive(gameObject, active)
    if gameObject then
        gameObject:SetActiveEx(active)
    end
end

-- 查找video配置
---@return XTableRadioSignClientConfig|nil
function XUiRadioSignMain:FindVideoConfig()
    if not self._RangeConfigs then
        return nil
    end

    for _, clientConfig in pairs(self._RangeConfigs) do
        if clientConfig.VideoConfigId and clientConfig.VideoConfigId ~= 0 then
            return clientConfig
        end
    end
    return nil
end

-- 更新已领奖状态的UI
---@param isReceived boolean
---@param config XTableRadioSignContent
function XUiRadioSignMain:UpdateReceivedRewardUI(isReceived, config)
    if isReceived then
        local videoConfig = self:FindVideoConfig()

        -- 更新文本
        if self.TxtDetatil then
            local endText = videoConfig and videoConfig.EndText or ""
            self.TxtDetatil.text = XUiHelper.ConvertLineBreakSymbol(endText)
        end

        -- 设置ImgVideo位置并显示
        if videoConfig then
            self:SetImgVideoPosition(videoConfig)
            self:SetGameObjectActive(self.ImgVideo and self.ImgVideo.gameObject, true)
        else
            self:SetGameObjectActive(self.ImgVideo and self.ImgVideo.gameObject, false)
        end

        -- 已领奖时隐藏ImgTips和ImageStart，显示LineGroup
        self:SetGameObjectActive(self.ImgTips and self.ImgTips.gameObject, false)
        self:SetGameObjectActive(self.ImageStart and self.ImageStart.gameObject, false)
        self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, false)

        -- 更新ImgMask和BtnPlayAgain显示状态（考虑播放状态）
        -- ImgMask：已领奖时显示，但如果正在播放视频则隐藏
        local shouldShowMask = self._PlayState ~= PlayState.PlayingVideo
        self:SetGameObjectActive(self.ImgMask and self.ImgMask.gameObject, shouldShowMask)

        -- BtnPlayAgain：已领奖时显示，但如果正在播放则隐藏
        local shouldShowBtn = self._PlayState == PlayState.Idle
        self:SetGameObjectActive(self.BtnPlayAgain and self.BtnPlayAgain.gameObject, shouldShowBtn)
    else
        self:SetGameObjectActive(self.ImgMask and self.ImgMask.gameObject, false)
        self:SetGameObjectActive(self.BtnPlayAgain and self.BtnPlayAgain.gameObject, false)
        self:SetGameObjectActive(self.ImgVideo and self.ImgVideo.gameObject, false)
        -- 未领奖时显示ImageStart和ImgTips，隐藏LineGroup
        self:SetGameObjectActive(self.ImageStart and self.ImageStart.gameObject, true)
        self:SetGameObjectActive(self.ImgTips and self.ImgTips.gameObject, true)
        self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, false)
    end
end

-- 更新按钮状态和红点
---@param xBtn XUiButtonLua 按钮组件
---@param config XTableRadioSignContent 配置
function XUiRadioSignMain:UpdateButtonState(xBtn, config)
    if not xBtn or not config then
        return
    end

    -- 更新按钮状态（根据时间ID）
    local timeId = config.TimeId
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    local isReceived = self._Control:IsRewardReceived(config.Id)

    -- 检查前一关的奖励是否领取（解锁条件）
    local isPrevContentReceived = self:IsPrevContentReceived(config)

    -- 优先显示已领取状态
    if isReceived then
        -- 已领取时，无论是否激活，都显示BgGou
        xBtn:SetButtonState(XUiButtonState.Normal)
        xBtn:SetActive("BgGou", true)
        xBtn:SetActive("BgLock", false)
        xBtn:ShowReddot(false)
    elseif isInTime and isPrevContentReceived then
        -- 激活且未领取，且前一关已领取，可以解锁
        xBtn:SetButtonState(XUiButtonState.Normal)
        xBtn:ShowReddot(true)
        xBtn:SetActive("BgGou", false)
        xBtn:SetActive("BgLock", false)
    else
        -- 未激活或前一关未领取，显示BgLock并设置Disable状态
        xBtn:SetButtonState(XUiButtonState.Disable)
        xBtn:ShowReddot(false)
        xBtn:SetActive("BgLock", true)
        xBtn:SetActive("BgGou", false)
    end
end

-- 检查前一关的奖励是否已领取
---@param config XTableRadioSignContent 当前配置
---@return boolean 前一关已领取返回true，否则返回false（第一关返回true）
function XUiRadioSignMain:IsPrevContentReceived(config)
    if not config or not self._Configs then
        return true -- 如果没有配置，默认返回true（允许访问）
    end

    -- 找到当前配置在列表中的位置
    local currentIndex = nil
    for i, cfg in ipairs(self._Configs) do
        if cfg.Id == config.Id then
            currentIndex = i
            break
        end
    end

    -- 如果是第一关，没有前一关，返回true（允许访问）
    if not currentIndex or currentIndex <= 1 then
        return true
    end

    -- 获取前一关的配置
    local prevConfig = self._Configs[currentIndex - 1]
    if not prevConfig then
        return true -- 如果没有前一关配置，默认返回true
    end

    -- 检查前一关的奖励是否已领取
    return self._Control:IsRewardReceived(prevConfig.Id)
end

-- 更新所有按钮的状态和红点
function XUiRadioSignMain:UpdateAllButtons()
    if not self._BtnList or not self._Configs then
        return
    end

    for i, xBtn in ipairs(self._BtnList) do
        local config = self._Configs[i]
        if config then
            self:UpdateButtonState(xBtn, config)
        end
    end

    -- 刷新后重新设置当前页签的选中状态
    if self._Index and self.PanelTab then
        self.PanelTab:SelectIndex(self._Index)
    end
end

-- 更新奖励相关的UI（领奖完成后调用）
function XUiRadioSignMain:UpdateRewardUI()
    if not self._CurrentContentConfig then
        return
    end

    local config = self._CurrentContentConfig

    -- 更新奖励状态
    local isReceived = self._Control:IsRewardReceived(config.Id)
    if isReceived then
        self._GridReward:SetReceived(true)
    else
        self._GridReward:SetReceived(false)
    end

    -- 更新所有按钮的红点和状态
    self:UpdateAllButtons()

    -- 更新已领奖相关的UI元素（包括mask和按钮状态）
    self:UpdateReceivedRewardUI(isReceived, config)
end

-- BtnPlayAgain按钮点击事件
function XUiRadioSignMain:OnBtnPlayAgainClick()
    if not self._CurrentContentConfig then
        return
    end

    local videoConfig = self:FindVideoConfig()
    if videoConfig then
        self:PlayVideo(videoConfig)
    end
end

-- 初始化长按按钮组件
function XUiRadioSignMain:InitLongClickButtons()
    -- 初始化 BtnAdd 长按按钮组件
    if not self._BtnAddLongClick and self.BtnAdd then
        -- 确保按钮可交互
        if self.BtnAdd.gameObject then
            local button = self.BtnAdd.gameObject:GetComponent(typeof(CS.UnityEngine.UI.Button))
            if button then
                button.interactable = true
            end

            -- 查找 Press 子对象
            local pressTransform = self.BtnAdd.gameObject.transform:Find("Press")
            if pressTransform then
                self._BtnAddPress = pressTransform.gameObject
                -- 初始状态隐藏
                self._BtnAddPress:SetActiveEx(false)
            end
        end

        self._BtnAddLongClick = XUiButtonLongClick.New(
            self.BtnAdd,
            100, -- interval: 连续触发间隔（毫秒）
            self,
            function(caller)
                -- clickCallback: 短按回调
                self:OnBtnAddClick()
            end,
            function(caller, pressingTime, longClickHandler, proxy)
                -- longClickCallback: 长按回调，每100ms调用一次
                -- pressingTime 是已经减去 Offset 的时间（毫秒），传递给回调用于加速计算
                self:OnBtnAddClick(pressingTime)
                return false, false -- 不退出，继续触发
            end,
            nil,                    -- longClickUpCallback: 长按抬起回调（不需要）
            true,                   -- isCanExit: 不允许指针退出时触发抬起
            nil,                    -- proxy
            false,                  -- onlyOneCallback
            nil,                    -- noAutoUp
            0.5                     -- TriggerOffset: 长按触发延迟（秒）
        )

        if not self._BtnAddLongClick then
            XLog.Error("[XUiRadioSignMain] _BtnAddLongClick 初始化失败！")
        else
            -- 添加按下和抬起监听器来控制 Press GameObject 的显示
            if self._BtnAddLongClick.Widget then
                self._BtnAddLongClick.Widget:AddPointerDownListener(function()
                    -- 按下时显示 Press
                    if self._BtnAddPress then
                        self._BtnAddPress:SetActiveEx(true)
                    end
                end)
                self._BtnAddLongClick.Widget:AddPointerUpListener(function()
                    -- 抬起时隐藏 Press
                    if self._BtnAddPress then
                        self._BtnAddPress:SetActiveEx(false)
                    end
                end)
                self._BtnAddLongClick.Widget:AddPointerExitListener(function()
                    -- 指针退出时也隐藏 Press
                    if self._BtnAddPress then
                        self._BtnAddPress:SetActiveEx(false)
                    end
                end)
            end
        end
    end

    -- 初始化 BtnSub 长按按钮组件
    if not self._BtnSubLongClick and self.BtnSub then
        -- 确保按钮可交互
        if self.BtnSub.gameObject then
            local button = self.BtnSub.gameObject:GetComponent(typeof(CS.UnityEngine.UI.Button))
            if button then
                button.interactable = true
            end

            -- 查找 Press 子对象
            local pressTransform = self.BtnSub.gameObject.transform:Find("Press")
            if pressTransform then
                self._BtnSubPress = pressTransform.gameObject
                -- 初始状态隐藏
                self._BtnSubPress:SetActiveEx(false)
            end
        end

        self._BtnSubLongClick = XUiButtonLongClick.New(
            self.BtnSub,
            100, -- interval: 连续触发间隔（毫秒）
            self,
            function(caller)
                -- clickCallback: 短按回调
                self:OnBtnSubClick()
            end,
            function(caller, pressingTime, longClickHandler, proxy)
                -- longClickCallback: 长按回调，每100ms调用一次
                -- pressingTime 是已经减去 Offset 的时间（毫秒），传递给回调用于加速计算
                self:OnBtnSubClick(pressingTime)
                return false, false -- 不退出，继续触发
            end,
            nil,                    -- longClickUpCallback: 长按抬起回调（不需要）
            false,                  -- isCanExit: 不允许指针退出时触发抬起
            nil,                    -- proxy
            false,                  -- onlyOneCallback
            nil,                    -- noAutoUp
            0.5                     -- TriggerOffset: 长按触发延迟（秒）
        )

        if not self._BtnSubLongClick then
            XLog.Error("[XUiRadioSignMain] _BtnSubLongClick 初始化失败！")
        else
            -- 添加按下和抬起监听器来控制 Press GameObject 的显示
            if self._BtnSubLongClick.Widget then
                self._BtnSubLongClick.Widget:AddPointerDownListener(function()
                    -- 按下时显示 Press
                    if self._BtnSubPress then
                        self._BtnSubPress:SetActiveEx(true)
                    end
                end)
                self._BtnSubLongClick.Widget:AddPointerUpListener(function()
                    -- 抬起时隐藏 Press
                    if self._BtnSubPress then
                        self._BtnSubPress:SetActiveEx(false)
                    end
                end)
                self._BtnSubLongClick.Widget:AddPointerExitListener(function()
                    -- 指针退出时也隐藏 Press
                    if self._BtnSubPress then
                        self._BtnSubPress:SetActiveEx(false)
                    end
                end)
            end
        end
    end
end

-- BtnAdd按钮点击事件（增加FM值）
-- @param pressingTime number 可选，长按时间（毫秒），用于计算加速步长
function XUiRadioSignMain:OnBtnAddClick(pressingTime)
    if not self._BtnKnob then
        return
    end

    -- 如果正在播放CV或Video，禁止操作
    if self._PlayState ~= PlayState.Idle then
        return
    end

    -- 获取当前值
    local currentValue = self._BtnKnob:GetValue()

    -- 基础步长（0.01，即1%）
    local baseStep = 0.01
    local step = baseStep

    -- 如果提供了长按时间，计算加速步长
    if pressingTime and pressingTime > 0 then
        -- 加速阈值：长按超过 1 秒（1000ms）后开始加速
        local accelerateThreshold = 1000
        if pressingTime > accelerateThreshold then
            -- 计算加速倍数：超过阈值的时间越长，加速越快
            -- 公式：加速倍数 = 1 + (超过阈值的时间 / 1000) * 加速系数
            local accelerateTime = pressingTime - accelerateThreshold
            local accelerateFactor = 0.5 -- 加速系数，每超过1秒增加0.5倍
            local accelerateMultiplier = 1 + (accelerateTime / 1000) * accelerateFactor
            -- 限制最大加速倍数为 5 倍
            accelerateMultiplier = math.min(accelerateMultiplier, 5)
            step = baseStep * accelerateMultiplier
        end
    end

    local newValue = math.min(1.0, currentValue + step)

    -- 设置新值
    self._BtnKnob:SetValue(newValue)
    -- 手动触发回调（因为SetValue可能不触发回调），true 表示用户手动操作
    self:OnBtnKnobValueChanged(newValue, true)
end

-- BtnSub按钮点击事件（减少FM值）
-- @param pressingTime number 可选，长按时间（毫秒），用于计算加速步长
function XUiRadioSignMain:OnBtnSubClick(pressingTime)
    if not self._BtnKnob then
        return
    end

    -- 如果正在播放CV或Video，禁止操作
    if self._PlayState ~= PlayState.Idle then
        return
    end

    -- 获取当前值
    local currentValue = self._BtnKnob:GetValue()

    -- 基础步长（0.01，即1%）
    local baseStep = 0.01
    local step = baseStep

    -- 如果提供了长按时间，计算加速步长
    if pressingTime and pressingTime > 0 then
        -- 加速阈值：长按超过 1 秒（1000ms）后开始加速
        local accelerateThreshold = 1000
        if pressingTime > accelerateThreshold then
            -- 计算加速倍数：超过阈值的时间越长，加速越快
            -- 公式：加速倍数 = 1 + (超过阈值的时间 / 1000) * 加速系数
            local accelerateTime = pressingTime - accelerateThreshold
            local accelerateFactor = 0.5 -- 加速系数，每超过1秒增加0.5倍
            local accelerateMultiplier = 1 + (accelerateTime / 1000) * accelerateFactor
            -- 限制最大加速倍数为 5 倍
            accelerateMultiplier = math.min(accelerateMultiplier, 5)
            step = baseStep * accelerateMultiplier
        end
    end

    local newValue = math.max(0.0, currentValue - step)

    -- 设置新值
    self._BtnKnob:SetValue(newValue)
    -- 手动触发回调（因为SetValue可能不触发回调），true 表示用户手动操作
    self:OnBtnKnobValueChanged(newValue, true)
end

---@param content XTableRadioSignClientConfig
function XUiRadioSignMain:PlayVideo(content)
    if not content or not content.VideoConfigId or content.VideoConfigId == 0 then
        XLog.Debug("[XUiRadioSignMain] PlayVideo: 无效的VideoConfigId", content and content.VideoConfigId)
        return
    end

    -- 保存当前播放的content配置
    self._PlayingVideoContent = content

    -- 设置播放状态，禁止旋转
    self._PlayState = PlayState.PlayingVideo
    self:SetButtonRotationEnabled(false)

    if self.LineGroup and self.LineGroup.gameObject then
        self.LineGroup.gameObject:SetActiveEx(false)
    end

    -- 隐藏ImgTips和ImageStart
    self:SetGameObjectActive(self.ImgTips and self.ImgTips.gameObject, false)
    self:SetGameObjectActive(self.ImageStart and self.ImageStart.gameObject, false)

    -- 播放视频时隐藏ImgMask（如果已领奖）
    if self._CurrentContentConfig then
        local isReceived = self._Control:IsRewardReceived(self._CurrentContentConfig.Id)
        if isReceived then
            self:SetGameObjectActive(self.ImgMask and self.ImgMask.gameObject, false)
            self:SetGameObjectActive(self.BtnPlayAgain and self.BtnPlayAgain.gameObject, false)
        end
    end

    -- 使用全屏视频播放器播放视频；全局 Analyzer 保持常驻
    local videoId = content.VideoConfigId

    -- 在视频播放时, 就发送请求获取奖励, 但是表现上, 弹出奖励和切换重播状态等, 都要等到视频播放完成后
    if self._CurrentContentConfig then
        local isReceived = self._Control:IsRewardReceived(self._CurrentContentConfig.Id)
        -- 防止重复触发：只有未领奖且未在请求中时才发送请求
        if not isReceived and self._RewardRequestState ~= RewardRequestState.Pending then
            self._RewardRequestState = RewardRequestState.Pending
            local contentId = self._CurrentContentConfig.Id
            XMVCA.XRadioSign:RadioSignGainRewardRequest(contentId, function(isSuccess, rewardGoodsList)
                self._RewardRequestState = RewardRequestState.Completed
                self._RewardRequestSuccess = isSuccess
                -- 保存奖励列表，延后到视频播放完成后弹出
                self._PendingRewardList = rewardGoodsList
                if not isSuccess then
                    XLog.Debug("[XUiRadioSignMain] PlayUiVideo: 奖励请求失败, contentId =", contentId)
                else
                    -- 请求成功后立即更新按钮状态，解锁页签，允许玩家跳过视频
                    self:UpdateAllButtons()
                end
            end, true) -- 延后显示奖励
        else
            if self._RewardRequestState == RewardRequestState.Pending then
                XLog.Debug("[XUiRadioSignMain] PlayUiVideo: 请求已在进行中，忽略重复触发, contentId =",
                    self._CurrentContentConfig.Id)
            end
        end
    end

    -- 使用UiVideoPlayer全屏播放，结束后统一走StopVideo逻辑处理领奖和UI
    XLuaVideoManager.PlayUiVideo(videoId, function()
        self:StopVideo(true)
    end, nil, nil, true)
end

-- 取消奖励请求检查定时器
function XUiRadioSignMain:CancelRewardRequestCheckTimer()
    if self._RewardRequestCheckTimerId then
        XScheduleManager.UnSchedule(self._RewardRequestCheckTimerId)
        self._RewardRequestCheckTimerId = nil
    end
end

-- 尝试弹出待处理的奖励列表
-- 如果奖励请求已完成且成功，且有待弹出的奖励列表，则弹出
-- 如果请求还在进行中，等待请求完成后再弹出
function XUiRadioSignMain:TryShowPendingReward()
    -- 如果奖励请求已完成且成功，且有待弹出的奖励列表，则弹出
    if self._RewardRequestState == RewardRequestState.Completed and self._RewardRequestSuccess and self._PendingRewardList then
        self:CancelRewardRequestCheckTimer()
        XUiManager.OpenUiObtain(self._PendingRewardList)
        self._PendingRewardList = nil
        -- 更新界面
        self:UpdateRewardUI()
        -- 重置请求状态
        self._RewardRequestState = RewardRequestState.None
        self._RewardRequestSuccess = false
    elseif self._RewardRequestState == RewardRequestState.Pending then
        -- 如果请求还在进行中，等待请求完成后再弹出
        -- 如果已经有定时器在运行，不再创建新的
        if self._RewardRequestCheckTimerId then
            return
        end

        local function CheckRequest()
            -- 清除定时器ID，允许下次重新创建
            self._RewardRequestCheckTimerId = nil

            if self._RewardRequestState == RewardRequestState.Completed then
                if self._RewardRequestSuccess and self._PendingRewardList then
                    XUiManager.OpenUiObtain(self._PendingRewardList)
                    self._PendingRewardList = nil
                    -- 更新界面
                    self:UpdateRewardUI()
                end
                -- 重置请求状态
                self._RewardRequestState = RewardRequestState.None
                self._RewardRequestSuccess = false
            elseif self._RewardRequestState == RewardRequestState.Pending then
                -- 继续等待，创建新的定时器
                self._RewardRequestCheckTimerId = XScheduleManager.ScheduleOnce(CheckRequest, 0.1)
            end
        end
        self._RewardRequestCheckTimerId = XScheduleManager.ScheduleOnce(CheckRequest, 0.1)
    end
end

-- 停止播放视频，恢复LineGroup显示，隐藏Video
---@param isNormalEnd boolean 是否正常播放结束（true=正常结束，false=错误结束，nil=手动停止）
function XUiRadioSignMain:StopVideo(isNormalEnd)
    -- 如果正常播放结束，处理奖励请求结果
    if isNormalEnd == true and self._CurrentContentConfig then
        -- 如果奖励请求已完成，直接更新UI
        if self._RewardRequestState == RewardRequestState.Completed then
            if self._RewardRequestSuccess then
                -- 弹出延后的奖励
                if self._PendingRewardList then
                    XUiManager.OpenUiObtain(self._PendingRewardList)
                    self._PendingRewardList = nil
                end
                -- 领奖完成后，更新界面
                self:UpdateRewardUI()
            end
            -- 重置请求状态
            self._RewardRequestState = RewardRequestState.None
            self._RewardRequestSuccess = false
        elseif self._RewardRequestState == RewardRequestState.Pending then
            -- 如果请求还在进行中，使用统一的检查机制
            -- 如果已经有定时器在运行，不再创建新的（TryShowPendingReward 可能已经创建了）
            if not self._RewardRequestCheckTimerId then
                local function CheckRequest()
                    -- 清除定时器ID，允许下次重新创建
                    self._RewardRequestCheckTimerId = nil

                    if self._RewardRequestState == RewardRequestState.Completed then
                        if self._RewardRequestSuccess then
                            -- 弹出延后的奖励
                            if self._PendingRewardList then
                                XUiManager.OpenUiObtain(self._PendingRewardList)
                                self._PendingRewardList = nil
                            end
                            -- 领奖完成后，更新界面
                            self:UpdateRewardUI()
                        end
                        -- 重置请求状态
                        self._RewardRequestState = RewardRequestState.None
                        self._RewardRequestSuccess = false
                    elseif self._RewardRequestState == RewardRequestState.Pending then
                        -- 继续等待，创建新的定时器
                        self._RewardRequestCheckTimerId = XScheduleManager.ScheduleOnce(CheckRequest, 0.1)
                    end
                end
                self._RewardRequestCheckTimerId = XScheduleManager.ScheduleOnce(CheckRequest, 0.1)
            end
        else
            -- 如果没有提前请求，说明可能是手动重播已领奖的视频，不需要再次请求
            -- 直接更新UI即可
            self:UpdateRewardUI()
        end
    else
        -- 非正常结束或手动停止，重置请求状态
        self._RewardRequestState = RewardRequestState.None
        self._RewardRequestSuccess = false
        self._PendingRewardList = nil
    end

    -- 恢复播放状态，允许旋转
    self._PlayState = PlayState.Idle
    self:SetButtonRotationEnabled(true)

    -- 根据领奖状态显示不同的UI元素
    if self._CurrentContentConfig then
        local isReceived = self._Control:IsRewardReceived(self._CurrentContentConfig.Id)
        if isReceived then
            -- 已领奖：隐藏ImgTips和ImageStart，显示ImgMask、BtnPlayAgain
            self:SetGameObjectActive(self.ImgTips and self.ImgTips.gameObject, false)
            self:SetGameObjectActive(self.ImageStart and self.ImageStart.gameObject, false)
            self:SetGameObjectActive(self.ImgMask and self.ImgMask.gameObject, true)
            self:SetGameObjectActive(self.BtnPlayAgain and self.BtnPlayAgain.gameObject, true)
            -- 正常播放结束时隐藏LineGroup，错误结束或手动停止时显示LineGroup
            if isNormalEnd == true then
                self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, false)
            else
                self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, true)
            end
        else
            -- 未领奖：显示ImgTips和ImageStart，隐藏ImgMask、BtnPlayAgain和LineGroup
            self:SetGameObjectActive(self.ImgTips and self.ImgTips.gameObject, true)
            self:SetGameObjectActive(self.ImageStart and self.ImageStart.gameObject, true)
            self:SetGameObjectActive(self.ImgMask and self.ImgMask.gameObject, false)
            self:SetGameObjectActive(self.BtnPlayAgain and self.BtnPlayAgain.gameObject, false)
            -- 正常播放结束时隐藏LineGroup
            self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, false)
        end
    else
        -- 没有当前content配置时，根据是否正常播放结束决定LineGroup的显示状态
        if isNormalEnd == true then
            -- 正常播放结束：隐藏LineGroup
            self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, false)
        else
            -- 错误结束或手动停止：显示LineGroup
            self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, true)
        end
    end

    -- 清除当前播放的content配置
    self._PlayingVideoContent = nil

    -- 暂时屏蔽随机模式
    -- 视频播放结束后，停止 RMS 随机模式，恢复正常模式
    -- if self._RMSStrip1 then
    --     self._RMSStrip1:StopRandomMode()
    -- end
    -- if self._RMSStrip2 then
    --     self._RMSStrip2:StopRandomMode()
    -- end

    -- 视频播放结束后，恢复 RMS 分析器
    local musicAudioInfo = XAudioManager.CurrentMusicAudioInfo1
    if musicAudioInfo ~= nil then
        -- 安全地检查 Unity 对象是否存在
        local isValid = true
        if type(musicAudioInfo.Exist) == "function" then
            isValid = musicAudioInfo:Exist()
        end
        if isValid then
            XAudioManager.ReplayCurrentMusic()
        end
    end
    XAudioManager.StartAnalyzer()
end

---@param content XTableRadioSignClientConfig
function XUiRadioSignMain:PlayCV(content)
    if not content or not content.CV or content.CV == "" then
        XLog.Debug("[XUiRadioSignMain] PlayCV: 无效的CV配置", content and content.CV)
        return
    end

    local cvId = tonumber(content.CV)
    if not cvId or cvId <= 0 then
        XLog.Debug("[XUiRadioSignMain] PlayCV: 无效的CV ID", content.CV, cvId)
        return
    end

    -- 设置播放状态，禁止旋转
    self._PlayState = PlayState.PlayingCV
    self:SetButtonRotationEnabled(false)

    local cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", 1)
    -- 播放CV
    self._PlayingAudioInfo = XLuaAudioManager.PlayCvWithCvType(cvId, cvType)

    -- 设置CV播放结束回调
    if self._PlayingAudioInfo then
        self._PlayingAudioInfo:AddFinishCallback(function()
            self:StopCV()
        end)
    end

    -- 清理之前的字幕定时器
    self:CancelSubtitleTimers()

    -- 初始化字幕为空
    if self.TxtSubtitles then
        self.TxtSubtitles.text = ""
    end

    -- 播放字幕
    self:PlaySubtitles(content)
end

-- 停止播放CV，恢复状态
function XUiRadioSignMain:StopCV()
    -- 恢复播放状态，允许旋转
    self._PlayState = PlayState.Idle
    self:SetButtonRotationEnabled(true)
    self._PlayingAudioInfo = nil
end

-- 播放字幕
---@param content XTableRadioSignClientConfig
function XUiRadioSignMain:PlaySubtitles(content)
    if not content or not self.TxtSubtitles then
        XLog.Debug("[XUiRadioSignMain] PlaySubtitles: 无效的配置或字幕组件不存在")
        return
    end

    local subtitles = content.Subtitles
    local subtitlesTime = content.SubtitlesTime

    if not subtitles or not subtitlesTime then
        XLog.Debug("[XUiRadioSignMain] PlaySubtitles: 字幕数据为空")
        return
    end

    -- 确保数组长度一致
    local subtitleCount = math.min(#subtitles, #subtitlesTime)

    if subtitleCount == 0 then
        return
    end

    -- 先取消之前的字幕定时器，避免重复创建
    self:CancelSubtitleTimers()

    -- 显示字幕组件
    if self.TxtSubtitles.gameObject then
        self.TxtSubtitles.gameObject:SetActiveEx(true)
    end

    -- 为每个字幕设置定时器
    for i = 1, subtitleCount do
        local subtitle = subtitles[i]
        local time = subtitlesTime[i]

        if subtitle and time and time >= 0 then
            local timerId
            timerId = XScheduleManager.ScheduleOnce(function()
                if self.TxtSubtitles then
                    self.TxtSubtitles.text = subtitle
                end
                -- 从列表中移除已触发的定时器ID
                for j, id in ipairs(self._SubtitleTimerIds) do
                    if id == timerId then
                        table.remove(self._SubtitleTimerIds, j)
                        break
                    end
                end
            end, time)

            table.insert(self._SubtitleTimerIds, timerId)
        end
    end
end

-- 取消所有字幕定时器
function XUiRadioSignMain:CancelSubtitleTimers()
    if self._SubtitleTimerIds then
        for _, timerId in ipairs(self._SubtitleTimerIds) do
            if timerId then
                XScheduleManager.UnSchedule(timerId)
            end
        end
        self._SubtitleTimerIds = {}
    end

    -- 清空字幕文本并隐藏字幕
    if self.TxtSubtitles then
        self.TxtSubtitles.text = ""
        if self.TxtSubtitles.gameObject then
            self.TxtSubtitles.gameObject:SetActiveEx(false)
        end
    end
end

-- @param value number 旋钮值 (0-1)
-- @param isUserAction boolean 是否是用户手动操作，true=用户操作，false=初始化/程序设置
function XUiRadioSignMain:OnBtnKnobValueChanged(value, isUserAction)
    -- 如果正在播放CV或Video，禁止旋转
    if self._PlayState ~= PlayState.Idle then
        return
    end

    -- 旋转按钮后隐藏ImgMask
    if self.ImgMask and self.ImgMask.gameObject then
        self.ImgMask.gameObject:SetActiveEx(false)
    end

    -- 只有用户手动操作时才隐藏ImageStart（初始化时不隐藏），并显示LineGroup
    if isUserAction then
        if self.ImageStart and self.ImageStart.gameObject then
            self.ImageStart.gameObject:SetActiveEx(false)
        end
        -- ImageStart隐藏时，显示LineGroup
        self:SetGameObjectActive(self.LineGroup and self.LineGroup.gameObject, true)
    end

    -- 更新ImgMine位置
    self:SetImgMinePosition(value)

    -- 计算当前FM值（转换为0-100范围）
    local fm = value * (self._DisplayMaxFm - self._DisplayMinFm) + self._DisplayMinFm

    -- 设置当前FM值
    self.LineGroup:SetCurrentValue(fm)

    -- 检测是否在过渡区，并激活/隐藏 SoundNoise 节点
    self:CheckAndUpdateSoundNoise(fm)

    -- 查找当前FM值在哪个配置范围内
    local targetConfig = self:FindConfigByFm(fm)

    -- 如果配置改变，取消之前的定时器
    if self._CurrentConfig ~= targetConfig then
        self:CancelStandTimer()
        self:CancelLightTimers()
        self:ResetLights()
        self._CurrentConfig = targetConfig

        -- 如果新配置有StandTime，启动定时器
        if targetConfig and targetConfig.StandTime and targetConfig.StandTime > 0 then
            self._StandTimerId = XScheduleManager.ScheduleOnce(function()
                self:OnStandTimeReached(targetConfig)
            end, targetConfig.StandTime)

            -- 只有配置有视频时才启动灯光点亮效果（播放CV不需要亮灯）
            if targetConfig.VideoConfigId and targetConfig.VideoConfigId ~= 0 then
                self:StartLightEffect(targetConfig.StandTime)
            end
        end
    end
end

-- 根据value设置图片位置（通用方法）
---@param imgTransform CS.UnityEngine.Transform
---@param value number 0-1之间的值
function XUiRadioSignMain:SetImagePositionByValue(imgTransform, value)
    if not self.BarStart or not self.BarEnd or not imgTransform then
        return
    end

    local startPosition = self.BarStart.transform.position
    local endPosition = self.BarEnd.transform.position
    imgTransform.position = startPosition + (endPosition - startPosition) * value
end

-- 设置ImgMine位置
---@param value number 0-1之间的值，表示在BarStart和BarEnd之间的位置比例
function XUiRadioSignMain:SetImgMinePosition(value)
    if self.ImgMine then
        self:SetImagePositionByValue(self.ImgMine.transform, value)
    end
end

-- 设置ImgVideo位置（固定在video播放位置，不跟随value改变）
---@param videoConfig XTableRadioSignClientConfig 视频配置
function XUiRadioSignMain:SetImgVideoPosition(videoConfig)
    if not self.ImgVideo or not videoConfig then
        return
    end

    -- 计算video配置的FM范围中心位置（转换为0-100范围）
    local minFm = self:ConvertFmToRange(videoConfig.MinPreciseFM)
    local maxFm = self:ConvertFmToRange(videoConfig.MaxPreciseFM)
    local centerFm = (minFm + maxFm) / 2

    -- 将FM值转换为0-1之间的value
    local value = (centerFm - self._DisplayMinFm) / (self._DisplayMaxFm - self._DisplayMinFm)

    self:SetImagePositionByValue(self.ImgVideo.transform, value)
end

-- 设置按钮旋转是否启用
---@param enabled boolean 是否启用
function XUiRadioSignMain:SetButtonRotationEnabled(enabled)
    if not self._BtnKnob then
        return
    end

    self._BtnKnob.enabled = enabled
    local component = self._BtnKnob:GetComponent("XUiComponent.XUiButtonRotation")
    if component then
        component.enabled = enabled
    end

    -- 显示/隐藏禁用状态的按钮
    if self.BtnKnobDisable then
        self:SetGameObjectActive(self.BtnKnobDisable.gameObject, not enabled)
    end
end

-- 将FM值从原始范围(30-120)转换为0-100范围
---@param fmValue number 原始FM值（配置表中的值，范围30-120）
---@return number 转换后的0-100范围值
function XUiRadioSignMain:ConvertFmToRange(fmValue)
    if not fmValue then
        return 0
    end
    -- 从原始范围(_MinFm到_MaxFm)转换为显示范围(0-100)
    local normalizedValue = (fmValue - self._MinFm) / (self._MaxFm - self._MinFm)
    return normalizedValue * (self._DisplayMaxFm - self._DisplayMinFm) + self._DisplayMinFm
end

-- 检测是否在过渡区，并激活/隐藏 SoundNoise 节点
---@param fm number FM值（0-100范围）
function XUiRadioSignMain:CheckAndUpdateSoundNoise(fm)
    if not self._RangeConfigs then
        return
    end

    local isInTransition = false

    -- 检查是否在左侧或右侧过渡区
    for _, config in pairs(self._RangeConfigs) do
        -- 左侧过渡区：从 MinVagueFM 到 MinPreciseFM
        local leftMinFm = self:ConvertFmToRange(config.MinVagueFM)
        local leftMaxFm = self:ConvertFmToRange(config.MinPreciseFM)
        if fm >= leftMinFm and fm < leftMaxFm then
            isInTransition = true
            break
        end

        -- 右侧过渡区：从 MaxPreciseFM 到 MaxVagueFM
        local rightMinFm = self:ConvertFmToRange(config.MaxPreciseFM)
        local rightMaxFm = self:ConvertFmToRange(config.MaxVagueFM)
        if fm > rightMinFm and fm <= rightMaxFm then
            isInTransition = true
            break
        end
    end

    -- 激活或隐藏 SoundNoise 节点
    if self.SoundNoise then
        self:SetGameObjectActive(self.SoundNoise.gameObject, isInTransition)
    end
end

-- 根据FM值查找匹配的配置
---@param fm number FM值（0-100范围）
---@return XTableRadioSignClientConfig|nil
function XUiRadioSignMain:FindConfigByFm(fm)
    if not self._RangeConfigs then
        return nil
    end

    for _, config in pairs(self._RangeConfigs) do
        local minFm = self:ConvertFmToRange(config.MinPreciseFM)
        local maxFm = self:ConvertFmToRange(config.MaxPreciseFM)
        if fm >= minFm and fm <= maxFm then
            return config
        end
    end
    return nil
end

-- 取消停留定时器
function XUiRadioSignMain:CancelStandTimer()
    if self._StandTimerId then
        XScheduleManager.UnSchedule(self._StandTimerId)
        self._StandTimerId = nil
    end
end

-- 启动灯光点亮效果
---@param standTime number 停留时间（毫秒）
function XUiRadioSignMain:StartLightEffect(standTime)
    if not self._ImgLights or #self._ImgLights == 0 then
        return
    end

    -- 先取消之前的灯光定时器，避免重复创建
    self:CancelLightTimers()

    -- 先重置所有灯光
    self:ResetLights()

    -- 计算每个灯光点亮的时间间隔
    local lightCount = #self._ImgLights
    local interval = standTime / lightCount

    -- 记录开始时间和间隔
    self._LightEffectStartTime = CS.UnityEngine.Time.realtimeSinceStartup * 1000 -- 转换为毫秒
    self._LightEffectInterval = interval
    self._LightEffectCount = lightCount
    self._LightEffectCurrentIndex = 0 -- 当前已点亮的灯光索引

    -- 使用 ScheduleForever 定时器，定期检查应该点亮哪个灯光
    self._LightTimerId = XScheduleManager.ScheduleForever(function()
        if not self._LightEffectStartTime or not self._LightEffectInterval then
            return
        end

        local currentTime = CS.UnityEngine.Time.realtimeSinceStartup * 1000 -- 转换为毫秒
        local elapsedTime = currentTime - self._LightEffectStartTime

        -- 计算应该点亮到第几个灯光（从1开始）
        local targetIndex = math.floor(elapsedTime / self._LightEffectInterval) + 1

        -- 如果已经超过所有灯光，停止定时器
        if targetIndex > self._LightEffectCount then
            -- 确保所有灯光都已点亮
            for i = 1, self._LightEffectCount do
                self:SetLightOn(i)
            end
            self:CancelLightTimers()
            return
        end

        -- 只点亮新增加的灯光，避免重复设置
        if targetIndex > self._LightEffectCurrentIndex then
            for i = self._LightEffectCurrentIndex + 1, targetIndex do
                self:SetLightOn(i)
            end
            self._LightEffectCurrentIndex = targetIndex
        end
    end, 16) -- 约60fps的检查频率
end

-- 设置指定索引的灯光为点亮状态
---@param index number 灯光索引（从1开始）
function XUiRadioSignMain:SetLightOn(index)
    if not self._ImgLights or index < 1 or index > #self._ImgLights then
        return
    end

    local imgLight = self._ImgLights[index]
    if imgLight then
        imgLight.gameObject:SetActiveEx(true)
    end
end

-- 重置所有灯光为关闭状态
function XUiRadioSignMain:ResetLights()
    if not self._ImgLights then
        return
    end

    for _, imgLight in ipairs(self._ImgLights) do
        if imgLight then
            imgLight.gameObject:SetActiveEx(false)
        end
    end
end

-- 取消所有灯光定时器
function XUiRadioSignMain:CancelLightTimers()
    if self._LightTimerId then
        XScheduleManager.UnSchedule(self._LightTimerId)
        self._LightTimerId = nil
    end

    self._LightEffectStartTime = nil
    self._LightEffectInterval = nil
    self._LightEffectCount = 0
    self._LightEffectCurrentIndex = 0

    -- 重置所有灯光
    self:ResetLights()
end

-- 停留时间到达时的回调
---@param config XTableRadioSignClientConfig
function XUiRadioSignMain:OnStandTimeReached(config)
    if not config then
        return
    end

    -- 检查当前是否还在同一个配置范围内
    if self._CurrentConfig ~= config then
        return
    end

    -- 如果当前content已经领过奖，不自动播放，停留在mask状态，只能手动重播
    if self._CurrentContentConfig then
        local isReceived = self._Control:IsRewardReceived(self._CurrentContentConfig.Id)
        if isReceived then
            -- 已领奖时，显示mask和重播按钮，不自动播放
            self:UpdateReceivedRewardUI(true, self._CurrentContentConfig)
            -- 清除定时器ID
            self._StandTimerId = nil
            return
        end
    end

    -- 未领奖时，正常自动播放
    -- 优先播放视频，如果没有视频则播放CV
    if config.VideoConfigId and config.VideoConfigId ~= 0 then
        self:PlayVideo(config)
    elseif config.CV and config.CV ~= "" then
        self:PlayCV(config)
    end

    -- 清除定时器ID
    self._StandTimerId = nil
end

-- 启动RMS分析器
function XUiRadioSignMain:PlayRMS()
    -- 如果已经在运行，先停止
    self:StopRMS()

    -- 启动音频分析器
    XAudioManager.StartAnalyzer()

    -- 启动定时器定期获取RMS值
    self._RMSScheduleId = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        local rmsLeft = 0
        local rmsRight = 0

        -- 从 XAudioManager 获取 RMS
        rmsLeft = XAudioManager.GetRMS(0)
        rmsRight = XAudioManager.GetRMS(1)

        -- 更新左声道 RMS 可视化显示（RMS 值范围 0-3）
        if self._RMSStrip1 then
            self._RMSStrip1:UpdateStrips(rmsLeft)
        end

        -- 更新右声道 RMS 可视化显示（RMS 值范围 0-3）
        if self._RMSStrip2 then
            self._RMSStrip2:UpdateStrips(rmsRight)
        end

        -- 调试
        -- if XMain.IsEditorDebug then
        --     XLog.Debug("RadioSign RMS Left:", rmsLeft, "Right:", rmsRight, "PlayingVideo:", self._PlayState == PlayState.PlayingVideo)
        -- end
    end, RMS_SCHEDULE_INTERVAL, 0)
end

-- 停止RMS刷新
function XUiRadioSignMain:StopRMS()
    -- 清理RMS定时器
    if self._RMSScheduleId then
        XScheduleManager.UnSchedule(self._RMSScheduleId)
        self._RMSScheduleId = nil
    end
end

return XUiRadioSignMain
