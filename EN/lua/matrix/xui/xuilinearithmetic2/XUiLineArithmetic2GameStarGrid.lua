---@class XUiLineArithmetic2GameStarGrid : XUiNode
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2GameStarGrid = XClass(XUiNode, "XUiLineArithmetic2GameStarGrid")

---@param data XLineArithmetic2ControlDataStarDesc
function XUiLineArithmetic2GameStarGrid:Update(data)
    if data.IsFinish then
        if self._IsFinish ~= true then
            self._IsFinish = true
            self:PlayAnimation("SelectEnable")
        end
        self.Normal.gameObject:SetActiveEx(false)
        self.Select.gameObject:SetActiveEx(true)
        self.TxtTargetOn.text = data.Desc
        if self.TxtTargetTl2 then
            self.TxtTargetTl2.text = XUiHelper.GetText("LineArithmeticTarget", data.Index)
        end
    else
        self._IsFinish = false
        self.Normal.gameObject:SetActiveEx(true)
        self.Select.gameObject:SetActiveEx(false)
        self.TxtTargetOff.text = data.Desc
        if self.TxtTargetTl1 then
            self.TxtTargetTl1.text = XUiHelper.GetText("LineArithmeticTarget", data.Index)
        end
    end
end

return XUiLineArithmetic2GameStarGrid