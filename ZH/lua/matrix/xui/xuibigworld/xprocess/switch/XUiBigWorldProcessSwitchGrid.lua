---@class XUiBigWorldProcessSwitchGrid : XUiNode
---@field BtnGo XUiComponent.XUiButtonExt
---@field Parent XUiBigWorldProcessSwitch
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessSwitchGrid = XClass(XUiNode, "XUiBigWorldProcessSwitchGrid")

function XUiBigWorldProcessSwitchGrid:OnStart()
    ---@type XBWCourseVersionEntity
    self._VersionEntity = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessSwitchGrid:OnEnable()
end

function XUiBigWorldProcessSwitchGrid:OnDisable()
end

function XUiBigWorldProcessSwitchGrid:OnDestroy()
end

function XUiBigWorldProcessSwitchGrid:OnBtnGoClick()
    local isValid = self._VersionEntity:IsValid()

    if isValid then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_CHANGE_VERSION, self._VersionEntity)
        self.Parent:Close()
    else
        XMVCA.XBigWorldUI:TipMsg(self._VersionEntity:GetUnlockTip())
    end
end

---@param versionEntity XBWCourseVersionEntity
function XUiBigWorldProcessSwitchGrid:Refresh(versionEntity)
    self._VersionEntity = versionEntity
    self:_RefreshState()
end

function XUiBigWorldProcessSwitchGrid:TryRefreshValid(isCurrentValid)
    local isValid = self._VersionEntity:IsValid()

    if isCurrentValid ~= isValid then
        self.BtnGo:SetDisable(isValid)
    end

    return isValid
end

function XUiBigWorldProcessSwitchGrid:_RefreshState()
    if not self._VersionEntity then
        return
    end

    local isComplete = self._VersionEntity:IsComplete()

    self.BtnGo:SetNameByGroup(0, self._VersionEntity:GetName())
    self.BtnGo:SetNameByGroup(1, self._VersionEntity:GetProgressStr())
    self.BtnGo:ShowTag(isComplete)
    self.BtnGo:ActiveTextByGroup(1, not isComplete)
    self.BtnGo:ShowReddot(self._VersionEntity:IsNew())
    self.BtnGo:SetDisable(not self._VersionEntity:IsValid())
    self.BtnGo:SetRawImage(self._VersionEntity:GetSwitchIcon())
    self._VersionEntity:Record()
end

function XUiBigWorldProcessSwitchGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnGo:AddEventListener(Handler(self, self.OnBtnGoClick))
end

function XUiBigWorldProcessSwitchGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessSwitchGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessSwitchGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessSwitchGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessSwitchGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessSwitchGrid:_InitUi()
end

return XUiBigWorldProcessSwitchGrid
