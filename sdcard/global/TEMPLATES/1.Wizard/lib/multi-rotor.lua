local M = {}

M.pages = {

    {
        id = "intro",
        title = "Multirotor Wizard",
        text = {
            default = {
                "This wizard helps you",
                "set up a multirotor."
            },
            color = {
                "Welcome to the Multirotor Wizard!",
                "Let's get started."
            }
        },
        image = "multirotor",
        next = "motor_layout"
    },

    {
        id = "motor_layout",
        title = "Motor Layout",
        text = {
            default = {
                "Choose your motor",
                "configuration."
            }
        },
        options = {"Quad X", "Quad +", "Hexa", "Octo"},
        image = "motor",
        next = "receiver_type"
    },

    {
        id = "receiver_type",
        title = "Receiver Type",
        text = {
            default = {
                "Select your receiver",
                "protocol."
            }
        },
        options = {"SBUS", "CRSF", "ELRS"},
        image = "receiver",
        next = "done"
    },

    {
        id = "done",
        title = "Setup Complete",
        text = {
            default = {
                "Your multirotor model",
                "is now configured."
            }
        },
        image = "check"
    }
}

return M

