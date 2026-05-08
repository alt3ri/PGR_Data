---@class XUiFubenBossSingleChallengeUnlockBanner : XLuaUi
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleChallengeUnlockBanner = XLuaUiManager.Register(
    XLuaUi, "UiFubenBossSingleChallengeUnlockBanner")

function XUiFubenBossSingleChallengeUnlockBanner:OnStart(
    bossBannerImg,
    nameplateIcon)

    self.RoleMonster:SetRawImage(bossBannerImg)

    if nameplateIcon then
        self.ImgUiNameplate:SetImage(nameplateIcon)
    end
end
