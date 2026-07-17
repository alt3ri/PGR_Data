---@class XUiDrawShowNew : XLuaUi
local XUiDrawShowNew = XLuaUiManager.Register(XLuaUi, "UiDrawShowNew")
local XUiGridDrawShowReward = require("XUi/XUiDraw/XUiGridDrawShowReward")
local XUiGridDrawResult = require("XUi/XUiDraw/XUiGridDrawResult")
local ODD_TYPE = 1
local EVEN_TYPE = 0
local EVEN_MAX = 10
local ODD_MAX = 9
local DrawState = {
    Show = 1,
    Result = 2
}
local MAX_DRAW_COUNT = 10
function XUiDrawShowNew:OnStart(drawInfo, rewardList, state, closeCb)
    self.DrawInfo = drawInfo
    self.RewardList = rewardList
    ---@type XUiGridDrawShowModel[]
    self.GridRewardList = {}
    self.CloseCb = closeCb
    self.CurrIndex = 1
    self.CurrState = state or DrawState.Show
    self.IsClosed = false
    self.IsTransitioning = false
    self.HasStartedFlow = false
    self:InitUi()
    self:RegisterButton()

    self.TxtTips = self.GameObject:FindTransform("TxtTips")
    self.TxtTips.gameObject:SetActiveEx(false)
    if #self.RewardList == 1 then
        self.BtnSkip.gameObject:SetActiveEx(false)
    end

    self.MaxEffectGroupId = 0
end

function XUiDrawShowNew:OnEnable()
    -- 防止 Performance UI 关闭后 OnEnable 和 closeCb 同时触发 PlayNext
    if self.HasStartedFlow or self.IsTransitioning then
        return
    end
    self.HasStartedFlow = true
    self:RefreshByState()
end

function XUiDrawShowNew:OnDisable()
    self:StopCv()
end

function XUiDrawShowNew:OnDestroy()
    self:StopCv()
    for _, grid in pairs(self.GridRewardList) do
        grid:OnDestroy()
    end
    XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.DRAW, false)
end

function XUiDrawShowNew:RegisterButton()
    self.BtnSkip.CallBack = function()
        if self.IsTransitioning then
            return
        end
        if self.CurrState == DrawState.Result then
            self:OnClose()
        else
            if self.LastReward then
                self.LastReward:OnShowEnd()
            end
            -- 跳过时先播放剩余奖励中所有有 Performance 的表演，播完后再进入 Result
            self.IsTransitioning = true
            self:PlayRemainingPerformances(self.CurrIndex, function()
                self.IsTransitioning = false
                self.CurrState = DrawState.Result
                self:ShowResult()
            end)
        end
    end
    self:RegisterClickEvent(self.BtnClick, function()
        if self.IsTransitioning then
            return
        end
        if self.CurrState == DrawState.Result then
            self:OnClose()
        else
            self:PlayNext()
        end
    end)
end

function XUiDrawShowNew:InitUi()
    self.FarCameraList = {}
    self.NearCameraList = {}
    self.ModelPanelList = {}
    self.UiPanelList = {}
    self.UiCameraList = {}
    for i = 1, MAX_DRAW_COUNT do
        self.FarCameraList[i] = self.UiModelGo.transform:Find("FarRoot/FarCamera" .. i)
        self.NearCameraList[i] = self.UiModelGo.transform:Find("NearRoot/NearCamera" .. i)
        self.ModelPanelList[i] = self.UiModelGo.transform:Find("NearRoot/PanelModelCase" .. i)
        self.UiPanelList[i] = self.UiModelGo.transform:Find("UiRoot/PanelUi" .. i)
        self.UiCameraList[i] = self.UiModelGo.transform:Find("UiRoot/UiCamera" .. i)
    end
    self.GridUiTemplate = self.UiModelGo.transform:Find("UiRoot/GridUi")
    self.GridUiTemplate.gameObject:SetActiveEx(false)
    self.GridModelTemplate = self.UiModelGo.transform:Find("NearRoot/GridModelCase")
    self.GridModelTemplate.gameObject:SetActiveEx(false)

    self.GridPanelDic = {}
    self.GridPanelDic[EVEN_TYPE] = {}
    self.GridPanelDic[ODD_TYPE] = {}
    self.PanelTen = self.UiModelGo.transform:Find("UiRoot/GridExhibition/PanelTen")
    self.PanelNine = self.UiModelGo.transform:Find("UiRoot/GridExhibition/PanelNine")
    for i = 1, EVEN_MAX do
        local obj = self.PanelTen:Find(string.format("Grid%02d", i))
        self.GridPanelDic[EVEN_TYPE][i] = XUiGridDrawResult.New(obj, self)
        self.GridPanelDic[EVEN_TYPE][i]:SetActive(false)
    end
    for i = 1, ODD_MAX do
        local obj = self.PanelNine:Find(string.format("Grid%02d", i))
        self.GridPanelDic[ODD_TYPE][i] = XUiGridDrawResult.New(obj, self)
        self.GridPanelDic[ODD_TYPE][i]:SetActive(false)
    end
    self.PanelTen.gameObject:SetActiveEx(false)
    self.PanelNine.gameObject:SetActiveEx(false)

    self.ResultNearCamera = self.UiModelGo.transform:Find("NearRoot/NearCamera11")
    self.ResultFarCamera = self.UiModelGo.transform:Find("FarRoot/FarCamera11")
    self.ResultUiCamera = self.UiModelGo.transform:Find("UiRoot/UiCamera11")
    self.ResultUiCamera.gameObject:SetActiveEx(false)
    ---@type UnityEngine.Camera
    self.UiCamera = self.UiModelGo.transform:Find("UiRoot/Camera"):GetComponent(typeof(CS.UnityEngine.Camera))
    ---@type UnityEngine.Transform
    self.PanelTenEnableAnim = self.UiModelGo.transform:Find("Animation/PanelTenEnable")
    ---@type UnityEngine.Transform
    self.PanelNineEnableAnim = self.UiModelGo.transform:Find("Animation/PanelNineEnable")
end

function XUiDrawShowNew:PlayNext()
    if self.LastReward then
        self.LastReward:OnShowEnd()
    end
    if self.CurrIndex > #self.RewardList then
        self.CurrState = DrawState.Result
        self:ShowResult()
        return
    end
    -- 检查当前奖励是否需要角色表演
    local rewardInfo = self.RewardList[self.CurrIndex]
    if XDataCenter.DrawManager.CheckHasPerformance(rewardInfo) then
        self.IsTransitioning = true
        XLuaUiManager.Open("UiNewDrawMainV4P5Performance", rewardInfo, function()
            self.IsTransitioning = false
            -- 表演关闭后正常展示该奖励
            self:ShowReward(self.CurrIndex)
        end)
        return
    end
    self:ShowReward(self.CurrIndex)
end

-- 正常展示指定索引的奖励并推进Index
function XUiDrawShowNew:ShowReward(index)
    self.LastReward = self.GridRewardList[index]
    if not self.LastReward then
        local modelObj = CS.UnityEngine.GameObject.Instantiate(self.GridModelTemplate, self.ModelPanelList[index])
        modelObj.gameObject:SetActiveEx(true)
        local uiObj = CS.UnityEngine.GameObject.Instantiate(self.GridUiTemplate, self.UiPanelList[index])
        uiObj.gameObject:SetActiveEx(true)
        self.GridRewardList[index] = XUiGridDrawShowReward.New(self, self.ModelPanelList[index], self.UiPanelList[index], self.FarCameraList[index], self.NearCameraList[index], self.UiCameraList[index])
        self.LastReward = self.GridRewardList[index]
    end
    self.LastReward:OnShow(self.RewardList[index])
    self.CurrIndex = index + 1
end

function XUiDrawShowNew:ShowResult()
    self.TxtTips.gameObject:SetActiveEx(true)
    self.BtnSkip.gameObject:SetActiveEx(false)
    if #self.RewardList == 1 then
        -- 单抽无需展示结果面板，直接关闭
        self.UiCamera.gateFit = CS.UnityEngine.Camera.GateFitMode.Vertical
        self:OnClose()
        return
    end
    self.UiCamera.gateFit = CS.UnityEngine.Camera.GateFitMode.Horizontal
    local finishCallback = function()
        self.BtnClick.gameObject:SetActiveEx(true)
    end
    local beginCallback = function()
        self.BtnClick.gameObject:SetActiveEx(false)
    end
    if #self.RewardList == 10 then
        self.PanelTenEnableAnim:PlayTimelineAnimation(finishCallback, beginCallback)
    else
        self.PanelNineEnableAnim:PlayTimelineAnimation(finishCallback, beginCallback)
    end
    self.ResultNearCamera.gameObject:SetActiveEx(true)
    self.ResultFarCamera.gameObject:SetActiveEx(true)
    self.ResultUiCamera.gameObject:SetActiveEx(true)
    if #self.RewardList % 2 == 0 then
        self.PanelTen.gameObject:SetActiveEx(true)
        local offset = (EVEN_MAX - #self.RewardList) / 2
        for i = 1, #self.RewardList do
            local grid = self.GridPanelDic[EVEN_TYPE][offset + i]
            if grid then
                grid:SetData(self.RewardList[i])
                grid:SetActive(true)
            end
        end
    else
        self.PanelNine.gameObject:SetActiveEx(true)
        local offset = (ODD_MAX - #self.RewardList) / 2
        for i = 1, #self.RewardList do
            local grid = self.GridPanelDic[ODD_TYPE][offset + i]
            if grid then
                grid:SetData(self.RewardList[i])
                grid:SetActive(true)
            end
        end
    end
    self:PlayCardEffectSound()
end

function XUiDrawShowNew:RefreshByState()
    if self.CurrState == DrawState.Show then
        self:PlayNext()
    elseif self.CurrState == DrawState.Result then
        -- 从 UiDrawNew 跳过进入 Result 时，先播完所有有 Performance 的奖励表演，再 ShowResult
        self.IsTransitioning = true
        self:PlayRemainingPerformances(self.CurrIndex, function()
            self.IsTransitioning = false
            self:ShowResult()
        end)
    end
end

function XUiDrawShowNew:SetDrawEffectGroupId(effectGroupId)
    if effectGroupId > self.MaxEffectGroupId then
        self.MaxEffectGroupId = effectGroupId
    end
end

function XUiDrawShowNew:PlayCardEffectSound()
    local voiceId = XDrawConfigs.GetCardEffectSound(self.MaxEffectGroupId)
    if voiceId and voiceId > 0 then
        self.CvInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, voiceId)
    end
end

function XUiDrawShowNew:StopCv()
    if self.CvInfo then
        self.CvInfo:Stop()
        self.CvInfo = nil
    end
end

function XUiDrawShowNew:OnClose()
    if self.IsClosed then
        return
    end
    self.IsClosed = true
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

-- 从 startIndex 开始，依次播放剩余奖励中所有有 Performance 的表演
-- 全部播完后调用 doneCb
function XUiDrawShowNew:PlayRemainingPerformances(startIndex, doneCb)
    -- 查找下一个有 Performance 的奖励
    local nextIndex
    for i = startIndex, #self.RewardList do
        if XDataCenter.DrawManager.CheckHasPerformance(self.RewardList[i]) then
            nextIndex = i
            break
        end
    end
    if not nextIndex then
        -- 没有剩余的 Performance 了，直接调用 doneCb
        if doneCb then
            doneCb()
        end
        return
    end
    -- 播放这个表演，结束后递归查找下一个
    XLuaUiManager.Open("UiNewDrawMainV4P5Performance", self.RewardList[nextIndex], function()
        self:PlayRemainingPerformances(nextIndex + 1, doneCb)
    end)
end

return XUiDrawShowNew
