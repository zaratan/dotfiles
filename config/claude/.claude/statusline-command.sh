#!/usr/bin/env bash
# Claude Code status line — powerline solarized dark

input=$(cat)

# ==========================================================================
# Solarized Dark palette — https://ethanschoonover.com/solarized/
# ==========================================================================

# Base tones (dark background theme)
SOL_BASE03="0;43;54"          # #002b36  darkest bg
SOL_BASE02="7;54;66"          # #073642  bg highlights
SOL_BASE01="88;110;117"       # #586e75  optional emphasized content
SOL_BASE00="101;123;131"      # #657b83  body text
SOL_BASE0="131;148;150"       # #839496  primary content
SOL_BASE1="147;161;161"       # #93a1a1  secondary content
SOL_BASE2="238;232;213"       # #eee8d5  bg (light theme)
SOL_BASE3="253;246;227"       # #fdf6e3  bg (light theme)

# Accent colors
SOL_YELLOW="181;137;0"        # #b58900
SOL_ORANGE="203;75;22"        # #cb4b16
SOL_RED="220;50;47"           # #dc322f
SOL_MAGENTA="211;54;130"      # #d33682
SOL_VIOLET="108;113;196"      # #6c71c4
SOL_BLUE="38;139;210"         # #268bd2
SOL_CYAN="42;161;152"         # #2aa198
SOL_GREEN="133;153;0"         # #859900

# ==========================================================================
# Glyphs
# ==========================================================================
SEP=$(printf '\xee\x82\xb0')             # U+E0B0 powerline right arrow
BRANCH=$(printf '\xee\x82\xa0')          # U+E0A0 git branch
STAGED="●"
MODIFIED="±"
TIMER="⏱"
ICON_PLUS=$(printf '\xef\x81\x95')       # U+F055 circle-plus
ICON_MINUS=$(printf '\xef\x81\x96')      # U+F056 circle-minus
ICON_FILES=$(printf '\xf3\xb0\xa6\x93')  # U+F0993 files

# ==========================================================================
# Helpers
# ==========================================================================
fg() { printf '\033[38;2;%sm' "$1"; }
bg() { printf '\033[48;2;%sm' "$1"; }
rst=$'\033[0m'

# ==========================================================================
# Data extraction
# ==========================================================================
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
wall_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
api_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
agent=$(echo "$input" | jq -r '.agent.name // empty')

fmt_duration() {
  local ms=$1 secs mins hours days
  secs=$(( ms / 1000 )); mins=$(( secs / 60 )); hours=$(( mins / 60 )); days=$(( hours / 24 ))
  if [ "$days" -gt 0 ]; then printf '%dj %dh' "$days" $(( hours % 24 ))
  elif [ "$hours" -gt 0 ]; then printf '%dh %02dm' "$hours" $(( mins % 60 ))
  elif [ "$mins" -gt 0 ]; then printf '%dm %02ds' "$mins" $(( secs % 60 ))
  else printf '%ds' "$secs"; fi
}

wall_str=$(fmt_duration "$wall_ms")
api_str=$(fmt_duration "$api_ms")

# ==========================================================================
# Git cache (5s TTL)
# ==========================================================================
cwd_hash=$(printf '%s' "$cwd" | md5 -q 2>/dev/null || printf '%s' "$cwd" | md5sum | cut -d' ' -f1)
CACHE_FILE="/tmp/claude-statusline-git-${cwd_hash}"
git_branch="" ; staged=0 ; modified=0 ; diff_added=0 ; diff_removed=0 ; files_changed=0

if [ -n "$cwd" ]; then
  refresh=1
  if [ -f "$CACHE_FILE" ]; then
    now=$(date +%s); mtime=$(date -r "$CACHE_FILE" +%s 2>/dev/null || echo 0)
    [ $(( now - mtime )) -lt 5 ] && refresh=0
  fi
  if [ "$refresh" -eq 0 ]; then
    IFS='|' read -r git_branch staged modified diff_added diff_removed files_changed < "$CACHE_FILE"
  else
    if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
                   || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
      while IFS= read -r line; do
        [[ "${line:0:1}" != " " && "${line:0:1}" != "?" ]] && (( staged++ ))
        [[ "${line:1:1}" != " " && "${line:1:1}" != "?" ]] && (( modified++ ))
      done < <(git -C "$cwd" status --porcelain 2>/dev/null)
      diff_output=$(git -C "$cwd" diff --numstat 2>/dev/null; git -C "$cwd" diff --numstat --cached 2>/dev/null)
      while IFS=$'\t' read -r a r _; do
        [ -z "$a" ] && continue
        [[ "$a" == "-" ]] && continue; diff_added=$(( diff_added + a ))
        [[ "$r" == "-" ]] && continue; diff_removed=$(( diff_removed + r ))
      done <<< "$diff_output"
      while IFS= read -r f; do
        [ -n "$f" ] && diff_added=$(( diff_added + $(wc -l < "$cwd/$f" 2>/dev/null || echo 0) ))
      done < <(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null)
      files_changed=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    fi
    printf '%s|%s|%s|%s|%s|%s' "$git_branch" "$staged" "$modified" "$diff_added" "$diff_removed" "$files_changed" > "$CACHE_FILE"
  fi
fi

# ==========================================================================
# Render powerline
# ==========================================================================
out=""
prev_bg=""

emit_sep() {
  local next_bg=$1
  if [ -n "$prev_bg" ]; then
    out+="$(fg "$prev_bg")$(bg "$next_bg")${SEP}${rst}"
  fi
}

# Seg 1: Git branch — blue bg, dark text
if [ -n "$git_branch" ]; then
  emit_sep "$SOL_BLUE"
  out+="$(bg "$SOL_BLUE")$(fg "$SOL_BASE03") ${BRANCH} ${git_branch}"
  [ "${staged:-0}" -gt 0 ] && out+=" ${STAGED}${staged}"
  [ "${modified:-0}" -gt 0 ] && out+=" ${MODIFIED}${modified}"
  out+=" ${rst}"
  prev_bg=$SOL_BLUE
fi

# Seg 2: Model — cyan bg, dark text
emit_sep "$SOL_CYAN"
out+="$(bg "$SOL_CYAN")$(fg "$SOL_BASE03") ${model} ${rst}"
prev_bg=$SOL_CYAN

# Seg 3: Context — green/yellow/red bg, dark text
if [ "$used_pct" != "null" ] && [ "$used_pct" -gt 0 ] 2>/dev/null; then
  filled=$(( used_pct * 10 / 100 )); [ "$filled" -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  if [ "$used_pct" -ge 90 ]; then ctx_clr=$SOL_RED
  elif [ "$used_pct" -ge 70 ]; then ctx_clr=$SOL_YELLOW
  else ctx_clr=$SOL_GREEN; fi
  emit_sep "$ctx_clr"
  out+="$(bg "$ctx_clr") $(fg "$SOL_BASE01")"
  for (( i=0; i<filled; i++ )); do out+="█"; done
  out+="$(fg "$SOL_BASE02")"
  for (( i=0; i<empty; i++ )); do out+="░"; done
  out+="$(fg "$SOL_BASE03") ${used_pct}% ${rst}"
  prev_bg=$ctx_clr
else
  emit_sep "$SOL_GREEN"
  out+="$(bg "$SOL_GREEN") $(fg "$SOL_BASE02")░░░░░░░░░░ ${rst}"
  prev_bg=$SOL_GREEN
fi

# Seg 4: Diff — violet bg, dark text
emit_sep "$SOL_VIOLET"
out+="$(bg "$SOL_VIOLET")$(fg "$SOL_BASE02") "
[ "${files_changed:-0}" -gt 0 ] && out+="${ICON_FILES} ${files_changed} "
out+="${ICON_PLUS} ${diff_added:-0} ${ICON_MINUS} ${diff_removed:-0} ${rst}"
prev_bg=$SOL_VIOLET

# Seg 5: Agent — orange bg, dark text (conditional)
if [ -n "$agent" ]; then
  emit_sep "$SOL_ORANGE"
  out+="$(bg "$SOL_ORANGE")$(fg "$SOL_BASE03") ${agent} ${rst}"
  prev_bg=$SOL_ORANGE
fi

# Seg 6: Time — base02 bg, base1 text (subdued)
emit_sep "$SOL_BASE02"
out+="$(bg "$SOL_BASE02")$(fg "$SOL_BASE0") ${TIMER} ${wall_str} (api: ${api_str}) ${rst}"
prev_bg=$SOL_BASE02

# Final cap
out+="$(fg "$prev_bg")${SEP}${rst}"

printf '%b\n' "${out}"
