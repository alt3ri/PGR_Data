---@class XUiLuckyTenant2GameGridChess : XUiNode
---@field _Root XLuaUi|XUiLuckyTenant2Game
---@field _Control XLuckyTenant2Control
---@field _Data table
---@field public Button XUiComponent.XUiButton
local XUiLuckyTenant2GameGridChess = XClass(XUiNode, "XUiLuckyTenant2GameGridChess")

function XUiLuckyTenant2GameGridChess:OnStart()
    self:InitComponents()

    ---@type XUiComponent.XUiButton
    local button = self.Button
    if button then
        button.CallBack = function()
            self:OnClick()
        end
    end
end

function XUiLuckyTenant2GameGridChess:InitComponents()
    -- 一次性特效的定时器表，key 为特效标识，value 为 ScheduleOnce 返回的 timerId，用于回收
    self._EffectTimers = {}

    -- Effect用于游戏界面的特效显示
    local effect = XUiHelper.TryGetComponent(self.Transform, "PanelChess/Effect", "RectTransform")
    if effect then
        -- 显隐来控制特效播放, 注意节点刷新时，需要刷新特效显隐

        -- 被传染的棋子，持续播放，常驻
        self.FxUiLuckyTenant212Ganrao01 = effect:Find("FxUiLuckyTenant212Ganrao01")

        -- 倒计时减少时，播放一次这个特效，之后，再刷新减少回合数
        self.FxUiLuckyTenant214Shalou01 = effect:Find("FxUiLuckyTenant214Shalou01")

        -- 暂不接
        -- self.FxUiLuckyTenant207 = effect:Find("FxUiLuckyTenant207")

        -- 宝盒以外棋子被消除时播放，播放后再消失
        self.FxUiLuckyTenant208 = effect:Find("FxUiLuckyTenant208")

        -- 宝盒棋子被消除时播放，播放后再消失
        self.FxUiLuckyTenant209 = effect:Find("FxUiLuckyTenant209")

        -- 武器类技能（Type401-407）、角色升级（Type301）发动时，发动技能的棋子播放（复用同一特效）
        self.FxUiLuckyTenant213 = effect:Find("FxUiLuckyTenant213")

        -- 子虫和红朝发动传染技能时，播放
        self.FxUiLuckyTenant211 = effect:Find("FxUiLuckyTenant211")

        -- 被角色消除的棋子，播放一次这个特效，播放后再消失
        self.FxUiLuckyTenant215 = effect:Find("FxUiLuckyTenant215")

        -- 技能发动时, 播放这个特效
        self.FxGridChessDuang = effect:Find("FxGridChessDuang")
    end
end

function XUiLuckyTenant2GameGridChess:UpdateRound(round)
    if round then
        if self.TxtTime01 then
            self.TxtTime01.text = tostring(round)
        end
        if self.TxtTime02 then
            self.TxtTime02.text = tostring(round)
        end
        if self.PanleRound then
            self.PanleRound.gameObject:SetActiveEx(true)
        end
    else
        if self.PanleRound then
            self.PanleRound.gameObject:SetActiveEx(false)
        end
    end
end

---更新倒计时效果（显示前两个有剩余回合数的状态）
---@param data table 棋子数据
function XUiLuckyTenant2GameGridChess:UpdateTimePanels(data)
    local states = data.States or {}
    local rounds = {}
    for _, state in ipairs(states) do
        local round = state.Round or state.RemainRound or state.StateRound
        if round ~= nil and round >= 0 then
            rounds[#rounds + 1] = round
        end
    end

    -- 如果 States 为空但 data.Round 存在，也使用它（兼容旧数据）
    -- 注意：data.Round 可能是 false（第一回合隐藏倒计时）
    if #rounds == 0 and type(data.Round) == "number" and data.Round >= 0 then
        rounds[#rounds + 1] = data.Round
    end

    -- 显示第一个倒计时
    if self.PanelTime01 then
        if rounds[1] then
            self.PanelTime01.gameObject:SetActiveEx(true)
            if self.TxtTime01 then
                self.TxtTime01.text = tostring(rounds[1])
            end
        else
            self.PanelTime01.gameObject:SetActiveEx(false)
        end
    end

    -- 显示第二个倒计时
    if self.PanelTime02 then
        if rounds[2] then
            self.PanelTime02.gameObject:SetActiveEx(true)
            if self.TxtTime02 then
                self.TxtTime02.text = tostring(rounds[2])
            end
        else
            self.PanelTime02.gameObject:SetActiveEx(false)
        end
    end
end

---统一更新等级显示：仅当可升级时显示等级面板与文本，游戏界面与选棋/背包界面共用
---@param data table 棋子数据（需含 IsCanUpgrade、Level）
function XUiLuckyTenant2GameGridChess:UpdateLevelDisplay(data)
    if not data then
        return
    end
    local isCanUpgrade = data.IsCanUpgrade or false
    if self.PanelLv then
        self.PanelLv.gameObject:SetActiveEx(isCanUpgrade)
    end
    if self.TxtLv then
        if isCanUpgrade then
            self.TxtLv.text = "Lv." .. tostring(data.Level or 1)
        else
            self.TxtLv.text = ""
        end
    end
end

---@param data table 棋子数据
function XUiLuckyTenant2GameGridChess:Update(data)
    -- 游戏界面：处理JustChangeRound快速更新
    if data and data.JustChangeRound ~= nil then
        self:UpdateRound(data.JustChangeRound)
        return
    end

    self._Data = data
    if not data then
        return
    end

    -- 游戏界面：处理IsValid和空位置
    if data.IsValid ~= nil then
        if data.IsValid then
            -- 设置图标
            if self.RImgIcon then
                if self.RImgIcon.SetImage then
                    self.RImgIcon:SetImage(data.Icon)
                end
            end

            -- 显示PanelChess
            if self.PanelChess then
                self.PanelChess.gameObject:SetActiveEx(true)
            end

            -- 设置品质
            if self.ImgQuality then
                if type(data.Quality) == "number" then
                    local qualityIcon = self._Control:GetQualityIconCircle(data.Quality)
                    if qualityIcon and qualityIcon ~= "" then
                        self.ImgQuality:SetSprite(qualityIcon)
                    end
                elseif type(data.Quality) == "string" and data.Quality ~= "" then
                    self.ImgQuality:SetImage(data.Quality)
                end
            end

            -- 设置分数/价值
            if self.TxtCost then
                self.TxtCost.text = tostring(data.Score or data.Value or 0)
            end

            -- 设置名称（只有棋盘上的棋子才显示名字）
            -- IsValid 为 true 表示棋子在棋盘上
            if self.TxtName then
                if data.IsValid == true then
                    self.TxtName.text = data.Name or ""
                else
                    self.TxtName.text = ""
                end
            end

            -- 设置等级（游戏界面与选棋/背包共用逻辑）
            self:UpdateLevelDisplay(data)

            -- 设置位置名称
            if data.X and data.Y then
                self.Transform.name = "Chess_" .. data.X .. "_" .. data.Y
            end


            -- 更新倒计时效果（显示前两个有剩余回合数的状态）
            self:UpdateTimePanels(data)

            -- 特效显隐：被传染等状态根据 data.States 刷新
            self:UpdateEffectVisibility(data)
        else
            -- 隐藏PanelChess
            if self.PanelChess then
                self.PanelChess.gameObject:SetActiveEx(false)
            end
            self:UpdateEffectVisibility(nil)
        end
        return
    end

    -- 选棋界面/背包界面：更新基本信息
    -- 更新品质图标
    if self.ImgQuality then
        if data.QualityValue then
            local control = self._Control
            if not control and self.Parent then
                control = self.Parent._Control
            end
            if not control and self._Root and self._Root._Control then
                control = self._Root._Control
            end
            if control and control.GetQualityIconCircle then
                local qualityIcon = control:GetQualityIconCircle(data.QualityValue)
                if qualityIcon and self.ImgQuality.SetSprite then
                    self.ImgQuality:SetSprite(qualityIcon)
                end
            end
        elseif data.Quality and type(data.Quality) == "string" then
            if self.ImgQuality.SetSprite then
                self.ImgQuality:SetSprite(data.Quality)
            elseif self.ImgQuality.SetImage then
                self.ImgQuality:SetImage(data.Quality)
            end
        end
    end

    -- 更新棋子图标
    if self.RImgIcon then
        if self.RImgIcon.SetImage then
            self.RImgIcon:SetImage(data.Icon or "")
        end
    end

    -- 显示PanelChess（选棋界面/背包界面有数据时显示）
    if self.PanelChess then
        self.PanelChess.gameObject:SetActiveEx(true)
    end

    -- 更新价值
    if self.TxtCost then
        self.TxtCost.text = tostring(data.Value or 0)
    end

    -- 更新倒计时效果（显示前两个有剩余回合数的状态）
    self:UpdateTimePanels(data)

    -- 更新等级（与游戏界面共用：仅可升级时显示）
    self:UpdateLevelDisplay(data)

    -- 隐藏名称（背包/选棋界面的棋子不显示名字）
    if self.TxtName then
        self.TxtName.text = ""
    end
end

function XUiLuckyTenant2GameGridChess:OnClick()
    if not self._Data then
        return
    end

    -- 游戏界面：处理棋盘上的棋子点击
    if self._Data.IsValid ~= nil then
        if self._Data.IsValid then
            -- 更新棋子详情数据
            self._Control:UpdatePieceDataOnChessboard(self._Data)
            self.Parent:OnClickPieceOnChessboard(self._Data)
        end
        return
    end

    -- 选棋界面/背包界面：处理选择逻辑
    -- 检查是否在背包界面
    local bagUi = self:FindBagUI()
    if bagUi then
        -- 在背包界面中，选择该棋子并刷新详情
        local control = self._Control
        if not control and self.Parent then
            control = self.Parent._Control
        end
        if not control and bagUi._Control then
            control = bagUi._Control
        end

        if control and self._Data.Uid then
            -- 通过 Uid 查找背包中的棋子数据
            local uiData = control:GetUiData()
            local bagData = uiData.Bag
            local selectedPiece = nil

            -- 在所有分组中查找匹配的棋子
            for _, groupData in ipairs(bagData) do
                if groupData.Pieces then
                    for _, pieceData in ipairs(groupData.Pieces) do
                        if pieceData.Uid == self._Data.Uid then
                            selectedPiece = pieceData
                            break
                        end
                    end
                    if selectedPiece then
                        break
                    end
                end
            end

            -- 如果找到了棋子，选择它并刷新详情
            if selectedPiece then
                control:SelectBagPiece(selectedPiece)
                bagUi:UpdateBag()
            end
        end
    end
end

---获取背包 UI（XUiLuckyTenant2ChessBag）
---@return XUiLuckyTenant2ChessBag|nil
function XUiLuckyTenant2GameGridChess:FindBagUI()
    -- 通过 Parent（Detail）的方法获取 Bag UI
    if self.Parent and self.Parent.GetBagUI then
        return self.Parent:GetBagUI()
    end
    return nil
end

---根据 data.States 刷新特效显隐（被传染常驻、其它由 PlayEffectXxx 触发）
---@param data table|nil 棋子数据，含 States = { { StateType = number } }
function XUiLuckyTenant2GameGridChess:UpdateEffectVisibility(data)
    local showInfection = false
    if data and data.States then
        local TriggerState = (require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")).TriggerState
        for _, state in ipairs(data.States) do
            if state.StateType == TriggerState.Infection then
                showInfection = true
                break
            end
        end
    end
    -- 缓存上一次感染状态，仅当状态变化时才刷新（避免同回合多次 Update 重复刷新）
    if self._LastShowInfection ~= showInfection then
        self._LastShowInfection = showInfection
        if self.FxUiLuckyTenant212Ganrao01 then
            self.FxUiLuckyTenant212Ganrao01.gameObject:SetActiveEx(showInfection)
            if showInfection then
                -- todo：临时改为代码设置层级，在之后等待美术修复UI特效层级问题
                local uiEffectLayer = self.FxUiLuckyTenant212Ganrao01:GetComponent("XUiEffectLayer")
                if uiEffectLayer then
                    uiEffectLayer.enabled = false
                end

                local gr1 = self.FxUiLuckyTenant212Ganrao01:Find("1/gr1")
                if gr1 then
                    local renderer = gr1.transform:GetComponent("Renderer")
                    if renderer then
                        local canvas = self.Parent.Transform:GetComponent("Canvas")
                        if canvas then
                            renderer.sortingOrder = canvas.sortingOrder + 2
                        end
                    end
                end
            end
        end
    end
    -- 每次刷新时先隐藏所有一次性特效，避免上回合残留
    self:_HideEffectNode(self.FxUiLuckyTenant214Shalou01)
    self:_HideEffectNode(self.FxUiLuckyTenant208)
    self:_HideEffectNode(self.FxUiLuckyTenant209)
    self:_HideEffectNode(self.FxUiLuckyTenant213)
    self:_HideEffectNode(self.FxUiLuckyTenant211)
    self:_HideEffectNode(self.FxUiLuckyTenant215)
end

---隐藏单个特效节点（空安全）
---@param node userdata|nil 特效节点（Unity Transform）
function XUiLuckyTenant2GameGridChess:_HideEffectNode(node)
    if node and node.gameObject then
        node.gameObject:SetActiveEx(false)
    end
end

---播放一次性特效：显示节点，delayMs 后隐藏并回收定时器。不等待播完，onFinish 若传入则立即调用，便于直接进入下一步动画。
---@param timerKey string 定时器键，用于收集与回收（同一 key 会先取消上一次）
---@param node userdata 特效节点（Unity Transform/GameObject）
---@param delayMs number 播放时长（毫秒），播完后仅隐藏节点
---@param onFinish function|nil 若传入则立即调用，不再等待 delayMs
function XUiLuckyTenant2GameGridChess:_PlayOneShotEffect(timerKey, node, delayMs, onFinish)
    if not node or not self._EffectTimers then return end
    -- 同 key 冲突：先取消上一次的定时器，再起本次定时器
    if self._EffectTimers[timerKey] then
        XScheduleManager.UnSchedule(self._EffectTimers[timerKey])
        self._EffectTimers[timerKey] = nil
    end
    node.gameObject:SetActiveEx(true)
    local timers = self._EffectTimers
    self._EffectTimers[timerKey] = XScheduleManager.ScheduleOnce(function()
        timers[timerKey] = nil
        if node then
            node.gameObject:SetActiveEx(false)
        end
    end, delayMs)
    -- 定时器已起，再回调 onFinish，不阻塞流程、直接下一动画
    if type(onFinish) == "function" then
        onFinish()
    end
end

---取消本格所有一次性特效定时器并隐藏特效节点（OnDisable/OnDestroy 时调用）
function XUiLuckyTenant2GameGridChess:CancelAllEffectTimers()
    if self._EffectTimers then
        for key, timerId in pairs(self._EffectTimers) do
            if timerId then
                XScheduleManager.UnSchedule(timerId)
            end
            self._EffectTimers[key] = nil
        end
    end
    -- 隐藏所有特效节点，避免残留
    self:_HideEffectNode(self.FxUiLuckyTenant214Shalou01)
    self:_HideEffectNode(self.FxUiLuckyTenant208)
    self:_HideEffectNode(self.FxUiLuckyTenant209)
    self:_HideEffectNode(self.FxUiLuckyTenant213)
    self:_HideEffectNode(self.FxUiLuckyTenant211)
    self:_HideEffectNode(self.FxUiLuckyTenant215)
    self:_HideEffectNode(self.FxGridChessDuang)
end

---倒计时减少时播放一次，不主动隐藏节点，依赖后续 UpdateEffectVisibility 重置
---@param skillId number|nil 来源技能ID（动画组传入，用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectCountdownDecrease(skillId, onFinish)
    if not self.FxUiLuckyTenant214Shalou01 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self.FxUiLuckyTenant214Shalou01.gameObject:SetActiveEx(true)
    if type(onFinish) == "function" then
        onFinish()
    end
end

---宝盒以外棋子被消除时播放一次，1200ms 后隐藏；onFinish 若传入则立即调用
---@param skillId number|nil 来源技能ID（用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectEliminatedNormal(skillId, onFinish)
    if not self.FxUiLuckyTenant208 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("208", self.FxUiLuckyTenant208, 1200, onFinish)
end

---宝盒棋子被消除时播放一次，1200ms 后隐藏；onFinish 若传入则立即调用
---@param skillId number|nil 来源技能ID（用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectEliminatedBox(skillId, onFinish)
    if not self.FxUiLuckyTenant209 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("209", self.FxUiLuckyTenant209, 1200, onFinish)
end

---武器类（Type401-407）、角色升级（Type301）发动时播放 FxUiLuckyTenant213，1200ms 后隐藏；onFinish 若传入则立即调用
---@param skillId number|nil 来源技能ID（用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectWeaponSkill(skillId, onFinish)
    if not self.FxUiLuckyTenant213 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("213", self.FxUiLuckyTenant213, 1200, onFinish)
end

---宝盒品质提升（Type507品质+1）时播放 FxUiLuckyTenant213，1200ms 后隐藏；onFinish 若传入则立即调用
---@param skillId number|nil 来源技能ID（用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectBoxUpgrade(skillId, onFinish)
    if not self.FxUiLuckyTenant213 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("213", self.FxUiLuckyTenant213, 1200, onFinish)
end

---宝盒重生品质提升（Type502重生时品质提升）时播放 FxUiLuckyTenant213，1200ms 后隐藏；onFinish 若传入则立即调用
---@param skillId number|nil 来源技能ID（用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectBoxReborn(skillId, onFinish)
    if not self.FxUiLuckyTenant213 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("213", self.FxUiLuckyTenant213, 1200, onFinish)
end

---子虫和红潮发动传染技能时播放，1200ms 后隐藏；onFinish 若传入则立即调用
---@param skillId number|nil 来源技能ID（用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectInfectionSkill(skillId, onFinish)
    if not self.FxUiLuckyTenant211 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("211", self.FxUiLuckyTenant211, 1200, onFinish)
end

---被角色消除的棋子播放一次，1200ms 后隐藏；onFinish 若传入则立即调用
---@param skillId number|nil 来源技能ID（用于日志）
---@param onFinish function|nil 若传入则立即调用
function XUiLuckyTenant2GameGridChess:PlayEffectRoleEliminate(skillId, onFinish)
    if not self.FxUiLuckyTenant215 then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("215", self.FxUiLuckyTenant215, 1200, onFinish)
end

---播放棋子抖动动画
function XUiLuckyTenant2GameGridChess:PlayShakeAnimation()
    if self.PlayAnimation then
        self:PlayAnimation("Shake")
    end
end

---播放 Duang 特效
function XUiLuckyTenant2GameGridChess:PlayEffectDuang()
    if not self.FxGridChessDuang then return end
    local x, y = (self._Data and self._Data.X), (self._Data and self._Data.Y)
    self:_PlayOneShotEffect("Duang", self.FxGridChessDuang, 2000)
end

function XUiLuckyTenant2GameGridChess:ShowEffect()
    if self._Data and (self._Data.IsValid == nil or self._Data.IsValid) then
        self:UpdateEffectVisibility(self._Data)
    end
end

function XUiLuckyTenant2GameGridChess:OnEnable()
end

function XUiLuckyTenant2GameGridChess:OnDisable()
    self:CancelAllEffectTimers()
end

function XUiLuckyTenant2GameGridChess:OnDestroy()
    self:CancelAllEffectTimers()
end

return XUiLuckyTenant2GameGridChess
