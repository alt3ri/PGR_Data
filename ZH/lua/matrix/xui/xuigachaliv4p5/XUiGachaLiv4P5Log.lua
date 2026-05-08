---@class XUiGachaLiv4P5Log : XLuaUi
local XUiGachaLiv4P5Log = XLuaUiManager.Register(XLuaUi, "UiGachaLifu405Log")

function XUiGachaLiv4P5Log:OnAwake()
    self._PanelDic = {}
    self._PanelDataDic = {
        [1] = require("XUi/XUiGachaLiv4P5/Grid/XUiPanelGachaLiv4P5Reward"), -- 奖励详情
        [2] = require("XUi/XUiGachaLiv4P5/Grid/XUiPanelGachaLiv4P5Rule"), -- 基础规则
        [3] = require("XUi/XUiGachaLiv4P5/Grid/XUiPanelGachaLiv4P5Detail"), -- 掉落详情
        [4] = require("XUi/XUiGachaLiv4P5/Grid/XUiPanelGachaLiv4P5Record") -- 研发记录
    }

    self:InitButton()
    self:InitPanel()
end

function XUiGachaLiv4P5Log:OnStart(gachaConfig, forceIndex)
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

function XUiGachaLiv4P5Log:OnEnable()
    self.PanelTabTc:SelectIndex(self._CurIndex)
end

function XUiGachaLiv4P5Log:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiGachaLiv4P5Log:InitPanel()
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

function XUiGachaLiv4P5Log:OnBtnTabClick(index)
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

return XUiGachaLiv4P5Log