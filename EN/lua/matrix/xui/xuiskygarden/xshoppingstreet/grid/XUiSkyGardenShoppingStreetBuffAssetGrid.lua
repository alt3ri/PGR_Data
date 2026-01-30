---@class XUiSkyGardenShoppingStreetBuffAssetGrid : XUiNode
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetBuffAssetGrid = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuffAssetGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetBuffAssetGrid:Update(data, i)
    local buffId
    if type(data) == "number" then
        buffId = data
    else
        if data.BuffId then
            buffId = data.BuffId
        else
            buffId = data.BuffConfigId
        end
    end

    self._buffId = buffId
    local params = self._Control:ParseBuffDescParamsById(buffId)
    local ressCfg = self._Control:GetStageResConfigs()
    local resId, num, resCfg
    for _resId, _num in pairs(params) do
        resId = _resId
        num = _num
        resCfg = ressCfg[resId]
        if resCfg then break end
    end
    if not resCfg then
        self.TxtNum.text = 0
        return
    end

    self.ImgAsset:SetSprite(resCfg.Icon)
    self.ImgAsset.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
    self.TxtNum.text = self._Control:GetValueByResConfig(num, resCfg)
end

function XUiSkyGardenShoppingStreetBuffAssetGrid:SetClickCallback(cb)
    if not self.UiSkyGardenShoppingStreetGridAsset then return end
    self._CallBack = cb
    self.UiSkyGardenShoppingStreetGridAsset.enabled = true
    self.UiSkyGardenShoppingStreetGridAsset:AddEventListener(function ()
        if self._CallBack then
            self._CallBack()
        else
            XMVCA.XSkyGardenShoppingStreet:ShowBuffTips(self._buffId, self.ImgAsset.transform.position)
        end
    end)
end

--endregion

return XUiSkyGardenShoppingStreetBuffAssetGrid
