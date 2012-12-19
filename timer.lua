
local BASE_WIDTH = 36
local DONOT_UPDATE = 9999
local SOON, SECOND, SHORT, MINUTE, HOUR, DAY = 10, 60, 600, 3600, 86400
local BUFF, ACTION = 'Buff', 'Action'

local round = function(x) return floor(x + 0.5) end

local tdCC = tdCore(...)

local Style = tdCC:NewModule('Style')
local Shine = tdCC:NewModule('Shine', CreateFrame('Frame'))
local Timer = tdCC:NewModule('Timer', CreateFrame('Frame'), 'Update', 'Event')

----- style


Style.Texts = {}
Style.NextUpdates = {}
Style.Keys = {
    Soon   = 'soon',
    Second = 'second',
    Short  = 'minute',
    Minute = 'minute',
    Hour   = 'hour',
    Day    = 'hour',
}

function Style:New(timer)
    local style = self:Bind({})
    style.timer = timer
    return style
end

function Style:GetInfo()
    local remain = self:GetRemain()
    
    if remain < SOON then
        return 'Soon'
    elseif remain < SECOND then
        return 'Second'
    elseif remain < SHORT then
        return self.timer:getMMSS() and 'Short' or 'Minute'
    elseif remain < MINUTE then
        return 'Minute'
    elseif remain < HOUR then
        return 'Hour'
    else
        return 'Day'
    end
end

function Style:GetRemain()
    return self.timer:GetRemain()
end

function Style:IsChanged()
    local info = self:GetInfo()
    
    if info ~= self.info then
        self.info = info
        return true
    end
end

function Style:GetTimeText()
    return self.Texts[self.info](self:GetRemain())
end

function Style:GetNextUpdate()
    return self.NextUpdates[self.info](self:GetRemain())
end

function Style:GetTimeColor()
    local color = self:GetSetting()
    return color.r, color.g, color.b
end

function Style:GetTimeScale()
    return self:GetSetting().scale
end

function Style:GetKey()
    return self.Keys[self.info]
end

function Style:GetSetting()
    return self.timer.set.styles[self:GetKey()]
end

local Texts = Style.Texts
function Texts.Soon(remain)
    return format('%d', ceil(remain))
end
Texts.Second = Texts.Soon

function Texts.Short(remain)
    remain = ceil(remain)
    
    return format('%d:%02d', floor(remain / SECOND), ceil(remain % SECOND))
end

function Texts.Minute(remain)
    return format('%dm', ceil(remain / SECOND))
end

function Texts.Hour(remain)
    return format('%dh', ceil(remain / MINUTE))
end

function Texts.Day(remain)
    return format('%dd', ceil(remain / HOUR))
end

local NextUpdates = Style.NextUpdates
function NextUpdates.Soon(remain)
    return remain - floor(remain)
end
NextUpdates.Second = NextUpdates.Soon
NextUpdates.Short  = NextUpdates.Soon

function NextUpdates.Minute(remain)
    return remain % SECOND
end

function NextUpdates.Hour(remain)
    return remain % MINUTE
end

function NextUpdates.Day(remain)
    return remain % HOUR
end

----- timer

local timers = {}
local actives = {}

local function cooldownGetSize(self)
    local width, height = self:GetSize()
    if not width or width == 0 then
        width, height = self:GetParent():GetSize()
    end
    return width or 0, height or 0
end

local function cooldownOnHide(self)
    Timer:Get(self):Stop()
end

local function cooldownOnSizeChanged(self, width, height)
    local timer = Timer:Get(self)
    if timer.width ~= width then
        timer:UpdateSize(width, height)
        if timer.start then
            timer:Start(timer.start, timer.duration)
        end
    end
end

local function cooldownInit(self)
    self:HookScript('OnSizeChanged', cooldownOnSizeChanged)
    self:HookScript('OnHide', cooldownOnHide)
end

local function getClass(cooldown)
    return cooldown:GetReverse() and BUFF or ACTION
end

local function getSetting(cooldown)
    return tdCC:GetProfile().class[getClass(cooldown)]
end

local function shouldShow(cooldown, start, duration, charges, maxCharges)
    if not cooldown.noCooldownCount and start > 0 and duration > 0 then
        local set = getSetting(cooldown)
        
        return set.enable and set.minDuration <= duration and ((charges or 0) == 0 or (not set.hideHaveCharges))
    end
end

local function setCooldown(cooldown, start, duration, charges, maxCharges)
    if shouldShow(cooldown, start, duration, charges, maxCharges) then
        Timer:Get(cooldown):Start(start, duration)
    elseif timers[cooldown] then
        timers[cooldown]:Stop()
    end
end

function Timer:New(cooldown)
    local timer = self:Bind(CreateFrame('Frame', nil, cooldown:GetParent()))
    
    timer:UpdateSize(cooldownGetSize(cooldown))
    timer:SetPoint('CENTER')
    
    timer.cooldown = cooldown
    timer.style = Style:New(timer)
    timer.text = timer:CreateFontString(nil, 'OVERLAY')
    
    cooldownInit(cooldown)
    
    timers[cooldown] = timer
    
    return timer
end

function Timer:Get(cooldown)
    return timers[cooldown] or self:New(cooldown)
end

function Timer:UpdateSize(width, height)
    self.width = width
    self.ratio = round(width) / BASE_WIDTH
    self:SetSize(width, height)
end

function Timer:UpdateStyle()
    if self.style:IsChanged() or not self.fontReady then
        self.fontReady = self.text:SetFont(self:getFontArgs())
    end
end

function Timer:UpdateText()
    if not self.fontReady then return end
    
    self.text:Show()
    self.text:SetText(self.style:GetTimeText())
    self.text:SetTextColor(self.style:GetTimeColor())
end

function Timer:UpdatePosition()
    self.text:SetPoint('CENTER', self, self:getPositionArgs())
end

function Timer:UpdateBlizzModel()
    self.cooldown:SetAlpha(self:getHideBlizzModel() and 0 or 1)
end

function Timer:UpdateNextUpdate()
    self.nextUpdate = self.style:GetNextUpdate()
end

function Timer:Update()
    local time = GetTime()
    if self.start > time then
        self.nextUpdate = self.start - time
        return
    end
    
    local remain, startRemain = self:GetRemain(), self:getStartRemain()
    if startRemain > 0 and startRemain < remain then
        self.text:Hide()
        self.nextUpdate = remain - startRemain
        return
    end
    
    if remain < 0.2 then
        Shine:StartShine(self)
        self:Stop()
        return
    end
    
    self:UpdateStyle()
    self:UpdateText()
    self:UpdateNextUpdate()
end

function Timer:Start(start, duration)
    self.set = self:GetSetting()
    
    if not self.ratio or self.ratio == 0 then
        self.nextUpdate = DONOT_UPDATE
    elseif self.ratio < self:getMinRatio() then
        return
    else
        self:UpdateBlizzModel()
        self:UpdatePosition()
        
        self.nextUpdate = start - GetTime()
    end
    
    self.fontReady = nil
    self.start = start
    self.duration = duration
    
    self:Show()
    actives[self] = true
end

function Timer:Stop()
    self.nextUpdate = DONOT_UPDATE
    actives[self] = nil
    
    if self.fontReady then
        self.text:SetText('')
    end
    
    self.start = nil
    self.duration = nil
    self.fontReady = nil
    
    self:Hide()
    self.cooldown:SetAlpha(1)
end

function Timer:GetRemain()
    return self.start + self.duration - GetTime()
end

function Timer:getMinRatio()
    return self.set.minRatio
end

function Timer:getHideBlizzModel()
    return self.set.hideBlizzModel
end

function Timer:getPositionArgs()
    return self.set.anchor, self.set.xOffset * self.ratio, self.set.yOffset * self.ratio
end

function Timer:getScale()
    return self.style:GetTimeScale()
end

function Timer:getFontArgs()
    return self.set.fontFace, self.set.fontSize * self:getScale() * self.ratio, self.set.fontOutline
end

function Timer:getStartRemain()
    return self.set.startRemain
end

function Timer:getMMSS()
    return self.set.mmss
end

function Timer:GetSetting()
    return getSetting(self.cooldown)
end

function Timer:OnUpdate(elapsed)
    if next(actives) then
        for timer in pairs(actives) do
            timer.nextUpdate = timer.nextUpdate - elapsed
            if timer.nextUpdate < 0 then
                timer:Update()
            end
        end
    end
end

----- compat

local actions = {}
local function actionOnShow(self)
    actions[self] = true
end

local function actionOnHide(self)
    actions[self] = nil
end

local function actionInit(button, action, cooldown)
    if not cooldown.tdaction then
        cooldown:HookScript('OnShow', actionOnShow)
        cooldown:HookScript('OnHide', actionOnHide)
    end
    cooldown.tdaction = action
end

function Timer:ACTIONBAR_UPDATE_COOLDOWN()
    for cooldown in pairs(actions) do
        local start, duration, enable = GetActionCooldown(cooldown.tdaction)
        local charges, maxCharges, chargeStart, chargeDuration = GetActionCharges(cooldown.tdaction)
        if enable and enable ~= 0 then
            setCooldown(cooldown, start, duration, charges, maxCharges)
        end
    end
end

----- init
function Timer:OnProfileUpdate()
    for cooldown, timer in pairs(timers) do
        if timer.start then
            timer:Start(timer.start, timer.duration)
        end
    end
end

function Timer:OnInit()
    hooksecurefunc(getmetatable(ActionButton1Cooldown).__index, 'SetCooldown', setCooldown)
    hooksecurefunc('SetActionUIButton', actionInit)
    
    for i, button in pairs(ActionBarButtonEventsFrame.frames) do
        actionInit(button, button.action, button.cooldown)
    end
    
    self:SetHandle('OnProfileUpdate', self.OnProfileUpdate)
    self:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN')
    self:StartUpdate()
end

---- Shine


local shines = {}
local shineCount = 0

local function animOnFinished(self)
    local parent = self:GetParent()
    if parent:IsShown() then
        parent:Hide()
    end
end

local function scaleOnFinished(self)
    self:GetParent():Finish()
end

function Shine:New(timer)
    local shine = self:Bind(CreateFrame('Frame', nil, timer:GetParent()))
    
    shine:Hide()
    shine:SetPoint('CENTER')
    shine:SetToplevel(true)
    shine:SetScript('OnHide', self.OnHide)
    
    local anim = shine:CreateAnimationGroup()
    anim:SetLooping('BOUNCE')
    anim:SetScript('OnFinished', animOnFinished)
    
    local grow = anim:CreateAnimation('Scale')
    grow:SetOrigin('CENTER', 0, 0)
    grow:SetOrder(0)
    grow:SetScript('OnFinished', scaleOnFinished)
    
    local icon = shine:CreateTexture(nil, 'OVERLAY')
	icon:SetBlendMode('ADD')
    icon:SetAllPoints(shine)
    
    shine.grow = grow
    shine.anim = anim
	shine.icon = icon
    shine.timer = timer
    
    shines[timer] = shine
    
    return shine
end

function Shine:OnHide()
	if self.anim:IsPlaying() then
		self.anim:Stop()
	end
    
	self:Hide()
    shineCount = shineCount - 1
end

function Shine:GetShine(timer)
    return shines[timer] or self:New(timer)
end

function Shine:Start()
    if self.anim:IsPlaying() then
        self.anim:Stop()
        shineCount = shineCount - 1
    end
    
    local width, height = self.timer:GetSize()
    
	local icon = self.icon
	local r, g, b = icon:GetVertexColor()
	icon:SetVertexColor(r, g, b, self:getShineAlpha())
	icon:SetTexture(self:GetIcon())
    
    local scale = self:getShineScale()
    self:SetSize(width * scale, height * scale)
    
    self.grow:SetScale(1 / scale, 1 / scale)
    self.grow:SetDuration(self:getShineDuration())
    
    shineCount = shineCount + 1

	self:Show()
	self.anim:Play()
end

function Shine:StartShine(timer)
    if shineCount > 10 then return end
    if not timer.set.shine or timer.set.shineMinDuration >= timer.duration then return end
    
    self:GetShine(timer):Start()
end

function Shine:GetIcon()
    local frame = self:GetParent()
    if frame then
        local icon = frame.icon
        if icon and icon.GetTexture then
            return icon:GetTexture()
        end

        local name = frame:GetName()
        if name then
            local icon = _G[name .. 'Icon'] or _G[name .. 'IconTexture']
            if icon and icon.GetTexture then
                frame.icon = icon
                return icon:GetTexture()
            end
        end
    end
end

-- setting

function Shine:getShineClass()
    return self.timer.set.shineClass
end

function Shine:getShineScale()
    return self.timer.set.shineScale
end

function Shine:getShineDuration()
    return self.timer.set.shineDuration
end

function Shine:getShineAlpha()
    return self.timer.set.shineAlpha
end
