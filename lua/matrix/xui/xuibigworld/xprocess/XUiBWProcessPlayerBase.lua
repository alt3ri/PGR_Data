---@class XUiBWProcessPlayerBase : XUiNode
---@field CanvasGroup UnityEngine.CanvasGroup
local XUiBWProcessPlayerBase = XClass(XUiNode, "XUiBWProcessPlayerBase")

function XUiBWProcessPlayerBase:SetInterval(interval)
    self.__Interval = interval
end

function XUiBWProcessPlayerBase:GetInterval()
    return self.__Interval or 0.1
end

---@return XDynamicTableNormal
function XUiBWProcessPlayerBase:GetDynamicTable()
    XLog.Error("请重写GetDynamicTable方法! 返回正确的动态列表!")
end

function XUiBWProcessPlayerBase:PlayDynamicAnimation()
    local interval = self:GetInterval()
    local dynamicTable = self:GetDynamicTable()

    if not dynamicTable then
        return
    end

    XMVCA.XBigWorldUI:SetMaskActive(true, "XUiBWProcessPlayerBase")

    RunAsyn(function()
        local startIndex, count = self:_GetGridCountAndTransparent(dynamicTable)

        for i = startIndex, startIndex + count - 1 do
            ---@type XUiBWProcessAnimationBase
            local grid = dynamicTable:GetGridByIndex(i)

            if grid then
                grid:PlayEnableAnimation()
            end

            asynWaitSecond(interval)
        end

        XMVCA.XBigWorldUI:SetMaskActive(false, "XUiBWProcessPlayerBase")
    end)
end

---@param dynamicTable XDynamicTableNormal
function XUiBWProcessPlayerBase:_GetGridCountAndTransparent(dynamicTable)
    local grids = dynamicTable:GetGrids()
    local count = 0
    local startIndex = math.maxinteger

    if not XTool.IsTableEmpty(grids) then
        for index, grid in pairs(grids) do
            grid:SetAlpha(0)
            count = count + 1
            startIndex = math.min(startIndex, index)
        end
    end

    return startIndex, count
end

return XUiBWProcessPlayerBase
