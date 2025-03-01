# Base16 Styling Guidelines:
# base00 - Default Background
# base01 - Lighter Background (Used for status bars)
# base02 - Selection Background
# base03 - Comments, Invisibles, Line Highlighting
# base04 - Dark Foreground (Used for status bars)
# base05 - Default Foreground, Caret, Delimiters, Operators
# base06 - Light Foreground (Not often used)
# base07 - Light Background (Not often used)
# base08 - Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
# base09 - Integers, Boolean, Constants, XML Attributes, Markup Link Url
# base0A - Classes, Markup Bold, Search Text Background
# base0B - Strings, Inherited Class, Markup Code, Diff Inserted
# base0C - Support, Regular Expressions, Escape Characters, Markup Quotes
# base0D - Functions, Methods, Attribute IDs, Headings
# base0E - Keywords, Storage, Selector, Markup Italic, Diff Changed

set -g @base00 "default"   # #000000
set -g @base01 "colour18"  # #282828
set -g @base02 "colour19"  # #383838
set -g @base03 "colour8"   # #585858
set -g @base04 "colour20"  # #B8B8B8
set -g @base05 "colour7"   # #D8D8D8
set -g @base06 "colour21"  # #E8E8E8
set -g @base07 "colour15"  # #F8F8F8
set -g @base08 "colour1"   # #AB4642
set -g @base09 "colour16"  # #DC9656
set -g @base0A "colour3"   # #F7CA88
set -g @base0B "colour2"   # #A1B56C
set -g @base0C "colour6"   # #86C1B9
set -g @base0D "colour4"   # #7CAFC2
set -g @base0E "colour5"   # #BA8BAF
set -g @base0F "colour17"  # #A16946

set -g status-left-length 32
set -g status-right-length 150
set -g status-interval 5

# Default statusbar colors
set-option -g status-fg colour19  # base02
set-option -g status-bg colour18  # base01
set-option -g status-style fg=colour19,bg=colour18

set-window-option -g window-status-style fg=colour20,bg=default  # base04
  # base00
set -g window-status-format " #I #W"

# Active window title colors
set-window-option -g window-status-current-style fg=colour18,bg=colour6  # base01
   # base0C
set-window-option -g window-status-current-format " #[bold,fg=colour18,bg=colour6]#W "

# Pane border colors
set-window-option -g pane-border-style fg=colour8   # base03
set-window-option -g pane-active-border-style fg=colour6  # base0C

# Message text
set-option -g message-style fg=colour6,bg=default  # base00
  # base0C

# Pane number display
set-option -g display-panes-active-colour colour6  # base0C
set-option -g display-panes-colour colour18  # base01

# Clock
set-window-option -g clock-mode-colour colour6  # base0C

# Status components
set -g status-left "#[default,bg=colour5,fg=colour18] #S "  # base0E/base01

tm_tunes="#(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'No Music')"
tm_battery="#(acpi -b | awk '{print $4}' | tr -d ',')"
tm_date="#[default,bg=colour19,fg=colour7] %R"  # base02/base05
tm_host="#[fg=colour18,bg=colour5] #h "  # base01/base0E

set -g status-right "#[bg=colour4,fg=colour18] ♫ $tm_tunes #[fg=colour18,bg=colour16] ♥ $tm_battery $tm_date $tm_host"

# tm_tunes="#[fg=$tm_color_music]#(osascript ~/.dotfiles/applescripts/tunes.scpt | cut -c 1-50)"
# tm_battery="#(~/.dotfiles/bin/battery_indicator.sh)"
