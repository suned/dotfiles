function activate-env --description "Create a symlink to a .env file in the current directory"
    if test (count $argv) -ne 1
        echo "Usage: useenv PATH_TO_ENV_FILE"
        return 1
    end

    ln -sf (realpath $argv[1]) .env
    echo ".env now points to $argv[1]"
end
