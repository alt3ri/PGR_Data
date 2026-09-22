--- 战斗中的主卡释放特效节点
---@class XUiGridBattleCardUsed: XUiNode
---@field RImgOutline @外发光描边
---@field CanvasGroup UnityEngine.CanvasGroup 
local XUiGridBattleCardUsed = XClass(XUiNode, "XUiGridBattleCardUsed")


function XUiGridBattleCardUsed:OnStart()
    if self.CanvasGroup then
        self.CanvasGroup.alpha = 0
    end
end

function XUiGridBattleCardUsed:OnDisable()
    if self.CanvasGroup then
        self.CanvasGroup.alpha = 0
    end
end

function XUiGridBattleCardUsed:InitRImgOutline(rImg)
    if not string.IsNilOrEmpty(rImg) and self.RImgOutline then
        self.RImgOutline:SetRawImage(rImg)
    end
end

return XUiGridBattleCardUsed