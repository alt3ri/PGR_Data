---@class XAudioAgency : XAgency
---@field private _Model XAudioModel
local XAudioAgency = XClass(XAgency, "XAudioAgency")
function XAudioAgency:OnInit()
    --初始化一些变量
end

function XAudioAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XAudioAgency:InitEvent()
    --实现跨Agency事件注册
    self:AddAgencyEvent(XEventId.EVENT_PRE_ENTER_FIGHT, self.OpenStageAudioLog, self)
    self:AddAgencyEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.CloseStageAudioLogBySettle, self)
    self:AddAgencyEvent(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.OnLogin,self)
end

function XAudioAgency:RemoveEvent()
    self:RemoveEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, self.OpenStageAudioLog)
    self:RemoveEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.CloseStageAudioLogBySettle)
    self:RemoveEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.OnLogin)
end

function XAudioAgency:OpenStageAudioLog(stageId)
    if not XMain.IsWindowsEditor then
        return
    end

    if not stageId then
        -- XLog.Error("尝试记录音频数据失败，stageId为空", stageId)
        return
    end

    if not CS.XAudioManager.IsLogCollect then
        CS.XAudioManager.SetIsLogCollect()
    end
    CS.XAudioManager.StopGenerateLogFile() -- 避免日志混合冲突，先完全停止一遍日志记录
    CS.XAudioManager.StartGenerateLogFile(stageId)
    self.RecordStageId = stageId
end

function XAudioAgency:CloseStageAudioLogByStageId(isUpload)
    if not XTool.IsNumberValid(self.RecordStageId) then
        return
    end

    local stageCfg = XMVCA.XFuben:GetStageCfg(self.RecordStageId)
    if not stageCfg then
        XLog.Error("关卡数据错误", self.RecordStageId)
        return
    end

    if isUpload then
        local allLog = CS.XAudioManager.GetCurFullLog()
        if string.IsNilOrEmpty(allLog) then
            XLog.Error("CriAuLog上报失败 音频日志上报功能在战斗中被异常关闭")
            return
        end

        local titleName = string.format("CriAuLog_%s_%s", self.RecordStageId, stageCfg.Name)
        local url = string.format("http://10.0.30.108:8080/POST?file_name=%s", titleName)
        CS.XHttp.PostAsync(url, allLog)
    end

    self.RecordStageId = nil
    CS.XAudioManager.StopGenerateLogFile()
end

function XAudioAgency:CloseStageAudioLogBySettle()
    if not XMain.IsWindowsEditor then
        return
    end

    local allLog = CS.XAudioManager.GetCurFullLog()
    if string.IsNilOrEmpty(allLog) then
        XLog.Error("CriAuLog上报失败 音频日志上报功能在战斗中被异常关闭")
        return
    end

    self:CloseStageAudioLogByStageId(true)
end

function XAudioAgency:CloseStageAudioLogByReplay()
end

function XAudioAgency:OnLogin()
    self:InitAlbum()
    self:InitMainNeedCueId()
end

-- CD机 config start
-- 该方法仅检查表格格式 无功能
function XAudioAgency:InitAlbum()
    local AlbumTemplates = self:GetModelMusicPlayerAlbum()

    local cueIdDic = {}
    local id
    local cueId
    local priority
    for _, template in pairs(AlbumTemplates) do
        id = template.Id
        cueId = template.CueId
        if not cueId or cueId == 0 then
            XLog.Error("InitAlbum", "cueId", "id", tostring(id))
        end

        if not cueIdDic[cueId] then
            cueIdDic[cueId] = true
        else
            XLog.Error("InitAlbum 错误, 存在相同的cueId: " .. cueId .. "检查配置表 MusicPlayerAlbum.tab")
        end

        priority = template.Priority
        if not priority or priority == 0 then
            XLog.Error("InitAlbum", "Priority", "id", tostring(id))
        end
    end
end

function XAudioAgency:GetAlbumIdList()
    if XTool.IsTableEmpty(self._Model.AlbumIdList) then
        self._Model:CreateAlbumIdList()
    end

    return self._Model.AlbumIdList
end

function XAudioAgency:GetAlbumTemplateById(id)
    local AlbumTemplates = self:GetModelMusicPlayerAlbum()
    if not AlbumTemplates or not XTool.IsNumberValid(id) or id == 0 then
        return nil
    end

    local success, template = AlbumTemplates:TryGetValue(id)
    if success then
        return template
    else
        XLog.Error("GetAlbumTemplateById: 未找到配置, albumId=" .. tostring(id))
        return nil
    end
end

function XAudioAgency:IsHaveAlbumById(id)
    local AlbumTemplates = self:GetModelMusicPlayerAlbum()
    if not AlbumTemplates or not XTool.IsNumberValid(id) or id == 0 then
        return false
    end

    return AlbumTemplates:ContainsKey(id)
end

function XAudioAgency:GetAlbumTemplateByCueId(cueId)
    local albumId = self._Model:GetCueIdToMusicAlbumIdDic()[cueId]
    if not albumId then
        return nil
    end

    return self:GetAlbumTemplateById(albumId)
end
-- CD机 config end

-- CD机 manager start
function XAudioAgency:InitMainNeedCueId()
    local albumId = XSaveTool.GetData(self._Model.UiMainSavedAlbumIdKey)

    local isAlbumIdValid = XTool.IsNumberValid(albumId) and albumId ~= 0
    if isAlbumIdValid and self:IsHaveAlbumById(albumId) then
    else
        if isAlbumIdValid then
            XLog.Warning("InitMainNeedCueId: 存档中的 albumId=" .. tostring(albumId) .. " 在配置表中不存在,已重置为默认值")
        end

        XSaveTool.SaveData(self._Model.UiMainSavedAlbumIdKey, nil)
        albumId = self._Model.DefaultAlbumId
        if albumId == 0 then
            XLog.Error("Client/Config/ClientConfig.tab 表里面的 MusicPlayerMainViewNeedPlayedAlbumId 字段对应的值不能为0")
            return
        end
    end

    local template = self:GetAlbumTemplateById(albumId)
    if not template then
        XLog.Error("InitMainNeedCueId: 无法获取专辑配置, albumId=" .. tostring(albumId))
        return
    end

    local cueId = template.CueId
    if self:CheckMusicCanPlayByAlbum(cueId) then
        self._Model.UiMainNeedPlayedAlbumId = albumId
        CS.XAudioManager.UiMainNeedPlayedBgmCueId = cueId
    else
        self._Model.UiMainNeedPlayedAlbumId = self._Model.DefaultAlbumId
        local defaultTemplate = self:GetAlbumTemplateById(self._Model.DefaultAlbumId)
        if defaultTemplate then
            CS.XAudioManager.UiMainNeedPlayedBgmCueId = defaultTemplate.CueId
        else
            XLog.Error("InitMainNeedCueId: 默认专辑配置无效, DefaultAlbumId=" .. tostring(self._Model.DefaultAlbumId))
        end
    end
end

function XAudioAgency:ChangeUiMainAlbumId(albumId)
    local template = self:GetAlbumTemplateById(albumId)
    local cueId = template.CueId

    -- 检测CD机分包是否下载完成，未完成则拦截切换操作
    if not XMVCA.XSubPackage:CheckSubpackageDownloadByFunctionType(XFunctionManager.FunctionName.UiMainMusicAlbum) then
        return false
    end

    self._Model.UiMainNeedPlayedAlbumId = albumId
    XSaveTool.SaveData(self._Model.UiMainSavedAlbumIdKey, albumId)
    CS.XAudioManager.UiMainNeedPlayedBgmCueId = cueId
    return true
end

function XAudioAgency:GetUiMainNeedPlayedAlbumId()
    -- 与 ChangeUiMainAlbumId 的写入校验口径保持一致：只校验 CD 机功能对应的分包，
    if not XMVCA.XSubPackage:CheckSubpackageDownloadByFunctionType(XFunctionManager.FunctionName.UiMainMusicAlbum) then
        return self._Model.DefaultAlbumId
    end
    return self._Model.UiMainNeedPlayedAlbumId
end
-- CD机 manager end

----------public start----------
-- 检测cueId当前是否能在CD机上播放
function XAudioAgency:CheckMusicCanPlayByAlbum(cueId)
    local albumConfig = self:GetAlbumTemplateByCueId(cueId)
    if not albumConfig then
        return false
    end

    -- 没有condition就是默认可以播放
    local conditionId = albumConfig.ConditionId
    if XTool.IsNumberValid(conditionId) then
        return XConditionManager.CheckCondition(conditionId)
    end

    return true
end

-- get Model config
function XAudioAgency:GetModelMusicPlayerAlbum()
    return self._Model:GetMusicPlayerAlbum()
end
--

----------public end----------

----------private start----------


----------private end----------

return XAudioAgency