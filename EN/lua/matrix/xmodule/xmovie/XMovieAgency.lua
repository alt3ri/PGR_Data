---@class XMovieAgency : XAgency
---@field _Model XMovieModel
local XMovieAgency = XClass(XAgency, "XMovieAgency")

function XMovieAgency:OnInit()
    --初始化一些变量
    self.EnumConst = require("XModule/XMovie/XMovieEnumConst")
end

function XMovieAgency:InitRpc()
    -- 注册服务器事件
end

function XMovieAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()

    self.RequestName = {
        AddStageBookmarkRequest = "AddStageBookmarkRequest",                    -- 添加关卡书签
        GetStageBookmarkRequest = "GetStageBookmarkRequest",                    -- 获取关卡书签
        DeleteStageBookmarkRequest = "DeleteStageBookmarkRequest",              -- 删除关卡书签
    }
end

--region 配置表
-- 获取ClientConfig表配置
function XMovieAgency:GetClientConfig(key, index)
    return self._Model:GetClientConfig(key, index)
end

-- 获取ClientConfig表配置所有参数
function XMovieAgency:GetClientConfigParams(key)
    return self._Model:GetClientConfigParams(key)
end
--endregion

--region rpc
-- 请求剧情选项记录
function XMovieAgency:RequestMovieOptions(movieId)
    if not XLoginManager.IsLogin() then
        return
    end

    local isCfgExit = self._Model:IsRecordOptionsConfigExit(movieId)
    if not isCfgExit then
        return
    end

    local req = { MovieId = movieId }
    XNetwork.CallWithAutoHandleErrorCode("QueryMovieOptionsRequest", req, function(res)
        self._Model:UpdateMovieOptions(movieId, res.MovieList)
    end)
end

-- 请求记录剧情选项
function XMovieAgency:RequestRecordOption(movieId, actionId, optionIndex)
    local isNeed = self._Model:IsOptionNeedRecord(movieId, actionId, optionIndex)
    if not isNeed then
        return
    end

    local optionId = self._Model:PackOptionId(actionId, optionIndex)
    local req = { MovieId = movieId, OptionId = optionId }
    XNetwork.CallWithAutoHandleErrorCode("UpdateMovieOptionsRequest", req, function(res)
        self._Model:AddMovieOption(movieId, optionId)
    end)
end

-- 是否选择过选项
function XMovieAgency:IsOptionPassed(movieId, actionId, optionIndex)
    return self._Model:IsOptionPassed(movieId, actionId, optionIndex)
end

-- 请求添加关卡书签
function XMovieAgency:RequestAddStageBookmark(cb)
    local stageId = XDataCenter.MovieManager.GetStageId()
    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    local actionId = XDataCenter.MovieManager.GetCurPlayingActionId()
    if not XTool.IsNumberValidEx(stageId) or string.IsNilOrEmpty(movieId) or not XTool.IsNumberValidEx(actionId) then
        return
    end
    
    local bookmarkData = self._Model:GetBookmarkData()
    if bookmarkData and bookmarkData.StageId == stageId and bookmarkData.MovieId == movieId and bookmarkData.ActionId == actionId then
        if cb then cb() end
        return
    end

    local isCover = bookmarkData ~= nil
    local optionDic = XDataCenter.MovieManager.GetSelectionDataDic()
    XMessagePack.MarkAsTable(optionDic)
    local req = { StageId = stageId, MovieId = movieId, ActionId = actionId, OptionInfos = optionDic }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.AddStageBookmarkRequest, req, function(res)
        self._Model:SetBookmarkData(req)
        if cb then cb() end

        -- 埋点
        local dict = {}
        dict["stage_id"] = stageId
        dict["movie_id"] = movieId
        dict["is_cover"] = isCover and 1 or 0
        CS.XRecord.Record(dict, "200020", "StoryBookmarkSave")
    end)
end

-- 请求获取关卡书签
function XMovieAgency:RequestGetStageBookmark(cb)
    local bookmarkData, isRequest = self._Model:GetBookmarkData()
    if bookmarkData or isRequest then
        if cb then cb(bookmarkData) end
        return
    end
    
    local req = {}
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.GetStageBookmarkRequest, req, function(res)
        self._Model:SetBookmarkData(res.StageBookmarkData, true)
        if cb then cb(res.StageBookmarkData) end
    end)
end

-- 请求删除关卡书签
function XMovieAgency:RequestDeleteStageBookmark()
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.DeleteStageBookmarkRequest, nil, nil)
    self._Model:SetBookmarkData()
end
--endregion

--region 参数转换
-- 参数转数字
function XMovieAgency:ParamToNumber(param)
    if param and param ~= "" then
        return tonumber(param)
    else
        return 0
    end
end

-- 切割参数
function XMovieAgency:SplitParam(param, splitStr, isNumber)
    if not param or param == "" then
        return {}
    end

    local result = string.Split(param, splitStr)
    if isNumber then
        local cnt = #result
        for i = 1, cnt do
            result[i] = tonumber(result[i])
        end
    end
    return result
end

-- 解析运动曲线参数：空 → nil；1..4 → 对应类型号；非法值报错并返回 nil
function XMovieAgency:ParamToCurveType(param)
    if string.IsNilOrEmpty(param) then
        return nil
    end
    local n = tonumber(param)
    local T = XMovieConfigs.MOVIE_CURVE_TYPE
    if n == T.OUT_QUAD or n == T.IN_QUAD or n == T.OUT_CUBIC or n == T.IN_CUBIC then
        return n
    end
    XLog.Error("XMovieAgency:ParamToCurveType invalid value: " .. tostring(param))
    return nil
end

-- Lua 自定义 Tween 用：返回 t -> easedT 的函数（nil 表示线性）
function XMovieAgency:GetCurveEvaluator(curveType)
    local T = XMovieConfigs.MOVIE_CURVE_TYPE
    if curveType == T.OUT_QUAD then
        return function(t) return 1 - (1 - t) * (1 - t) end
    elseif curveType == T.IN_QUAD then
        return function(t) return t * t end
    elseif curveType == T.OUT_CUBIC then
        return function(t) local k = 1 - t; return 1 - k * k * k end
    elseif curveType == T.IN_CUBIC then
        return function(t) return t * t * t end
    end
    return nil
end

-- DOTween 用：返回 CS.DG.Tweening.Ease 枚举（nil 表示不设置 ease，保持线性）
function XMovieAgency:GetDOTweenEase(curveType)
    local T = XMovieConfigs.MOVIE_CURVE_TYPE
    local Ease = CS.DG.Tweening.Ease
    if curveType == T.OUT_QUAD then
        return Ease.OutQuad
    elseif curveType == T.IN_QUAD then
        return Ease.InQuad
    elseif curveType == T.OUT_CUBIC then
        return Ease.OutCubic
    elseif curveType == T.IN_CUBIC then
        return Ease.InCubic
    end
    return nil
end

-- 格式化剧情文本
function XMovieAgency:FormatContent(content)
    if not content or content == "" then
        return ""
    end
    -- 替换玩家名称
    content = XDataCenter.MovieManager.ReplacePlayerName(content)
    -- 提取指挥官性别文本
    content = self:ExtractGenderContent(content)
    -- 替换十进制特殊符号
    content = self:ReplaceDecimalismCodeToStr(content)
    -- 字符串换行符可用化
    content = XUiHelper.ConvertLineBreakSymbol(content)

    return content
end

-- 提取指挥官性别对应文本
function XMovieAgency:ExtractGenderContent(content, specGender)
    local gender = nil
    if specGender and specGender > 0 then
        gender = specGender
    else
        gender = XPlayer.GetShowGender()
    end
    
    if gender == XEnumConst.PLAYER.GENDER_TYPE.MAN then
        content = string.gsub(content, "<[WT]>.-</[WT]>", "")  -- 同时匹配<W>和<T>
        content = string.gsub(content, "</?M>", "")  -- 匹配<M>和</M>
        return content
    elseif gender == XEnumConst.PLAYER.GENDER_TYPE.WOMAN then
        content = string.gsub(content, "<[MT]>.-</[MT]>", "")  -- 同时匹配<M>和<T>
        content = string.gsub(content, "</?W>", "")  -- 匹配<W>和</W>
        return content
    elseif gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY then
        local isManOrWoman = string.gmatch(content, "<T>.-</T>")
        if not isManOrWoman() then
            content = string.gsub(content, '<W>.-</W>', "")
            content = string.gsub(content, "</?M>", "")  -- 匹配<M>和</M>
        else
            content = string.gsub(content, "<[MW]>.-</[MW]>", "")  -- 同时匹配<M>和<W>
            content = string.gsub(content, "</?T>", "")  -- 匹配<T>和</T>
        end
    end
    return content
end


-- 将十进制编码转换成字符串
-- 配置表string和List<string>里的文本只要有英文逗号，加载出来的文本会自动增加英文的双引号
-- 配置示例：配置{226|153|170}，运行时转{226,153,170}
function XMovieAgency:ReplaceDecimalismCodeToStr(content)
    local replaceDic = {}
    for matchStr in string.gmatch(content, "{.-}") do
        if not replaceDic[matchStr] then
            local bytesStr = string.gsub(matchStr, "|", ",")
            local bytes = load("return " .. bytesStr)()
            local str = self:BytesToStr(bytes)
            content = string.gsub(content, matchStr, str)
            replaceDic[matchStr] = true
        end
    end
    return content
end

-- 十进制数组转字符串
function XMovieAgency:BytesToStr(bytes)
    local str = ""
    for i, v in ipairs(bytes) do
        str = str .. string.char(v)
    end
    return str
end
--endregion

--region 播放剧情、跳转Bookmark

-- 通过GM指令播放剧情
-- c#调用 XDebuggerStoryList.cs
function XMovieAgency.PlayMovieByDebugger(movieId, actionIdStr, optionStr)
    if string.IsNilOrEmpty(movieId) then
        XUiManager.TipError("请先输入MovieId!")
        return
    end
    
    local actionId
    if not string.IsNilOrEmpty(actionIdStr) then
        actionId = tonumber(actionIdStr)
        if not actionId then
            XUiManager.TipError("请检查开始的ActionId，请输入一个整数！")
            return
        end
    end

    local optionDic = {}
    if not string.IsNilOrEmpty(actionIdStr) then
        local result = {}
        -- 使用 gmatch 匹配非逗号、非分号的连续字符
        for word in string.gmatch(optionStr, "[^,;]+") do
            table.insert(result, word)
        end

        for i = 1, #result, 2 do
            local aId = tonumber(result[i])
            local selIndex = tonumber(result[i + 1])
            optionDic[aId] = selIndex
        end
    end
    XDataCenter.MovieManager.PlayMovie(movieId, nil, nil, nil, nil, actionId, optionDic)
end

-- 获取书签数据
function XMovieAgency:GetBookmarkData()
    return self._Model:GetBookmarkData()
end

-- 获取书签名称
function XMovieAgency:GetBookmarkName()
    local bookmarkData = self:GetBookmarkData()
    if not bookmarkData then return "" end
    
    local stageId = bookmarkData.StageId
    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
    if stageCfg.Type == XEnumConst.FuBen.StageType.Mainline then
        local chapterOrderId = XDataCenter.FubenMainLineManager.GetChapterOrderIdByStageId(stageId)
        return string.format("%s %s-%s", stageCfg.Name, chapterOrderId, stageCfg.OrderId)

    elseif stageCfg.Type == XEnumConst.FuBen.StageType.Mainline2 then
        local mainId = XMVCA.XMainLine2:GetStageMainId(stageId)
        local title = XMVCA.XMainLine2:GetMainTitle(mainId)
        local specialOrder = XMVCA.XMainLine2:GetStageSpecialorder(stageId)
        return string.format("%s%s %s-%s", specialOrder or "", stageCfg.Name, title, stageCfg.OrderId)

    -- 浮点纪实
    elseif stageCfg.Type == XEnumConst.FuBen.StageType.ShortStory then
        local mainId, chapterId = XFubenShortStoryChapterConfigs.GetStageMainId(stageId)
        local extralName = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(chapterId)
        return string.format("%s %s-%s", stageCfg.Name, extralName, stageCfg.OrderId)
        
    -- 外篇
    elseif stageCfg.Type == XEnumConst.FuBen.StageType.ExtraChapter then
        local mainId, chapterId = XFubenExtraChapterConfigs.GetStageMainId(stageId)
        local name  =XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(chapterId)
        return string.format("%s %s-%s", stageCfg.Name, name, stageCfg.OrderId)
        
    end
    return ""
end

-- 播放书签剧情
function XMovieAgency:PlayBookmarkMovie()
    local bookmarkData = self:GetBookmarkData()
    if not bookmarkData then return end

    -- 请求删除书签
    self:RequestDeleteStageBookmark()

    local stageId = bookmarkData.StageId
    local stageType = XMVCA.XFuben:GetStageType(stageId)
    -- 旧主线章节界面
    if stageType == XEnumConst.FuBen.StageType.Mainline then
        XDataCenter.FubenMainLineManager.OpenMainLineChapterOrStage(stageId)

    -- 新主线章节界面
    elseif stageType == XEnumConst.FuBen.StageType.Mainline2 then
        XMVCA.XMainLine2:OpenChapterUiByStageId(stageId)
        
    -- 旧浮点纪实
    elseif stageType == XEnumConst.FuBen.StageType.ShortStory then
        XDataCenter.ShortStoryChapterManager:ExOpenChapterUiByStageId(stageId)
        
    -- 外篇
    elseif stageType == XEnumConst.FuBen.StageType.ExtraChapter then
        XDataCenter.ExtraChapterManager:ExOpenChapterUiByStageId(stageId)
    end
    
    XDataCenter.MovieManager.PlayMovie(bookmarkData.MovieId, function()
        self:OnBookmarkMovieEnd(bookmarkData)
    end, nil, nil, nil, bookmarkData.ActionId, bookmarkData.OptionInfos, stageId)
end

-- 书签剧情播放结束回调
function XMovieAgency:OnBookmarkMovieEnd(bookmarkData)
    local stageId = bookmarkData.StageId
    if not XTool.IsNumberValidEx(stageId) then return end

    local movieId = bookmarkData.MovieId
    local isBeginStory = XMVCA.XFuben:IsStageBeginStory(stageId, movieId)
    if not isBeginStory then return end

    -- 新主线纯剧情关卡，不需要进战斗
    if XMVCA.XMainLine2:IsStageExit(stageId) then
        local detailType = XMVCA.XMainLine2:GetStageDetailType(stageId)
        if detailType == XEnumConst.MAINLINE2.STAGE_DETAIL_TYPE.MOVIE then
            return
        end
    end
    -- 旧主线纯剧情关卡，不需要进战斗
    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        return
    end
    
    -- 速通关卡战斗
    local isSpeedrun = XMVCA.XPlotExhibition:GetIsSpeedrun(stageId)
    if isSpeedrun then
        local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
        local team = XDataCenter.TeamManager.GetXTeamSpeedrun(stageId)
        XMVCA.XFuben:EnterFight(stageConfig, team:GetId(), nil, nil, nil, nil, true)
        return
    end
    
    -- 主线关卡战斗
    local team
    local stageConfig = XMVCA.XFuben:GetStageCfg(stageId)
    local robots = stageConfig.RobotId
    if #robots > 0 then
        team = XDataCenter.TeamManager.GetXTeamByStageId(stageId)
        team:UpdateEntityIds(XTool.Clone(robots))
    else
        team = XDataCenter.TeamManager.GetMainLineTeam()
    end
    XMVCA.XFuben:EnterFightByStageId(stageId, team:GetId(), nil, nil, nil, nil, true)
end

--endregion


-- 检查需要设置性别
function XMovieAgency:CheckTipsSetGender(movieId)
    -- 已设置性别
    if XPlayer.Gender and  XPlayer.Gender ~= 0 then return false end

    --local movieCfg = XMovieConfigs.GetMovieCfg(movieId)
    XLuaUiManager.Open("UiPlayer")
    XLuaUiManager.Open('UiPlayerPopupSetGender')
    return true
end

-- 获取第三性别开关配置
function XMovieAgency:GetOpenMovieThirdGender()
   return self._Model:IsOpenMovieThirdGender()
end

function XMovieAgency:GetOpenMovieSkipThirdGender()
    return self._Model:IsOpenMovieSkipThirdGender()
end

return XMovieAgency