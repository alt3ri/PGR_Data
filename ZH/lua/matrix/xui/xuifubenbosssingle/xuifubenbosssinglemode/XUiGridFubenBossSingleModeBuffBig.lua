local XUiGridFubenBossSingleModeBuffSmall =
    require("XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiGridFubenBossSingleModeBuffSmall")

local XUiPanelFubenBossSingleChallengeModePreview = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiPanelFubenBossSingleChallengeModePreview")

---@class XUiGridFubenBossSingleModeBuffBig : XUiGridFubenBossSingleModeBuffSmall

local XUiGridFubenBossSingleModeBuffBig =
    XClass(
        XUiGridFubenBossSingleModeBuffSmall,
        "XUiGridFubenBossSingleModeBuffBig")

function XUiGridFubenBossSingleModeBuffBig:Ctor(_0, _1)
    self._BuffPreview = XUiPanelFubenBossSingleChallengeModePreview.New(
        self.PanelMode.gameObject,
        self)
end

function XUiGridFubenBossSingleModeBuffBig:SetData(
    feature,
    buffGroups)

    XUiGridFubenBossSingleModeBuffBig.Super.SetData(self, feature, buffGroups, 0)
    self.UiTxtBuffDetail.text = feature:GetDesc()
    self:_SetHistoryTeam(feature)
    self._BuffPreview:SetData(feature:GetHistoryBuffGroup())
end

function XUiGridFubenBossSingleModeBuffBig:PlayExtendAnimation()
    self:PlayAnimationWithMask("Big")
end

function XUiGridFubenBossSingleModeBuffBig:_SetHistoryTeam(feature)
    if not self._CharHeads then
        self._CharHeads = {
            [1] = self.GridCharacter.gameObject
        }
    end

    local charIds = feature:GetCharacterList()
    local charIndex = 1

    for _, charId in pairs(charIds) do
        local grid = self._CharHeads[charIndex]

        if not grid then
            grid = XUiHelper.Instantiate(self.GridCharacter.gameObject, self.ListRole)
            self._CharHeads[charIndex] = grid
        end

        grid.transform
            :FindTransform("RImgHead")
            :GetComponent("RawImage")
            :SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(charId))

        grid:SetActiveEx(true)

        charIndex = charIndex + 1
    end

    self.TxtRoleEmpty.gameObject:SetActiveEx(charIndex == 1)

    for i = charIndex, #self._CharHeads do
        self._CharHeads[i]:SetActiveEx(false)
    end
end

return XUiGridFubenBossSingleModeBuffBig
