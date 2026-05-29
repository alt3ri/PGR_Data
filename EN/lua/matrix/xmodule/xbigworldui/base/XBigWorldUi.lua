---@class XBigWorldUi : XLuaUi 大世界UI专用
---@field _IsPauseFight boolean 界面打开时是否暂停战斗
---@field _IsChangeInput boolean 界面打开时是否切换为系统输入
local XBigWorldUi = XClass(XLuaUi, "XBigWorldUi")

function XBigWorldUi:OnAwakeUi()
    self._IsPauseFight = XMVCA.XBigWorldUI:IsPauseFight(self.Name)
    self._IsChangeInput = XMVCA.XBigWorldUI:IsChangeInput(self.Name)
    self._CustomChangeInput = false
    self._IsHideFightUi = XMVCA.XBigWorldUI:IsHideFightUi(self.Name)
    self._IsCloseCameraControl = XMVCA.XBigWorldUI:IsCloseCameraControl(self.Name)

    if self._IsPauseFight then
        XMVCA.XBigWorldGamePlay:PauseFight()
    end

    if self._IsHideFightUi then
        XMVCA.XBigWorldGamePlay:SetFightUiActive(false)
    end

    XMVCA.XBigWorldUI:RecordOpenedBigWorldUi(self.Name)

    XLuaUi.OnAwakeUi(self)
end

function XBigWorldUi:OnDestroyUi()
    if self._IsPauseFight then
        XMVCA.XBigWorldGamePlay:ResumeFight()
    end

    if self._IsHideFightUi then
        XMVCA.XBigWorldGamePlay:SetFightUiActive(true)
    end

    -- 移除输入 销毁时再切换（不能再隐藏时切换，因为input section移除的时候要先处理再切换），打开新的会有覆盖
    -- 销毁的时候可以恢复设置，影响到移除input section的列表移除
    self:ChangeFightInput()

    XMVCA.XBigWorldUI:RemoveOpenedBigWorldUi(self.Name)

    XLuaUi.OnDestroyUi(self)
end

function XBigWorldUi:SetCameraControlStatus(isActive)
    if not self._IsCloseCameraControl then return end
    XFightUtil.SetCameraOpEnabled(isActive)
end

function XBigWorldUi:OnEnableUi(...)
    self:SetCameraControlStatus(false)
    XUiManager.AddControllerTips(self.Name)
    XLuaUi.OnEnableUi(self, ...)

    -- 设置输入
    self:ChangeSystemInput()
end

function XBigWorldUi:OnDisableUi(...)
    self:SetCameraControlStatus(true)
    XLuaUi.OnDisableUi(self, ...)
    XUiManager.RemoveControllerTips(self.Name)
end

function XBigWorldUi:ChangePauseFight(value)
    if value ~= self._IsPauseFight then
        if self._IsPauseFight then
            XMVCA.XBigWorldGamePlay:ResumeFight()
        else
            XMVCA.XBigWorldGamePlay:PauseFight()
        end
        self._IsPauseFight = value
    end
end

function XBigWorldUi:ChangeSystemInput()
    if self._IsChangeInput and not self._SysInputChange then
        self._SysInputChange = true
        XMVCA.XBigWorldGamePlay:ChangeSystemInput()
    end
end

function XBigWorldUi:ChangeFightInput()
    if self._IsChangeInput and self._SysInputChange then
        self._SysInputChange = false
        XMVCA.XBigWorldGamePlay:ChangeFightInput()
    end
end

function XBigWorldUi:ChangeInput(value)
    if value ~= self._CustomChangeInput then
        if self._CustomChangeInput then
            XMVCA.XBigWorldGamePlay:ChangeFightInput()
        else
            XMVCA.XBigWorldGamePlay:ChangeSystemInput()
        end
        self._CustomChangeInput = value
    end
end

function XBigWorldUi:ChangeHideFightUi(value)
    if value ~= self._IsHideFightUi then
        if self._IsHideFightUi then
            XMVCA.XBigWorldGamePlay:SetFightUiActive(true)
        else
            XMVCA.XBigWorldGamePlay:SetFightUiActive(false)
        end
        self._IsHideFightUi = value
    end
end

--- 向队列头插入一个UI，保证队列下个打开的一定是这个UI
function XBigWorldUi:InsertQueueBeforeClose(uiName, ...)
    if not string.IsNilOrEmpty(uiName) then
        XMVCA.XBigWorldUI:InsertHeaderAwaitUi(uiName, ...)
        self:Close()
    end
end

--- 修改当前Ui打开的Param， 便于动态判断是否阻塞后续弹窗
--- 对应BigWorldPopupUi的CustomModalityParams字段
function XBigWorldUi:ChangePopupUiArgByIndex(index, value)
    XMVCA.XBigWorldUI:ChangeUiDataArgByIndex(self.Name, index, value)
end

return XBigWorldUi
