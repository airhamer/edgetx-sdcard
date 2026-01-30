local M = {}

M.pages = {

    {
        id = "intro",
        title = "Plane Wizard",
        text = {
            default = {
                "This wizard helps you",
                "set up a plane model."
            },
            color = {
                "Welcome to the Plane Wizard!",
                "Let's configure your aircraft."
            }
        },
        image = "plane",
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
        options = {"Normal", "V‑Tail", "A‑Tail"},
        image = "wing",
        next = "engine_type"
    },

    {
        id = "engine_type",
        title = "Engine Type",
        text = {
            default = {
                "Select your power",
                "system type."
            }
        },
        options = {"Electric", "Gas", "None"},
        image = "engine",
        next = "done"
    },

    {
        id = "done",
        title = "Setup Complete",
        text = {
            default = {
                "Your plane model",
                "is now configured."
            }
        },
        image = "check"
    }
}

return M
