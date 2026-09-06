local XUiGridCultureCost = XClass(XUiNode, "XUiGridCultureCost")

local COLOR_NORMAL = CS.UnityEngine.Color.black
local _, COLOR_LACK = CS.UnityEngine.ColorUtility.TryParseHtmlString("#E43730")

local StringFormat = string.format
local MathFloor = math.floor

local function GetShortCountText(count)
    if count < 1000 then
        return tostring(count)
    end
    local unit, value
    if count >= 1000000 then
        unit, value = "M", count / 1000000
    else
        unit, value = "K", count / 1000
    end
    value = MathFloor(value * 10) / 10
    local intValue = MathFloor(value)
    if value == intValue then
        return StringFormat("%d%s", intValue, unit)
    end
    return StringFormat("%.1f%s", value, unit)
end

function XUiGridCultureCost:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

--- 刷新一条消耗
---@param data table { Id, Count, IsEnough }
function XUiGridCultureCost:Update(data)
    self.ItemId = data.Id
    self.Icon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(data.Id))
    self.TxtCost.text = GetShortCountText(data.Count)
    local isEnough = data.IsEnough
    if isEnough == nil then
        isEnough = XDataCenter.ItemManager.GetCount(data.Id) >= data.Count
    end
    self.TxtCost.color = isEnough and COLOR_NORMAL or COLOR_LACK
end

function XUiGridCultureCost:OnBtnClick()
    if XTool.IsNumberValid(self.ItemId) then
        if self.ItemId == XDataCenter.ItemManager.ItemId.Coin then
            XLuaUiManager.Open("UiUseCoinPackage")
        else
            XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(self.ItemId))
        end
    end
end

return XUiGridCultureCost
