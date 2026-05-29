---@class XUiGuideNew : XLuaUi
---@field Guide XGuide
---@field BtnPassStyleCtrl XUiComponent.XUiStateControl
local XUiGuideNew = XLuaUiManager.Register(XLuaUi, "UiGuide")
local XUiPanelGuideBubble = require('XUi/XUiGuide/XUiPanelGuideBubble')
local XUiPanelGuideBubbleWithHead = require('XUi/XUiGuide/XUiPanelGuideBubbleWithHead')

--V3.6 点击继续指引的 遮罩区域形式
XUiGuideNew.XUIGuideMaskClickAreaType = {
    ClickMaskArea = 0, --仅能点击遮罩内的区域
    ClickAnyWhere = 1, --能点击任意地方
}

local FocusStyle = {
    Base = 0, -- 默认样式框
    Bubble = 1, -- 气泡框
    BubbleWithHead = 2, -- 带头像的气泡框
}

local FocusStyleEnum2StateName = {
    [FocusStyle.Base] = 'BaseStyle',
    [FocusStyle.Bubble] = 'BubbleStyle',
    [FocusStyle.BubbleWithHead] = 'BubbleStyleBlack',
}

function XUiGuideNew:OnAwake()
    self:AutoAddListener()
    self.PanelInfoRect = self.PanelInfo
    self.PanelWarning.gameObject:SetActive(false)
    self.BtnSkip.gameObject:SetActive(false)
    self.BtnPass.gameObject:SetActive(false)
    self.PanelInfo.gameObject:SetActive(false)

    self.LastClickTime = 0
    self.ContinueClickTimes = 0
    self.ClickInterval = 0.5
    self.MaskClickAreaType = nil  --V3.6 增加点击区域设置
end

function XUiGuideNew:OnStart(targetImg, isWeakGuide, guideDesc, icon, name, callback, offsetX, offsetY, maskClickAreaType)
    --V3.6 增加点击区域设置  以防万一加个默认值
    self.MaskClickAreaType = maskClickAreaType
    if self.MaskClickAreaType == nil then
        self.MaskClickAreaType = 0
    end

    self.Guide = self.BtnPanelMaskGuide:GetComponent("XGuide")
    if (not self.Guide) then
        self.Guide = self.BtnPanelMaskGuide.gameObject:AddComponent(typeof(CS.XGuide))
    end
    self.Guide:SetPass(false)
    self.Guide:SetTimeText(self.TxtTime)
    self.Callback = callback
    self.IsWeakGuide = isWeakGuide
    
    --V3.7 点击区域是全屏时 0.5秒内点击无反应
    if(self.MaskClickAreaType == XUiGuideNew.XUIGuideMaskClickAreaType.ClickAnyWhere) then
        self:ShowBtnMask(true)
        self.Timer = XScheduleManager.ScheduleOnce(function()
            self:ShowBtnMask(false)
        end,  500)
    end
    
    if targetImg then
        CS.XGuideEventPass.IsPassEvent = true
        CS.XGuideEventPass.IsFightGuide = true
        CS.XGuideEventPass.IsPassAll = false
        self.IsFight = true
        self:ShowMarkNew(true, true)
        local anchor = CS.UnityEngine.Vector2(0, 1)
        self:ShowDialog(icon, name, guideDesc, anchor, anchor, CS.UnityEngine.Vector2(500 + offsetX, -380 + offsetY))
        self:FocusOnFightPanel(targetImg)
        
        self.UiWidget = self.BtnPass.gameObject:AddComponent(typeof(CS.XUiWidget))
        self.UiWidget:AddPointerDownListener(function(eventData)
            if self.SafeAreaContentPane then
                self.SafeAreaContentPane.gameObject:SetActive(false)
            else
                self.Transform:Find("SafeAreaContentPane").gameObject:SetActive(false)
            end

            if self.BtnPanelMaskGuide then
                self.BtnPanelMaskGuide:GetComponent("Image").enabled = false
            else
                self.Transform:Find("FullScreenBackground/BtnPanelMaskGuide"):GetComponent("Image").enabled = false
            end
            
            local bgUi = self.Transform:Find("FullScreenBackground/BtnPanelMaskGuide/BtnPass/BaseStyle/Bg")

            if not bgUi then
                bgUi = self.Transform:Find("FullScreenBackground/BtnPanelMaskGuide/BtnPass/Bg")
            end

            if bgUi then
                bgUi.gameObject:SetActive(false)
            end
        end)
        --V3.6 增加点击区域设置 
        self.UiWidget:AddPointerUpListener(function(eventData)
            self:OnBtnPassClick()
        end)

        local maskWidget = self.Transform:Find("FullScreenBackground/BtnPanelMaskGuide").gameObject:AddComponent(typeof(CS.XUiWidget))
        if maskWidget then
            maskWidget:AddPointerDownListener(function(eventData)
                local fight = CS.XFight.Instance
                fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
                fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
            end)
            --V3.6 增加点击区域设置 
            maskWidget:AddPointerUpListener(function(eventData)
                if(self.MaskClickAreaType == XUiGuideNew.XUIGuideMaskClickAreaType.ClickAnyWhere) then
                    self:OnBtnPassClick()
                end
            end)
        end
    end

    -- CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_GUIDE_FIGHT_BTNDOWN, function(evt, args)
    --     if self.Callback and not self.IsWeakGuide then
    --         self.Callback()
    --         self.Callback = nil
    --     end
    -- end)

    --- 初始化气泡框
    if self.PanelBubbleRoot then

        ---@type XUiPanelGuideBubble
        self.PanelBubbleRoot.gameObject:SetActiveEx(false)
        self.PanelBubble = XUiPanelGuideBubble.New(self.PanelBubbleRoot, self)
    end

    --- 初始化带头像气泡框
    if self.PanelBubbleRoot2 then
        self.PanelBubbleRoot2.gameObject:SetActiveEx(false)
        self.PanelBubble2 = XUiPanelGuideBubbleWithHead.New(self.PanelBubbleRoot2, self)
    end
end

function XUiGuideNew:OnDestroy()
    -- CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_FIGHT_BTNDOWN, function(evt, args)
    if self.Callback then
        self.Callback = nil
    end
    -- end)
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = false
    end
    
    self:SendCloseUiClick()
end

function XUiGuideNew:SendCloseUiClick()
    if not XMain.IsDebug or not XFightUtil.IsFighting() then
        return
    end

    local fight = CS.XFight.Instance
    if not fight or not fight.InputControl.SendCloseUiClick then
        return
    end

    fight.InputControl:SendCloseUiClick(CS.XCloseUiSpecialGameplay.UiType.Guide)
end

function XUiGuideNew:AutoAddListener()
    self:RegisterClickEvent(self.BtnPanelMaskGuide, self.OnBtnPanelMaskGuideClick, false, false)
    self:RegisterClickEvent(self.BtnPass, self.OnBtnPassClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end
-- auto
function XUiGuideNew:OnBtnSkipClick()
    self.PanelWarning.gameObject:SetActive(true)
    XDataCenter.GuideManager.RecordBuryingPoint(XDataCenter.GuideManager.BuryingPointType.Click)
end

function XUiGuideNew:OnBtnConfirmClick()
    XDataCenter.GuideManager.ReqCompleteGuideGroup(function()
        XDataCenter.GuideManager.RecordBuryingPoint(XDataCenter.GuideManager.BuryingPointType.Skip)
        XDataCenter.GuideManager.ResetGuide()
        XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
        
        -- 新增指引跳过事件
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_SKIP)
    end)
end

function XUiGuideNew:CheckDouble()
    if XTime.GetServerNowTimestamp() - self.LastClickTime > self.ClickInterval then
        self.ContinueClickTimes = 0
    else
        self.ContinueClickTimes = self.ContinueClickTimes + 1
    end

    if self.ContinueClickTimes == 3 then
        self.ContinueClickTimes = 0
        self.BtnSkip.gameObject:SetActive(true)
        XDataCenter.GuideManager.RecordBuryingPoint(XDataCenter.GuideManager.BuryingPointType.Trigger)
    end

    self.LastClickTime = XTime.GetServerNowTimestamp()
end

function XUiGuideNew:OnBtnCancelClick()
    self.PanelWarning.gameObject:SetActive(false)
end

function XUiGuideNew:OnBtnPassClick()
    if self.Guide:IsRespondPassClick() then
        self.Guide:Reset()

        if self.Callback and not self.IsWeakGuide then
            self.Callback()
            self.Callback = nil
        end
    end
end

function XUiGuideNew:OnBtnPanelMaskGuideClick()
    if not XDataCenter.GuideManager.CheckIsFightGuide() and not CS.XGuideEventPass.IsFightGuide then
        self:CheckDouble()
    end

    CsXGameEventManager.Instance:Notify(CS.XEventId.EVENT_GUIDE_ANYCLICK)
end

--显示头像
function XUiGuideNew:ShowDialog(icon, name, content, anchorMax, anchorMin, position)
    self.PanelInfo.gameObject:SetActive(true)
    self:SetUiSprite(self.ImgRole, icon)
    self.TxtName.text = name or ""
    self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(content)

    self.PanelInfoRect.anchorMax = anchorMax
    self.PanelInfoRect.anchorMin = anchorMin
    self.PanelInfoRect.anchoredPosition = position
end

--隐藏头像
function XUiGuideNew:HideDialog()
    self.PanelInfo.gameObject:SetActive(false)
end

--聚焦panel
function XUiGuideNew:FocusOnPanel(panel, eulerAngles, passEvent, sizeDelta, offset, passAll, focusStyle, bubbleIndex, bubbleTextId, bubblePosOffset, imgIconId)
    eulerAngles = eulerAngles or CS.UnityEngine.Vector3.zero
    sizeDelta = sizeDelta or CS.UnityEngine.Vector2.zero
    offset = offset or CS.UnityEngine.Vector2.zero
    self.BtnPass.gameObject:SetActive(true)
    self.BtnPass.gameObject.transform.eulerAngles = eulerAngles
    self.Guide:SetTarget(panel, sizeDelta, offset)

    if not XTool.UObjIsNil(panel.gameObject) then
        CS.XGuideEventPass.Target = panel.gameObject
    end

    CS.XGuideEventPass.IsPassEvent = passEvent
    CS.XGuideEventPass.IsPassAll = passAll
    if self.AniGuideJiaoLoop then
        self.AniGuideJiaoLoop.gameObject:SetActive(false)
        self.AniGuideJiaoLoop.gameObject:SetActive(true)
    end

    focusStyle = focusStyle or FocusStyle.Base

    if self.BtnPassStyleCtrl then
        self.BtnPassStyleCtrl:ChangeState(FocusStyleEnum2StateName[focusStyle])
    end

    if focusStyle == FocusStyle.Bubble then
        local textCfg = XDataCenter.GuideManager.GetGuideTextTemplate(bubbleTextId)

        if not textCfg or string.IsNilOrEmpty(textCfg.Content) then
            XLog.Error('无效文本，切换回默认样式')

            if self.BtnPassStyleCtrl then
                self.BtnPassStyleCtrl:ChangeState(FocusStyleEnum2StateName[FocusStyle.Base])
                return
            end
        end

        if self.PanelBubble then
            self.PanelBubble:Open()
            self.PanelBubble:ShowBubble(bubbleIndex, textCfg, bubblePosOffset)
        end
        if self.PanelBubble2 then
            self.PanelBubble2:Close()
        end
    elseif focusStyle == FocusStyle.BubbleWithHead then
        local textCfg = XDataCenter.GuideManager.GetGuideTextTemplate(bubbleTextId)

        if not textCfg or string.IsNilOrEmpty(textCfg.Content) then
            XLog.Error('无效文本，切换回默认样式')

            if self.BtnPassStyleCtrl then
                self.BtnPassStyleCtrl:ChangeState(FocusStyleEnum2StateName[FocusStyle.Base])
            end
            return
        end

        if self.PanelBubble then
            self.PanelBubble:Close()
        end
        if self.PanelBubble2 then
            self.PanelBubble2:Open()
            self.PanelBubble2:ShowBubble(bubbleIndex, textCfg, bubblePosOffset, imgIconId)
        end
    else
        if self.PanelBubble then
            self.PanelBubble:Close()
        end
        if self.PanelBubble2 then
            self.PanelBubble2:Close()
        end
    end
end

function XUiGuideNew:FocusOn3DPanel(camera, panel, offset, eulerAngles, passEvent, sizeDelta)
    
    eulerAngles = eulerAngles or CS.UnityEngine.Vector3.zero
    sizeDelta = sizeDelta or CS.UnityEngine.Vector2.zero
    self.BtnPass.gameObject:SetActive(true)
    self.BtnPass.gameObject.transform.eulerAngles = eulerAngles
    self.Guide:SetTarget(panel, camera, sizeDelta, offset)

    if not XTool.UObjIsNil(panel.gameObject) then
        CS.XGuideEventPass.Target = panel.gameObject
    end

    CS.XGuideEventPass.IsPassEvent = passEvent
    if self.AniGuideJiaoLoop then
        self.AniGuideJiaoLoop.gameObject:SetActive(false)
        self.AniGuideJiaoLoop.gameObject:SetActive(true)
    end
end

function XUiGuideNew:FocusOnFightPanel(panel)
    self.BtnPass.gameObject:SetActive(true)
    self.Guide:SetTarget(panel, CS.UnityEngine.Vector2.zero)
    CS.XGuideEventPass.Target = nil
end

--显示遮罩
function XUiGuideNew:ShowMark(isShowMask, isShowRay)
    self.PanelMaskAll.gameObject:SetActive(isShowMask)
    self.BtnPanelMaskGuide.gameObject:SetActive(true)
    self.Guide:SetPass(not isShowMask)
end


--显示遮罩
function XUiGuideNew:ShowMarkNew(isShowMask, isShowRay)
    self.PanelMaskAll.gameObject:SetActive(isShowMask)
    self.BtnPanelMaskGuide.gameObject:SetActive(isShowRay)
    self.Guide:SetPass(not isShowMask)
end

function XUiGuideNew:ShowBtnMask(Enable)
    self.BtnMaskAll.gameObject:SetActive(Enable)
end 

function XUiGuideNew:ShowDragFromToPanel(fromTransform, fromOffset, toTransform, toOffset, passType)
    self.Guide:SetPass(false)
    self.Guide:SetDragFromTo(fromTransform, fromOffset, toTransform, toOffset, passType)
    self.BtnPass.gameObject:SetActive(true)
    CS.XGuideEventPass.IsPassEvent = true   
end

function XUiGuideNew:ResetDragPanel()
    self.Guide:Reset()
    self.Guide:ResetDragPanel()
end

