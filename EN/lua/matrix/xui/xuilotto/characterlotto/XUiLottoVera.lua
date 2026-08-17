local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
---@class XUiLottoVera : XLuaUi
local XUiLottoVera = XLuaUiManager.Register(XLuaUi, "UiLottoVera")

---@param groupData XLottoGroupEntity
function XUiLottoVera:OnStart(groupData, closeCb, backGround)
    ---@type XLottoGroupEntity
    self._LottoGroupData = groupData
    --- ui缓存数据,需考虑进入战斗时UI回收缓存
    self._LottoUiData = self._LottoUiData or XDataCenter.LottoManager.CreateLottoUiData()

    self:InitPanelAsset()
    self:InitPanelReward()
    self:InitDraw()
    self:InitScene()
    self:AddBtnListener()
end

function XUiLottoVera:OnEnable()
    self:PlayEnableAnim()
    self:Refresh()
    self:AddEventListener()
    self:StartAutoCloseTimer()
end

function XUiLottoVera:OnDisable()
    self:RemoveEventListener()
    self:CloseAutoCloseTimer()
end

function XUiLottoVera:OnReleaseInst()
    return self._LottoUiData
end

function XUiLottoVera:OnResume(value)
    self._LottoUiData = value
end

--region Ui - AutoClose
function XUiLottoVera:StartAutoCloseTimer()
    if self._CloseTimer then
        self:CloseAutoCloseTimer()
    end
    local drawData = self._LottoGroupData:GetDrawData()
    local timeId = drawData:GetTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:_RefreshTimeText(endTime)
    self._CloseTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.Transform) then
            self:CloseAutoCloseTimer()
        end
        if XTime.GetServerNowTimestamp() > endTime then
            XDataCenter.LottoManager.OnActivityEnd()
        end
        self:_RefreshTimeText(endTime)
    end, XScheduleManager.SECOND, 0)
end

-- 每秒调用，number/unit 未变则跳过 Text 赋值，避免无意义的 UI 重绘
function XUiLottoVera:_RefreshTimeText(endTime)
    local time = endTime - XTime.GetServerNowTimestamp()
    local number, unit = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ESCAPE_ACTIVITY)
    if self._LastTimeNumber == number and self._LastTimeUnit == unit then
        return
    end
    self._LastTimeNumber = number
    self._LastTimeUnit = unit

    if self.TxtNumber then
        self.TxtNumber.text = tostring(number)
    end
    if self.TxtDay then
        self.TxtDay.text = unit
    end
end

function XUiLottoVera:CloseAutoCloseTimer()
    if self._CloseTimer then
        XScheduleManager.UnSchedule(self._CloseTimer)
        self._CloseTimer = nil
    end
end
--endregion

--region Ui - Refresh
function XUiLottoVera:Refresh()
    self:RefreshReward()
    self:RefreshDrawBtn()
    self:RefreshStoryBtn()
    self:RefreshSkipBtn(XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId()))
end

function XUiLottoVera:_AfterShowDrawResult()
    self:Refresh()
end
--endregion

--region Ui - PanelAsset
function XUiLottoVera:InitPanelAsset()
    local drawData = self._LottoGroupData:GetDrawData()
    local itemIds = {
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.HongKa,
        drawData:GetConsumeId()
    }
    ---@type XUiPanelActivityAsset
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
end
--endregion

--region Ui - PanelReward
function XUiLottoVera:InitPanelReward()
    ---@type XUiPanelLottoPreview
    local XUiPanelLottoPreview = require("XUi/XUiLotto/XUiPanelLottoPreview")

    local weaponFashionId = XLottoConfigs.GetLottoClientConfigNumber("VeraWeaponFashionId")
    local fashionDesc = XUiHelper.GetText("LottoVeraFashionDesc")
    self._PanelLottoPreview = XUiPanelLottoPreview.New(self.PanelPreview, self, self._LottoGroupData, weaponFashionId, fashionDesc)
end

function XUiLottoVera:RefreshReward()
    self._PanelLottoPreview:UpdateTwoLevelPanel(XEnumConst.Lotto.Vera)
end
--endregion

--region Ui - Btn
function XUiLottoVera:RefreshDrawBtn()
    local drawData = self._LottoGroupData:GetDrawData()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(drawData:GetConsumeId())
    self.BtnGo:SetDisable(drawData:IsLottoCountFinish())
    if drawData:IsLottoCountFinish() then
        self.PanelDrawButtons:GetObject("ImgUseItemIcon").gameObject:SetActiveEx(false)
        self.PanelDrawButtons:GetObject("TxtUseItemCount").gameObject:SetActiveEx(false)
    else
        self.PanelDrawButtons:GetObject("ImgUseItemIcon"):SetRawImage(icon)
        self.PanelDrawButtons:GetObject("TxtUseItemCount").text = drawData:GetConsumeCount() > 0 and
                "x" .. drawData:GetConsumeCount() or XUiHelper.GetText("LottoDrawFreeText")
    end
end

function XUiLottoVera:RefreshStoryBtn()
    if not self.TxtStoryProcess then
        return
    end
    local storyCount, storyAll = XMVCA.XCerberusGame:GetProgressChapterFashionStory()
    local count, all = XMVCA.XCerberusGame:GetProgressChapterFashionChallenge()
    local value = math.floor((storyCount + count) / (storyAll + all) * 100)
    self.TxtStoryProcess.text = value .. "%"
end

function XUiLottoVera:RefreshSkipBtn(isSkip)
    if not self.BtnShield then
        return
    end
    if isSkip then
        self.BtnShield:SetButtonState(XUiButtonState.Select)
    else
        self.BtnShield:SetButtonState(XUiButtonState.Normal)
    end
end
--endregion

--region Ui - Anim
function XUiLottoVera:PlayEnableAnim()
    local isFirst = XDataCenter.LottoManager.GetFirstAnim(self._LottoGroupData:GetId())
    local isSkip = XDataCenter.LottoManager.GetSkipAnim(self._LottoGroupData:GetId())
    if isFirst then
        --播放完首次动画后默认跳过动画
        isSkip = true
        XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), isSkip)
    end
    if not self._LottoUiData.IsAfterFirstEnable and (isFirst or not isSkip) then
        XDataCenter.LottoManager.SetFirstAnim(self._LottoGroupData:GetId(), true)
        self:PlayAnimationWithMask("AnimEnableLong")
        self._Scene:PlayLongEnableAnim()
    else
        local animName = "AnimEnableShort"
        if self._LottoUiData.IsAfterDraw then
            animName = "UiEnable"
        end
        self._LottoUiData.IsAfterDraw = false
        self:PlayAnimation(animName, function()
            -- 原因参考XUiLottoKarenina:PlayShortEnableAnim()
            self:ShowRewardDialog()
        end)
        self._Scene:PlayShortEnableAnim()
    end
    if not self._LottoUiData.IsAfterFirstEnable then
        self._LottoUiData.IsAfterFirstEnable = true
    end
end

function XUiLottoVera:PlayDrawAnim(timelineName)
    if not timelineName then
        self:_FinishDrawAnim()
        return
    end
    self._LottoUiData.IsAfterDraw = true
    self:PlayAnimation("UiDisable")
    self._Scene:PlayDrawAnim(timelineName)
end

function XUiLottoVera:SkipDrawAnim()
    XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_FINISH)
end

function XUiLottoVera:_FinishDrawAnim()
    XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_FINISH)
end
--endregion

--region Ui - BtnListener
function XUiLottoVera:AddBtnListener()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))

    self.BtnDrawRule:AddEventListener(handler(self, self.OnBtnDrawRuleClick))
    self.BtnXiangqing:AddEventListener(handler(self, self.OnBtnRewardDetailClick))
    self.BtnShield:AddEventListener(handler(self, self.OnBtnSkipAnimClick))
    self.BtnVoice:AddEventListener(handler(self, self.OnBtnSetClick))
    self.BtnStory:AddEventListener(handler(self, self.OnBtnStageClick))
    --Draw
    self.BtnGo:AddEventListener(handler(self, self.OnBtnDrawClick))
    self.BtnSkip:AddEventListener(handler(self, self.SkipDrawAnim))

    if self.BtnChange then
        self.BtnChange:AddEventListener(handler(self, self.OnBtnChangeClick))
        self:RefreshBtnChange()
    end
end

function XUiLottoVera:RefreshBtnChange()
    if not self.BtnChange then return end
    local lottoId = self._LottoGroupData:GetDrawData():GetId()
    self.BtnChange.gameObject:SetActiveEx(XDataCenter.LottoManager.IsLottoIdBelongSelfChoice(lottoId))
end

function XUiLottoVera:OnBtnChangeClick()
    -- 必须先翻 Entrance.IsChangeMode 再 Close，否则 Entrance.OnEnable 会因 dic 已选直接 CloseImmediately
    XDataCenter.LottoManager.OpenSelfChoiceEntranceForChange()
    self:Close()
end

function XUiLottoVera:OnBtnBackClick()
    -- 自选卡池：直接回主界面（Entrance 由 RunMain 一并关闭）
    local lottoId = self._LottoGroupData:GetDrawData():GetId()
    if XDataCenter.LottoManager.IsLottoIdBelongSelfChoice(lottoId) then
        XLuaUiManager.RunMain()
        return
    end
    self:Close()
end

function XUiLottoVera:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

--- 说明界面(奖励详情)
function XUiLottoVera:OnBtnRewardDetailClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData, 1, XEnumConst.Lotto.Vera)
end

--- 说明界面
function XUiLottoVera:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiLottoLog", self._LottoGroupData, 2, XEnumConst.Lotto.Vera)
end

--- 声音设置
function XUiLottoVera:OnBtnSetClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Setting) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnSet)
    XLuaUiManager.Open("UiSet", false)
end

--- 动画跳过
function XUiLottoVera:OnBtnSkipAnimClick()
    local state = self.BtnShield:GetToggleState()
    XDataCenter.LottoManager.SetSkipAnim(self._LottoGroupData:GetId(), state)
end

--- 进入三头犬
function XUiLottoVera:OnBtnStageClick()
    if XLuaUiManager.IsUiLoad("UiCerberusGameMainV2P9") then
        self:Close()
    else
        XDataCenter.FunctionalSkipManager.OnOpenCerberusGame()
    end
end
--endregion

--region Scene
function XUiLottoVera:InitScene()
    if not self.UiSceneInfo then
        return
    end
    local XUiLottoSceneVera = require("XUi/XUiLotto/Scene/XUiLottoSceneVera")
    ---@type XUiLottoSceneVera
    self._Scene = XUiLottoSceneVera.New(self.UiModelGo.transform, self, self.UiSceneInfo)
end
--endregion

--region Draw
function XUiLottoVera:InitDraw()
    local XUiLottoDrawControl = require("XUi/XUiLotto/Draw/XUiLottoDrawControl")
    ---@type XUiLottoDrawControl
    self._DrawControl = XUiLottoDrawControl.New(self.Transform, self, self._LottoGroupData)
end

function XUiLottoVera:ShowRewardDialog()
    self._DrawControl:ShowRewardDialog(XEnumConst.Lotto.Vera)
end

function XUiLottoVera:OnBtnDrawClick()
    self._DrawControl:OnBtnDrawClick()
end

function XUiLottoVera:ShowDrawResult()
    self._DrawControl:ShowDrawResult()
end
--endregion

--region Event
function XUiLottoVera:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_AFTER_DRAW_RESULT_SHOW, self._AfterShowDrawResult, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_DRAW_ON_START, self.PlayDrawAnim, self)
    XEventManager.AddEventListener(XEventId.EVENT_LOTTO_DRAW_ON_FINISH, self.ShowDrawResult, self)
end

function XUiLottoVera:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_AFTER_BUY_DRAW_SKIP_TICKET, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_AFTER_DRAW_RESULT_SHOW, self._AfterShowDrawResult, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_DRAW_ON_START, self.PlayDrawAnim, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LOTTO_DRAW_ON_FINISH, self.ShowDrawResult, self)
end
--endregion

return XUiLottoVera