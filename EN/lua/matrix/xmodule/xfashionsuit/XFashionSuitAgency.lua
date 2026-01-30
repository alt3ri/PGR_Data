---@class XFashionSuitAgency : XAgency
---@field private _Model XFashionSuitModel
local XFashionSuitAgency = XClass(XAgency, "XFashionSuitAgency")

function XFashionSuitAgency:OnInit()
    --初始化一些变量
end

function XFashionSuitAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XFashionSuitAgency:InitEvent()
    
end

----------public start----------

--region 涂装套装

function XFashionSuitAgency:SetFashionSuitData(fashionSuitList)
    self._Model:SetFashionSuitData(fashionSuitList)
end

function XFashionSuitAgency:OpenMain()
    local config = self._Model:GetClientConfigById("CloseGuideGroupId")
    local guideGroupIds = config and config.Values
    local needCloseIds = {}

    if not XTool.IsTableEmpty(guideGroupIds) then
        for _, idStr in ipairs(guideGroupIds) do
            local id = tonumber(idStr)
            if not XDataCenter.GuideManager.CheckIsGuide(id) then
                table.insert(needCloseIds, id)
            end
        end
    end

    if #needCloseIds > 0 then
        --玩家主动进入套装界面后，强制完成指定ID的强引导
        XDataCenter.GuideManager.ReqMultiGuideComplete(needCloseIds, function()
            XLuaUiManager.Open("UiFashionSuitMain")
        end)
    else
        XLuaUiManager.Open("UiFashionSuitMain")
    end
end

function XFashionSuitAgency:IsRed()
    --功能未开启
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FashionSuit) then
        return false
    end
    --涂装上新、全收集奖励未领取
    local configs = self._Model:GetFashionSuitConfigs()
    for _, config in pairs(configs) do
        local ownCount = 0
        for _, fashionId in pairs(config.FashionIds) do
            if not self._Model:IsFashionViewed(fashionId) then
                return true
            end
            if XDataCenter.FashionManager.CheckHasFashion(fashionId) then
                ownCount = ownCount + 1
            end
        end
        if ownCount == #config.FashionIds and not self._Model:IsSuitRewardGain(config.Id) then
            return true
        end
    end
    return false
end

function XFashionSuitAgency:GetFashionSuitId(fashionId)
  if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FashionSuit) then
        return false
    end
    local configs = self._Model:GetFashionSuitConfigs()
    for _,cfg in  pairs(configs) do
       if table.contains(cfg.FashionIds,fashionId)  then
            return cfg.Id
        end
    end
    return nil
end

function XFashionSuitAgency:CheckFashionShopOpen(suitId, cb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) then
        if cb then
            cb()
        end
    end
    local shopIds = self._Model:GetSuitShopIds(suitId)
    if XTool.IsTableEmpty(shopIds) then
        if cb then
            cb()
        end
    else
        XShopManager.RequestShopValidInfo(shopIds, cb)
    end
end

function XFashionSuitAgency:GetSuitShopIds(suitId)
    return self._Model:GetSuitShopIds(suitId)
end

--endregion

----------public end----------

----------private start----------


----------private end----------

return XFashionSuitAgency