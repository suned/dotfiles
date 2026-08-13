function aws-ephemeral --description 'SSO login, load short-term creds into THIS shell, wipe the on-disk token cache'
    set -l profile sandbox
    if set -q argv[1]
        set profile $argv[1]
    end

    aws sso login --profile $profile
    or begin
        echo "aws-ephemeral: sso login failed" >&2
        return 1
    end

    # Capture BEFORE logout; env-no-export gives KEY=VALUE lines fish can parse.
    set -l creds (aws configure export-credentials --profile $profile --format env-no-export)
    or begin
        echo "aws-ephemeral: export-credentials failed" >&2
        return 1
    end
    if test (count $creds) -eq 0
        echo "aws-ephemeral: no credentials returned" >&2
        return 1
    end

    for line in $creds
        # -m1: split on the FIRST '=' only, so '=' padding in the session token survives
        set -l kv (string split -m1 '=' -- $line)
        set -gx $kv[1] $kv[2]
    end

    # export-credentials doesn't emit the region, and we drop AWS_PROFILE below,
    # so pull the profile's region (fallback eu-west-1) into the shell too.
    set -l region (aws configure get region --profile $profile 2>/dev/null)
    test -z "$region"; and set region eu-west-1
    set -gx AWS_REGION $region
    set -gx AWS_DEFAULT_REGION $region

    # ---- Prompt info (display only; the SDK ignores these vars) ----
    # One STS call tells us the principal we ACTUALLY ended up as (works for SSO
    # roles, IAM users, and plain assumed roles alike) and doubles as a
    # creds-work check.
    set -l principal
    set -l arn (aws sts get-caller-identity --query Arn --output text 2>/dev/null)
    if test -n "$arn"
        # arn:partition:service:region:account:RESOURCE
        # RESOURCE = assumed-role/<role>/<session>  (SSO role = AWSReservedSSO_<PermSet>_<16hex>)
        #          or user/<name>
        set -l cf (string split ':' -- $arn)
        set -l rparts (string split '/' -- $cf[6])
        set principal $rparts[2]
        set principal (string replace -r '^AWSReservedSSO_' '' -- $principal)
        set principal (string replace -r '_[0-9a-fA-F]{16}$' '' -- $principal)
    end
    test -z "$principal"; and set principal (aws configure get sso_role_name --profile $profile 2>/dev/null)
    test -z "$principal"; and set principal unknown

    # Classify capability so the prompt can colour it (red = write, green =
    # read-only). Edit the patterns to match your permission-set / role / user
    # naming; anything unmatched stays 'unknown' (yellow) as a look-closer cue.
    set -l cap unknown
    switch $principal
        case '*Admin*' '*PowerUser*' '*FullAccess*' '*Write*' '*Deploy*'
            set cap write
        case '*ReadOnly*' '*View*' '*-ro' 'agent-ro'
            set cap read
    end

    set -gx AWS_EPHEMERAL_INFO "$profile · $principal"
    set -gx AWS_EPHEMERAL_CAP $cap

    set -e AWS_PROFILE          # rely on the env creds, not the now-tokenless profile
    aws sso logout              # clears ~/.aws/sso/cache + ~/.aws/cli/cache

    echo "aws-ephemeral: '$profile' creds loaded into this shell; disk cache wiped (expires $AWS_CREDENTIAL_EXPIRATION)"
end
