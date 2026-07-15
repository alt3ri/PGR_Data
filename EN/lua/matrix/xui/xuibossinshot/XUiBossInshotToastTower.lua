local XBossInshotModel = require("XModule/XBossInshot/XBossInshotModel")

local XUiBossInshotToastTower =
    XLuaUiManager.Register(XLuaUi, "UiBossInshotToastTower")

function XUiBossInshotToastTower:OnStart(toastData, autoCloseCb)
    self:_SetToastType(
        toastData.ToastType,
        toastData.PrevLevel,
        toastData.PrevLevelType == XBossInshotModel.TowerLevelType.ChallengeLevel,
        toastData.CurLevel,
        toastData.CurLevelType == XBossInshotModel.TowerLevelType.ChallengeLevel,
        toastData.TargetScore)

    self._AutoCloseSchedule = XScheduleManager.ScheduleOnce(
        handler(self, self._AutoClose),
        CS.XGame.ClientConfig:GetInt("UiBossInshotToastTowerCloseTime"))

    self._AutoCloseCallback = autoCloseCb
end

function XUiBossInshotToastTower:_AutoClose()
    XScheduleManager.UnSchedule(self._AutoCloseSchedule)
    self._AutoCloseSchedule = nil

    self:Close()

    if self._AutoCloseCallback then
        self._AutoCloseCallback()
    end
end

function XUiBossInshotToastTower:_SetToastType(
    toastType,
    fromLevel,
    fromLevelIsChallenge,
    toLevel,
    toLevelIsChallenge,
    targetScore)

    local function text(...)
        return string.gsub(CS.XTextManager.GetText(...), "\\n", "\n")
    end

    local toastProfiles = {
        [XBossInshotModel.ToastType.Up] = {
            self.RImgBgUp,
            self.ImgArrowUp,
            self.PanelFloorUp,
            self.PanelFloorDown,
            self.ImgTitleArrowUp,

            Title = "BossInshotToastTowerUp",
            SetLeftNumbers = true,
            DescFunc = function()
                return text(
                    "BossInshotToastTowerDescUp",
                    targetScore,
                    toLevel - fromLevel)
            end
        },

        [XBossInshotModel.ToastType.Down] = {
            self.RImgBgDown,
            self.ImgArrowDown,
            self.PanelFloorUp,
            self.PanelFloorDown,
            self.ImgTitleArrowDown,

            Title = "BossInshotToastTowerDown",
            SetLeftNumbers = true,
            DescFunc = function()
                return text(
                    "BossInshotToastTowerDescDown",
                    targetScore,
                    toLevel)
            end
        },

        [XBossInshotModel.ToastType.Clear] = {
            self.RImgBgUp,
            self.ImgFinish,

            Title = "BossInshotToastTowerClear",
            DescFunc = function()
                return text("BossInshotToastTowerDescClear")
            end
        },

        [XBossInshotModel.ToastType.DownProtected] = {
            self.RImgBgDown,
            self.ImgProtect,

            Title = "BossInshotToastTowerDownProtected",
            DescFunc = function()
                return text(
                    "BossInshotToastTowerDescDownProtected",
                    targetScore)
            end
        }
    }

    local allGo = {
        [self.ImgUpBgLow] = true,
        [self.ImgUpBgHigh] = true,
        [self.ImgUpBgGrey] = true,
        [self.ImgDownBgLow] = true,
        [self.ImgDownBgHigh] = true,
        [self.ImgDownBgGrey] = true
    }

    for _, goSet in pairs(toastProfiles) do
        for _, go in ipairs(goSet) do
            allGo[go] = true
        end
    end

    for go, _ in pairs(allGo) do
        go.gameObject:SetActiveEx(false)
    end

    local toastProfile = toastProfiles[toastType]

    for _, go in ipairs(toastProfile) do
        go.gameObject:SetActiveEx(true)
    end

    self.TxtTitle.text = text(toastProfile.Title)
    self.TxtDesc.text = toastProfile.DescFunc()

    if toastProfile.SetLeftNumbers then
        local up
        local upLevelIsChallenge
        local down
        local downLevelIsChallenge

        if toastType == XBossInshotModel.ToastType.Up then
            up = toLevel
            upLevelIsChallenge = toLevelIsChallenge
            down = fromLevel
            downLevelIsChallenge = fromLevelIsChallenge
        else
            up = fromLevel
            upLevelIsChallenge = fromLevelIsChallenge
            down = toLevel
            downLevelIsChallenge = toLevelIsChallenge
        end

        self.TxtNumUp.text = text("BossInshotToastTowerFloor", up)

        if upLevelIsChallenge then
            self.ImgUpBgHigh.gameObject:SetActiveEx(true)
        else
            self.ImgUpBgLow.gameObject:SetActiveEx(true)
        end

        self.TxtNumDown.text = text("BossInshotToastTowerFloor", down)

        if downLevelIsChallenge then
            self.ImgDownBgHigh.gameObject:SetActiveEx(true)
        else
            self.ImgDownBgLow.gameObject:SetActiveEx(true)
        end
    end
end

return XUiBossInshotToastTower
