local XTheatre5GameEntityBase = require('XModule/XTheatre5/ControlEntity/XTheatre5GameEntityBase')

--- PVE玩法内Entity
---@class XTheatre5PVEGameEntity: XTheatre5GameEntityBase
---@field protected _Model XTheatre5Model
local XTheatre5PVEGameEntity = XClass(XTheatre5GameEntityBase, 'XTheatre5PVEGameEntity')

function XTheatre5PVEGameEntity:OnInit()
    self._Data = self._Model.PVEAdventureData
end

function XTheatre5PVEGameEntity:OnRelease()
    self._Data = nil
end

function XTheatre5PVEGameEntity:GetCurRoundGridUnlockCostReduce()
    if not self._Data.PveChapterData then
        return 0
    end
    local chapterCfg = self._Model:GetPveChapterCfg(self._Data.PveChapterData.ChapterId)
    local turns = self._Data:GetRoundNumWithoutGridUnlock()
    local baseReduce = chapterCfg.GridUnlockDiscount
    return baseReduce * turns
end

function XTheatre5PVEGameEntity:GetRuneGridInitCount()
    if not self._Data.PveChapterData then
        return 0
    end
    local chapterCfg = self._Model:GetPveChapterCfg(self._Data.PveChapterData.ChapterId)
    return chapterCfg.BagRuneGridInitCount
end

return XTheatre5PVEGameEntity