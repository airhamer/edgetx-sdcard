local M = {}

M.pages = {

    {
        id = "intro",
        title = "Wing Wizard",
        text = {
            default = {
                "This wizard helps you",
                "set up a flying wing."
            },
            color = {
                "Welcome to the Wing Wizard!",
                "Let's configure your wing."
            }
        },
        image = "wing",
        next = "servo_layout"
    },

    {
        id = "servo_layout",
        title = "Servo Layout",
        text = {
            default = {
                "Choose your servo",
                "configuration."
            }
        },
        options = {"2‑Servo Elevon", "4‑Servo Elevon"},
        image = "servo",
        next = "motor_type"
    },

    {
        id = "motor_type",
        title = "Motor Type",
        text = {
            default = {
                "Select your motor",
                "configuration."
            }
        },
        options = {"Pusher", "None"},
        image = "motor",
        next = "done"
    },

    {
        id = "done",
        title = "Setup Complete",
        text = {
            default = {
                "Your wing model",
                "is now configured."
            }
        },
        image = "check"
    }
}

return M

