--- 波次图标基类
---@class XUiPBRBaseWaveGrid: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
local XUiPBRBaseWaveGrid = XClass(XUiNode, "XUiPBRBaseWaveGrid")

function XUiPBRBaseWaveGrid:OnStart(gridType)
    self.GridType = gridType
end

function XUiPBRBaseWaveGrid:RefreshShow(waveId, waveIndex, nextWaveIndex)
    self.WaveId = waveId
    self.WaveIndex = waveIndex
    
    self:AOPBeforeRefresh(nextWaveIndex)

    if self.ImgNext then
        self.ImgNext.gameObject:SetActiveEx(false)
    end

    if self.ImgFinish then
        self.ImgFinish.gameObject:SetActiveEx(false)
    end

    -- 当前节点是下一波/已通关的波次
    if waveIndex == nextWaveIndex then
        if self.ImgNext then
            self.ImgNext.gameObject:SetActiveEx(true)
        end
        
        self:AOPWhenNextShow()
    elseif waveIndex < nextWaveIndex then
        if self.ImgFinish then
            self.ImgFinish.gameObject:SetActiveEx(true)
        end
        
        self:AOPWhenFinishShow()
    end
    
    self:AOPAfterRefresh(nextWaveIndex)
end

function XUiPBRBaseWaveGrid:AOPBeforeRefresh(nextWaveIndex)
    
end

function XUiPBRBaseWaveGrid:AOPWhenNextShow()
    
end

function XUiPBRBaseWaveGrid:AOPWhenFinishShow()
    
end

function XUiPBRBaseWaveGrid:AOPAfterRefresh(nextWaveIndex)
    
end

return XUiPBRBaseWaveGrid