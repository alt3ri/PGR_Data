---@class XAccumulateExpendRulerL
local XAccumulateExpendRulerL = XClass(nil, "XAccumulateExpendRulerL")

function XAccumulateExpendRulerL:Ctor(title, desc)
    self:SetData(title, desc)
end

function XAccumulateExpendRulerL:SetData(title, desc)
    self._Title = title or ""
    self._Desc = desc or ""
end

function XAccumulateExpendRulerL:GetTitle()
    return self._Title
end

function XAccumulateExpendRulerL:GetDesc()
    return self._Desc
end

return XAccumulateExpendRulerL