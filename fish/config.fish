
# devbox shellenv broken for fish in version 0.17.8
# workaround: default shell is zsh. hook executed there
# before fish is started.
# if command -q devbox
#     devbox global shellenv --init-hook | source
# end

if command -q devbox
    devbox completion fish | source
end


if type -q aws_completer
	function __aws_completer
		set -lx COMP_LINE (commandline -pc)
		set -lx COMP_POINT (string length $COMP_LINE)
		aws_completer | tr -d ' '
	end

	complete -c aws -f -a "(__aws_completer)"
end

if command -q direnv
    direnv hook fish | source
end


if command -q starship
    starship init fish | source
end

set -x DIRENV_LOG_FORMAT ""

if command -q zed
    set -x GIT_EDITOR "zed --wait"
end


if status is-interactive
    abbr gst "git status"
    abbr ga "git add"
    abbr gaa "git add -A"
    abbr gcm "git commit -m"
    abbr gp "git push"
    abbr gco "git checkout"
    abbr gpu "git push --set-upstream origin (git branch --show-current)"
    abbr gd "git diff"
    abbr gl "git log"
    abbr ap "aws-profile"
    abbr asl "aws sso login"

    abbr pm "python -m"
    abbr pt "pytest"
    abbr pts "pytest -s"
    abbr ptlf "pytest --lf"
    abbr ptd "pytest --pdb --pdbcls=pdbr:RichPdb"
    abbr ip "ipython"

    abbr cr "cargo run"
    abbr cb "cargo build"

    abbr z "zed"
    abbr ae "activate-env"
    abbr db "devbox"
    abbr --set-cursor zn "~/zeronorth/%"

    if command -q eza
        alias ls "eza --icons -F -H --git --group-directories-first"
    end

    alias cage "~/cage/cage"
end
