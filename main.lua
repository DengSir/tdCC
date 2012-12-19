
local tdCC = tdCore:NewAddon(...)

local L = tdCC:GetLocale()

function tdCC:GetDefault()
    return {
        class = {
            Buff = {
                enable = true, hideBlizzModel = true, mmss = false, hideHaveCharges = false,
                minRatio = 0, minDuration = 0, startRemain = 60,
                fontFace = STANDARD_TEXT_FONT:lower(), fontSize = 26, fontOutline = 'OUTLINE',
                anchor = 'TOPRIGHT', xOffset = 0, yOffset = 0,
                styles = {
                    soon   = {r = 1, g = 0.1, b = 0.1, scale = 1},
                    second = {r = 1, g = 1,   b = 1,   scale = 1},
                    minute = {r = 1, g = 1,   b = 1,   scale = 1},
                    hour   = {r = 1, g = 1,   b = 1,   scale = 1},
                },
            },
            Action = {
                enable = true, hideBlizzModel = false, mmss = false, hideUsable = false,
                minRatio = 0, minDuration = 2.2, startRemain = 0,
                fontFace = STANDARD_TEXT_FONT:lower(), fontSize = 20, fontOutline = 'OUTLINE',
                anchor = 'CENTER', xOffset = 0, yOffset = 0,
                styles = {
                    soon   = {r = 1,   g = 0.1, b = 0.1, scale = 1.2},
                    second = {r = 1,   g = 1,   b = 1,   scale = 1  },
                    minute = {r = 0.8, g = 0.6, b = 0,   scale = 1  },
                    hour   = {r = 0.4, g = 0.4, b = 0.4, scale = 1},
                },
                shine = true, shineMinDuration = 10, shineClass = 'Icon',
                shineScale = 4, shineDuration =  1, shineAlpha = 1,
            }
        }
    }
end

function tdCC:OnInit()
    self:InitDB('TDDB_TDCOOLDOWNCOUNT', self:GetDefault())
    
    local function getGeneral(class)
        local gui = {
            type = 'Widget', label = GENERAL,
            {
                type = 'CheckBox', label = ENABLE, name = 'ActionDefaultEnable',
                profile = {self:GetName(), 'class', class, 'enable'},
            },
            {
                type = 'CheckBox', label = L['Hide blizz cooldown model'], depend = 'ActionDefaultEnable',
                profile = {self:GetName(), 'class', class, 'hideBlizzModel'},
            },
            {
                type = 'CheckBox', label = L['Minimum duration to display text as MM:SS'], depend = 'ActionDefaultEnable',
                profile = {self:GetName(), 'class', class, 'mmss'},
            },
            {
                type = 'LineEdit', label = L['Remaining how long after the start timer'], depend = 'ActionDefaultEnable',
                numeric = true,
                profile = {self:GetName(), 'class', class, 'startRemain'},
            },
            {
                type = 'Slider', label = L['Minimum duration to display text'], depend = 'ActionDefaultEnable',
                minValue = 0, maxValue = 10, valueStep = 0.1,
                profile = {self:GetName(), 'class', class, 'minDuration'},
            },
            {
                type = 'Slider', label = L['Minimum size to display text'], depend = 'ActionDefaultEnable',
                minValue = 0, maxValue = 3, valueStep = 0.1,
                profile = {self:GetName(), 'class', class, 'minRatio'},
            },
        }
        
        if class == 'Action' then
            tinsert(gui, 4, {
                type = 'CheckBox', label = L['Hide timer when has charges'], depend = 'ActionDefaultEnable',
                profile = {self:GetName(), 'class', class, 'hideHaveCharges'},
            })
        end
        return gui
    end
    
    local function getStyle(class)
        return {
            type = 'Widget', label = L['Style'], depend = 'ActionDefaultEnable',
            {
                type = 'ColorBox', label = L['Soon'], width = 20, height = 20,
                profile = {self:GetName(), 'class', class, 'styles', 'soon'},
                verticalArgs = {0, 3, 0},
            },
            {
                type = 'Slider', minValue = 0.5, maxValue = 2, valueStep = 0.1,
                profile = {self:GetName(), 'class', class, 'styles', 'soon', 'scale'},
            },
            {
                type = 'ColorBox', label = L['Second'], width = 20, height = 20,
                profile = {self:GetName(), 'class', class, 'styles', 'second'},
                verticalArgs = {0, 3, 0},
            },
            {
                type = 'Slider', minValue = 0.5, maxValue = 2, valueStep = 0.1,
                profile = {self:GetName(), 'class', class, 'styles', 'second', 'scale'},
            },
            {
                type = 'ColorBox', label = L['Minute'], width = 20, height = 20,
                profile = {self:GetName(), 'class', class, 'styles', 'minute'},
                verticalArgs = {0, 3, 0},
            },
            {
                type = 'Slider', minValue = 0.5, maxValue = 2, valueStep = 0.1,
                profile = {self:GetName(), 'class', class, 'styles', 'minute', 'scale'},
            },
            {
                type = 'ColorBox', label = L['Hour'], width = 20, height = 20,
                profile = {self:GetName(), 'class', class, 'styles', 'hour'},
                verticalArgs = {0, 3, 0},
            },
            {
                type = 'Slider', minValue = 0.5, maxValue = 2, valueStep = 0.1,
                profile = {self:GetName(), 'class', class, 'styles', 'hour', 'scale'},
            },
            {
                type = 'FontComboBox', label = L['Font'],
                profile = {self:GetName(), 'class', class, 'fontFace'},
            },
            {
                type = 'Slider', label = L['Font Size'],
                minValue = 5, maxValue = 36, valueStep = 1,
                profile = {self:GetName(), 'class', class, 'fontSize'},
            },
            {
                type = 'ComboBox', label = L['Anchor'],
                profile = {self:GetName(), 'class', class, 'anchor'},
                itemList = {
                    {value = 'TOPLEFT',     text = L['TopLeft']},
                    {value = 'TOP',         text = L['Top']},
                    {value = 'TOPRIGHT',    text = L['TopRight']},
                    {value = 'LEFT',        text = L['Left']},
                    {value = 'CENTER',      text = L['Center']},
                    {value = 'RIGHT',       text = L['Right']},
                    {value = 'BOTTOMLEFT',  text = L['BottomLeft']},
                    {value = 'BOTTOM',      text = L['Bottom']},
                    {value = 'BOTTOMRIGHT', text = L['BottomRight']},
                },
            },
        }
    end
    
    local gui = {
        type = 'TabWidget',
        {
            type = 'TabWidget', label = 'Action',
            getGeneral('Action'),
            getStyle('Action'),
            {
                type = 'Widget', label = L['Shine'], depend = 'ActionDefaultEnable',
                {
                    type = 'CheckBox', label = ENABLE, name = 'ActionShineEnable',
                    profile = {self:GetName(), 'class', 'Action', 'shine'}
                },
                {
                    type = 'Slider', label = L['Minimum duration to display shine'], depend = 'ActionShineEnable',
                    minValue = 0, maxValue = 60,
                    profile = {self:GetName(), 'class', 'Action', 'shineMinDuration'},
                },
                {
                    type = 'Slider', label = L['Shine scale'], depend = 'ActionShineEnable',
                    minValue = 2, maxValue = 10, valueStep = 0.2,
                    profile = {self:GetName(), 'class', 'Action', 'shineScale'},
                },
                {
                    type = 'Slider', label = L['Shine duration'], depend = 'ActionShineEnable',
                    minValue = 0.5, maxValue = 5, valueStep = 0.1,
                    profile = {self:GetName(), 'class', 'Action', 'shineDuration'},
                },
                {
                    type = 'Slider', label = L['Shine alpha'], depend = 'ActionShineEnable',
                    minValue = 0.2, maxValue = 1, valueStep = 0.1,
                    profile = {self:GetName(), 'class', 'Action', 'shineAlpha'},
                },
            },
        },
        {
            type = 'TabWidget', label = 'Buff',
            getGeneral('Buff'),
            getStyle('Buff'),
        },
    }
    
    self:InitOption(gui)
end
