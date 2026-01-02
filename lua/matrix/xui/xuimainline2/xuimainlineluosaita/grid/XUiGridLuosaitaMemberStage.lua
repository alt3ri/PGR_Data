local CSInstantiate = CS.UnityEngine.Object.Instantiate
local XUiGridLuosaitaMember = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMember")

---@class XUiGridLuosaitaMemberStage : XUiNode
---@field Parent XUiPanelLuosaitaSection
---@field _Control XMainLineLuosaitaControl
---@field MemberData XMainLineLuosaitaPositionInfo
local XUiGridLuosaitaMemberStage = XClass(XUiGridLuosaitaMember, "XUiGridLuosaitaMemberStage")

function XUiGridLuosaitaMemberStage:OnStart(prefabName)
    self.PrefabName = prefabName
    self.SubPrefabs = {}
    self:RegisterUiEvents()
end

---@param memberData XMainLineLuosaitaPositionInfo
function XUiGridLuosaitaMemberStage:Refresh(memberData)
    self.MemberData = memberData
    self.MainId = XEnumConst.MAINLINE2.SPECIAL_MAINID.LUOSAITA
    self.ChapterId = XMVCA.XMainLine2:GetMainFirstChapterId(self.MainId)
    self.GroupId = XMVCA.XMainLine2:GetChapterFirstStageGroupId(self.ChapterId)
    self.StageId = memberData:GetStageId()
    self.StageIds = { self.StageId }

    XMVCA.XMainLine2:CacheStageChapterId(self.StageId, self.ChapterId)
    XMVCA.XMainLine2:CacheStageGroupId(self.StageId, self.GroupId)

    local isShow = self:IsShow()
    local isPass = self:IsPass()
    if not isShow then
        self:Close()
        return
    end
    self:Open()

    local isUnlock = self:IsUnlock()
    local isCur = isUnlock and not isPass

    self:RefreshInfo()
    self:RefreshStageProgress()
    self:RefreshAchievements()
    self:RefreshLock(isUnlock)
    self:ShowSubPrefab("PanelEffect", isCur)
    self:ShowSubPrefab("PanelKill", isPass)
end

function XUiGridLuosaitaMemberStage:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUiGridLuosaitaMemberStage:OnDestroy()
    
end

function XUiGridLuosaitaMemberStage:OnBtnStageClick()
    if self.Parent:IsDragOperation() then
        return
    end
    
    local isUnlock, tips = self:IsUnlock()
    if not isUnlock then
        XUiManager.TipMsg(tips)
        return
    end

    local detailType = XMVCA.XMainLine2:GetStageDetailType(self.StageId)
    if detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.MOVIE or detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.CG then
        XLuaUiManager.Open("UiMainLine2DetailStory", self.StageIds, self.ChapterId, self.MainId)
    elseif detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_NORMAL or detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_SPECIAL or detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_BOSS then
        XLuaUiManager.Open("UiMainLine2DetailBattle", self.StageIds, self.ChapterId, self.MainId)
    end
end

-- 刷新关卡信息
function XUiGridLuosaitaMemberStage:RefreshInfo()
    local stagePrefab = self:LoadSubPrefab("PanelStageActive")
    local uiObj = stagePrefab:GetComponent("UiObject")

    local stageName
    local chapterTitle = XMVCA.XMainLine2:GetMainTitle(self.MainId)
    local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
    local specialorder = XMVCA.XMainLine2:GetStageSpecialorder(self.StageId)
    local detailType = XMVCA.XMainLine2:GetStageDetailType(self.StageId)
    if specialorder then
        stageName = string.format("%s-%s%s %s", chapterTitle, stageCfg.OrderId, specialorder, stageCfg.Name)
    elseif detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.FIGHT_BOSS then
        stageName = string.format("%s-%s\n<size=30>%s</size>", chapterTitle, stageCfg.OrderId, stageCfg.Name)
    else
        stageName = string.format("%s-%s %s", chapterTitle, stageCfg.OrderId, stageCfg.Name)
    end
    uiObj:GetObject("TxtName").text = stageName
    uiObj:GetObject("RImgIcon"):SetRawImage(stageCfg.Icon)
end

-- 刷新关卡进度
function XUiGridLuosaitaMemberStage:RefreshStageProgress()
    local reachCnt, allCnt = XMVCA.XMainLine2:GetStageProgress(self.StageId)
    local isShowProgress = allCnt > 0
    if not isShowProgress then
        return
    end

    -- 已完成不显示进度
    local showProgress = reachCnt < allCnt
    if not showProgress then
        self:ShowSubPrefab("PanelProgress", false)
        return
    end

    local prefab = self:LoadSubPrefab("PanelProgress")
    local transform = prefab.transform
    self.RImgGreyBg = self.RImgGreyBg or XUiHelper.TryGetComponent(transform, "RawImage", "RawImage")
    self.ImgProgress = self.ImgProgress or XUiHelper.TryGetComponent(transform, "Image", "Image")
    self.PanelJd = self.PanelJd or XUiHelper.TryGetComponent(transform, "PanelJd")
    self.TxtGreyProgress = self.TxtGreyProgress or XUiHelper.TryGetComponent(transform, "PanelJd/Text1", "Text")
    self.TxtProgress = self.TxtProgress or XUiHelper.TryGetComponent(transform, "PanelJd/Text2", "Text")

    -- 背景图
    local stageCfg = XMVCA.XMainLine2:GetConfigStage(self.StageId)
    self.RImgGreyBg:SetRawImage(stageCfg.ProgressGreyBg)
    self.ImgProgress:SetSprite(stageCfg.ProgressBg)

    -- 进度
    local progress = reachCnt / allCnt
    self.ImgProgress.fillAmount = progress
    self.TxtGreyProgress.text = math.floor(progress * 100)
    self.TxtProgress.text = math.floor(progress * 100)
end

-- 刷新成就
function XUiGridLuosaitaMemberStage:RefreshAchievements()
    -- 获取所有关卡的成就
    local achieveInfos = XMVCA.XMainLine2:GetStagesAchievementInfos(self.StageId, false, false)

    -- 无成就时不显示
    if #achieveInfos == 0 then
        return
    end

    -- 加载成就预制体
    if not self.AchieveUiObjs then
        local prefab = self:LoadSubPrefab("PanelAchievement")
        local uiObj = prefab:GetComponent("UiObject")
        local achieveUiObj = uiObj:GetObject("GridAchieve")
        self.AchieveUiObjs = { achieveUiObj }
    end

    for i, info in ipairs(achieveInfos) do
        local uiObj = self.AchieveUiObjs[i]
        if not uiObj then
            local cloneGo = self.AchieveUiObjs[1].gameObject
            local go = CSInstantiate(cloneGo, cloneGo.transform.parent)
            uiObj = go:GetComponent("UiObject")
            table.insert(self.AchieveUiObjs, uiObj)
        end
        uiObj.gameObject:SetActiveEx(true)

        -- 隐藏显示
        local isHide = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.HIDE and not info.IsUnLock
        if isHide then
            uiObj.gameObject:SetActiveEx(false)
            goto CONTINUE
        end

        local isNormal = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.NORMAL
        local isSpecial = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.SPECIAL
        local isHideSpecial = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.HIDE

        uiObj:GetObject("GridNormal").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgNormalFinish").gameObject:SetActiveEx(isNormal and info.IsUnLock)
        uiObj:GetObject("GridHide").gameObject:SetActiveEx(isSpecial)
        uiObj:GetObject("RImgHideFinish").gameObject:SetActiveEx(isSpecial and info.IsUnLock)

        local gridRealHide = uiObj:GetObject('GridRealHide')
        local rImgRealHideFinish = uiObj:GetObject('RImgRealHideFinish')

        if gridRealHide then
            gridRealHide.gameObject:SetActiveEx(isHideSpecial)
        end

        if rImgRealHideFinish then
            rImgRealHideFinish.gameObject:SetActiveEx(isHideSpecial and info.IsUnLock)
        end

        ::CONTINUE::
    end
end

-- 刷新上锁状态
function XUiGridLuosaitaMemberStage:RefreshLock(isUnlock)
    if isUnlock then
        self:ShowSubPrefab("PanelStageLock", false)
        return
    end

    local prefab = self:ShowSubPrefab("PanelStageLock", true)
    local rImgIcon = XUiHelper.TryGetComponent(prefab.transform, "RImgIcon", "RawImage")
    if rImgIcon then
        local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
        rImgIcon:SetRawImage(stageCfg.Icon)
    end
end

-- 加载子预制体
function XUiGridLuosaitaMemberStage:LoadSubPrefab(prefabName)
    local prefab = self.SubPrefabs[prefabName]
    if prefab then
        return prefab
    end

    local parentGo = self[prefabName .. "Parent"]
    prefab = parentGo:LoadPrefabEx(XUiConfigs.GetUiObjectPrefabPath(self.PrefabName, prefabName))
    self.SubPrefabs[prefabName] = prefab
    return prefab
end

-- 显示/隐藏子预制体
function XUiGridLuosaitaMemberStage:ShowSubPrefab(prefabName, isShow)
    local prefab = self.SubPrefabs[prefabName]
    if not prefab and isShow then
        prefab = self:LoadSubPrefab(prefabName)
    end

    if prefab then
        prefab.gameObject:SetActiveEx(isShow)
    end
    return prefab
end

-- 是否通关
function XUiGridLuosaitaMemberStage:IsPass()
    return XMVCA.XMainLine2:IsStagePass(self.StageId)
end

-- 是否显示
function XUiGridLuosaitaMemberStage:IsShow()
    return self._Control:IsStageShow(self.StageId)
end

-- 是否解锁
function XUiGridLuosaitaMemberStage:IsUnlock()
    return self._Control:IsStageUnlock(self.StageId)
end

return XUiGridLuosaitaMemberStage
