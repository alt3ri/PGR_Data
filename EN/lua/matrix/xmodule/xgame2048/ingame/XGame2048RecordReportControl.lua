--- 负责游戏内埋点上报的控制器
---@class XGame2048RecordReportControl: XControl
---@field private _MainControl XGame2048GameControl
---@field private _Model XGame2048Model
local XGame2048RecordReportControl = XClass(XControl, 'XGame2048RecordReportControl')

function XGame2048RecordReportControl:OnInit()

end

function XGame2048RecordReportControl:OnRelease()

end

function XGame2048RecordReportControl:OnInitGame()
    self._DispelRecordInfo = {
        start_time = self._MainControl.TurnControl:GetStartTime(),
        stage_id = self._MainControl:GetStageId(),
    }
end

function XGame2048RecordReportControl:CollectDispelInfo(beginX, endX, beginY, endY, gridPairs, isWaterFireSelect, dispelType)
    local columns = math.abs(beginX - endX) + 1
    local rows = math.abs(beginY - endY) + 1

    self:AddDispelBaseInfo(columns * rows, XTool.GetTableCount(gridPairs))

    if isWaterFireSelect then
        local gridEntities = self._MainControl.GridsControl:GetGridEntities()

        local fireInRangeCount, waterInRangeCount, fireTotalCount, waterTotalCount, adjustCount = 0, 0, 0, 0, 0
        
        if not XTool.IsTableEmpty(gridEntities) then

            local minGeneratedLevel = self._MainControl.TurnControl:GetCurBoardLvGenerateGridLevel()
            
            for i, grid in pairs(gridEntities) do
                local x = grid:GetX()
                local y = grid:GetY()
                local gridType = grid:GetGridType()
                local inRange = (x >= beginX and x<= endX) and (y >= beginY and y <= endY)
                local isDispelType = gridType == dispelType
                
                if gridType == XMVCA.XGame2048.EnumConst.GridType.Fire then
                    fireTotalCount = fireTotalCount + 1

                    if inRange then
                        fireInRangeCount = fireInRangeCount + 1

                        if not isDispelType then
                            adjustCount = adjustCount + 1
                        end
                    end
                elseif gridType == XMVCA.XGame2048.EnumConst.GridType.Water then
                    waterTotalCount = waterTotalCount + 1

                    if inRange then
                        waterInRangeCount = waterInRangeCount + 1

                        if not isDispelType then
                            adjustCount = adjustCount + 1
                        end
                    end
                end
            end
        end
        
        self:AddWaterFireDispelInfo(dispelType, fireInRangeCount, waterInRangeCount, fireTotalCount, waterTotalCount, adjustCount)
    end
end

---@param aimBlockCount @有几个格子受到消除效果的影响
---@param dispelGridCount @实际消除了几个方块
function XGame2048RecordReportControl:AddDispelBaseInfo(aimBlockCount, dispelGridCount)
    self._DispelRecordInfo["aim_block_count"] = aimBlockCount
    self._DispelRecordInfo["dispel_grid_count"] = dispelGridCount
end

function XGame2048RecordReportControl:AddWaterFireDispelInfo(dispelType, fireInRangeCount, waterInRangeCount, fireTotalCount, waterTotalCount, adjustCount)
    self._DispelRecordInfo["dispel_type"] = dispelType
    self._DispelRecordInfo["fire_in_range_count"] = fireInRangeCount
    self._DispelRecordInfo["water_in_range_count"] = waterInRangeCount
    self._DispelRecordInfo["fire_total_count"] = fireTotalCount
    self._DispelRecordInfo["water_total_count"] = waterTotalCount
    self._DispelRecordInfo["adjust_count"] = adjustCount
end

function XGame2048RecordReportControl:DoReport()
    if XMain.IsEditorDebug then
        CS.XRecord.RecordTest(self._DispelRecordInfo, "900012", "Game2048ClientRecord")
    else
        CS.XRecord.Record(self._DispelRecordInfo, "900012", "Game2048ClientRecord")
    end
end

return XGame2048RecordReportControl