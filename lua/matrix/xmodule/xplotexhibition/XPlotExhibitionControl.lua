-- 请搞清楚 角色和机体的关系
-- role = 角色
-- character = 机体（角色拥有多个机体）
-- force = 势力
-- story = 剧情 (机体拥有多个剧情)
---@class XPlotExhibitionControl : XControl
---@field private _Model XPlotExhibitionModel
local XPlotExhibitionControl = XClass(XControl, "XPlotExhibitionControl")

function XPlotExhibitionControl:OnInit()
    self._UiData = {
        -- 主界面
        Main = {
            IsInit = false,
            IsDirty = true,
            ---@type XPlotExhibitionControlRole[]
            AllRoleList = {},
            ---@type XPlotExhibitionControlRole[]
            FilterRoleList = {}
        },
        -- 筛选
        Filter = {
            IsInit = false,
            IsDirty = true,
            ---@type XPlotExhibitionControlFilter[]
            FilterList = {}
        },
        -- 角色详情
        Detail = {
            IsDirty = true,
            ---@type XPlotExhibitionControlRole
            Role = false,
            ---@type XPlotExhibitionControlCharacter[]@该角色对应的机体
            CharacterList = {},
            Name = "",
            ---@type XPlotExhibitionControlCharacter
            SelectedCharacter = false,
        },
        -- 角色详情的右侧剧情列表
        StoryDetail = {
            IsDirty = true,
            ---@type XPlotExhibitionControlStory[]
            StoryList = {},
        },
        -- 势力
        ForceDetail = {
            IsDirty = true,
            ---@type XPlotExhibitionControlForce
            Force = false,
            --- @type XTablePlotExhibitionForceCharacter
            CharacterList = {}
        },
    }

    self._AllForce = {}
    ---@type table<XPlotExhibitionControlForce, XTablePlotExhibitionForceCharacter[]>
    self._Force2Character = {}

    self._FilterForce = {}

    self._StoryConfigs = false
end

-- 进战斗不释放control，否则无法还原界面状况
function XPlotExhibitionControl:UseUiStackOperationRef()
    return true
end

function XPlotExhibitionControl:AddAgencyEvent()
end

function XPlotExhibitionControl:RemoveAgencyEvent()
end

function XPlotExhibitionControl:OnRelease()
end

function XPlotExhibitionControl:GetUiData()
    return self._UiData
end

---@param config XTablePlotExhibitionRoleGroup
function XPlotExhibitionControl:CreateRole(config)
    local forceDict = {}
    for i = 1, #config.CharacterId do
        local characterConfig = self._Model:GetCharacterConfig(config.CharacterId[i])
        if characterConfig then
            for j = 1, #characterConfig.Force do
                forceDict[characterConfig.Force[j]] = true
            end
        else
            XLog.Error("[XPlotExhibitionModel:GetRoleIdMarked] CharacterConfig is nil:" .. tostring(config.CharacterId[i]))
        end
    end

    ---@class XPlotExhibitionControlRole
    local Role = {
        Id = config.Id,
        Name = config.RoleName,
        Icon = false,
        ---@type number[]@该角色对应的机体，子集
        CharacterIds = config.CharacterId,
        Amount = #config.CharacterId,
        Progress = 0,
        IsNew = false,
        Priority = config.Priority,
        ForceDict = forceDict,
    }
    return Role
end

function XPlotExhibitionControl:UpdateMain(forceUpdate)
    if forceUpdate then
        self._UiData.Main.IsDirty = true
    end

    local data = self._UiData.Main
    if not data.IsInit then
        data.IsInit = true
        local roleConfigs = self._Model:GetRoleGroupConfigs()
        for i, config in pairs(roleConfigs) do
            -- 角色的势力 = 角色拥有的机体，所属的势力的合集
            local role = self:CreateRole(config)
            data.AllRoleList[#data.AllRoleList + 1] = role
        end
        table.sort(data.AllRoleList, function(a, b)
            if a.Priority ~= b.Priority then
                return a.Priority < b.Priority
            else
                return a.Id < b.Id
            end
        end)
    end

    if data.IsDirty then
        data.IsDirty = false
        data.FilterRoleList = {}
        for i = 1, #data.AllRoleList do
            local Role = data.AllRoleList[i]
            if self:CheckRoleFilter(Role) then
                data.FilterRoleList[#data.FilterRoleList + 1] = Role
            end
        end

        for i = 1, #data.FilterRoleList do
            local role = data.FilterRoleList[i]
            local characterIds = role.CharacterIds
            local isNew = false
            for j = 1, #characterIds do
                local characterId = characterIds[j]
                local characterConfig = self._Model:GetCharacterConfig(characterId)
                if characterConfig then
                    local newTimeId = characterConfig.NewTime
                    if newTimeId > 0 then
                        if XFunctionManager.CheckInTimeByTimeId(newTimeId) then
                            isNew = true
                            break
                        end
                    end
                else
                    XLog.Error("[XPlotExhibitionModel:GetRoleIdMarked] subConfig is nil:" .. tostring(characterId))
                end
            end
            role.IsNew = isNew

            local currentProgress, totalProgress = self:GetProgressByRoleId(role.Id)
            local progress = self:GetProgress4Text(currentProgress, totalProgress)
            role.Progress = progress

            -- 更新立绘
            --当玩家有设置该角色下某一机体标记时，以该标记的机体对应配置资源作为图片展示
            local storyId = self._Model:GetRoleCover(role.Id)
            local storyConfig
            if storyId and storyId > 0 then
                storyConfig = self._Model:GetStoryLineConfig(storyId)
            end
            if storyConfig then
                role.Icon = storyConfig.StoryBg
            else
                --读取配置的第一个机体资源作为图片展示
                local roleGroupConfig = self._Model:GetRoleGroupConfig(role.Id)
                local characterIdList = roleGroupConfig.CharacterId
                local characterId = characterIdList[#characterIdList]
                local characterConfig = self._Model:GetCharacterConfig(characterId)
                role.Icon = characterConfig.CharacterCg
            end
        end
    end
end

function XPlotExhibitionControl:GetProgressByRoleId(roleId)
    local characterIdList = self._Model:GetRoleGroupConfig(roleId).CharacterId
    local currentProgress, totalProgress = 0, 0
    for i = 1, #characterIdList do
        local characterId = characterIdList[i]
        local currentProgressChild, totalProgressChild = self:GetProgressByCharacterId(characterId)
        currentProgress = currentProgress + currentProgressChild
        totalProgress = totalProgress + totalProgressChild
    end
    return currentProgress, totalProgress
end

function XPlotExhibitionControl:GetProgressByCharacterId(characterId)
    local storyConfigs = self:GetStoryConfigs(characterId)
    local currentProgress, totalProgress = 0, 0
    for i = 1, #storyConfigs do
        local storyConfig = storyConfigs[i]
        local currentProgressChild, totalProgressChild = XMVCA.XPlotExhibition:GetProgressByStoryConfig(storyConfig)
        currentProgress = currentProgress + currentProgressChild
        totalProgress = totalProgress + totalProgressChild
    end
    return currentProgress, totalProgress
end

function XPlotExhibitionControl:IsForceSelected(forceId)
    if XTool.IsTableEmpty(self._FilterForce) then
        return true
    end
    return self._FilterForce[forceId]
end

function XPlotExhibitionControl:UpdateFilter(forceUpdate)
    if forceUpdate then
        self._UiData.Filter.IsDirty = true
    end

    if not self._UiData.Main.IsInit then
        self:UpdateMain()
        XLog.Error("[XPlotExhibitionControl] 理论上，应该先初始化了角色列表，但是现在没有，是不是有问题?")
    end
    local data = self._UiData.Filter
    if not data.IsInit then
        data.IsInit = true
        local forceConfigs = self._Model:GetForceConfigs()
        for i, config in pairs(forceConfigs) do
            ---@class XPlotExhibitionControlFilter
            local force = {
                Id = config.Id,
                Name = config.ForceName,
                Icon = config.ForceLogo,
                -- 默认全选
                IsSelected = false
            }
            data.FilterList[#data.FilterList + 1] = force
        end
        table.sort(data.FilterList, function(a, b)
            return a.Id < b.Id
        end)
    end
    if data.IsDirty then
        data.IsDirty = false
        for i = 1, #data.FilterList do
            local force = data.FilterList[i]
            force.IsSelected = self._FilterForce[force.Id]
        end
    end
end

function XPlotExhibitionControl:SetFilterForceSelected(forceId, value)
    if value then
        self._FilterForce[forceId] = true
    else
        self._FilterForce[forceId] = nil
    end
    self:UpdateFilter(true)
    self:UpdateMain(true)
end

function XPlotExhibitionControl:IsFilterEmpty()
    return XTool.IsTableEmpty(self._FilterForce)
end

function XPlotExhibitionControl:ClearFilterForceSelected()
    self._FilterForce = {}
    self:UpdateMain(true)
    self:UpdateFilter(true)
end

---@param Role XPlotExhibitionControlRole
function XPlotExhibitionControl:CheckRoleFilter(Role)
    for forceId, _ in pairs(Role.ForceDict) do
        if self:IsForceSelected(forceId) then
            return true
        end
    end
    return false
end

function XPlotExhibitionControl:SetRole4UiDetail(role)
    if not role then
        XLog.Error("[XPlotExhibitionControl] 选中的角色不存在？")
        return
    end
    if self._UiData.Detail.Role ~= role then
        self._UiData.Detail.Role = role
        self._UiData.StoryDetail.IsDirty = true
        self:UpdateDetail(true)
    end
end

---@param Role XPlotExhibitionControlRole
function XPlotExhibitionControl:OpenUiDetail(role)
    self:SetRole4UiDetail(role)
    XLuaUiManager.Open("UiPlotExhibitionDetail")
end

function XPlotExhibitionControl:UpdateDetail(forceUpdate)
    local data = self._UiData.Detail
    if forceUpdate then
        data.IsDirty = true
    end
    if data.IsDirty then
        data.IsDirty = false

        local Role = data.Role
        data.Name = Role.Name
        data.CharacterList = {}
        local RoleConfig = self._Model:GetRoleGroupConfig(Role.Id)
        -- 该角色对应的机体，子集
        for i = 1, #RoleConfig.CharacterId do
            local characterId = RoleConfig.CharacterId[i]
            local characterConfig = self._Model:GetCharacterConfig(characterId)
            if characterConfig then
                local currentProgress, totalProgress = self:GetProgressByCharacterId(characterId)
                local forceIdList = characterConfig.Force
                local forces = {}
                for j = 1, #forceIdList do
                    local forceId = forceIdList[j]
                    local force = self:GetForce(forceId)
                    forces[#forces + 1] = force
                end
                ---@class XPlotExhibitionControlCharacter
                local Character = {
                    Role = Role,
                    RoleId = Role.Id,
                    Id = characterId,
                    Name = XMVCA.XCharacter:GetCharacterFullNameStr(characterId),
                    Icon = XMVCA.XCharacter:GetCharRoundnessHeadIcon(characterId),
                    Progress = self:GetProgress4Text(currentProgress, totalProgress),
                    IsNew = XFunctionManager.CheckInTimeByTimeId(characterConfig.NewTime),
                    IsSelected = false,
                    Forces = forces,
                }
                data.CharacterList[#data.CharacterList + 1] = Character
            else
                XLog.Error(string.format("XPlotExhibitionModel:GetStoryLineConfig error: %s", characterId))
            end
        end
        -- 默认选中第一个
        data.SelectedCharacter = data.CharacterList[1]
    end

    -- 刷新选中状态
    for i = 1, #data.CharacterList do
        local Character = data.CharacterList[i]
        Character.IsSelected = Character == data.SelectedCharacter
    end
end

-- 选择机体
---@param Character XPlotExhibitionControlCharacter
function XPlotExhibitionControl:SelectCharacter(Character)
    self._UiData.Detail.SelectedCharacter = Character
    self:UpdateDetail()
end

function XPlotExhibitionControl:UpdateStoryDetail(forceUpdate)
    local data = self._UiData.StoryDetail
    if forceUpdate then
        data.IsDirty = true
    end
    if data.IsDirty then
        data.IsDirty = false
        data.StoryList = {}
        -- 右侧剧情列表，包含该角色所有机体的剧情
        local roleId = self._UiData.Detail.Role.Id
        for i = 1, #self._UiData.Detail.CharacterList do
            local character = self._UiData.Detail.CharacterList[i]
            local storyConfigs = self:GetStoryConfigs(character.Id)
            for j = 1, #storyConfigs do
                local storyConfig = storyConfigs[j]
                local characterConfig = self._Model:GetCharacterConfig(character.Id)
                local forceList = {}
                for k = 1, #characterConfig.Force do
                    forceList[k] = self:GetForce(characterConfig.Force[k])
                end

                local currentProgress, totalProgress = XMVCA.XPlotExhibition:GetProgressByStoryConfig(storyConfig)
                local newTimeId = storyConfig.NewTime
                local isNew
                if newTimeId then
                    if newTimeId ~= 0 then
                        isNew = XFunctionManager.CheckInTimeByTimeId(newTimeId)
                    end
                end
                if isNew == nil then
                    isNew = false
                end
                -- 只有主线，才显示图标
                local achievementIcon, isAchievementIconUnlock
                if storyConfig.StoryType == XEnumConst.FuBen.ChapterType.MainLine2 then
                    achievementIcon, isAchievementIconUnlock = XMVCA.XMainLine2:GetMainAchievementIconWithLockState(storyConfig.StoryChapter)
                    if not achievementIcon then
                        XLog.Error("[XPlotExhibitionControl] 找不到对应的主线成就配置，请检查配置:" .. tostring(storyConfig.StoryChapter))
                    end
                end
                ---@class XPlotExhibitionControlStory
                local story = {
                    Id = storyConfig.Id,
                    RoleId = roleId,
                    CharacterId = character.Id,
                    CharacterName = character.Name,
                    StoryName = storyConfig.StoryName,
                    StoryType = storyConfig.StoryType,
                    StoryChapter = storyConfig.StoryChapter,
                    StoryBg = storyConfig.StoryBg,
                    --StoryDesc = storyConfig.StoryDes,
                    ---@type XPlotExhibitionControlForce[]
                    Force = forceList,
                    Progress = self:GetProgress4Text(currentProgress, totalProgress),
                    IsCover = self._Model:GetRoleCover(character.RoleId) == storyConfig.Id,
                    IsNew = isNew,
                    AchievementIcon = achievementIcon,
                    IsAchievementIconUnlock = isAchievementIconUnlock,
                    Priority = storyConfig.Priority,
                }
                data.StoryList[#data.StoryList + 1] = story
            end
        end
        table.sort(data.StoryList, function(a, b)
            if a.Priority == b.Priority then
                return a.Id < b.Id
            end
            return a.Priority < b.Priority
        end)
    end
end

---@param story XPlotExhibitionControlStory
function XPlotExhibitionControl:JumpStory(story)
    -- 点击故事封面，跳转到对应的章节(主线等)
    local chapterType = story.StoryType
    local chapterId = story.StoryChapter
end

---@return XPlotExhibitionControlForce
function XPlotExhibitionControl:GetForce(forceId)
    if not self._AllForce[forceId] then
        local config = self._Model:GetForceConfig(forceId)
        ---@class XPlotExhibitionControlForce
        local force = {
            Id = forceId,
            Name = config.ForceName,
            Logo = config.ForceLogo,
            Desc = config.ForceDes,
        }
        self._AllForce[forceId] = force
    end
    return self._AllForce[forceId]
end

---@param story XPlotExhibitionControlStory
function XPlotExhibitionControl:SetRoleCover(story)
    if self._Model:GetRoleCover(story.RoleId) == story.Id then
        return
    end
    self._Model:SetRoleCover(story.RoleId, story.Id)
    for i = 1, #self._UiData.StoryDetail.StoryList do
        local storyData = self._UiData.StoryDetail.StoryList[i]
        storyData.IsCover = storyData.Id == story.Id
    end
    self:UpdateMain(true)
    -- 提示设置成功
end

---@param force XPlotExhibitionControlForce
function XPlotExhibitionControl:OpenUiForceDetail(force)
    if not force then
        XLog.Error("[XPlotExhibitionControl] 选中不存在的势力")
        return
    end
    if self._UiData.ForceDetail.Force ~= force then
        self._UiData.ForceDetail.Force = force
        self:UpdateForceDetail(true)
    end
    XLuaUiManager.Open("UiPlotExhibitionPopupPower")
end

function XPlotExhibitionControl:UpdateForceDetail(forceUpdate)
    local data = self._UiData.ForceDetail
    if forceUpdate then
        data.IsDirty = true
    end
    if data.IsDirty then
        data.IsDirty = false

        local force = data.Force
        if not self._Force2Character[force.Id] then
            local characterList = {}
            local characterConfigs = self._Model:GetCharacterConfigs()
            for _, characterConfig in pairs(characterConfigs) do
                for i = 1, #characterConfig.Force do
                    if characterConfig.Force[i] == force.Id then
                        local characterId = characterConfig.Id
                        local currentProgress, totalProgress = self:GetProgressByCharacterId(characterId)

                        ---@class XTablePlotExhibitionForceCharacter
                        local Character = {
                            CharacterId = characterId,
                            Name = XMVCA.XCharacter:GetCharacterFullNameStr(characterId),
                            Icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId),
                            Progress = self:GetProgress4Text(currentProgress, totalProgress),
                            IsNew = XFunctionManager.CheckInTimeByTimeId(characterConfig.NewTime)
                        }
                        characterList[#characterList + 1] = Character
                    end
                end
            end
            self._Force2Character[force.Id] = characterList
        end
        data.CharacterList = self._Force2Character[force.Id]
    end
end

-- 一个机体拥有多个剧情
---@return XTablePlotExhibitionStoryLine[]
function XPlotExhibitionControl:GetStoryConfigs(characterId)
    if not self._StoryConfigs then
        self._StoryConfigs = {}
        local storyConfigs = self._Model:GetStoryLineConfigs()
        for _, storyConfig in pairs(storyConfigs) do
            self._StoryConfigs[storyConfig.CharacterId] = self._StoryConfigs[storyConfig.CharacterId] or {}
            local storyList = self._StoryConfigs[storyConfig.CharacterId]
            storyList[#storyList + 1] = storyConfig
        end
    end
    if not self._StoryConfigs[characterId] then
        self._StoryConfigs[characterId] = {}
        XLog.Error("[XPlotExhibitionControl] 这个角色没有配置剧情:" .. tostring(characterId))
    end
    return self._StoryConfigs[characterId]
end

function XPlotExhibitionControl:GetRole(roleId)
    if not self._UiData.Main.IsInit then
        self:UpdateMain()
    end
    local allRoleList = self._UiData.Main.AllRoleList
    for i = 1, #allRoleList do
        local role = allRoleList[i]
        if role.Id == roleId then
            return role
        end
    end
end

function XPlotExhibitionControl:GetRoleIdByCharacterId(characterId)
    if not self._UiData.Main.IsInit then
        self:UpdateMain()
    end
    local allRole = self._UiData.Main.AllRoleList
    for i = 1, #allRole do
        local role = allRole[i]
        for j = 1, #role.CharacterIds do
            if role.CharacterIds[j] == characterId then
                return role.Id
            end
        end
    end
end

function XPlotExhibitionControl:GetProgress4Text(current, total)
    if total <= 0 then
        --XLog.Error("[XPlotExhibitionControl] 剧情进度上限为0")
        return 0
    else
        return math.ceil(current / total * 100)
    end
end

---@param data XPlotExhibitionControlStory
function XPlotExhibitionControl:SkipToChapter(data)
    local chapterType = data.StoryType
    local chapterId = data.StoryChapter
    local difficult = XDataCenter.FubenManager.DifficultNormal

    --主线
    if chapterType == XEnumConst.FuBen.ChapterType.MainLine then
        local viewModel = XDataCenter.FubenMainLineManager:ExGetChapterViewModelById(chapterId, difficult)
        XDataCenter.FubenMainLineManager:ExOpenChapterUi(viewModel, difficult)
        return
    end

    --外篇旧闻
    if chapterType == XEnumConst.FuBen.ChapterType.ExtralChapter then
        local viewModel = XDataCenter.ExtraChapterManager:ExGetChapterViewModelById(chapterId, difficult)
        XDataCenter.ExtraChapterManager:ExOpenChapterUi(viewModel, difficult)
        return
    end

    --浮点纪实
    if chapterType == XEnumConst.FuBen.ChapterType.ShortStory then
        local viewModel = XDataCenter.ShortStoryChapterManager:ExGetChapterViewModelById(chapterId, difficult)
        XDataCenter.ShortStoryChapterManager:ExOpenChapterUi(viewModel)
        return
    end

    --间章旧闻
    if chapterType == XEnumConst.FuBen.ChapterType.Prequel then
        local viewModel = XDataCenter.PrequelManager:ExGetChapterViewModelByChapterId(chapterId)
        if viewModel then
            XDataCenter.PrequelManager:ExOpenChapterUi(viewModel, difficult)
        else
            XLog.Error("[XPlotExhibitionControl] 未找到间章旧闻:" .. tostring(chapterId))
        end
        return
    end

    --本我回廊（角色塔）
    if chapterType == XEnumConst.FuBen.ChapterType.CharacterTower then
        local viewModel = XDataCenter.CharacterTowerManager:ExGetChapterViewModelBuyChapterId(chapterId)
        if viewModel then
            XDataCenter.CharacterTowerManager:ExOpenChapterUi(viewModel, difficult)
        else
            XLog.Error("[XPlotExhibitionControl] 未找到本我回廊:" .. tostring(chapterId))
        end
        return
    end

    --主线2
    if chapterType == XEnumConst.FuBen.ChapterType.MainLine2 then
        XMVCA.XMainLine2:OpenChapterUi(chapterId)
        return
    end

    --好感度剧情
    if chapterType == XEnumConst.FuBen.ChapterType.FavorabilityStory then
        XMVCA.XFavorability:OpenUiStory(data.CharacterId)
        return
    end
    XLog.Error("[XPlotExhibitionControl] 未实现的chapterType跳转:" .. tostring(chapterType))
end

return XPlotExhibitionControl