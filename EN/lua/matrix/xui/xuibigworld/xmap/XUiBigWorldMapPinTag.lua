---@class XUiBigWorldMapPinTag : XUiNode
---@field TagSelect UnityEngine.RectTransform
---@field TagTrack UnityEngine.RectTransform
---@field ImgPlayer UnityEngine.UI.Image
---@field ImgTag UnityEngine.UI.Image
---@field Parent XUiBigWorldMapPin
local XUiBigWorldMapPinTag = XClass(XUiNode, "XUiBigWorldMapPinTag")

function XUiBigWorldMapPinTag:OnStart(isPlayer)
    ---@type XBWMapPinData
    self._PinData = false
    self._IsPlayer = isPlayer or false

    self:_Init()
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPinTag:Refresh(pinData)
    self._PinData = pinData
    
    self:_RefreshIcon(pinData)
    self:_RefreshTrack(pinData)
end

function XUiBigWorldMapPinTag:SetSelect(isSelect)
    self.TagSelect.gameObject:SetActiveEx(isSelect)
end

---@return XBWMapPinData
function XUiBigWorldMapPinTag:GetPinData()
    return self._PinData
end

function XUiBigWorldMapPinTag:_Init()
    self.ImgPlayer.gameObject:SetActiveEx(self._IsPlayer)
    self.ImgTag.gameObject:SetActiveEx(not self._IsPlayer)
    self:SetSelect(false)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPinTag:_RefreshIcon(pinData)
    if pinData:IsQuest() then
        self:_RefreshQuest(pinData.QuestId)
    else
        self:_RefreshStyle(pinData.StyleId, pinData:IsActive())
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPinTag:_RefreshStyle(styleId, isActive)
    local icon = XMVCA.XBigWorldMap:GetPinIconByStyleId(styleId, isActive)
    
    self.ImgTag:SetImage(icon)
end

function XUiBigWorldMapPinTag:_RefreshQuest(questId)
    local icon = XMVCA.XBigWorldQuest:GetQuestIcon(questId)
    
    self.ImgTag:SetImage(icon)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPinTag:_RefreshTrack(pinData)
    if self.TagTrack then
        self.TagTrack.gameObject:SetActiveEx(pinData:IsTracking())
    end
end

return XUiBigWorldMapPinTag
