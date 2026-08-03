function activate-env --description "Create a symlink to a .env file in the current directory"
    if test (count $argv) -ne 1
        echo "Usage: activate-env PATH_TO_ENV_FILE"
        return 1
    end

    set -l env_path $argv[1]

    if not test -e $env_path
        echo "Error: file '$env_path' not found."
        return 1
    end

    if not test -f $env_path
        echo "Error: '$env_path' is not a regular file."
        return 1
    end

    set -l abs_env_path (realpath $env_path 2>/dev/null)

    if test -z "$abs_env_path"
        echo "Error: Unable to resolve path '$env_path'"
        return 1
    end

    ln -sf $abs_env_path .env
    echo ".env now points to $abs_env_path"
end

complete -c activate-env --no-files -a '(find . -maxdepth 1 -type f -name ".env.*" | string replace -r '^./' "")'
