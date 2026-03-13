--- 愚人节看板界面飘窗播报
---@class XUiMainAprilFoolsToastHall: XLuaUi
---@field _Control XAprilFoolDayControl
local XUiMainAprilFoolsToastHall = XLuaUiManager.Register(XLuaUi, 'UiMainAprilFoolsToastHall')
local MathLerp = CS.UnityEngine.Mathf.Lerp

function XUiMainAprilFoolsToastHall:OnStart(id)
    self.Id = id

    local cfg = self._Control:GetFoolsDayActivityBroadcastCfgById(self.Id)

    if cfg then
        self:ShowMainTip(cfg)
        
        --todo czy 根据配置的UI样式，切换不同的Ui显示，等UI正式后再处理
    end
end

function XUiMainAprilFoolsToastHall:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.CloseMainTip, self)
end

function XUiMainAprilFoolsToastHall:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.CloseMainTip, self)
end

function XUiMainAprilFoolsToastHall:CloseMainTip()
    -- 直接移除自己
    XLuaUiManager.Remove('UiMainAprilFoolsToastHall')
end

---@param cfg XTableFoolsDayActivityBroadcast
function XUiMainAprilFoolsToastHall:ShowMainTip(cfg)
    self.PanelMain.gameObject:SetActiveEx(true)
    self:StopTweener(self._MainMoveTimer)
    self:StopTweener(self._MainWaitTimer)
    self.Txt.text = cfg.Content
    
    local moveDuration = cfg.TipMoveDuration
    local stayTime = cfg.TipStayTime

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content)
    local startPosX = self.Viewport.rect.width + self.Content.rect.width
    local endPosX = 0
    self.Content.anchoredPosition = Vector2(startPosX, 0)
    self._MainMoveTimer = XUiHelper.Tween(moveDuration, function(t)
        if not self.Content:Exist() then
            return true
        end
        self.Content.anchoredPosition = Vector2(MathLerp(startPosX, endPosX, t), 0)
    end, function()
        self._MainWaitTimer = XScheduleManager.ScheduleOnce(function() 
            -- 关闭自己
            self:Close()
            -- 尝试打开下一个
            XMVCA.XAprilFoolDay:TryPopTips()
        end, stayTime)
        self:_AddTimerId(self._MainWaitTimer)
    end)
    self:_AddTimerId(self._MainMoveTimer)
end

return XUiMainAprilFoolsToastHall