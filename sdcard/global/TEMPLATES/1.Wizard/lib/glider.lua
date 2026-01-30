local M = {}

M.pages = {

    {
        id = "intro",
        title = "Glider Wizard",
        text = {
            default = {
                "This wizard helps you",
                "set up a glider model."
            },
            color = {
                "Welcome to the Glider Wizard!",
                "Let's configure your sailplane."
            }
        },
        image = "glider",
        next = "wing_type"
    },

    {
        id = "wing_type",
        title = "Wing Type",
        text = {
            default = {
                "Choose your wing",
                "configuration."
            }
        },
        options = {"2‑Servo", "4‑Servo", "Flaperon"},
        image = "wing",
        next = "launch_mode"
    },

    {
        id = "launch_mode",
        title = "Launch Mode",
        text = {
            default = {
                "Select your launch",
                "method."
            }
        },
        options = {"Hand Launch", "Winch", "Motor Assist"},
        image = "launch",
        next = "done"
    },

    {
        id = "done",
        title = "Setup Complete",
        text = {
            default = {
                "Your glider model",
                "is now configured."
            }
        },
        image = "check"
    }
}

return M

