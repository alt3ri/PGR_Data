---@class XUiGachaBiankaLog : XLuaUi
local XUiGachaBiankaLog = XLuaUiManager.Register(XLuaUi, "UiGachaBianka402Log")

function XUiGachaBiankaLog:OnAwake()
    self._PanelDic = {}
    self._PanelDataDic = {
        [1] = require("XUi/XUiGachaBianka/Grid/XUiPanelGachaBiankaReward"), -- 奖励详情
        [2] = require("XUi/XUiGachaBianka/Grid/XUiPanelGachaBiankaRule"), -- 基础规则
        [3] = require("XUi/XUiGachaBianka/Grid/XUiPanelGachaBiankaDetail"), -- 掉落详情
        [4] = require("XUi/XUiGachaBianka/Grid/XUiPanelGachaBiankaRecord") -- 研发记录
    }

    self:InitButton()
    self:InitPanel()
end

function XUiGachaBiankaLog:OnStart(gachaConfig, forceIndex)
    self._GachaConfig = gachaConfig
    self._CurIndex = forceIndex or 1

    local timeId = self._GachaConfig.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiGachaBiankaLog:OnEnable()
    self.PanelTabTc:SelectIndex(self._CurIndex)
end

function XUiGachaBiankaLog:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiGachaBiankaLog:InitPanel()
    local tabBtns = {
        self.BtnTab1,
        self.BtnTab2,
        self.BtnTab3,
        self.BtnTab4,
        self.BtnTab5,
    }
    self.PanelTabTc:Init(tabBtns, function(index)
        self:OnBtnTabClick(index)
    end)
    for index, v in pairs(self._PanelDataDic) do
        local panelData = v.New(self["Panel" .. index], self)
        self._PanelDic[index] = panelData
    end
end

function XUiGachaBiankaLog:OnBtnTabClick(index)
    for i, panelData in pairs(self._PanelDic) do
        if i == index then
            panelData:Open()
            panelData:RefreshUiShow(self._GachaConfig)
        else
            panelData:Close()
        end
    end
    self._CurIndex = index
    self:PlayAnimation("QieHuan")
end

return XUiGachaBiankaLog