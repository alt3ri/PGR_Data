local XUiFunctionShowNode = require('XUi/XUiCommon/XUiFunctionShow/XUiFunctionShowNode')

---@class XUiGridActivityButton: XUiNode
local XUiGridActivityButton = XClass(XUiFunctionShowNode, "XUiGridActivityButton")

function XUiGridActivityButton:OnStart(config, rootUi)
    self:Init(config, rootUi)
end

---@param config XTableActivityBtn
---@param rootUi XLuaUi
function XUiGridActivityButton:Init(config, rootUi)
    self.Config = config
    self.GameObject.name = string.format("GridBtnActivity%d", config.Id)
    self.RootUi = rootUi
   -- 名字/icon 海外主界面活动标题加换行
    local name = self.Config.Name
    local nameEN = self.Config.NameEN
    if not string.IsNilOrEmpty(name) then
        name = string.gsub(name, "\\n", "\n")
    end
    if not string.IsNilOrEmpty(nameEN) then
        nameEN = string.gsub(nameEN, "\\n", "\n")
    end
    self.Btn:SetNameByGroup(0, name)
    self.Btn:SetNameByGroup(1, nameEN)
    self.Btn:SetRawImage(self.Config.BtnIcon)
    -- 红点注册
    self._IsDailyRedPoint = false
    self._DailyRedPointKey = nil
    self._IsOnceRedPoint = false
    self._OnceRedPointKey = nil
    local reds = self.Config.RedPointConditions
    if not XTool.IsTableEmpty(reds) then
        local realReds = {}
        for k, v in pairs(reds) do
            local redPointKey = XRedPointConditions.Types[v]
            table.insert(realReds, redPointKey)
            if XMVCA.XDailyReset:IsDailyResetRedPoint(redPointKey) then
                self._IsDailyRedPoint = true
                self._DailyRedPointKey = string.format("%s_ActivityBtn_%s", XPlayer.Id, self.Config.Id)
            elseif redPointKey == XRedPointConditions.Types.CONDITION_ACTIVITY_BTN_ONCE then
                self._IsOnceRedPoint = true
                self._OnceRedPointKey = XMVCA.XUiMain:GetActivityBtnIdentityKey(self.Config)
            end
        end
        -- 红点条件只接受一个 key：Once 优先于 Daily
        -- 同按钮同时配 Daily 与 Once 为非常驻边界情形，二者 key 空间不兼容会冲突，不在此覆盖
        self.RedId = self:AddRedPointEvent(self.Btn.ReddotObj, self.CheckRed, self, realReds, self._OnceRedPointKey or self._DailyRedPointKey)
    end

    -- 特效
    if self.Config.Effect1 then
        self.EffectGo1 = self.Effect1:LoadPrefab(self.Config.Effect1)
    end
    if self.Config.Effect2 then
        self.EffectGo2 = self.Effect2:LoadPrefab(self.Config.Effect2)
    end

    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
    
    -- 扩展，使用对应系统自己的UI控件来实现额外的逻辑
    if not string.IsNilOrEmpty(self.Config.ManagerName) then
        local cls = nil
        if self.Config.IsAgency then
            local agency = XMVCA:GetAgency(self.Config.ManagerName)

            if agency and agency.ExGetUIActivityBtnCls then
                cls = agency:ExGetUIActivityBtnCls()
            end
        else
            local manager = XDataCenter[self.Config.ManagerName]
            
            if manager and manager.ExGetUIActivityBtnCls then
                cls = manager.ExGetUIActivityBtnCls()
            end
        end

        if cls and CheckIsClass(cls) then
            self.ExNode = cls.New(self.GameObject, self, self.RootUi)
        end
    end
end

function XUiGridActivityButton:OnBtnClick()
    local skipId = self.Config.SkipId
    if not skipId or skipId == 0 then
        return
    end
    local activityId = self.Config.Id or 0
    if activityId > 0 and not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.MainLeftTopActivity, activityId) then
        return
    end

    XUiHelper.RecordBuriedSpotTypeLevelOne(1000 + self.Config.Id)
    XFunctionManager.SkipInterface(skipId)
    if self._IsDailyRedPoint then
        XMVCA.XDailyReset:SaveDailyRedPoint(self._DailyRedPointKey)
        if self.RedId then
            XRedPointManager.Check(self.RedId)
        end
    end
    if self._IsOnceRedPoint then
        XMVCA.XUiMain:SaveActivityBtnRedOnceClicked(self._OnceRedPointKey)
        if self.RedId then
            XRedPointManager.Check(self.RedId)
        end
    end
end

function XUiGridActivityButton:OnEnable()
    if self.RedId then
        XRedPointManager.Check(self.RedId)
    end
end

function XUiGridActivityButton:CheckRed(count)
    self.Btn:ShowReddot(count >= 0)
end

function XUiGridActivityButton:InitEvent(fun)
    -- 红点事件
    if not string.IsNilOrEmpty(self.Config.RedPointRefreshEventId) then
        XEventManager.AddEventListener(self.Config.RedPointRefreshEventId, self.RefreshReddotShow, self)
    end
    
    if not fun then
        return
    end
    self.EventFun = function()
        fun()
    end

    local eventId = self.Config.EventId
    if not eventId then
        return
    end

    XEventManager.AddEventListener(eventId, self.EventFun, self)
end

-- 两种方式激活：
-- 1.Ui初始化时检查check
-- 2.监听事件检查check
function XUiGridActivityButton:CheckShow()
    local isShow = XMVCA.XUiMain:CheckActivityBtnShow(self.Config)
    if isShow then
        self:Open()
    else
        self:Close()
    end

    return isShow
end

function XUiGridActivityButton:RefreshReddotShow()
    if self:IsNodeShow() then
        if XTool.IsNumberValid(self.RedId) then
            XRedPointManager.Check(self.RedId)
        end
    end
end

function XUiGridActivityButton:RefreshByTimeUpdate()
    if not self.Config then
        return
    end

    -- 刷新倒计时
    -- 如果有leftTime字段 优先用leftTime，否则不显示
    local text = ""
    if self.Config.LeftTimeFun then
        text = XMVCA.XLeftTime:GetLeftTimeByFunName(self.Config.LeftTimeFun, self.Config.TimeId)
    end

    self.Btn:SetNameByGroup(2, text)
end

function XUiGridActivityButton:OnRelease()
    if not string.IsNilOrEmpty(self.Config.RedPointRefreshEventId) then
        XEventManager.RemoveEventListener(self.Config.RedPointRefreshEventId, self.RefreshReddotShow, self)
    end
    
    local eventId = self.Config.EventId
    if not eventId or not self.EventFun then
        return
    end
    XEventManager.RemoveEventListener(eventId, self.EventFun, self)
end

return XUiGridActivityButton