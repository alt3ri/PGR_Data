---@class XUiArenaPopupNewRecord : XLuaUi
---@field TxtName UnityEngine.UI.Text
---@field TxtScore UnityEngine.UI.Text
---@field BtnBack XUiComponent.XUiButton
---@field private _TargetScore number 目标分数
---@field private _ScoreTweenId number 分数动画定时器ID
local XUiArenaPopupNewRecord = XLuaUiManager.Register(XLuaUi, "UiArenaPopupNewRecord")

function XUiArenaPopupNewRecord:OnAwake()
    self:_RegisterButtonClicks()
    self._TargetScore = 0
    self._ScoreTweenId = nil
end

---@param data table 新纪录数据 {areaName, buffName, score, areaId, distributeType}
function XUiArenaPopupNewRecord:OnStart(data)
    if not data then
        return
    end
    
    -- 设置Buff名称
    local buffName = data.buffName or ""
    self.TxtName.text = buffName
    
    -- 保存目标分数，动画在 OnEnable 中播放
    self._TargetScore = data.score or 0
    self.TxtScore.text = "0"
end

function XUiArenaPopupNewRecord:OnEnable()
    -- 播放分数动画：从 0 上涨到目标分数
    self:_PlayScoreAnimation()
end

function XUiArenaPopupNewRecord:OnDisable()
end

function XUiArenaPopupNewRecord:OnDestroy()
    -- 清理动画定时器
    self:_ClearScoreAnimation()
end

-- region 私有方法

function XUiArenaPopupNewRecord:_RegisterButtonClicks()
    if self.BtnBack then
        self:RegisterClickEvent(self.BtnBack, self.Close, true)
    end
end

--- 播放分数动画：从 0 上涨到目标分数
function XUiArenaPopupNewRecord:_PlayScoreAnimation()
    if not self.TxtScore or self._TargetScore <= 0 then
        return
    end
    
    -- 动画时长（秒）
    local animaTime = 1.0 -- 可以根据需要调整
    
    -- 使用 XUiHelper.Tween 实现平滑的数值上涨动画
    self._ScoreTweenId = XUiHelper.Tween(animaTime, function(progress)
        if XTool.UObjIsNil(self.Transform) or not self.TxtScore then
            return
        end
        
        -- 计算当前显示的分数（从 0 到目标分数）
        local currentScore = math.floor(progress * self._TargetScore)
        self.TxtScore.text = tostring(currentScore)
    end, function()
        -- 动画结束，确保显示最终分数
        if not XTool.UObjIsNil(self.Transform) and self.TxtScore then
            self.TxtScore.text = tostring(self._TargetScore)
        end
        self._ScoreTweenId = nil
    end)
end

--- 清理分数动画
function XUiArenaPopupNewRecord:_ClearScoreAnimation()
    if self._ScoreTweenId then
        -- XUiHelper.Tween 返回的 ID 可以通过 XScheduleManager 取消
        -- 但通常 Tween 会在界面销毁时自动清理，这里主要是重置状态
        self._ScoreTweenId = nil
    end
end

-- endregion

return XUiArenaPopupNewRecord

