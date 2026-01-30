local M = {}

M.pages = {

    {
        id = "intro",
        title = "Helicopter Wizard",
        text = {
            default = {
                "This wizard helps you",
                "set up a helicopter."
            },
            color = {
                "Welcome to the Helicopter Wizard!",
                "Let's configure your heli."
            }
        },
        image = "heli",
        next = "swash_type"
    },

    {
        id = "swash_type",
        title = "Swashplate Type",
        text = {
            default = {
                "Choose your swash",
                "configuration."
            }
        },
        options = {"120° CCPM", "140° CCPM", "Mechanical"},
        image = "swash",
        next = "tail_type"
    },

    {
        id = "tail_type",
        title = "Tail Type",
        text = {
            default = {
                "Select your tail",
                "configuration."
            }
        },
        options = {"Heading Hold", "Rate Mode"},
        image = "tail",
        next = "done"
    },

    {
        id = "done",
        title = "Setup Complete",
        text = {
            default = {
                "Your helicopter model",
                "is now configured."
            }
        },
        image = "check"
    }
}

return M

