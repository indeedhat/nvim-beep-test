# Nvim beep test
Speed training for nvim motions

Mostly this is just a project to learn about making plugins with lua

## What it does
When ran on any buffer it will randomly highlight a symbol in red.\
Once the cursor is over the highlight a new one will be selected

## Installation
Just require the package in your favourite manager and your good to go
```lua
require('packer').startup(function()
    use 'indeedhat/nvim-beep-test'
end)
```

## Usage
Start the plugin\
`:BeepTestStart`

Stop the plugin\
`:BeepTestStop`

## Dependencies
nvim >= 0.5.0\
nvim-treesitter plugin
