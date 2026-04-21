# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$HOME/.npm-global/bin:$PATH"

# opencode
export PATH=/home/yegor/.opencode/bin:$PATH

# Ctrl+Backspace — delete whole word
bindkey '^H' backward-kill-word
export LANG=en_GB.UTF-8
export LC_ALL=en_GB.UTF-8

export HF_TOKEN="PLACEHOLDER"
export CONTEXT7_API_KEY="PLACEHOLDER"

# Claw Code (Rust) with OpenRouter
export OPENAI_API_KEY="PLACEHOLDER"
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="nvidia/nemotron-3-super-120b-a12b:free"

alias claw="/home/yegor/claw-code/rust/target/debug/claw --model openai/$OPENAI_MODEL"

export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/home/yegor/.bun/_bun" ] && source "/home/yegor/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# VPN v2rayA Toggle Commands
alias pon="export http_proxy=http://127.0.0.1:20171 https_proxy=http://127.0.0.1:20171 all_proxy=socks5://127.0.0.1:20170 && echo \"Proxy ON\""
alias poff="unset http_proxy https_proxy all_proxy && echo \"Proxy OFF\""

export NVIDIA_API_KEY="PLACEHOLDER"
