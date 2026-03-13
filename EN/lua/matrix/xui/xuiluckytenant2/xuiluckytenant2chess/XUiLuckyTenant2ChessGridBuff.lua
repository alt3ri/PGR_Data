---@class XUiLuckyTenant2ChessGridBuff : XUiNode
---@field _Data table 状态数据
local XUiLuckyTenant2ChessGridBuff = XClass(XUiNode, "XUiLuckyTenant2ChessGridBuff")

---@param data table 状态数据（包含 StateType 和 Round）
function XUiLuckyTenant2ChessGridBuff:Update(data)
    self._Data = data
    if not data then
        return
    end

    -- 设置品质背景（根据羁绊等级，由 Control 传入 ImageBg）
    if self.ImageBg and data.ImageBg then
        if self.ImageBg.SetRawImage then
            self.ImageBg:SetRawImage(data.ImageBg)
        elseif self.ImageBg.SetImage then
            self.ImageBg:SetImage(data.ImageBg)
        end
    end

    -- 更新剩余回合数
    if self.TxtRemainRound then
        local remainRound = data.Round
        if remainRound == nil then
            remainRound = data.RemainRound
        end
        if remainRound == nil then
            remainRound = data.StateRound
        end
        if remainRound ~= nil and remainRound >= 0 then
            self.TxtRemainRound.text = tostring(remainRound)
            self.TxtRemainRound.gameObject:SetActiveEx(true)
        else
            self.TxtRemainRound.gameObject:SetActiveEx(false)
        end
    end

    -- 更新状态描述
    if self.TxtBuffDoc then
        local desc = data.Desc or ""
        self.TxtBuffDoc.text = XUiHelper.ReplaceTextNewLine(desc)
    end

    if XMain.IsEditorDebug then
        if self.TxtBuffName then
            self.TxtBuffDoc.text = self.TxtBuffDoc.text .. string.format("[Id:%s]", data.SkillId)
        end
    end
end

return XUiLuckyTenant2ChessGridBuff
