local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationEat : XLineArithmetic2Animation
local XLineArithmetic2AnimationEat = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationEat")

function XLineArithmetic2AnimationEat:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.GRID_EAT
    self._Duration = 0
    self._Passed = 0
    self._GridUid = 0
    --self._EndGridUid = 0
    self._EatIndex = 0
    self._EatGridType = XLineArithmetic2Enum.GRID.NONE
end

function XLineArithmetic2AnimationEat:SetData(gridUid, endGridUid, eatIndex, eatGridType)
    self._GridUid = gridUid
    --self._EndGridUid = endGridUid
    self._EatIndex = eatIndex
    self._EatGridType = eatGridType
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationEat:Update(game, ui, deltaTime)
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.PLAYING

        local grid = ui:GetGrid(self._GridUid)
        if grid then
            local uiData = grid:GetUiData()
            if uiData.Type == XLineArithmetic2Enum.GRID.BASE
                    or uiData.Type == XLineArithmetic2Enum.GRID.OBSTACLE
            then
                if uiData.Score >= 10 then
                    ui:PlaySound("Score10")
                else
                    ui:PlaySound("Score1")
                end
            end
        else
            XLog.Error("[XLineArithmetic2AnimationEat] 要吃掉的格子不存在")
        end

        --local endGrid = ui:GetGrid(self._EndGridUid)
        --if endGrid then
        --    endGrid:PlayAnimation("Grid04Eat")
        --else
        --    XLog.Error("[XLineArithmetic2AnimationEat] 终点格子不存在")
        --end

        -- 播放完成，隐藏箭头
        ui:RemoveOverLineByIndex(self._EatIndex)
        return
    end
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.PLAYING then
        self._Passed = self._Passed + deltaTime

        if self._Passed >= self._Duration then
            self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
        end
    end
end

return XLineArithmetic2AnimationEat