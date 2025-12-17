---@class XUiBountyChallengeChapterDetailCharacter : XUiNode
---@field _Control XBountyChallengeControl
local XUiBountyChallengeChapterDetailCharacter = XClass(XUiNode, "XUiBountyChallengeChapterDetailCharacter")

function XUiBountyChallengeChapterDetailCharacter:OnStart()
end

---@param data XUiBountyChallengeChapterDetailCharacterData
function XUiBountyChallengeChapterDetailCharacter:Update(data)
    self.RImgHead:SetRawImage(data.Icon)
end

return XUiBountyChallengeChapterDetailCharacter