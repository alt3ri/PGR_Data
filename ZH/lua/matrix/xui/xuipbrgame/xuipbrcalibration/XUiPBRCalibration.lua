---
---@class XUiPBRCalibration: XLuaUi
---@field protected _Control XPBRGameControl
---@field PanelTab XUiButtonGroup 页签选项组
---@field BtnTab1 XUiComponent.XUiButton 手动调节页签
---@field BtnTab2 XUiComponent.XUiButton 自动调节页签
---@field PanelAdjustment @手动调节子界面
---@field PanelAuto @自动调节子界面
local XUiPBRCalibration = XLuaUiManager.Register(XLuaUi, "UiPBRCalibration")

local XUiPanelPBRAdjustment = require("XUi/XUiPBRGame/XUiPBRCalibration/XUiPanelPBRAdjustment")
local XUiPanelPBRAuto = require("XUi/XUiPBRGame/XUiPBRCalibration/XUiPanelPBRAuto")

--region Ui生命周期

function XUiPBRCalibration:OnAwake()
    self:BindExitBtns()
    self.BtnSoundSet:AddEventListener(function()
        XLuaUiManager.Open("UiSet", false)
    end)

    ---@type XUiPanelPBRAdjustment
    self._PanelAdjustment = XUiPanelPBRAdjustment.New(self.PanelAdjustment, self)
    ---@type XUiPanelPBRAuto
    self._PanelAuto = XUiPanelPBRAuto.New(self.PanelAuto, self)

    self.PanelTab:Init({self.BtnTab1, self.BtnTab2}, handler(self, self.OnTabSelect))
end

function XUiPBRCalibration:OnStart()
    -- 界面打开即播放校准 BGM（首次打开：先缓存配置再由 SelectIndex 触发面板读取，保证顺序）
    local calibrateCtrl = self._Control.CalibrateControl
    calibrateCtrl:StartCalibration(calibrateCtrl:GetCalibrateBgmId())
    self.PanelTab:SelectIndex(1)
end

function XUiPBRCalibration:OnEnable()
    -- 从设置界面返回时重新播放校准 BGM（同曲短路保证首次不会重复播放）
    local calibrateCtrl = self._Control.CalibrateControl
    calibrateCtrl:StartCalibration(calibrateCtrl:GetCalibrateBgmId())
end

function XUiPBRCalibration:OnDisable()
    -- 跳转设置等界面隐藏时停止校准 BGM，与 OnEnable 成对
    self._Control.CalibrateControl:StopCalibration()
end

function XUiPBRCalibration:OnTabSelect(index)
    -- 先隐后显：确保旧面板 StopCalibration 先于新面板 StartCalibration
    if index == 1 then
        self._PanelAuto:SetVisible(false)
        self._PanelAdjustment:SetVisible(true)
    else
        self._PanelAdjustment:SetVisible(false)
        self._PanelAuto:SetVisible(true)
    end
end

function XUiPBRCalibration:OnDestroy()
    -- 界面关闭时停止播放（兜底，OnDisable 一般已停）
    self._Control.CalibrateControl:StopCalibration()
end

--endregion

return XUiPBRCalibration
