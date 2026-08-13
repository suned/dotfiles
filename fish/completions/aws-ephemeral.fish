set profiles (cat ~/.aws/config | string match -r '\[profile .*\]' | string replace -r '\[profile (.*)\]' '$1' | string join ' ')
complete -c aws-ephemeral -f -a $profiles
