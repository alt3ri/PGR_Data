---@class XUiSkyGardenShoppingStreetGameResTips : XLuaUi
---@field TxtGold UnityEngine.UI.Text
---@field TxtFavorability UnityEngine.UI.Text
---@field TxtEnvironmental UnityEngine.UI.Text
---@field TxtPassenger UnityEngine.UI.Text
---@field TagPassenger UnityEngine.RectTransform
---@field TagEnvironmental UnityEngine.RectTransform

local XUiSkyGardenShoppingStreetGameResTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGameResTips")
local XUiSkyGardenShoppingStreetAssetTag = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetAssetTag")

function XUiSkyGardenShoppingStreetGameResTips:OnStart(...)
    self:_RegisterButtonClicks()
    
    self._stageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    self._ResIndex = {
        self._stageResType.InitGold,
        self._stageResType.InitFriendly,
        self._stageResType.InitCustomerNum,
        self._stageResType.InitEnvironment,
    }
    self._ComponentDic = {
        [self._stageResType.InitGold] = self.TxtGold,
        [self._stageResType.InitFriendly] = self.TxtFavorability,
        [self._stageResType.InitCustomerNum] = self.TxtPassenger,
        [self._stageResType.InitEnvironment] = self.TxtEnvironmental,
    }
    
    local resCfgs = self._Control:GetStageResConfigs()
    for _, key in ipairs(self._ResIndex) do
        local com = self._ComponentDic[key]
        local cfg = resCfgs[key]
        com.text = cfg.Desc
    end

    self._ComponentTagPassDic = {
        self._stageResType.AddCustomerFix,
        self._stageResType.AddCustomerRatio
    }
    self._ComponentTagEnvDic = {
        self._stageResType.AddEnvironmentFix,
        self._stageResType.AddEnvironmentRatio,
    }

    self._PassUis = {}
    XTool.UpdateDynamicItem(self._PassUis, self._ComponentTagPassDic, self.TagPassenger, XUiSkyGardenShoppingStreetAssetTag, self)

    self._EnvUis = {}
    XTool.UpdateDynamicItem(self._EnvUis, self._ComponentTagEnvDic, self.TagEnvironmental, XUiSkyGardenShoppingStreetAssetTag, self)

    for index, key in ipairs(self._ComponentTagPassDic) do
        local num = self._Control:GetStageResById(key)
        self._PassUis[index]:SetText(self._Control:GetValueByResConfig(num, resCfgs[key], false, true))
    end
    for index, key in ipairs(self._ComponentTagEnvDic) do
        local num = self._Control:GetStageResById(key)
        self._EnvUis[index]:SetText(self._Control:GetValueByResConfig(num, resCfgs[key], false, true))
    end
end

function XUiSkyGardenShoppingStreetGameResTips:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

return XUiSkyGardenShoppingStreetGameResTips
