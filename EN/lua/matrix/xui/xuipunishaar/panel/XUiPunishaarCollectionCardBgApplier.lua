--- 图鉴主卡格背景应用层：负责底图、前遮和球值标签，并缓存卡牌显示状态。
---@class XUiPunishaarCollectionCardBgApplier
local XUiPunishaarCollectionCardBgApplier = XClass(nil, "XUiPunishaarCollectionCardBgApplier")

local Reader = require("XUi/XUiPunishaar/Panel/XUiPunishaarCollectionCardBgSettingsReader")
---@param host XUiPanelPunishaarCollectionCard
function XUiPunishaarCollectionCardBgApplier:Ctor(host)
    self._Host = host
end

--- 整卡属性指纹：全等则整体 return（每帧调用退化成一次表比较，对齐 GC 优化任务）。
local function Fingerprint(cardType, cardSize, level, color, ballConsume, ballOutPut)
    return string.format("%s|%s|%s|%s|%s|%s",
            tostring(cardType), tostring(cardSize), tostring(level),
            tostring(color), tostring(ballConsume), tostring(ballOutPut))
end

--- SetSprite 带图变跳过（path==_lastSpritePath 跳过，对齐 GC 优化任务 §3）。
--- RawImage 节点（RImg*）用 SetRawImage，Image 节点（Img*）用 SetSprite；首次按节点检测缓存，热路径避 GetComponent。
---@param node UnityEngine.UI.Image|RawImage|nil
---@param path string|nil
---@param key string 节点键（_lastSpritePath / _isRaw 字典）
function XUiPunishaarCollectionCardBgApplier:_SetSpriteIfChanged(node, path, key)
    if not node then
        return
    end
    if not self._LastSpritePath then
        self._LastSpritePath = {}
    end
    if self._LastSpritePath[key] == path then
        return
    end  -- 图变跳过（含 nil→nil）
    self._LastSpritePath[key] = path
    if path and path ~= "" then
        -- RawImage vs Image 首次检测缓存（node 上 GetComponent RawImage 非空即 RawImage）
        if not self._IsRaw then
            self._IsRaw = {}
        end
        if self._IsRaw[key] == nil then
            local raw = node:GetComponent(typeof(CS.UnityEngine.UI.RawImage))
            self._IsRaw[key] = (not XTool.UObjIsNil(raw)) and true or false
        end
        if self._IsRaw[key] then
            node:SetRawImage(path)
        else
            node:SetSprite(path)
        end
        if not node.gameObject.activeSelf then
            node.gameObject:SetActiveEx(true)
        end
    else
        -- 配置缺：隐节点（nil 守护兜底）
        node.gameObject:SetActiveEx(false)
    end
end

--- 显隐带跳过。
local function SetActiveIfChanged(go, active, lastActiveDict, key)
    if not go then
        return
    end
    if lastActiveDict[key] == active then
        return
    end
    lastActiveDict[key] = active
    go.gameObject:SetActiveEx(active)
end

--- 刷新卡牌视觉框（底图/前遮/球值标签）。
--- 直接传参（禁临时 table ViewModel）：调用方展平传值，避免每帧/每次刷新分配 table。
---@param control XPunishaarControl
---@param cardType number|nil
---@param cardSize number|nil
---@param level number|nil
---@param color number|nil
---@param ballConsume number
---@param ballOutPut number
function XUiPunishaarCollectionCardBgApplier:Refresh(control, cardType, cardSize, level, color, ballConsume, ballOutPut)
    -- 整卡属性指纹缓存：全等 return（热路径退化）
    local fp = Fingerprint(cardType, cardSize, level, color, ballConsume, ballOutPut)
    if self._LastFingerprint == fp then
        return
    end
    self._LastFingerprint = fp

    if not control then
        return
    end
    local host = self._Host

    if not self._LastActive then
        self._LastActive = {}
    end

    -- 底图（Level 维度）
    self:_SetSpriteIfChanged(host.RImgQualityBg, Reader.GetBgSprite(control, cardType, cardSize, level), "bg")
    -- 前遮（无依赖）
    self:_SetSpriteIfChanged(host.RImgFrontBg, Reader.GetFrontSprite(control, cardType, cardSize), "front")

    -- 球值标签（Color 维度，产/消互斥）
    local ball = Reader.GetBallDisplay(control, ballConsume, ballOutPut, color)
    self:_SetSpriteIfChanged(host.ImgBallInBg, ball.showIn and ball.bgSprite or nil, "ballInBg")
    SetActiveIfChanged(host.ImgBallInBg, ball.showIn, self._LastActive, "ballInBg")
    self:_SetSpriteIfChanged(host.ImgBallOutBg, ball.showOut and ball.bgSprite or nil, "ballOutBg")
    SetActiveIfChanged(host.ImgBallOutBg, ball.showOut, self._LastActive, "ballOutBg")
    self:_SetSpriteIfChanged(host.ImgBall, ball.iconSprite, "ball")
    local showBall = ball.showIn or ball.showOut
    SetActiveIfChanged(host.ImgBall, showBall, self._LastActive, "ball")
end

return XUiPunishaarCollectionCardBgApplier
