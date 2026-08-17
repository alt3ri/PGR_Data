---@class XUiEnvelopeGuessingCollectionCharacterCard : XUiNode
---@field private _Control XEnvelopeGuessingControl
local XUiEnvelopeGuessingCollectionCharacterCard = XClass(XUiNode, "XUiEnvelopeGuessingCollectionCharacterCard")

function XUiEnvelopeGuessingCollectionCharacterCard:OnStart()
    self.CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    if self.BtnClick then
        self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
    end
end

-- 入场动画前先隐藏
function XUiEnvelopeGuessingCollectionCharacterCard:HideForEnterAnimation()
    if not XTool.UObjIsNil(self.CanvasGroup) then
        self.CanvasGroup.alpha = 0
    end
end

-- 播放入场动画：显示并播放
function XUiEnvelopeGuessingCollectionCharacterCard:PlayEnterAnimation()
    if not XTool.UObjIsNil(self.CanvasGroup) then
        self.CanvasGroup.alpha = 1
    end
    self:PlayAnimation("GridCollectionEnable")
end

function XUiEnvelopeGuessingCollectionCharacterCard:SetData(charConf, onClick)
    self._CharConf = charConf
    self.OnClick = onClick
    self:Refresh()
end

function XUiEnvelopeGuessingCollectionCharacterCard:Refresh()
    if not XTool.UObjIsNil(self.CanvasGroup) then
        self.CanvasGroup.alpha = 1
    end

    local unlocked = self._Control:IsCharacterOpened(self._CharConf.Id)
    local watched = false

    if unlocked then
        watched = self._Control:IsCharacterStoryWatched(self._CharConf.Id)
    end

    self.RImgCardBg.gameObject:SetActiveEx(unlocked and watched)
    self.RImgCardBgMask.gameObject:SetActiveEx(unlocked and not watched)
    self.RImgCardRole.gameObject:SetActiveEx(unlocked and not watched)
    self.RImgCardPackage.gameObject:SetActiveEx(not unlocked)

    if unlocked then
        if watched then
            self.RImgCardBg:SetRawImage(self._CharConf.CgAssetPathUnlocked)
        else
            self.RImgCardRole:SetRawImage(self._CharConf.CgAssetPathLocked)
        end
    end

    if self.TxtName then
        if unlocked then
            self.TxtName.text = self._CharConf.CharacterName
        else
            self.TxtName.text = CS.XTextManager.GetText("EnvelopeGuessingCollectionUiLockedCharacterName")
        end
    end
end

function XUiEnvelopeGuessingCollectionCharacterCard:OnBtnClick()
    if self.OnClick then
        self.OnClick(self._CharConf)
    end
end

return XUiEnvelopeGuessingCollectionCharacterCard
