local XUiPacMan2StarTarget = require("XUi/XUiPacMan2/XUiPacMan2StarTarget")
local XUiPacMan2GridLife = require("XUi/XUiPacMan2/XUiPacMan2GridLife")
local XUiPacMan2MoveTo = require("XUi/XUiPacMan2/XUiPacMan2MoveTo")
local XUiPacMan2GamepadInput = require("XUi/XUiPacMan2/XUiPacMan2GamepadInput")
local XUiToggle = require("XUi/XUiCommon/XUiToggle")

-- 游戏实体类型枚举
local EntityEnum = {
    Orb = 1,           -- 豆子
    Key = 2,           -- 钥匙
    GoldOrb = 3,       -- 金豆
    TurnIntoFood = 4,  -- 将怪物变为食物的道具
    TurnIntoShoe = 5,  -- 将怪物变为跑鞋的道具
    Ghost = 6,         -- 普通怪物
    RangeGhost = 7,    -- 范围警戒怪物
    SlowGhost = 8,     -- 减速怪物
    Shoe = 9,          -- 跑鞋道具
    PlayerClone = 10,  -- 玩家分身
    Food = 11,         -- 食物
    ShowKey = 12,      -- 显示钥匙（仅用于UI展示）
    Snake = 13,        -- 贪吃蛇怪物
    EatGhost = 14,     -- 贪吃怪物
    SlowDownGhost = 15,-- 减速效果道具
    SpeedUpPlayer = 16 -- 加速效果道具
}

-- 提示类型枚举
local TipsType = {
    None = 0,        -- 无提示
    Enter = 1,       -- 进入关卡
    EatMonster = 2,  -- 怪物吃豆数量超过x星级
    EatPlayer = 3,   -- 玩家吃豆数量达到x星级
    RemainOrbs = 4,  -- 追击阶段还剩x豆子
    StartChase = 5,  -- 追击开始
    GetItem = 6,     -- 拾取道具
    KillMonster = 7, -- 击杀怪物
    EnableKey = 8,   -- 撤离点启用
    Switch = 9,      -- 切换操作方式
}

local BackgroundType = {
    Default = 1,
    PlayerKillGhost = 2,
    GhostKillPlayer = 3,
}

-- 方向枚举
local Direction = {
    None = 0,  -- 无方向
    Up = 1,    -- 上
    Down = 2,  -- 下
    Left = 3,  -- 左
    Right = 4, -- 右
}

---@class UiPacMan2Game : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2Game = XLuaUiManager.Register(XLuaUi, "UiPacMan2Game")

function XUiPacMan2Game:OnAwake()
    -- 初始化基本状态
    self._StageId = false
    self._StagePrefab = false
    ---@type XPacMan2.XPacMan2GameManager
    self._GameManager = false
    ---@type XPacMan2.XPacMan2Movement
    self._PlayerMovement = false
    self._IsGameOver = false
    self._LastKillAmount = 0
    self._LastScore = -1
    self._UpdateTips = false
    
    -- 注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OpenPauseUi)
    self.BtnUp.CallBack = function() self:OnClickUp() end
    self.BtnDown.CallBack = function() self:OnClickDown() end
    self.BtnLeft.CallBack = function() self:OnClickLeft() end
    self.BtnRight.CallBack = function() self:OnClickRight() end
    
    -- 初始化拖拽相关变量
    self._DragOffset = XLuaVector2.New()
    self._OperationPos = XLuaVector2.New()
    -- 初始化当前方向（本地记录，不使用movement的方向，使用枚举值）
    self._CurrentDirection = Direction.None
    
    -- 初始化星级相关
    ---@type XTablePacMan2Stage
    self._ConfigStarList = false
    self._StarList = {
        XUiPacMan2StarTarget.New(self.GridStar01, self),
        XUiPacMan2StarTarget.New(self.GridStar02, self),
        XUiPacMan2StarTarget.New(self.GridStar03, self),
    }
    
    -- 初始化倒计时相关
    self._CountDown = 0
    --self._CountDownTimer = false
    self._CountDownText = {
        self.RawImgShuzi03,
        self.RawImgShuzi02,
        self.RawImgShuzi01,
        self.RawImgShuzi04,
    }
    self._IsCountDown = false
    
    -- 初始化生命值相关
    self._Hp = false
    ---@type XUiPacMan2GridLife[]
    self._HpGrids = {}
    self.GridLife.gameObject:SetActiveEx(false)
    
    -- 初始化提示相关
    self._Tips = {}
    self._SwitchTipKey = false
    self._SwitchTipTouch = false
    ---@type XTablePacMan2StageTips[]
    local allConfigs = self._Control:GetStageTips()
    for _, config in pairs(allConfigs) do
        if config.TriggerType == TipsType.Switch then
            if config.TriggerPram[1] == 1 then
                self._SwitchTipKey = config
            else
                self._SwitchTipTouch = config
            end
        else
            self._Tips[#self._Tips + 1] = config
        end
    end
    
    -- 初始化操作方式相关
    self._IsTouch = self._Control:GetToggleTouch()
    -- 初始化 XUiToggle 组件
    ---@type XUiToggle
    self._ToggleSwitch = XUiToggle.New(self.BtnSwitch, self)
    self._ToggleSwitch:SetOnValueChanged(function(value)
        self._IsTouch = value == 0
        self._Control:SetToggleTouch(self._IsTouch)
        self:UpdateInput()
        self:UpdateTipsTextBySwitchInput()
    end)
    -- 设置初始状态：IsTouch=true -> On状态(value=0), IsTouch=false -> Off状态(value=1)
    self._ToggleSwitch:SetToggleState(self._IsTouch)
    self:InitInput()
    
    -- 初始化进度条相关
    self.PanelPlayer.transform.position = self.StartProgress.position
    self.PanelEnemy.transform.position = self.EndProgress.position
    ---@type XUiPacMan2MoveTo
    self._MoverPlayer = XUiPacMan2MoveTo.New(self.PanelPlayer, 100)
    ---@type XUiPacMan2MoveTo
    self._MoverEnemy = XUiPacMan2MoveTo.New(self.PanelEnemy, 100)
    
    -- 初始化提示文本数组
    local text1 = self.TxtTips
    text1.text = ""
    local text2 = XUiHelper.Instantiate(text1.transform, text1.transform.parent)
    local text3 = XUiHelper.Instantiate(text1.transform, text1.transform.parent)
    text1.gameObject:SetActiveEx(false)
    text2.gameObject:SetActiveEx(false)
    self._TxtTipsArray = { text3:GetComponent(typeof(CS.UnityEngine.UI.Text)), text2:GetComponent(typeof(CS.UnityEngine.UI.Text)), text1 }

    self._BackgroundType = BackgroundType.Default
    self._Backgounrd = {}
    
    -- 初始化像素化特效节点列表（用于选择最近的节点）
    self._PixelationNodes = {}
    if self.FxPixelation01 then
        table.insert(self._PixelationNodes, self.FxPixelation01)
    end
    if self.FxPixelation02 then
        table.insert(self._PixelationNodes, self.FxPixelation02)
    end
    if self.FxPixelation03 then
        table.insert(self._PixelationNodes, self.FxPixelation03)
    end
    
    -- 初始化像素化特效定时器列表
    self._PixelationTimers = {}
    
    -- 初始化 FlashKill 特效定时器列表
    self._FlashKillTimers = {}
    
    -- 初始化 FlashKill 特效节点
    if self.FlashKill then
        self.FlashKill.gameObject:SetActiveEx(false)
    end
    
    ---@type XUiPacMan2GamepadInput
    -- 初始化手柄输入处理
    self._GamepadInput = XUiPacMan2GamepadInput.New(self)
end

function XUiPacMan2Game:OnStart(stageId)
    self._StageId = stageId
    self:StartGame()
end

function XUiPacMan2Game:OnDestroy()
    -- 禁用道具音效（需要在 _StagePrefab 被置为 nil 之前调用）
    self:_DisableItemSounds()
    
    -- 因为会缓存 prefab，所以这里要手动销毁
    -- 避免下次打开游戏, 使用了缓存的prefab
    local prefabComponent = self.UiSceneInfo.Transform:GetComponent("XUiLoadPrefab")
    if prefabComponent then
        CS.UnityEngine.Object.DestroyImmediate(prefabComponent)
    end
    self._StagePrefab = nil
    self._GameManager = nil
    self._PlayerMovement = nil
    
    -- XUiToggle 继承自 XUiNode，会自动随父节点销毁，无需手动调用

    ---@type XGoInputHandler
    local goInputHandler = self.InputHandler
    goInputHandler:RemoveAllListeners()
    self._Control:SetPlaying(false)

    self._MoverPlayer:Destroy()
    self._MoverPlayer = nil
    self._MoverEnemy:Destroy()
    self._MoverEnemy = nil
    
    -- 清理背景相关资源
    self._Backgounrd = {}
    self._BackgroundType = nil
    
    -- 清理像素化特效定时器
    self:_ClearPixelationTimers()
    
    -- 清理 FlashKill 特效定时器
    self:_ClearFlashKillTimers()
    
    -- 销毁手柄输入处理
    if self._GamepadInput then
        self._GamepadInput:Dispose()
        self._GamepadInput = nil
    end
end

function XUiPacMan2Game:OnEnable()
    self:Update()
    self._TimerId = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 100) -- 100ms
    self:AddListenerInput()

    -- 键盘图标显示
    if self.Keyboard then
        if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
            self.Keyboard.gameObject:SetActiveEx(true)
            self.BtnUp.gameObject:SetActiveEx(false)
            self.BtnDown.gameObject:SetActiveEx(false)
            self.BtnLeft.gameObject:SetActiveEx(false)
            self.BtnRight.gameObject:SetActiveEx(false)
        else
            self.Keyboard.gameObject:SetActiveEx(false)
            self.BtnUp.gameObject:SetActiveEx(true)
            self.BtnDown.gameObject:SetActiveEx(true)
            self.BtnLeft.gameObject:SetActiveEx(true)
            self.BtnRight.gameObject:SetActiveEx(true)
        end
    end
    
    -- 启用手柄输入
    if self._GamepadInput then
        self._GamepadInput:Enable()
    end
end

function XUiPacMan2Game:OnDisable()
    XScheduleManager.UnSchedule(self._TimerId)
    self._TimerId = false
    --if self._CountDownTimer then
    --    XScheduleManager.UnSchedule(self._CountDownTimer)
    --    self._CountDownTimer = false
    --end
    
    -- 禁用手柄输入
    if self._GamepadInput then
        self._GamepadInput:Disable()
    end
end

local GameState = {
    None = 0,
    Playing = 1,
    Paused = 2,
    GameOver = 3,
    GameClear = 4,
}

function XUiPacMan2Game:Update()
    if self._IsGameOver then
        return
    end
    
    self:CheckGameState()
    self:UpdatePlayerHp()
    self:UpdateScore()
    self:UpdateOrbs()
    self:UpdateProps()
    self:UpdateKills()
    self:UpdateKeyVisibility()
    self:UpdatePlayerKillGhostPhase()
    self:ProcessTips()
end

-- 检查游戏状态
function XUiPacMan2Game:CheckGameState()
    if self._GameManager then
        if self._GameManager:GetGameState() == GameState.GameClear
                or self._GameManager:GetGameState() == GameState.GameOver then
            self._IsGameOver = true
            self:OpenSettlement()
        else
            if self._GameManager.IsPauseOnHpDecrease then
                self._GameManager.IsPauseOnHpDecrease = false
                self:StartCountDown()
            end
        end
    end
end

-- 更新玩家生命值
function XUiPacMan2Game:UpdatePlayerHp()
    local hp = self._GameManager:GetPlayerHp()
    if self._Hp ~= hp then
        local animation = self._Hp ~= false
        self._Hp = hp
        self:UpdateHp(hp, animation)
    end
end

-- 更新分数显示
function XUiPacMan2Game:UpdateScore()
    local score = self._GameManager:GetOrbs()
    if self._LastScore ~= score then
        self._LastScore = score
        self:UpdateStar(score)
        self._UpdateTips = true
    end
end

-- 更新豆子相关状态
function XUiPacMan2Game:UpdateOrbs()
    -- 当豆子数量变化时，触发
    self._UpdateProgressBar = false
    local orbsEaten = self._GameManager:GetOrbsEaten()
    if self._LastOrbsEaten ~= orbsEaten then
        self._LastOrbsEaten = orbsEaten
        self._UpdateTips = true
        self._UpdateProgressBar = true
    end

    -- 当敌人吃豆子数量变化时, 触发
    local orbsEatenByEnemy = self._GameManager.EnemyOrbs
    if self._LastOrbsEatenByEnemy ~= orbsEatenByEnemy then
        self._LastOrbsEatenByEnemy = orbsEatenByEnemy
        self._UpdateProgressBar = true
    end

    if self._UpdateProgressBar then
        self:UpdateProgressBar()
    end
end

-- 更新道具状态
function XUiPacMan2Game:UpdateProps()
    if self._GameManager.EatPropList.Count > 0 then
        for i = 0, self._GameManager.EatPropList.Count - 1 do
            local itemId = self._GameManager.EatPropList[i]
            self:UpdateTips(TipsType.GetItem, itemId)
        end
        self._GameManager.EatPropList:Clear()
    end
end

-- 更新击杀数
function XUiPacMan2Game:UpdateKills()
    if self._LastKillAmount ~= self._GameManager.Kills then
        self._LastKillAmount = self._GameManager.Kills
        self:UpdateTips(TipsType.KillMonster)
        -- 当 kills 数量变化时，显示像素化特效
        self:ShowPixelationEffect()
        -- 当 kills 数量变化时，显示 FlashKill 特效
        self:ShowFlashKillEffect()
    end
end

-- 更新钥匙可见性
function XUiPacMan2Game:UpdateKeyVisibility()
    if self._IsShowKey ~= true then
        if self._GameManager:GetOrbs() >= self._GameManager.OrbsToShowKey then
            self._IsShowKey = true
            self.PanelExit.gameObject:SetActiveEx(false)
        end
    end
end

-- 处理提示信息
function XUiPacMan2Game:ProcessTips()
    if self._UpdateTips then
        self:UpdateTips()
        self._UpdateTips = false
    end
end

function XUiPacMan2Game:StartGame()
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    local prefab = stageConfig.Prefab
    if not prefab or prefab == "" then
        XLog.Error("[UiPacMan2Game] StartGame prefab is nil")
        return
    end
    self._StagePrefab = self.UiSceneInfo.Transform:LoadPrefab(prefab, true, true)
    self._GameManager = self._StagePrefab:FindGameObject("PacManGameManager"):GetComponent("XPacMan2GameManager")
    self._PlayerMovement = self._GameManager.Player:GetComponent("XPacMan2Movement")
    self:ImportConfig()

    -- let's start the game
    self._GameManager:Pause()
    XMVCA.XPacMan2:PacMan2StageStartRequest(self._StageId, function(isSuccess)
        if isSuccess then
            self:StartCountDown()
        else
            XLog.Warning("[XUiPacMan2Game] 错误，应该关闭游戏界面")
            --self:Close()
            if XMain.IsZLBDebug then
                self:StartCountDown()
            end
        end
    end)

    self:InitBackground()
    self:InitStarPosition()
    self:InitPanelExit()
    self:UpdateTips()
    self:UpdateProgressBar()
end

function XUiPacMan2Game:OpenSettlement()
    -- 结算时恢复鼠标显示并禁用手柄输入检测
    if self._GamepadInput then
        self._GamepadInput:RestoreCursor()
        self._GamepadInput:Disable()
    end
    
    -- 只有成功才发送请求
    if self._GameManager:GetGameState() == GameState.GameClear then
        local data = {
            StageId = self._StageId,
            Score = self._GameManager:GetOrbs(),
            --玩法耗时
            Time = math.floor(self._GameManager.Duration),
            --算力结晶
            Orbs = self._GameManager.Orbs,
            --吸入怪兽
            Kills = self._GameManager.Kills,
            --剩余生命
            Hp = self._GameManager:GetPlayerHp(),
            --是否触发1血保底系统
            IsLastHp = self._GameManager.IsLastHp,
            --冲刺穿越
            Shoe = {
                -- 普通怪
                { Id = EntityEnum.Ghost, Times = self._GameManager.ShoeNormalGhost, },
                -- 范围怪
                { Id = EntityEnum.RangeGhost, Times = self._GameManager.ShoeRangeGhost, },
                -- 淤泥怪
                { Id = EntityEnum.SlowGhost, Times = self._GameManager.ShoeSlowGhost, },
                -- 跑鞋道具
                { Id = EntityEnum.Shoe, Times = self._GameManager.ShoeProp, }
            },
            --夺回豆子数-埋点
            TakeBackPoint = self._GameManager.OrbsPayback,
            --是否触发全图追击-埋点
            IsTriggerChase = self._GameManager:GetGhostState() == CS.XPacMan2.XPacMan2GhostState.Attack or self._GameManager:GetGhostState() == CS.XPacMan2.XPacMan2GhostState.ReviveProtectionTime
        }
        XMVCA.XPacMan2:PacMan2SettleRequest(data)
    end

    ---@class XPacMan2SettlementData
    local data = {
        StageId = self._StageId,
        Score = self._GameManager:GetOrbs(),
        IsWin = self._GameManager:GetGameState() == GameState.GameClear,
        Orbs = self._GameManager.Orbs,
        OrbScore = self._GameManager.OrbScore,
        Kills = self._GameManager.Kills,
        KillScore = self._GameManager.KillScore,
        Hp = self._GameManager:GetPlayerHp(),
        --HpScore = 0,
        --ShoeCount = self._GameManager.ShoeCount,
        --ShoeScore = self._GameManager.ShoeScore,
        OrbsPayback = self._GameManager.OrbsPayback,
    }
    XLuaUiManager.Open("UiPacMan2PopupSettlement", data)
end

function XUiPacMan2Game:ImportConfig()
    -- 初始化游戏管理器配置
    self._GameManager.ShouldPauseOnHpDecrease = true

    ---@type UnityEngine.GameObject
    local stagePrefab = self._StagePrefab
    local gameConfig = self._Control:GetGameConfig()

    ---@type XTablePacMan2Stage
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    self._GameManager.OrbsToShowKey = stageConfig.RedOrb
    self._GameManager:SetOrbs(0)
    self._GameManager:SetEnemyOrbs(0)
    self._GameManager:SetOrbsAttackThreshold(stageConfig.OrbsAttackThreshold)
    self._GameManager.ReviveProtectionTimeDuration = self:Divide1000(stageConfig.ReviveProtectionTime)

    -- 初始化玩家生命值组件
    ---@type XPacMan2.XPacMan2Hp
    local hpComponent = self._GameManager.Player.transform:GetComponent(typeof(CS.XPacMan2.XPacMan2Hp))
    hpComponent.Lives = stageConfig.InitialHp
    -- 美术做了6格，所以上限设为6，比初始血量要高，因为在游戏途中，可以获得更多血量
    hpComponent.MaxLives = 6--stageConfig.InitialHp

    -- 配置玩家角色移动参数
    local characterSpeed = gameConfig.CharacterSpeed.Value
    local players = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Player), true)
    local characterTurningSpend = gameConfig.CharacterTurningSpend.Value
    for i = 0, players.Length - 1 do
        local player = players[i]
        ---@type UnityEngine.Transform
        local playerTransform = player.transform
        ---@type XPacMan2.XPacMan2Movement
        local movement = playerTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(characterSpeed)
        movement.RotateDuration = self:Divide1000(characterTurningSpend)
    end

    -- 配置金豆（金魂石）参数
    local goldOrbConfig = self._Control:GetEntityConfig(EntityEnum.GoldOrb)
    local goldOrbs = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2GoldOrb), true)
    for i = 0, goldOrbs.Length - 1 do
        local goldOrb = goldOrbs[i]
        goldOrb.Hp = goldOrbConfig.Params[1]
    end

    -- 配置将怪物变为食物的道具参数
    local turnIntoFoodConfig = self._Control:GetEntityConfig(EntityEnum.TurnIntoFood)
    local turnIntoFoods = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2TurnGhostIntoFood), true)
    for i = 0, turnIntoFoods.Length - 1 do
        ---@type XPacMan2.XPacMan2TurnGhostIntoFood
        local turnIntoFood = turnIntoFoods[i]
        turnIntoFood.Duration = turnIntoFoodConfig.Params[1]
        turnIntoFood.CoolDown = turnIntoFoodConfig.Params[2]
    end

    -- 配置食物参数
    local foodConfig = self._Control:GetEntityConfig(EntityEnum.Food)
    if foodConfig then
        local foods = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Food), true)
        for i = 0, foods.Length - 1 do
            local food = foods[i]
            local movement = food:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:Divide1000(foodConfig.Speed)
        end
    end

    -- 配置将怪物变为跑鞋的道具参数
    local turnIntoShoeConfig = self._Control:GetEntityConfig(EntityEnum.TurnIntoShoe)
    local turnIntoShoes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2TurnGhostIntoShoe), true)
    local shoeConfig = self._Control:GetEntityConfig(EntityEnum.Shoe)
    for i = 0, turnIntoShoes.Length - 1 do
        ---@type XPacMan2.XPacMan2TurnGhostIntoShoe
        local turnIntoShoe = turnIntoShoes[i]
        turnIntoShoe.Duration = turnIntoShoeConfig.Params[1]
        turnIntoShoe.SpeedOverlay = self:Divide1000(shoeConfig.Params[2])
        turnIntoShoe.SpeedIncrease = self:Divide1000(shoeConfig.Params[3])
        if shoeConfig.Params[4] and shoeConfig.Params[4] > 0 then
            turnIntoShoe.MaxLayer = shoeConfig.Params[4]
        end
    end

    -- 配置普通怪物参数
    local ghostConfig = self._Control:GetEntityConfig(EntityEnum.Ghost)
    local ghostPatrols = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostPatrol), true)
    for i = 0, ghostPatrols.Length - 1 do
        local ghost = ghostPatrols[i]

        local speed = ghostConfig.Speed
        local movement = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(speed)
        movement.RotateDuration = ghostConfig.TurningDuration

        ---@type XPacMan2.XPacMan2BehaviorGhostRange
        local range = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
        if range then
            range.Range = Vector2(ghostConfig.AlertX, ghostConfig.AlertY)
            range:UpdateRangeVisible()
            self:UpdateRange(range, ghostConfig.AlertVisibility)
        end
    end

    -- 配置警戒范围怪物参数
    local ghostRangeConfig = self._Control:GetEntityConfig(EntityEnum.RangeGhost)
    local ghostRanges = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange), true)
    for i = 0, ghostRanges.Length - 1 do
        local ghost = ghostRanges[i]
        if ghost:GetType().Name == "XPacMan2BehaviorGhostRange" then
            local speed = ghostRangeConfig.Speed
            local movement = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:Divide1000(speed)
            movement.RotateDuration = ghostRangeConfig.TurningDuration

            ---@type XPacMan2.XPacMan2BehaviorGhostRange
            local range = ghost:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
            if range then
                range.Range = Vector2(ghostRangeConfig.AlertX, ghostRangeConfig.AlertY)
                range:UpdateRangeVisible()
            end
            self:UpdateRange(range, ghostRangeConfig.AlertVisibility)
        end
    end

    -- 配置减速怪物（淤泥怪）参数
    local ghostSlowConfig = self._Control:GetEntityConfig(EntityEnum.SlowGhost)
    local ghostSlowDowns = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SlowDown), true)
    for i = 0, ghostSlowDowns.Length - 1 do
        ---@type XPacMan2.XPacMan2SlowDown
        local ghost = ghostSlowDowns[i]
        local speed = ghostSlowConfig.Speed
        local movement = ghost.transform.parent:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(speed)
        movement.RotateDuration = ghostSlowConfig.TurningDuration

        ---@type XPacMan2.XPacMan2BehaviorGhostRange
        local range = ghost.transform.parent:GetComponent(typeof(CS.XPacMan2.XPacMan2BehaviorGhostRange))
        if range then
            range.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])
            self:UpdateRange(range, true)
            range:UpdateRangeVisible()
        end

        ghost.SpeedMultipiler = ghostSlowConfig.Params[1] / 100
        --ghost.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])

        ---@type XPacMan2.XPacMan2SlowDown
        local slowDown = ghostSlowDowns[i]
        slowDown.Range = Vector2(ghostSlowConfig.Params[2], ghostSlowConfig.Params[3])
        slowDown:UpdateRange()
    end

    -- 配置跑鞋道具参数
    local shoeConfig = self._Control:GetEntityConfig(EntityEnum.Shoe)
    local shoes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Shoe), true)
    for i = 0, shoes.Length - 1 do
        local shoe = shoes[i]
        local shoeTransform = shoe.transform
        local movement = shoeTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(shoeConfig.Speed)
    end

    -- 配置玩家分身参数
    local playerCloneConfig = self._Control:GetEntityConfig(EntityEnum.PlayerClone)
    local playerClones = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2PlayerClone), true)
    for i = 0, playerClones.Length - 1 do
        local playerClone = playerClones[i]
        local playerCloneTransform = playerClone.transform
        local movement = playerCloneTransform:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
        movement.Speed = self:Divide1000(playerCloneConfig.Speed)

        playerClone.Duration = playerCloneConfig.Params[1]
        playerClone.GhostStopDuration = playerCloneConfig.Params[2]
    end

    -- 设置关卡星级要求
    self._ConfigStarList = stageConfig.Star

    -- 配置无敌效果持续时间
    local invincibleValue = gameConfig.Invincible.Value
    if invincibleValue then
        local invincibles = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2Invincible), true)
        for i = 0, invincibles.Length - 1 do
            local invincible = invincibles[i]
            invincible.Duration = invincibleValue / 1000
        end
    else
        XLog.Error("[XUiPacMan2Game] 找不到无敌时间长度的配置")
    end

    -- 配置贪吃蛇怪物参数
    local snakeConfig = self._Control:GetEntityConfig(EntityEnum.Snake)
    if snakeConfig then
        local snakes = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SnakeHead), true)
        for i = 0, snakes.Length - 1 do
            local snake = snakes[i]
            snake.MaxLength = snakeConfig.Params[1]

            local movement = snake:GetComponent(typeof(CS.XPacMan2.XPacMan2Movement))
            movement.Speed = self:Divide1000(snakeConfig.Speed)
        end
    end

    -- 配置贪吃怪物参数
    local ghostEatOrbConfig = self._Control:GetEntityConfig(EntityEnum.EatGhost)
    if ghostEatOrbConfig then
        local ghostEatOrbs = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2BehaviorGhostEatOrb), true)
        for i = 0, ghostEatOrbs.Length - 1 do
            local ghostEatOrb = ghostEatOrbs[i]
            ghostEatOrb.SpeedHungry = self:Divide1000(ghostEatOrbConfig.Speed)
            ghostEatOrb.SpeedFull = self:Divide1000(ghostEatOrbConfig.Params[1])
            ghostEatOrb.Full = ghostEatOrbConfig.Params[2]
            ghostEatOrb:UpdateStatus()
        end
    end

    -- 配置全局减速道具参数
    local ghostSlowDownGhostsConfig = self._Control:GetEntityConfig(EntityEnum.SlowDownGhost)
    if ghostSlowDownGhostsConfig then
        local ghostSlowDownGhosts = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SlowDownGhosts), true)
        for i = 0, ghostSlowDownGhosts.Length - 1 do
            local ghostSlowDownGhost = ghostSlowDownGhosts[i]
            ghostSlowDownGhost.SpeedMultiplier = ghostSlowDownGhostsConfig.Params[1] / 10000
            ghostSlowDownGhost.Duration = ghostSlowDownGhostsConfig.Params[2]
        end
    end

    -- 配置玩家加速道具参数
    local speedUpPlayerConfig = self._Control:GetEntityConfig(EntityEnum.SpeedUpPlayer)
    if speedUpPlayerConfig then
        local speedUpPlayers = stagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SpeedUpPlayer), true)
        for i = 0, speedUpPlayers.Length - 1 do
            local speedUpPlayer = speedUpPlayers[i]
            speedUpPlayer.SpeedMultiplier = (speedUpPlayerConfig.Params[1] / 10000 + 1)
            speedUpPlayer.Duration = speedUpPlayerConfig.Params[2]
        end
    end
end

function XUiPacMan2Game:Divide1000(value)
    return value / 1000
end

--- 禁用道具音效（在离开关卡时调用）
function XUiPacMan2Game:_DisableItemSounds()
    if not self._StagePrefab then
        return
    end
    
    -- 查找所有 XPacMan2SlowDownGhosts 组件
    local ghostSlowDownGhosts = self._StagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SlowDownGhosts), true)
    for i = 0, ghostSlowDownGhosts.Length - 1 do
        local component = ghostSlowDownGhosts[i]
        local soundComp = component:GetComponent("XUguiPlaySoundWithSource")
        if soundComp then
            soundComp.CueId = 0
        end
    end
    
    -- 查找所有 XPacMan2SpeedUpPlayer 组件
    local speedUpPlayers = self._StagePrefab:GetComponentsInChildren(typeof(CS.XPacMan2.XPacMan2SpeedUpPlayer), true)
    for i = 0, speedUpPlayers.Length - 1 do
        local component = speedUpPlayers[i]
        local soundComp = component:GetComponent("XUguiPlaySoundWithSource")
        if soundComp then
            soundComp.CueId = 0
        end
    end
end

function XUiPacMan2Game:UpdateRange(range, value)
    -- 这一期没有范围怪
    --if value then
    --    if range.RangeTransform then
    --        range.RangeTransform.gameObject:SetActiveEx(true)
    --    end
    --    range.IsRangeVisible = true
    --else
    --    if range.RangeTransform then
    --        range.RangeTransform.gameObject:SetActiveEx(false)
    --    end
    --    range.IsRangeVisible = false
    --end
end

function XUiPacMan2Game:AddListenerInput()
    ---@type XGoInputHandler
    local goInputHandler = self.InputHandler
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:OnBeginDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    self._DragOffset.x = x
    self._DragOffset.y = y
end

-----@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:OnDrag(eventData)
    local x, y = self:GetPosByEventData(eventData)
    local offsetX = x - self._DragOffset.x
    local offsetY = y - self._DragOffset.y

    local isTriggerMove = false
    local length = offsetX ^ 2 + offsetY ^ 2
    if length > 5 then
        -- 在长度足够的情况下, 以长度为方向移动
        local xAbs = math.abs(offsetX)
        local yAbs = math.abs(offsetY)
        if xAbs > yAbs then
            if offsetX > 0 then
                -- 如果当前方向已经是Right，则不调用Move
                if self._CurrentDirection ~= Direction.Right then
                    self._CurrentDirection = Direction.Right
                    self._PlayerMovement:MoveRight()
                    self._PlayerMovement:CheckOccupied(Vector2.right)
                    isTriggerMove = true
                end
            else
                -- 如果当前方向已经是Left，则不调用Move
                if self._CurrentDirection ~= Direction.Left then
                    self._CurrentDirection = Direction.Left
                    self._PlayerMovement:MoveLeft()
                    isTriggerMove = true
                end
            end
        else
            if offsetY > 0 then
                -- 如果当前方向已经是Up，则不调用Move
                if self._CurrentDirection ~= Direction.Up then
                    self._CurrentDirection = Direction.Up
                    self._PlayerMovement:MoveUp()
                    isTriggerMove = true
                end
            else
                -- 如果当前方向已经是Down，则不调用Move
                if self._CurrentDirection ~= Direction.Down then
                    self._CurrentDirection = Direction.Down
                    self._PlayerMovement:MoveDown()
                    isTriggerMove = true
                end
            end
        end
        -- 其实人的手并没有那么精准，经常会拖出介于两者之间的角度，所以当处于边界角度时，需要进行“聪明”的判断，否则会被认为“操作手感不好”
        -- 但是这相当于要预判下一个拐弯处的方向，目前已经没有时间做这种事情了~~
        -- 所以由角度改为距离判断
        --else
        --    -- 否则以角度为方向移动
        --    local atan = math.atan(offsetY, offsetX) * 180 / math.pi
        --    if atan < 45 and atan > -45 then
        --        self._PlayerMovement:MoveRight()
        --        isTriggerMove = true
        --    elseif atan > 135 or atan < -135 then
        --        self._PlayerMovement:MoveLeft()
        --        isTriggerMove = true
        --    elseif atan > 45 and atan < 135 then
        --        self._PlayerMovement:MoveUp()
        --        isTriggerMove = true
        --    elseif atan < -45 and atan > -135 then
        --        self._PlayerMovement:MoveDown()
        --        isTriggerMove = true
        --    end
        --end
    end

    -- 重置操控点
    if isTriggerMove then
        self._DragOffset.x = x
        self._DragOffset.y = y
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:OnEndDrag(eventData)
    self._DragOffset.x = 0
    self._DragOffset.y = 0
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiPacMan2Game:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.InputHandler.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    return x, y
end

function XUiPacMan2Game:UpdateStar(score)
    local starDatas = {}
    for i = 1, #self._ConfigStarList do
        local starScore = self._ConfigStarList[i]
        ---@class XUiPacMan2StarTargetData
        local starData = {
            Star = i,
            Score = starScore,
            IsOn = score >= self._ConfigStarList[i],
        }
        table.insert(starDatas, starData)
    end
    XTool.UpdateDynamicItem(self._StarList, starDatas, self.GridStar01, XUiPacMan2StarTarget, self)
end

function XUiPacMan2Game:StartCountDown()
    self._IsCountDown = true
    self.PanelCountdown.gameObject:SetActiveEx(true)
    -- 重置当前方向
    self._CurrentDirection = Direction.None
    self:PlayAnimation("Countdown", function()
        self._IsCountDown = false
        self.PanelCountdown.gameObject:SetActiveEx(false)
        self._GameManager:Resume()
        -- 恢复游戏时重新启用手柄功能
        if self._GamepadInput then
            self._GamepadInput:Enable()
        end
    end)
    --local countDown = 4
    --self._CountDown = countDown - 1
    --self:SetCountDownText(countDown - self._CountDown)
    --self.PanelCountdown.gameObject:SetAxctiveEx(true)
    --self._CountDownTimer = XScheduleManager.ScheduleForever(function()
    --    self._CountDown = self._CountDown - 1
    --    self:SetCountDownText(countDown - self._CountDown)
    --    if self._CountDown < 0 then
    --        XScheduleManager.UnSchedule(self._CountDownTimer)
    --        self._CountDownTimer = false
    --        self._GameManager:Resume()
    --        self.PanelCountdown.gameObject:SetActiveEx(false)
    --        self._IsCountDown = false
    --    end
    --end, XScheduleManager.SECOND)
end

function XUiPacMan2Game:SetCountDownText(value)
    for i = 1, 4 do
        local ui = self._CountDownText[i]
        if ui then
            if value then
                ui.gameObject:SetActiveEx(value == i)
            end
        end
    end
end

function XUiPacMan2Game:UpdateHp(hp, animation)
    for i = 1, hp do
        local gridLife = self._HpGrids[i]
        if not gridLife then
            local ui = XUiHelper.Instantiate(self.GridLife, self.GridLife.transform.parent)
            ui.gameObject:SetActiveEx(true)
            gridLife = XUiPacMan2GridLife.New(ui, self)
            table.insert(self._HpGrids, gridLife)
        end
        gridLife:Update(true, animation)
    end
    for i = hp + 1, #self._HpGrids do
        local gridLife = self._HpGrids[i]
        if gridLife then
            gridLife:Update(false, animation)
        end
    end
end

function XUiPacMan2Game:OpenPauseUi()
    if self._IsCountDown then
        return
    end
    -- 只有playing可以打开暂停界面
    -- 修复:复活触发倒计时的时候，点快点能打开暂停界面
    if self._GameManager:GetGameState() == GameState.Playing then
        self._GameManager:Pause()
        -- 暂停游戏时恢复鼠标显示并禁用手柄功能
        if self._GamepadInput then
            self._GamepadInput:RestoreCursor()
            self._GamepadInput:Disable()
        end
        XLuaUiManager.Open("UiPacMan2PopupStageStop", self._StageId, function()
            self:StartCountDown()
            --self._GameManager:Resume()
        end)
    else
        XLog.Warning("[XUiPacMan2Game] 游戏不在进行中，禁止打开暂停界面")
    end
end

function XUiPacMan2Game:OnClickUp()
    self._CurrentDirection = Direction.Up
    self._PlayerMovement:MoveUp()
end

function XUiPacMan2Game:OnClickDown()
    self._CurrentDirection = Direction.Down
    self._PlayerMovement:MoveDown()
end

function XUiPacMan2Game:OnClickLeft()
    self._CurrentDirection = Direction.Left
    self._PlayerMovement:MoveLeft()
end

function XUiPacMan2Game:OnClickRight()
    self._CurrentDirection = Direction.Right
    self._PlayerMovement:MoveRight()
end

function XUiPacMan2Game:UpdateTips(tipsType, params1)
    if not tipsType then
        -- 处理所有类型的提示
        for i = #self._Tips, 1, -1 do
            ---@type XTablePacMan2StageTips
            local tipsConfig = self._Tips[i]
            
            if self:ShouldShowTip(tipsConfig) then
                self:AppendText(XUiHelper.ReplaceTextNewLine(tipsConfig.TipsContent))
                table.remove(self._Tips, i)
            end
        end
    else
        -- 触发特定类型
        for i = 1, #self._Tips do
            ---@type XTablePacMan2StageTips
            local tipsConfig = self._Tips[i]

            -- 触发类型:获得道具
            if tipsType == TipsType.GetItem and tipsConfig.TriggerType == TipsType.GetItem then
                local itemId = params1
                if itemId == tipsConfig.TriggerPram[1] then
                    -- 道具类型的tips，即使文本相同也要显示（传入true强制添加）
                    self:AppendText(XUiHelper.ReplaceTextNewLine(tipsConfig.TipsContent), true)
                end
            end

            -- 触发类型:击杀怪物
            if tipsType == TipsType.KillMonster and tipsConfig.TriggerType == TipsType.KillMonster then
                self:AppendText(XUiHelper.ReplaceTextNewLine(tipsConfig.TipsContent))
            end
        end
    end
end

-- 判断是否应该显示提示
function XUiPacMan2Game:ShouldShowTip(tipsConfig)
    local triggerType = tipsConfig.TriggerType
    
    -- 触发类型:进入
    if triggerType == TipsType.Enter then
        return true
    end
    
    -- 触发类型:怪物获得分数
    if triggerType == TipsType.EatMonster then
        local star = tipsConfig.TriggerPram[1]
        if star then
            local needOrbs = self._ConfigStarList[star]
            if needOrbs then
                local orbs = self._GameManager.EnemyOrbs
                -- 怪物吃豆时,当前抢走豆子数量之和大于关卡总豆子数量减X星会条件所需豆子数量之差时触发,参数1配置判断的星级条件
                if orbs >= (self._GameManager.OrbsTotal - needOrbs) then
                    return true
                end
            end
        end
    end
    
    -- 触发类型:玩家达到多少星级
    if triggerType == TipsType.EatPlayer then
        local star = tipsConfig.TriggerPram[1]
        if star then
            local needOrbs = self._ConfigStarList[star]
            if needOrbs then
                local orbs = self._GameManager:GetOrbs()
                if orbs >= needOrbs then
                    return true
                end
            end
        end
    end
    
    -- 触发类型:剩余多少Orb
    if triggerType == TipsType.RemainOrbs then
        local remainOrbs = self._GameManager.OrbsAttackThreshold - self._GameManager:GetOrbsEaten()
        if remainOrbs <= tipsConfig.TriggerPram[1] then
            return true
        end
    end
    
    -- 触发类型:开始追逐
    if triggerType == TipsType.StartChase then
        if self._GameManager:GetGhostState() == CS.XPacMan2.XPacMan2GhostState.Attack then
            return true
        end
    end
    
    -- 触发类型:显示通关钥匙
    if triggerType == TipsType.EnableKey then
        if self._GameManager:GetOrbs() >= self._GameManager.OrbsToShowKey then
            local needStar = tipsConfig.TriggerPram[2]
            local score = self._GameManager.Orbs
            local needStarScore = self._ConfigStarList[needStar]
            if needStarScore then
                -- 撤离点启用且满足参数配置的判断条件时触发,参数1配置启用时是否达到星级要求,已达到=1,未达到=2;参数2配置判断的星级条件
                if score < needStarScore and tipsConfig.TriggerPram[1] == 2 then
                    return true
                elseif score >= needStarScore and tipsConfig.TriggerPram[1] == 1 then
                    return true
                end
            end
        end
    end
    
    return false
end

function XUiPacMan2Game:InitInput()
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.CloudGame
            or XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Default
    then
        self.BtnSwitch.gameObject:SetActiveEx(true)
        self.Keyboard.gameObject:SetActiveEx(false)
        self:UpdateInput()
        return
    end
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        self.BtnSwitch.gameObject:SetActiveEx(false)
        self.Keyboard.gameObject:SetActiveEx(true)
        self.InputHandler.gameObject:SetActiveEx(false)
        self.PanelControl.gameObject:SetActiveEx(false)
        return
    end
end

function XUiPacMan2Game:UpdateInput()
    if self._IsTouch then
        self.InputHandler.gameObject:SetActiveEx(true)
        self.PanelControl.gameObject:SetActiveEx(false)
    else
        self.InputHandler.gameObject:SetActiveEx(false)
        self.PanelControl.gameObject:SetActiveEx(true)
    end
end

function XUiPacMan2Game:UpdateTipsTextBySwitchInput()
    if self._IsTouch then
        self:AppendText(self._SwitchTipKey.TipsContent)
    else
        self:AppendText(self._SwitchTipTouch.TipsContent)
    end
end

function XUiPacMan2Game:UpdateProgressBar()
    local totalScore = self._GameManager.OrbsTotal
    local playerScore = self._GameManager.Orbs
    local startProgressPosition = self.StartProgress.position
    local endProgressPosition = self.EndProgress.position

    local playerProgress = self:CalculateProgress(playerScore, totalScore)
    self.ImgPlayerBar.fillAmount = playerProgress
    local playerPosition = Vector3.Lerp(startProgressPosition, endProgressPosition, playerProgress)
    self._MoverPlayer:SetTargetPosition(playerPosition)
    --self.PanelPlayer.transform.position = playerPosition

    -- 敌人的进度和玩家是倒着算的
    local enemyScore = self._GameManager.EnemyOrbs
    local enemyProgress = 1 - self:CalculateProgress(totalScore - enemyScore, totalScore)
    self.ImgEnemyBar.fillAmount = enemyProgress
    local enemyPosition = Vector3.Lerp(endProgressPosition, startProgressPosition, enemyProgress)
    self._MoverEnemy:SetTargetPosition(enemyPosition)
    --self.PanelEnemy.transform.position = enemyPosition
end

function XUiPacMan2Game:CalculateProgress(score, totalScore)
    local progress = 0
    local lastStarScore = 0
    for i = 1, #self._ConfigStarList do
        local starScore = self._ConfigStarList[i]
        if score >= starScore then
            progress = progress + 1 / (#self._ConfigStarList + 1)
        else
            progress = progress + (score - lastStarScore) / (starScore - lastStarScore) / (#self._ConfigStarList + 1)
            break
        end
        lastStarScore = starScore
    end
    lastStarScore = self._ConfigStarList[#self._ConfigStarList]
    if score > lastStarScore then
        progress = progress + (score - lastStarScore) / (totalScore - lastStarScore) / (#self._ConfigStarList + 1)
    end
    return progress
end

function XUiPacMan2Game:InitStarPosition()
    local startPosition = self.StartPosition.position
    local endPosition = self.EndPosition.position
    for i = 1, #self._StarList do
        local star = self._StarList[i]
        star.Transform.position = Vector3.Lerp(startPosition, endPosition, i / (#self._StarList + 1))
    end
end

function XUiPacMan2Game:InitPanelExit()
    -- 设置进度条上，面包车的位置
    local position = self.PanelExit.transform.position
    local startPosition = self.StartPosition.position
    local endPosition = self.EndPosition.position
    local orbsToShowKey = self._GameManager.OrbsToShowKey
    local orbsTotal = self._GameManager.OrbsTotal
    local progress = self:CalculateProgress(orbsToShowKey, orbsTotal)
    position.y = startPosition.y + (endPosition.y - startPosition.y) * progress
    self.PanelExit.transform.position = position
end

--- 添加提示文本
---@param text string 提示文本
---@param forceAppend? boolean 是否强制添加（即使文本相同），默认false
function XUiPacMan2Game:AppendText(text, forceAppend)
    -- 如果不是强制添加，且文本相同，则跳过
    if not forceAppend and self._TxtTipsArray[1].text == text then
        return
    end
    for i = #self._TxtTipsArray, 2, -1 do
        local thisText = self._TxtTipsArray[i]
        thisText.text = self._TxtTipsArray[i - 1].text
        if (thisText.text ~= "") then
            thisText.gameObject:SetActiveEx(true)
        end
    end
    self._TxtTipsArray[1].text = text
    if XMain.IsDebug then
        print("Append text:" .. text)
    end
end

function XUiPacMan2Game:UpdatePlayerKillGhostPhase()
    if not self._GameManager then
        return
    end
    
    local isPlayerKillGhostPhase = self._GameManager.IsPlayerKillGhostPhase
    local ghostState = self._GameManager:GetGhostState()
    local backgroundType = BackgroundType.Default
    if isPlayerKillGhostPhase then
        backgroundType = BackgroundType.PlayerKillGhost
    elseif ghostState == CS.XPacMan2.XPacMan2GhostState.Attack then
        backgroundType = BackgroundType.GhostKillPlayer
    end
    if self._BackgroundType ~= backgroundType then
        self._BackgroundType = backgroundType
        self:UpdateBackground()
    end
end

function XUiPacMan2Game:UpdateBackground()
    local backgroundType = self._BackgroundType
    
    -- 遍历所有背景类型，显示当前类型，隐藏其他类型
    for bgType, bgGameObject in pairs(self._Backgounrd) do
        if bgGameObject then
            bgGameObject.gameObject:SetActiveEx(bgType == backgroundType)
        end
    end
end

function XUiPacMan2Game:InitBackground()
    local bgTileTextureSlow = self._StagePrefab.transform:Find("CameraLayer/TileMapCamera/UiPacMan2Background/GameObject/BgTileTextureSlow")
    local bgTileTextureQuick = self._StagePrefab.transform:Find("CameraLayer/TileMapCamera/UiPacMan2Background/GameObject/BgTileTextureQuick")
    local bgTileTextureReverse = self._StagePrefab.transform:Find("CameraLayer/TileMapCamera/UiPacMan2Background/GameObject/BgTileTextureReverse")
    
    if bgTileTextureSlow then
        self._Backgounrd[BackgroundType.Default] = bgTileTextureSlow
    end
    if bgTileTextureQuick then
        self._Backgounrd[BackgroundType.PlayerKillGhost] = bgTileTextureReverse
    end
    if bgTileTextureReverse then
        self._Backgounrd[BackgroundType.GhostKillPlayer] = bgTileTextureQuick
    end
    
    self:UpdateBackground()
end

--- 显示像素化特效（当 kills 数量变化时）
function XUiPacMan2Game:ShowPixelationEffect()
    if not self.FxPixelation01 or not self._GameManager or not self._GameManager.Player then
        return
    end
    
    -- 获取玩家世界坐标
    local playerWorldPosition = self._GameManager.Player.transform.position
    
    -- 获取场景相机（TileMapCamera）
    local sceneCameraTransform = self._StagePrefab and self._StagePrefab.transform:Find("CameraLayer/TileMapCamera")
    if not sceneCameraTransform then
        return
    end
    
    local sceneCamera = sceneCameraTransform:GetComponent(typeof(CS.UnityEngine.Camera))
    if not sceneCamera then
        return
    end
    
    -- 将玩家世界坐标转换为视口坐标
    local playerViewportPos = sceneCamera:WorldToViewportPoint(playerWorldPosition)
    
    -- 获取UI相机
    local uiCamera = CS.XUiManager.Instance.UiCamera
    
    -- 获取 _MoverPlayer 的位置（PanelPlayer 的 UI 世界坐标）
    local moverPlayerWorldPos = self.PanelPlayer.transform.position
    local moverPlayerViewportPos = uiCamera:WorldToViewportPoint(moverPlayerWorldPos)
    
    -- 计算玩家到 _MoverPlayer 的距离
    local dxPlayer = playerViewportPos.x - moverPlayerViewportPos.x
    local dyPlayer = playerViewportPos.y - moverPlayerViewportPos.y
    local playerToMoverDistance = math.sqrt(dxPlayer * dxPlayer + dyPlayer * dyPlayer)
    
    -- 计算 _MoverPlayer 到 3 个节点的距离
    local nodeDistances = {}
    if self._PixelationNodes then
        for i, node in ipairs(self._PixelationNodes) do
            if node and not XTool.UObjIsNil(node) then
                local nodeWorldPos = node.transform.position
                local nodeViewportPos = uiCamera:WorldToViewportPoint(nodeWorldPos)
                
                local dx = moverPlayerViewportPos.x - nodeViewportPos.x
                local dy = moverPlayerViewportPos.y - nodeViewportPos.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                nodeDistances[i] = {
                    node = node,
                    distance = distance
                }
            end
        end
    end
    
    -- 选择节点
    local selectedNode = nil
    
    -- 如果没有节点距离数据，使用默认的 FxPixelation01
    if XTool.IsTableEmpty(nodeDistances) then
        selectedNode = self.FxPixelation01
    else
        -- 按距离排序（从小到大）
        table.sort(nodeDistances, function(a, b)
            return a.distance < b.distance
        end)
        
        -- 根据玩家到 _MoverPlayer 的距离选择节点
        if #nodeDistances == 1 then
            selectedNode = nodeDistances[1].node
        elseif #nodeDistances == 2 then
            local d1 = nodeDistances[1].distance
            local d2 = nodeDistances[2].distance
            
            if playerToMoverDistance <= d1 then
                selectedNode = nodeDistances[1].node
            elseif playerToMoverDistance <= d2 then
                -- 在 d1 和 d2 之间，看更接近哪个
                local distToD1 = math.abs(playerToMoverDistance - d1)
                local distToD2 = math.abs(playerToMoverDistance - d2)
                selectedNode = (distToD1 < distToD2) and nodeDistances[1].node or nodeDistances[2].node
            else
                selectedNode = nodeDistances[2].node
            end
        elseif #nodeDistances >= 3 then
            local d1 = nodeDistances[1].distance
            local d2 = nodeDistances[2].distance
            local d3 = nodeDistances[3].distance
            
            if playerToMoverDistance <= d1 then
                selectedNode = nodeDistances[1].node
            elseif playerToMoverDistance <= d2 then
                -- 在 d1 和 d2 之间，看更接近哪个
                local distToD1 = math.abs(playerToMoverDistance - d1)
                local distToD2 = math.abs(playerToMoverDistance - d2)
                selectedNode = (distToD1 < distToD2) and nodeDistances[1].node or nodeDistances[2].node
            elseif playerToMoverDistance <= d3 then
                -- 在 d2 和 d3 之间，看更接近哪个
                local distToD2 = math.abs(playerToMoverDistance - d2)
                local distToD3 = math.abs(playerToMoverDistance - d3)
                selectedNode = (distToD2 < distToD3) and nodeDistances[2].node or nodeDistances[3].node
            else
                selectedNode = nodeDistances[3].node
            end
        end
    end
    
    -- 如果没有找到可用的节点，使用默认的 FxPixelation01
    if not selectedNode then
        selectedNode = self.FxPixelation01
    end
    
    -- 克隆选中的节点
    local clonedFx = XUiHelper.Instantiate(selectedNode.gameObject, selectedNode.transform.parent)
    
    -- 获取节点原始位置的 z 坐标（保持在相同的 UI 层级）
    local originalZ = selectedNode.transform.position.z
    
    -- 计算相机到节点的距离（用于 ViewportToWorldPoint）
    local cameraToNodeDistance = originalZ - uiCamera.transform.position.z
    
    -- 将玩家视口坐标转换为UI世界坐标，使用相机到节点的距离作为 z
    local viewportPosWithDepth = CS.UnityEngine.Vector3(playerViewportPos.x, playerViewportPos.y, cameraToNodeDistance)
    local uiWorldPosition = uiCamera:ViewportToWorldPoint(viewportPosWithDepth)
    
    -- 设置克隆体的位置
    clonedFx.transform.position = uiWorldPosition
    
    -- 激活克隆体
    clonedFx:SetActiveEx(true)
    
    -- 保存定时器ID以便后续销毁
    if not self._PixelationTimers then
        self._PixelationTimers = {}
    end
    
    -- 先声明 timerId，才能在回调函数内使用
    local timerId
    -- 一定时间后移除克隆体
    timerId = XScheduleManager.ScheduleOnce(function()
        if clonedFx and not XTool.UObjIsNil(clonedFx) then
            CS.UnityEngine.Object.Destroy(clonedFx)
        end
        -- 从定时器列表中移除
        if self._PixelationTimers then
            for i, id in ipairs(self._PixelationTimers) do
                if id == timerId then
                    table.remove(self._PixelationTimers, i)
                    break
                end
            end
        end
    end, XScheduleManager.SECOND * 5)
    
    -- 保存定时器ID以便后续销毁
    table.insert(self._PixelationTimers, timerId)
end

--- 清理所有像素化特效定时器
function XUiPacMan2Game:_ClearPixelationTimers()
    if self._PixelationTimers then
        for _, timerId in ipairs(self._PixelationTimers) do
            if timerId then
                XScheduleManager.UnSchedule(timerId)
            end
        end
        self._PixelationTimers = {}
    end
end

--- 显示 FlashKill 特效（当 kills 数量变化时）
function XUiPacMan2Game:ShowFlashKillEffect()
    if not self.FlashKill then
        return
    end
    
    -- 克隆 FlashKill 节点
    local clonedFx = XUiHelper.Instantiate(self.FlashKill.gameObject, self.FlashKill.transform.parent)
    
    -- 激活克隆体
    clonedFx:SetActiveEx(true)
    
    -- 保存定时器ID以便后续销毁
    if not self._FlashKillTimers then
        self._FlashKillTimers = {}
    end
    
    -- 先声明 timerId，才能在回调函数内使用
    local timerId
    -- 5秒后移除克隆体
    timerId = XScheduleManager.ScheduleOnce(function()
        if clonedFx and not XTool.UObjIsNil(clonedFx) then
            CS.UnityEngine.Object.Destroy(clonedFx)
        end
        -- 从定时器列表中移除
        if self._FlashKillTimers then
            for i, id in ipairs(self._FlashKillTimers) do
                if id == timerId then
                    table.remove(self._FlashKillTimers, i)
                    break
                end
            end
        end
    end, XScheduleManager.SECOND * 5)
    
    -- 保存定时器ID以便后续销毁
    table.insert(self._FlashKillTimers, timerId)
end

--- 清理所有 FlashKill 特效定时器
function XUiPacMan2Game:_ClearFlashKillTimers()
    if self._FlashKillTimers then
        for _, timerId in ipairs(self._FlashKillTimers) do
            if timerId then
                XScheduleManager.UnSchedule(timerId)
            end
        end
        self._FlashKillTimers = {}
    end
end

return XUiPacMan2Game