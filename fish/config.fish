if command -q direnv
    direnv hook fish | source
end

if command -q starship
    starship init fish | source
end


set -x DIRENV_LOG_FORMAT ""
set -x DEVELOPER_DIR "~/.nix-profile/"


if status is-interactive
    abbr gst "git status"
    abbr ga "git add"
    abbr gaa = "git add -A"
    abbr gcm "git commit -m"
    abbr gp "git push"
    abbr gco "git checkout"
    abbr gpu "git push --set-upstream origin (git branch --show-current)"
    abbr gd "git diff"
    abbr gl "git log"
    abbr ap "aws-profile"
    abbr asl "aws sso login"

    if command -q eza
        alias ls "eza --icons -F -H --git --group-directories-first"
    end
end
