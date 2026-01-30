---@class XUiFashionSuitMain : XLuaUi 涂装套装二级界面
---@field _Control XFashionSuitControl
local XUiFashionSuitMain = XLuaUiManager.Register(XLuaUi, "UiFashionSuitMain")

local HelpDataKey = "FashionSuitMainHelp"

function XUiFashionSuitMain:OnAwake()
    local config = XMVCA.XHelpCourse:GetHelpCourseCfgByFunction(HelpDataKey, true)
    if config then
        self.BtnHelp.gameObject:SetActiveEx(true)
        self:BindHelpBtn(self.BtnHelp, HelpDataKey)
    else
        self.BtnHelp.gameObject:SetActiveEx(false) --无配置则不显示
    end
end

function XUiFashionSuitMain:OnStart()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    --v4.1没有一级界面 此处是临时写法 后续可能加个Type字段 不同样式的套装界面对应不同的Panel类
    local suitId = self._Control:GetIntClientConfig("TempSuitIdV41")
    local config = self._Control:GetFashionSuitById(suitId)
    local go = self.PanelSuit:LoadPrefab(config.PrefabPath)
    ---@type XUiPanelFashionSuitNormal
    self._SuitView = require("XUi/XUiFashionSuit/Panel/XUiPanelFashionSuitNormal").New(go, self)
    self._SuitView:SetSuitId(suitId)

    --请求商店开启信息
    XMVCA.XFashionSuit:CheckFashionShopOpen(suitId)
end

function XUiFashionSuitMain:OnEnable()
    self._SuitView:UpdateView()
end

function XUiFashionSuitMain:OnDisable()

end

function XUiFashionSuitMain:OnDestroy()

end

return XUiFashionSuitMain