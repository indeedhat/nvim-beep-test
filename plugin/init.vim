if exists('g:loaded_nvim_beep_test')
  finish
endif

let g:loaded_nvim_beep_test = 1

command! -nargs=0 BeepTestStart luado require'nvim-beep-test'.start()
command! -nargs=0 BeepTestStop luado require'nvim-beep-test'.start()
