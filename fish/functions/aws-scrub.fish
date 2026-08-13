function aws-scrub --description 'Drop AWS creds from this shell and wipe the on-disk token cache'
    set -e AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_CREDENTIAL_EXPIRATION AWS_REGION AWS_DEFAULT_REGION AWS_PROFILE AWS_EPHEMERAL_INFO AWS_EPHEMERAL_CAP
    aws sso logout 2>/dev/null
    echo "aws-scrub: creds cleared"
end
