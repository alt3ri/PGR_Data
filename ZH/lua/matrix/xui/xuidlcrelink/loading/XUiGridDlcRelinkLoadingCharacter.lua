---@class XUiGridDlcRelinkLoadingCharacter : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkLoadingCharacter = XClass(XUiNode, "XUiGridDlcRelinkLoadingCharacter")

---@param playerData XDlcPlayerData
function XUiGridDlcRelinkLoadingCharacter:Refresh(playerData)
    -- 职业图标
    local occupationIcon = self._Control:GetCharacterOccupationIconTwo(playerData:GetCharacterId(), playerData:GetStyleType())
    if not string.IsNilOrEmpty(occupationIcon) and self.RImgIconCareer then
        self.RImgIconCareer:SetRawImage(occupationIcon)
    end

    -- 名称
    if self.TxtName then
        self.TxtName.text = playerData:GetNickname() or ""
    end

    -- 装备总战力
    if self.TxtLv then
        self.TxtLv.text = playerData:GetRelinkEquLevel()
    end

    -- 角色图标
    local characterId = playerData:GetCharacterId()
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local characterIcon = XDataCenter.FashionManager.GetRoleCharacterBigImage(fashionId)
    if not string.IsNilOrEmpty(characterIcon) and self.RImgCharacter then
        self.RImgCharacter:SetRawImage(characterIcon)
    end

    -- 进度条
    if self.ImgBar then
        self.ImgBar.fillAmount = 0
    end

    -- 进度
    if self.TxtProgress then
        self.TxtProgress.text = "0%"
    end
end

function XUiGridDlcRelinkLoadingCharacter:RefreshProgress(progress)
    if progress < 100 then
        self.ImgBar.fillAmount = progress / 100.0
        if self.TxtProgress then
            self.TxtProgress.text = string.format("%d%%", progress)
        end
    else
        self.ImgBar.fillAmount = 1.0
        if self.TxtProgress then
            self.TxtProgress.text = "100%"
        end
    end
end

return XUiGridDlcRelinkLoadingCharacter
