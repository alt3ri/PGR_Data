---@class XUiBountyChallengeChapterDetailCharacter : XUiNode
---@field _Control XBountyChallengeControl
local XUiBountyChallengeChapterDetailCharacter = XClass(XUiNode, "XUiBountyChallengeChapterDetailCharacter")

function XUiBountyChallengeChapterDetailCharacter:OnStart()
end

---@param data XUiBountyChallengeChapterDetailCharacterData
function XUiBountyChallengeChapterDetailCharacter:Update(data)
    self.RImgHead:SetRawImage(data.Icon)

    if self.ImgTag then
        self.ImgTag.gameObject:SetActiveEx(data.IsRobot or false)
    end
end

return XUiBountyChallengeChapterDetailCharacter