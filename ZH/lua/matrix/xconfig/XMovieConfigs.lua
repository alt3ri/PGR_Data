local TABLE_MOVIE_PATH_PREFIX = "Client/Movie/Movies/Movie%s.tab"
local TABLE_MOVIE_ACTOR_PATH = "Client/Movie/MovieActor.tab"
local TABLE_MOVIE_SPINE_ACTOR_PATH = "Client/Movie/MovieSpineActor.tab"
local TABLE_MOVIE_SPINE_ACTOR_V2_PATH = "Client/Movie/MovieSpineActorV2.tab"
local TABLE_MOVIE_ROLE_FACE_PATH = "Client/Movie/MovieRoleFace.tab"
local TABLE_MOVIE_SKIP_PATH = "Client/Movie/MovieSkips"
local TABLE_MOVIE_STAFF_PATH = "Client/Movie/MovieStaffs"
local TABLE_MOVIE_SPEED_PATH = "Client/Movie/MovieSpeed.tab"
local TABLE_MOVIE_SKIP_SUMMARY_PATH = "Client/Movie/MovieSkipSummary.tab"

local stringFormat = string.format
local checkTableExist = CS.XTableManager.CheckTableExist
local vector = CS.UnityEngine.Vector2
local tableInsert = table.insert
local pairs = pairs
local stringGsub = string.gsub

local MovieTemplates = {}
local MovieActorTemplates = {}
local MovieSpineActorTemplates = {}
local MovieSpineActorV2Templates = {}
local MovieRoleFaceTemplates = {}
local MovieSkipTemplates = {}
local MovieStaffTemplates = {}
local MovieSpeedTemplates = {}
local MovieSkipSummaryTemplates = {}

local IsLoadMovieSkipSummary = false

XMovieConfigs = XMovieConfigs or {}

XMovieConfigs.PLAYER_NAME_REPLACEMENT = "【kuroname】"
XMovieConfigs.TYPE_WRITER_SPEED = CS.XGame.ClientConfig:GetFloat("MovieWriterSpeed") or 0.04
XMovieConfigs.AutoPlayDelay = CS.XGame.ClientConfig:GetInt("AutoPlayDelay")  --自动播放对话默认停留时间
XMovieConfigs.PerWordDelay = CS.XGame.ClientConfig:GetInt("MoviePerWordDelay") --每个字的延迟时间
XMovieConfigs.ITEM_APPEAR_DURATION = CS.XGame.ClientConfig:GetFloat("ItemAppearDuration") --物品Icon淡入时长(秒)
XMovieConfigs.ITEM_DISAPPEAR_DURATION = CS.XGame.ClientConfig:GetFloat("ItemDisappearDuration") --物品Icon淡出时长(秒)
XMovieConfigs.ITEM_MOVIE_DURATION = CS.XGame.ClientConfig:GetFloat("ItemMovieDuration") --物品Icon位移默认时长(秒)
--为方便后续扩展 和策划约定 
--1-5为默认原有actor，层级在特效层之下
--6-10为中间插入横幅actor
--11-12 为左边分屏actor
--13-14为右边分屏actor
--15-17actor，层级在特效层之上，底部对话框之下
--18，对话旁边的头像
--19-21 为背景8的专属演员
XMovieConfigs.MAX_ACTOR_NUM = 21

XMovieConfigs.MAX_SPINE_ACTOR_NUM = 18

-- 运动曲线类型，演出用预制曲线编号（策划填 1..4，留空 = 线性）
XMovieConfigs.MOVIE_CURVE_TYPE = {
    NONE      = 0,
    OUT_QUAD  = 1, -- 先快后慢（缓）
    IN_QUAD   = 2, -- 先慢后快（缓）
    OUT_CUBIC = 3, -- 先快后慢（急）
    IN_CUBIC  = 4, -- 先慢后快（急）
}

-- 通用的spine动画
XMovieConfigs.SpineActorAnim =
{
    PanelActorEnable = "PanelActorEnable",
    PanelActorDisable = "PanelActorDisable",
    PanelActorBlowUp = "PanelActorBlowUp",
    PanelActorDark = "PanelActorDark",
    PanelActorDarkNor = "PanelActorDarkNor",
    PanelActorBlowUpNor = "PanelActorBlowUpNor",
    PanelActorDarkDisable = "PanelActorDarkDisable",
}

XMovieConfigs.SpineActorTrackType =
{
    Base = 0,
    Mouth = 1,
    Face = 2,
}

local InitStaffConfigs = function()
    local paths = CS.XTableManager.GetPaths(TABLE_MOVIE_STAFF_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        MovieStaffTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableMovieStaff, "Id")
    end)
end

local InitSpineActorV2Configs = function()
    MovieSpineActorV2Templates = {}

    if not checkTableExist(TABLE_MOVIE_SPINE_ACTOR_V2_PATH) then
        return
    end

    MovieSpineActorV2Templates = XTableManager.ReadByIntKey(TABLE_MOVIE_SPINE_ACTOR_V2_PATH, XTable.XTableMovieSpineActorV2, "RoleId")
end

function XMovieConfigs.Init()
    MovieActorTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_ACTOR_PATH, XTable.XTableMovieActor, "RoleId")
    MovieSpineActorTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_SPINE_ACTOR_PATH, XTable.XTableMovieSpineActor, "RoleId")
    MovieRoleFaceTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_ROLE_FACE_PATH, XTable.XTableMovieRoleFace, "RoleId")
    MovieSkipTemplates = {}--= XTableManager.ReadByStringKey(TABLE_MOVIE_SKIP_PATH, XTable.XTableMovieSkip, "Id")
    MovieSpeedTemplates = XTableManager.ReadByIntKey(TABLE_MOVIE_SPEED_PATH, XTable.XTableMovieSpeed, "Id")
    InitSpineActorV2Configs()
    InitStaffConfigs()

    IsLoadMovieSkipSummary = false
end

local function GetMoviePath(movieId)
    return stringFormat(TABLE_MOVIE_PATH_PREFIX, movieId)
end

local function InitMovieTemplate(movieId)
    local path = GetMoviePath(movieId)
    MovieTemplates[movieId] = XTableManager.ReadByIntKey(path, XTable.XTableMovieNew, "Id")
end

function XMovieConfigs.CheckMovieConfigExist(movieId)
    local path = stringFormat(TABLE_MOVIE_PATH_PREFIX, movieId)
    return checkTableExist(path)
end

function XMovieConfigs.GetMovieCfg(movieId)
    if not MovieTemplates[movieId] then
        InitMovieTemplate(movieId)
    end

    local config = MovieTemplates[movieId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetMovieCfg", "MovieConfig", stringFormat(TABLE_MOVIE_PATH_PREFIX, movieId), "Id", tostring(movieId))
        return
    end
    return config
end

function XMovieConfigs.DeleteMovieCfgs()
    if MovieTemplates then
        for movieId, _ in pairs(MovieTemplates) do
            local path = GetMoviePath(movieId)
            XTableManager.ReleaseTable(path)
        end
    end
    MovieTemplates = {}
end

function XMovieConfigs.GetActorImgPath(actorId)
    local config = MovieActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorImgPath", "MovieActor", TABLE_MOVIE_ACTOR_PATH, "actorId", tostring(actorId))
        return
    end
    return XModelManager.GetHXRes(config.RoleIcon)
end

function XMovieConfigs.GetActorFacePosVector2(actorId)
    local config = MovieActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorFacePosVector2", "MovieActor", TABLE_MOVIE_ACTOR_PATH, "actorId", tostring(actorId))
        return
    end
    return vector(config.FacePosX, config.FacePosY)
end

function XMovieConfigs.GetActorAvatarPosVector3(actorId)
    local config = MovieActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorFacePosVector2", "MovieActor", TABLE_MOVIE_ACTOR_PATH, "actorId", tostring(actorId))
        return
    end
    return XLuaVector3.New(config.AvatarPosX, config.AvatarPosY, config.AvatarPosZ)
end

-- 18号头像专属缩放：配置未填(0/nil)时默认 1
function XMovieConfigs.GetActorAvatarScale(actorId)
    local config = MovieActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorAvatarScale", "MovieActor", TABLE_MOVIE_ACTOR_PATH, "actorId", tostring(actorId))
        return 1
    end
    local scale = config.AvatarScale
    if not scale or scale == 0 then
        return 1
    end
    return scale
end

function XMovieConfigs.GetActorFaceImgPath(actorId, faceId)
    local config = MovieRoleFaceTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorFaceImgPath", "MovieRoleFace", TABLE_MOVIE_ROLE_FACE_PATH, "actorId", tostring(actorId))
        return
    end

    local face = config.FaceLook[faceId]
    if not face then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetActorFaceImgPath", "FaceLook", TABLE_MOVIE_ROLE_FACE_PATH, "actorId", tostring(actorId) .. " faceId :" .. tostring(faceId))
        return
    end

    return face
end

function XMovieConfigs.GetSpineActorSpinePath(actorId)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorSpinePath", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId))
        return
    end

    return config.SpinePath
end

function XMovieConfigs.GetSpineActorRoleAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorRoleAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.RoleAnims[index]
end

function XMovieConfigs.GetSpineActorRoleAnim2(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorRoleAnim2", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.RoleAnims2[index]
end

function XMovieConfigs.GetSpineActorKouIdleAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorKouIdleAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.KouIdleAnims[index]
end

function XMovieConfigs.GetSpineActorKouTalkAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorKouTalkAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.KouTalkAnims[index]
end

function XMovieConfigs.GetSpineActorTransitionAnim(actorId, index)
    local config = MovieSpineActorTemplates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorTransitionAnim", "MovieSpineActor", TABLE_MOVIE_SPINE_ACTOR_PATH, "actorId", tostring(actorId) .." index:", tostring(index))
        return
    end

    return config.TransitionAnims[index]
end

function XMovieConfigs.IsSpineActorV2(actorId)
    return MovieSpineActorV2Templates[actorId] ~= nil
end

function XMovieConfigs.GetSpineActorV2Config(actorId)
    local config = MovieSpineActorV2Templates[actorId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetSpineActorV2Config", "MovieSpineActorV2", TABLE_MOVIE_SPINE_ACTOR_V2_PATH, "actorId", tostring(actorId))
        return
    end

    return config
end

local function GetMovieSkipConfig(movieId)
    local config = MovieSkipTemplates[movieId]
    if not config then
        XLog.ErrorTableDataNotFound("XMovieConfigs.GetMovieSkipHaveSkipDesc", "MovieSkip", TABLE_MOVIE_SKIP_PATH, "movieId", tostring(movieId))
        return
    end
    return config
end

--region lua端弃用，C#端有调用，暂无法排查C#端相关组件是否还在使用，保留接口并增加输出提示

function XMovieConfigs.GetMovieSkipSkipDesc(movieId)
    XLog.Error('该接口已弃用，已改为XMovieConfigs.TryGetMovieSkipSummaryCfg')
    return ""
end

function XMovieConfigs.IsMovieSkipHaveSkipDesc(movieId)
    XLog.Error('该接口已弃用，已改为XMovieConfigs.CheckIsMovieSkipHaveSummary')
    return false
end

--endregion

--职员表 begin--
local GetStaffConfigs = function(staffPath)
    local config = MovieStaffTemplates[staffPath]
    if not config then
        XLog.Error("XMovieConfigs GetStaffConfig error:配置不存在, Id: " .. staffPath .. ", 配置路径: " .. TABLE_MOVIE_STAFF_PATH)
        return
    end
    return config
end

local GetStaffConfig = function(staffPath, staffId)
    local configs = GetStaffConfigs(staffPath)
    local config = configs[staffId]
    if not config then
        XLog.Error("XMovieConfigs GetStaffConfig error:配置不存在, Id: " .. staffId .. ", 配置路径: " .. TABLE_MOVIE_STAFF_PATH)
        return
    end
    return config
end

function XMovieConfigs.GetStaffIdList(staffPath)
    local staffIds = {}

    local config = GetStaffConfigs(staffPath)
    for staffId in pairs(config) do
        tableInsert(staffIds, staffId)
    end

    return staffIds
end

function XMovieConfigs.GetStaffName(staffPath, staffId)
    local config = GetStaffConfig(staffPath, staffId)
    return stringGsub(config.Name, "\\n", "\n")
end
--职员表 end--

function XMovieConfigs.GetMovieSpeedConfig(id)
    if id then
        local config = MovieSpeedTemplates[id]
        if not config then
            XLog.Error("XMovieConfigs GetMovieSpeedConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_MOVIE_SPEED_PATH)
            return
        end
        return config
    else
        return MovieSpeedTemplates
    end
end

function XMovieConfigs.GetMovieSpeedConfigBySpeed(speed)
    for i, config in pairs(MovieSpeedTemplates) do
        if config.Speed == speed then
            return i, config
        end
    end
    XLog.Error("XMovieConfigs GetMovieSpeedConfigBySpeed error:未找到, Speed: " .. speed .. "对应的配置表, 配置路径: " .. TABLE_MOVIE_SPEED_PATH)
    return 1
end

function XMovieConfigs.GetMovieSkipSummaryCfgById(storyId, noTips)
    if not IsLoadMovieSkipSummary then
        MovieSkipSummaryTemplates = XTableManager.ReadByStringKey(TABLE_MOVIE_SKIP_SUMMARY_PATH, XTable.XTableMovieSkipSummary, "StoryId")
        IsLoadMovieSkipSummary = true
    end
    
    local cfg = MovieSkipSummaryTemplates[storyId]

    if not cfg and not noTips then
        XLog.Error("XMovieConfigs GetMovieSkipSummaryCfgById error:配置不存在, storyId: " .. tostring(storyId) .. ", 配置路径: " .. TABLE_MOVIE_SKIP_SUMMARY_PATH)
    end
    
    return cfg
end

function XMovieConfigs.CheckIsMovieSkipHaveSummary(storyId)
    return not XTool.IsTableEmpty(XMovieConfigs.GetMovieSkipSummaryCfgById(storyId, true)) and true or false
end

function XMovieConfigs.TryGetMovieSkipSummaryCfg(storyId)
    if not XMovieConfigs.CheckIsMovieSkipHaveSummary(storyId) then return nil end

    return XMovieConfigs.GetMovieSkipSummaryCfgById(storyId)
end
