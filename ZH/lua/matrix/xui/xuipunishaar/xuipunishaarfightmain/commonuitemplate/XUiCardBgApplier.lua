--- 卡牌显示 Bg 应用层：持 5 共享节点，Refresh 调 Reader 取 sprite → SetSprite（图变跳过）+ 显隐（跳过）+ 整卡属性指纹缓存。
--- ComShop / ComBattle 各 New 一个实例挂自己的 5 节点；5 共享节点逻辑单份，两 Com 不再复制。#64
--- 独有节点不归本类：ComBattle 自接 RImgOutlineGroup、GridBattleCard 自接 PnlMask（调 Reader 取 sprite）。
---@class XUiCardBgApplier
local XUiCardBgApplier = XClass(nil, "XUiCardBgApplier")

local Reader = require("XModule/XPunishaar/SubModules/InGame/XPunishaarCardBgSettingsReader")

---@param host XUiComShopCardShow|XUiComBattleCardShow 持 5 节点（RImgQualityBg/RImgFrontBg/ImgBallInBg/ImgBallOutBg/ImgBall）+ _Control
function XUiCardBgApplier:Ctor(host)
    self._Host = host
end

--- 整卡属性指纹：全等则整体 return（每帧调用退化成一次表比较，对齐 GC 优化任务）。
-- 数值打包指纹（cardId+level+realConsume+realOutPut 4 字段）：
-- cardId 隐含 type/size/color/config；level 独立；real 含 buff。cardId 变时缓存失效防球区类型错位。
-- 位分配：cardId 32bit（< 2^32，覆盖未来迭代）+ level 8bit（< 256，三级够用余量大）+ real 各 8bit。
-- 乘法等价 << 24/16/8（0x100=2^8 等）；float < 2^53 无精度丢（cardId 32bit + level 8bit = 40bit < 53）。
local function Fingerprint(cardId, level, realConsume, realOutPut)
    return (cardId or 0) * 0x1000000             -- << 24 (cardId 32bit, < 2^32)
            + (level or 0) * 0x10000            -- << 16 (level 8bit, < 256)
            + math.floor(realConsume or 0) * 0x100  -- << 8 (8bit)
            + math.floor(realOutPut or 0)          -- << 0 (8bit)
end

--- SetSprite 带图变跳过（path==_lastSpritePath 跳过，对齐 GC 优化任务 §3）。
--- RawImage 节点（RImg*）用 SetRawImage，Image 节点（Img*）用 SetSprite；首次按节点检测缓存，热路径避 GetComponent。
---@param node UnityEngine.UI.Image|RawImage|nil
---@param path string|nil
---@param key string 节点键（_lastSpritePath / _isRaw 字典）
function XUiCardBgApplier:_SetSpriteIfChanged(node, path, key)
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

--- 材质球带 path 缓存跳过（同 _SetSpriteIfChanged 范式，材质球版）：path 不变跳过 Load+赋值，配置缺 Error。
--- 材质球共享（多卡同 Type/Size 同 Material 引用，只读赋值不改属性，安全；后期动态参数需克隆再议）。#LevelupFire
---@param node UnityEngine.UI.RawImage|nil
---@param path string|nil
---@param key string
function XUiCardBgApplier:_SetMaterialIfChanged(node, path, key)
    if not node then
        return
    end
    if not self._LastSpritePath then
        self._LastSpritePath = {}
    end
    if self._LastSpritePath[key] == path then
        return
    end  -- path 不变跳过（含 nil→nil，每帧调退化一次表比较）
    self._LastSpritePath[key] = path
    if not path or path == "" then
        XLog.Error("[CardBgApplier] ActiveVFX 材质球路径缺失（配置误删？）key=" .. tostring(key))
        return
    end
    local mat = self._Host._Control:GetLoader():Load(path)
    if XTool.UObjIsNil(mat) then
        XLog.Error("[CardBgApplier] ActiveVFX 材质球加载失败 path=" .. tostring(path))
        return
    end
    node.material = mat
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
---@param gameControl table
---@param cardType number|nil
---@param cardSize number|nil
---@param level number|nil
---@param color number|nil
---@param ballConsume number
---@param ballOutPut number
function XUiCardBgApplier:Refresh(gameControl, cardId, cardType, cardSize, level, color, configConsume, configOutPut, realConsume, realOutPut)
    -- 整卡属性指纹缓存：全等 return（cardId 隐含 type/size/color/config + level + real 含 buff）
    local fp = Fingerprint(cardId, level, realConsume, realOutPut)
    if self._LastFingerprint == fp then
        return
    end
    self._LastFingerprint = fp

    if not gameControl then
        return
    end
    local host = self._Host

    if not self._LastActive then
        self._LastActive = {}
    end

    -- 底图（Level 维度）
    self:_SetSpriteIfChanged(host.RImgQualityBg, Reader.GetBgSprite(gameControl, cardType, cardSize, level), "bg")
    -- 激活态火焰材质球（Type+Size 维度，Loader 缓存共享 Material）#LevelupFire
    self:_SetMaterialIfChanged(host.RImgLevelupFire, Reader.GetActiveVFXMaterialPath(gameControl, cardType, cardSize), "levelupFire")
    -- 前遮（无依赖）
    self:_SetSpriteIfChanged(host.RImgFrontBg, Reader.GetFrontSprite(gameControl, cardType, cardSize), "front")

    -- 球值标签（Color 维度，产/消互斥）
    local ball = Reader.GetBallDisplay(gameControl, configConsume, configOutPut, realConsume, realOutPut, color)
    self:_SetSpriteIfChanged(host.ImgBallInBg, ball.showIn and ball.bgSprite or nil, "ballInBg")
    SetActiveIfChanged(host.ImgBallInBg, ball.showIn, self._LastActive, "ballInBg")
    self:_SetSpriteIfChanged(host.ImgBallOutBg, ball.showOut and ball.bgSprite or nil, "ballOutBg")
    SetActiveIfChanged(host.ImgBallOutBg, ball.showOut, self._LastActive, "ballOutBg")
    local showBall = ball.showIn or ball.showOut
    -- 球图标 vs 数字：iconSprite 有 → 显 ImgBall 图标；无 → 隐 ImgBall + 显对应 color Txt 数字（BallColor.Red=1/Yellow=2/Blue=3）
    local hasIcon = not string.IsNilOrEmpty(ball.iconSprite)
    self:_SetSpriteIfChanged(host.ImgBall, ball.iconSprite, "ball")
    SetActiveIfChanged(host.ImgBall, hasIcon and showBall, self._LastActive, "ball")
    -- TxtRed/TxtYellow/TxtBlue：无图标时按 color 显数字；有图标时全隐
    local showTxtRed = not hasIcon and showBall and color == 1
    local showTxtYellow = not hasIcon and showBall and color == 2
    local showTxtBlue = not hasIcon and showBall and color == 3
    if host.TxtRed then
        if showTxtRed then
            host.TxtRed.text = tostring(ball.count)
        end
        SetActiveIfChanged(host.TxtRed.gameObject, showTxtRed, self._LastActive, "txtRed")
    end
    if host.TxtYellow then
        if showTxtYellow then
            host.TxtYellow.text = tostring(ball.count)
        end
        SetActiveIfChanged(host.TxtYellow.gameObject, showTxtYellow, self._LastActive, "txtYellow")
    end
    if host.TxtBlue then
        if showTxtBlue then
            host.TxtBlue.text = tostring(ball.count)
        end
        SetActiveIfChanged(host.TxtBlue.gameObject, showTxtBlue, self._LastActive, "txtBlue")
    end
end

return XUiCardBgApplier
