
---@class XUiGridRaceFightMapCharacter : XUiNode
---@field Parent XUiRaceFightMain
local XUiGridRaceFightMapCharacter = XClass(XUiNode, "XUiGridRaceFightMapCharacter")


function XUiGridRaceFightMapCharacter:OnStart(...)
    self:_RegisterButtonClicks()
end

function XUiGridRaceFightMapCharacter:Update(id, index)
    self._index = index
    self._config = self._Control:GetRaceCharacterById(id)
    self.RImgHead:SetRawImage(self._config.Icon)
    self.TxtNum.text = self._Control:GetRoadNameByIndex(index)
end

function XUiGridRaceFightMapCharacter:OnBtnClick()
    self.Parent:OnBtnHeadClick(self._index)
end

function XUiGridRaceFightMapCharacter:_RegisterButtonClicks()
    self.GridMapCharacter.CallBack = Handler(self, self.OnBtnClick)
end

return XUiGridRaceFightMapCharacter
