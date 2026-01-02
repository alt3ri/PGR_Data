---@class XUiDlcMultiPlayerCompetitionBulletChatGrid : XUiNode
---@field private _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerCompetitionBulletChatGrid = XClass(XUiNode, "XUiDlcMultiPlayerCompetitionBulletChatGrid")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp

function XUiDlcMultiPlayerCompetitionBulletChatGrid:OnStart(descFormat)
    self._CachedDanmakuDesc = descFormat or ""
    ---@type UnityEngine.RectTransform
    self._RectTransform = self.GameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))

    self.Select.enabled = false
    self.CanvasGroup.alpha = 0
end

---@param danmakuData XDlcMultiplayerDanmakuData 弹幕数据
---@param discussion XDlcMultiMouseHunterDiscussion 讨论数据
function XUiDlcMultiPlayerCompetitionBulletChatGrid:Refresh(danmakuData, discussion)
    if not danmakuData then
        XLog.Error("XUiDlcMultiPlayerCompetitionBulletChatGrid:Refresh - danmakuData is nil")
        return
    end

    if not discussion then
        XLog.Error("XUiDlcMultiPlayerCompetitionBulletChatGrid:Refresh - discussion is nil")
        return
    end

    -- 初始化头像
    XUiPlayerHead.InitPortrait(danmakuData.HeadPortraitId, danmakuData.HeadFrameId, self.Head)
    -- 获取阵营标题
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    local title = danmakuData.Camp == CampEnum.Camp1 and discussionConfig.Camp1 or discussionConfig.Camp2
    -- 设置弹幕文本
    self.TxtDetail.text = string.format(self._CachedDanmakuDesc, danmakuData.PlayerName or "", title or "", danmakuData.BpLevel or 0)
    -- 设置选中状态
    self.Select.enabled = danmakuData.PlayerId == XPlayer.Id
end

-- 设置锚点位置
---@param x number X轴位置
---@param y number Y轴位置
function XUiDlcMultiPlayerCompetitionBulletChatGrid:SetAnchoredPosition(x, y)
    self._RectTransform:SetAnchoredPosition(x, y)
end

-- 获取宽度
function XUiDlcMultiPlayerCompetitionBulletChatGrid:GetWidth()
    return self._RectTransform.rect.width
end

-- 移动到X位置
---@param x number X轴位置
---@param duration number 持续时间
---@param callback function 移动完成回调
function XUiDlcMultiPlayerCompetitionBulletChatGrid:MoveToX(x, duration, callback)
    self:StopTween()
    self._CurrentTween = self._RectTransform:DOAnchorPosX(x, duration):SetEase(CS.DG.Tweening.Ease.Linear):OnComplete(function()
        self._CurrentTween = nil
        if callback then
            callback()
        end
    end)
end

-- 停止当前的Tween
function XUiDlcMultiPlayerCompetitionBulletChatGrid:StopTween()
    if self._CurrentTween then
        self._CurrentTween:Kill()
        self._CurrentTween = nil
    end
end

-- 显示
function XUiDlcMultiPlayerCompetitionBulletChatGrid:Show()
    self.CanvasGroup.alpha = 1
end

-- 隐藏
function XUiDlcMultiPlayerCompetitionBulletChatGrid:Hide()
    self:StopTween()
    self.CanvasGroup.alpha = 0
end

return XUiDlcMultiPlayerCompetitionBulletChatGrid
