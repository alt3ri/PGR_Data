--- 通用的滑动列表聚焦控制
---@class XUiPBRStageListScrollView: XUiNode
---@field ScrollView UnityEngine.UI.ScrollRect
local XUiPBRStageListScrollView = XClass(XUiNode, 'XUiPBRStageListScrollView')

function XUiPBRStageListScrollView:OnStart(ScrollView)
    self.ScrollView = ScrollView or self.ScrollView
    self.UiMaskKey = 'ScrollFocus_' .. tostring(self)
    self._FuncOnScrollValueChaned = nil
    self._FuncOnScrollViewClick = nil
    self._FuncScrollMoveCallBack = nil
end

function XUiPBRStageListScrollView:OnDestroy()
    self:ClearSelfUiMask()
end

function XUiPBRStageListScrollView:Init()
    -- 滑动边界值
    self.HalfViewPortWidth = math.abs(self.ScrollView.viewport.rect.width / 2)
    self.HalfViewPortHeight = math.abs(self.ScrollView.viewport.rect.height / 2)
    
    CS.XUiHelper.RegisterClickEvent(self.ScrollView, handler(self, self.OnScrollViewClick))
    self.ScrollView.onValueChanged:AddListener(handler(self, self.OnScrollValueChanged))
    
    self:InitMoveParams()
end

function XUiPBRStageListScrollView:InitMoveParams(moveDuration)
    -- 没有参数的话默认从配置里借用一个
    self.MoveDuration = moveDuration or CS.XGame.ClientConfig:GetFloat('KotodamaActivityStageMoveDuration')
end

function XUiPBRStageListScrollView:RegisterCallBack(scrollValueChangedCb, scrollClickCb, scrollMoveCb)
    self._FuncOnScrollValueChaned = scrollValueChangedCb
    self._FuncOnScrollViewClick = scrollClickCb
    self._FuncScrollMoveCallBack = scrollMoveCb
end

--- 滑动窗滑动时的事件
function XUiPBRStageListScrollView:OnScrollValueChanged(vec2)
    if self._ScrollLastPosX == nil then
        self._ScrollLastPosX = vec2.x
    end
    -- 控制触发的滑动距离
    if math.abs(vec2.x - self._ScrollLastPosX) < 0.1 then
        return
    else
        self._ScrollLastPosX = vec2.x
    end

    if self._FuncOnScrollValueChaned then
        self._FuncOnScrollValueChaned(vec2)
    end
end

--- 点击滑动窗空白处事件
function XUiPBRStageListScrollView:OnScrollViewClick()
    if self._FuncOnScrollViewClick then
        self._FuncOnScrollViewClick()
    end
end

--- 通用移动方法
function XUiPBRStageListScrollView:PlayScrollViewMove(targetPosX, targetPosY, isElastic, tmpCb)
    -- 移动前设置状态，忽略界限对移动的影响
    self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

    local targetPos = self.ScrollView.content.localPosition
    
    targetPos.x = targetPosX and targetPosX or targetPos.x
    targetPos.y = targetPosY and targetPosY or targetPos.y
    
    XLuaUiManager.SetMask(true, self.UiMaskKey)
    
    self.ScrollView.inertia = false
    self._IsScrollMoving = true
    
    XUiHelper.DoMove(self.ScrollView.content, targetPos, self.MoveDuration, XUiHelper.EaseType.Sin, function()
        if isElastic then
            self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        else
            self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        end

        XLuaUiManager.SetMask(false, self.UiMaskKey)
        
        self._IsScrollMoving = false
        self.ScrollView.inertia = true

        if self._FuncScrollMoveCallBack then
            self._FuncScrollMoveCallBack()
        end
        
        -- 一次性的回调
        if tmpCb then
            tmpCb()
        end
    end)
end

--- 一键清空所有以自身为key的遮罩计数
function XUiPBRStageListScrollView:ClearSelfUiMask()
    if not self.UiMaskKey then
        return
    end
    
    while XLuaUiManager.IsMaskShow(self.UiMaskKey) do
        XLuaUiManager.SetMask(false, self.UiMaskKey)
    end
end

return XUiPBRStageListScrollView