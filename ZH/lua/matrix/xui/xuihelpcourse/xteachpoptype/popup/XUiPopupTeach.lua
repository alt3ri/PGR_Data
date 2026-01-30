local XUiPopTeachContent = require("XUi/XUiHelpCourse/XTeachPopType/Common/XUiPopTeachContent")

---@class XUiPopupTeach : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field PanelTeachContent UnityEngine.RectTransform
local XUiPopupTeach = XLuaUiManager.Register(XLuaUi, "UiPopupTeach")

function XUiPopupTeach:OnAwake()
    ---@type XUiPopTeachContent
    self._ContentUi = XUiPopTeachContent.New(self.PanelTeachContent, self, handler(self, self.OnTeachClickEvent))
    ---@type XUiComponent.XGesture.XUiGestureInputHandler
    self._GestureHandler = self.GameObject:AddComponent(typeof(CS.XUiComponent.XGesture.XUiGestureInputHandler))
    self:_RegisterButtonClicks()
    
    ---@param data Lean.Touch.LeanFinger
    self._GestureHandler.onFingerUp = handler(self, self._OnGestureHandlerFingerUpEvent)
    
    self._DragLimit = CS.XGame.ClientConfig:GetInt('PopupTeachDragLimit') or 100
    self._HorizontalDragAngleLimit = CS.XGame.ClientConfig:GetInt('PopupTeachDragAngleLimit') or 30
end

function XUiPopupTeach:OnStart(config, cb, jumpIndex, closeCb)
    ---@type XTableHelpCourse
    self.Config = config
    self.Cb = cb
    self.JumpIndex = jumpIndex
    self.CloseCb = closeCb
    self.ImageCount = #self.Config.ImageAsset

    self.BtnClose.gameObject:SetActiveEx(false)
    
    self._ContentUi:Refresh(self.Config, jumpIndex)
end

function XUiPopupTeach:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiPopupTeach:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiPopupTeach:OnDestroy()

end

-- region 按钮事件

function XUiPopupTeach:OnBtnTanchuangCloseClick()
    -- 与UiHelper逻辑一致
    if self.Cb then
        self.Cb()
    end
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

-- endregion

-- region 私有方法

function XUiPopupTeach:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
end

function XUiPopupTeach:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiPopupTeach:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiPopupTeach:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiPopupTeach:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiPopupTeach:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

---@param leanFinger Lean.Touch.LeanFinger
function XUiPopupTeach:_OnGestureHandlerFingerUpEvent(leanFinger)
    -- 将屏幕坐标转换为UI画布坐标，防止因屏幕尺寸分辨率引起的不一致
    local startHasValue, uiStartPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.Transform, leanFinger.StartScreenPosition, CS.XUiManager.Instance.UiCamera)
    local lastHasValue, uiLastPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.Transform, leanFinger.LastScreenPosition, CS.XUiManager.Instance.UiCamera)

    if startHasValue and lastHasValue then
        local diffVec2 = uiLastPos - uiStartPos

        if diffVec2.x < -self._DragLimit then
            -- 手势向左, 计算与向量left的夹角
            local angle = XLuaVector2.Angle(-1, 0, diffVec2.x, diffVec2.y)

            if angle <= self._HorizontalDragAngleLimit then
                self._ContentUi:TryMoveNextByHand()
            end
        end

        if diffVec2.x > self._DragLimit then
            -- 手势向右，计算与向量right的夹角
            local angle = XLuaVector2.Angle(1, 0, diffVec2.x, diffVec2.y)
            if angle <= self._HorizontalDragAngleLimit then
                self._ContentUi:TryMoveLastByHand()
            end
        end
    end
end

function XUiPopupTeach:OnTeachClickEvent(curIndex)
    local isFinal = curIndex >= self.ImageCount
    
    self.BtnClose.gameObject:SetActiveEx(isFinal)
end

-- endregion

return XUiPopupTeach
