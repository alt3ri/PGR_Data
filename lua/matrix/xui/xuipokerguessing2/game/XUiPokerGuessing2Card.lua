---@type System.Array
local Array = CS.System.Array
---@type UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3

---@class XUiPokerGuessing2Card : XUiNode
---@field _Control XPokerGuessing2Control
---@field Parent XUiPokerGuessing2Character
local XUiPokerGuessing2Card = XClass(XUiNode, "XUiPokerGuessing2Card")

function XUiPokerGuessing2Card:OnStart(isPlayerCard)
    if self.TxtNum then
        self.TxtNum.gameObject:SetActiveEx(false)
    end
    if self.ImgSpecial then
        self.ImgSpecial.gameObject:SetActiveEx(false)
    end

    self._OriginalParent = self.Transform.parent
    self._ParentOnDrag = false
    self._OriginalSiblingIndex = self.Transform:GetSiblingIndex()
    self._DragOffset = false
    self._IsOnOriginalParent = true
    self._IsCanDrag = false

    ---@type XGoInputHandler
    local goInputHandler = self.GoInputHandler
    if goInputHandler then
        goInputHandler:AddBeginDragListener(function(eventData)
            self:OnBeginDrag(eventData)
        end)
        goInputHandler:AddDragListener(function(eventData)
            self:OnDrag(eventData)
        end)
        goInputHandler:AddEndDragListener(function(eventData)
            self:OnEndDrag(eventData)
        end)
    end

    self._IsPutOnGround = false

    self._PositionZ = 0

    if self.PanelWhite then
        self.PanelWhite.gameObject:SetActiveEx(isPlayerCard)
    end
end

function XUiPokerGuessing2Card:SetIsCanDrag(value)
    self._IsCanDrag = value
end

function XUiPokerGuessing2Card:SetVisibleCardFace(value)
    self.RImgCardFace.gameObject:SetActiveEx(value)
end

function XUiPokerGuessing2Card:SetVisibleCardBack(value)
    self.RImgCardBack.gameObject:SetActiveEx(value)
end

---@param data XUiPokerGuessing2CardData
function XUiPokerGuessing2Card:Update(data, index, noShowChanged)
    self._Data = data
    if self.ImgBg then
        self.ImgBg:SetSprite(data.Icon)
    end
    if self.RImgCardFace then
        self.RImgCardFace:SetRawImage(data.Icon)
    end

    if noShowChanged then
        self:_HideChangedPanel()
    else
        self:TryShowChangedCard(false)
    end
end

function XUiPokerGuessing2Card:_HideChangedPanel()
    if self.PanelChange then
        self.PanelChange.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2Card:TryShowChangedCard(playAnimation, animDelayTime)
    if not self._Data or not XTool.IsNumberValid(self._Data.ChangedId) then
        self:_HideChangedPanel()
        return
    end

    if self.PanelChange then
        self.PanelChange.gameObject:SetActiveEx(true)

        if self.RImgChange then
            self.RImgChange:SetRawImage(self._Control:GetPokerGuessing2CardChangedFrontAssetPathById(self._Data.ChangedId))
        end

        if self.RImgGift then
            local url = self._Control:GetCharacterChangeCardIcon()

            if not string.IsNilOrEmpty(url) then
                self.RImgGift:SetRawImage(url)
            end
        end
    end
    
    if playAnimation then
        if XTool.IsNumberValid(animDelayTime) then
            self:DelayCall(function()
                self:PlayAnimation('ChangeCard', nil, nil,  CS.UnityEngine.Playables.DirectorWrapMode.None)
            end, animDelayTime)
        else
            self:PlayAnimation('ChangeCard', nil, nil,  CS.UnityEngine.Playables.DirectorWrapMode.None)
        end
    end
end

function XUiPokerGuessing2Card:ShowChangeCardAnimOnly()
    self:PlayAnimation('ChangeCard', nil, nil,  CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiPokerGuessing2Card:SetParentOnDrag(transform)
    self._ParentOnDrag = transform
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPokerGuessing2Card:OnBeginDrag(eventData)
    if not self._IsCanDrag then
        return
    end
    if not self._ParentOnDrag then
        return
    end
    local camera = CS.XUiManager.Instance.UiCamera
    local worldPosition = self.Transform.position
    self._PositionZ = worldPosition.z
    local screenPoint = camera:WorldToScreenPoint(worldPosition)
    -- 这块代码的作用是拖动卡牌时点击的位置和开始拖动前的位置一致
    --self._DragOffset = Vector2(screenPoint.x, screenPoint.y) - eventData.position 
    self.Transform:SetParent(self._ParentOnDrag, true)
    self._IsOnOriginalParent = false
    -- 设置世界旋转为0
    self.Transform.rotation = CS.UnityEngine.Quaternion.identity
    -- self.Transform.localEulerAngles = Vector3(0, 0, 0)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.PokerGuessing2SelectCard)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPokerGuessing2Card:OnDrag(eventData)
    if not self._IsCanDrag then
        return
    end
    if not self._ParentOnDrag then
        return
    end

    ---@type UnityEngine.Camera
    local camera = CS.XUiManager.Instance.UiCamera

    -- 将屏幕坐标转换为 RectTransform 的局部坐标
    local screenPointV2 = eventData.position --[[ + self._DragOffset  --]]
    local screenPoint = Vector3(screenPointV2.x, screenPointV2.y, self._PositionZ)
    local worldPosition = camera:ScreenToWorldPoint(screenPoint)

    ---@type UnityEngine.RectTransform
    local transform = self.Transform
    transform.position = worldPosition

    self._IsOnOriginalParent = false
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPokerGuessing2Card:OnEndDrag(eventData)
    if not self._IsCanDrag then
        return
    end
    if not self._ParentOnDrag then
        return
    end
    local camera = CS.XUiManager.Instance.UiCamera
    local screenPoint = camera:WorldToScreenPoint(self.Transform.position)
    local screenPointV2 = Vector2(screenPoint.x, screenPoint.y)
    local isInside = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self._ParentOnDrag, screenPointV2, camera)
    if isInside then
        self.Transform.localPosition = Vector3.zero
        self.Transform.localRotation = CS.UnityEngine.Quaternion.identity
        self._IsOnOriginalParent = false
        self:SetPlayerSelected()
        self.Parent:RevertCardParentAndPosition(self)
        self.Parent:SetAllCardPutOnGroup(false)
        self.Parent:ShowEffectPutDown()
        self:SetPutOnGround(true)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.PokerGuessing2DropDownCard)
    else
        if self._Control:IsSelectedCard(self._Data) then
            self._Control:SetSelectedCard(nil)
        end
        self:SetPutOnGround(false)
        self:ReverParent()
        self.Parent:ResortCards()
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.PokerGuessing2DeselectCard)
    end
end

function XUiPokerGuessing2Card:SetPlayerSelected()
    self._Control:SetSelectedCard(self._Data)
end

function XUiPokerGuessing2Card:ReverParent()
    self.Transform:SetParent(self._OriginalParent)
    self._IsOnOriginalParent = true
end

function XUiPokerGuessing2Card:ReverSiblingIndex()
    local siblingIndex = self._OriginalSiblingIndex
    self.Transform:SetSiblingIndex(siblingIndex)
end

function XUiPokerGuessing2Card:IsOnOriginalParent()
    return self._IsOnOriginalParent
end

function XUiPokerGuessing2Card:GetCardId()
    return self._Data and self._Data.Id or 0
end

function XUiPokerGuessing2Card:PlayAnimationCardToPutDown(duration)
    self._IsOnOriginalParent = false
    self._IsPutOnGround = true
    self.Transform:SetParent(self._ParentOnDrag, true)
    self.Transform.localEulerAngles = Vector3(0, 0, 0)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.PokerGuessing2SelectCard)
    -- 移动到父节点的局部坐标原点，而不是父节点的anchoredPosition3D
    self:DoMove(self.Transform, Vector3.zero, duration, nil, function()
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.PokerGuessing2DropDownCard)
        self.Parent:ShowEffectPutDown()
        self._Control:SetEnemySelectedCard(self._Data)
    end)
end

function XUiPokerGuessing2Card:IsPutOnGround()
    return self._IsPutOnGround
end

function XUiPokerGuessing2Card:SetPutOnGround(value)
    self._IsPutOnGround = value
end

-- SetWin 方法已移除，PanelWin 现在在 Character 上

function XUiPokerGuessing2Card:KeepTheCardFaceUp(value)
    if value then
        self.RImgCardFace.gameObject:SetActiveEx(true)
        self.RImgCardBack.gameObject:SetActiveEx(false)
    else
        self.RImgCardFace.gameObject:SetActiveEx(false)
        self.RImgCardBack.gameObject:SetActiveEx(true)
    end
end

function XUiPokerGuessing2Card:GetOriginalSiblingIndex()
    return self._OriginalSiblingIndex
end

function XUiPokerGuessing2Card:Reset()
    -- Reset 逻辑，PanelWin 现在由 Character 管理
end

function XUiPokerGuessing2Card:PlayAnimationRevealTheCard(callback)
    self:SetVisibleCardFace(false)
    self:_HideChangedPanel()
    self:TryShowChangedCard(false)
    self:PlayAnimation("ShowCard", callback, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

return XUiPokerGuessing2Card