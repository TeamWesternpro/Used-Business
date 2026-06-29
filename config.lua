Config = {}

Config.Debug = true

Config.AdminLicenses = {
    -- Add FiveM license identifiers here for admin access (no prefix)
    -- Example: '123456789abcdef',
    -- Then in server.cfg: add_ace license:123456789abcdef useddealership.admin allow
}

Config.Tablet = {
    Command = 'tablet',
    Keybind = 'F6',
    InteractionKey = 38,
    InteractionDistance = 2.0,
    PromptText = '~b~[E]~s~ Open Tablet'
}

Config.Peds = {
    {
        model = 's_m_m_businessman_01',
        coords = vector4(1156.27, -775.95, 57.55, 27.8),
        blip = {
            enabled = true,
            sprite = 474,
            color = 3,
            scale = 0.8,
            label = 'Used Business'
        }
    },
    {
        model = 's_m_m_businessman_01',
        coords = vector4(122.22, -1085.42, 29.30, 180.0),
        blip = {
            enabled = true,
            sprite = 474,
            color = 3,
            scale = 0.8,
            label = 'Open Tablet'
        }
    },
    {
        model = 's_m_m_businessman_01',
        coords = vector4(-35.77, -1154.80, 26.08, 90.0),
        blip = {
            enabled = true,
            sprite = 474,
            color = 3,
            scale = 0.8,
            label = 'Open Tablet'
        }
    },
    {
        model = 's_m_m_businessman_01',
        coords = vector4(-822.14, -1096.05, 11.42, 160.0),
        blip = {
            enabled = true,
            sprite = 474,
            color = 3,
            scale = 0.8,
            label = 'Open Tablet'
        }
    },
    {
        model = 's_m_m_businessman_01',
        coords = vector4(456.65, -978.55, 30.69, 90.0),
        blip = {
            enabled = true,
            sprite = 474,
            color = 3,
            scale = 0.8,
            label = 'Open Tablet'
        }
    }
}

-- Backward compatibility
Config.Ped = Config.Peds[1]
