local XUiGoldenMinerDisplayTitleGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerDisplayTitleGrid")
local XUiPanelGoldenMinerSuspendList = require('XUi/XUiGoldenMiner/Game/UiSuspend/XUiPanelGoldenMinerSuspendList')

---@class XUiGoldenMinerSuspend : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerSuspend = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerSuspend")

function XUiGoldenMinerSuspend:OnAwake()
    self:AddBtnClickListener()
end

function XUiGoldenMinerSuspend:OnStart(closeCallback, sureCallback, isOnHex)
    self._CloseCallback = closeCallback
    self._SureCallback = sureCallback

    self:UpdateHex()
    self:UpdateDisplayCommonHex()
    
    -- 没有商店了，不显示道具及其buff
    --self:UpdateItem()
    --self:UpdateItemBuff()

    self.PanelOverview.gameObject:SetActiveEx(isOnHex)
    self.PanelStop.gameObject:SetActiveEx(not isOnHex)
    
    if isOnHex then
        if self.TxtReport then
            self.TxtReport.text = XUiHelper.GetText("GoldenMinerShipDetailTitle")
        end
    end
    self.PanelResources.gameObject:SetActiveEx(false)
    self.ListChange.gameObject:SetActiveEx(false)

    if self.PanelNothing then
        self.PanelNothing.gameObject:SetActiveEx(false)
    end
end

function XUiGoldenMinerSuspend:OnEnable()
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.System)
end

function XUiGoldenMinerSuspend:OnDisable()
    XDataCenter.InputManagerPc.ResumeCurInputMap()
end

--region Ui - UpdateDisplayHex
function XUiGoldenMinerSuspend:UpdateHex()
    local hexList = self._Control:GetSelectedCoreHexList()
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.HEX)

    if not XTool.IsTableEmpty(hexList) then
        local grid = self:_CreateDescObj()
        grid:RefreshHexShow(hexList, nil, true)
    else
        self:_CreateNothingObj()
    end
end
--endregion

--region Ui - UpdateDisplayItem
function XUiGoldenMinerSuspend:UpdateItem()
    local buffList = self._Control:GetDisplayItemList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.ITEM)
    local grid = self:_CreateDescObj()
    grid:RefreshBuffShow(buffList)
end
--endregion

--region Ui - UpdateDisplayItemBuff
function XUiGoldenMinerSuspend:UpdateItemBuff()
    local buffList = self._Control:GetDisplayBuffList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.BUFF)
    local grid = self:_CreateDescObj()
    grid:RefreshBuffShow(buffList)
end
--endregion

--region Ui - UpdateDisplayCommonHex

function XUiGoldenMinerSuspend:UpdateDisplayCommonHex()
    local hexList = self._Control:GetSelectedCommonHexList()
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.BUFF)

    if not XTool.IsTableEmpty(hexList) then
        local grid = self:_CreateDescObj()
        grid:RefreshHexShow(hexList, nil, true)
    else
        self:_CreateNothingObj()
    end
end

--endregion

--region Ui - CreateUiObj
function XUiGoldenMinerSuspend:_CreateTitleObj(type)
    local grid = XUiGoldenMinerDisplayTitleGrid.New(XUiHelper.Instantiate(self.PanelResources.gameObject, self.PanelResources.transform.parent),
            self,
            self._Control:GetClientTxtDisplayMainTitle(type),
            self._Control:GetClientTxtDisplaySecondTitle(type))
    grid:Open()
end

function XUiGoldenMinerSuspend:_CreateDescObj()
    local grid = XUiPanelGoldenMinerSuspendList.New(XUiHelper.Instantiate(self.ListChange.gameObject, self.ListChange.transform.parent), self)
    grid:Open()
    
    return grid
end

function XUiGoldenMinerSuspend:_CreateNothingObj()
    if self.PanelNothing then
        local go = XUiHelper.Instantiate(self.PanelNothing.gameObject, self.PanelNothing.transform.parent)

        go:SetActiveEx(true)

        return go
    end
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerSuspend:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnCloseClick)

    if self.BtnBack then
        self:RegisterClickEvent(self.BtnBack, self.OnBtnCloseClick)
    end
end

function XUiGoldenMinerSuspend:OnBtnCloseClick()
    self:Close()
    if self._CloseCallback then
        self._CloseCallback()
    end

    self._CloseCallback = nil
    self._SureCallback = nil
end

function XUiGoldenMinerSuspend:OnBtnExitClick()
    self:Close()
    if self._SureCallback then
        self._SureCallback()
    end

    self._CloseCallback = nil
    self._SureCallback = nil
end
--endregion