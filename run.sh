verify_arg=""
extra_argument=""
op_command="op run --env-file="./.env" --"

for arg in "$@"; do
    case $arg in
    --trezor)
        op_command=""
        extra_argument+=trezor@
        ;;
    --broadcast)
        op_command="op run --env-file="./.env" --"
        # verify_arg="--verify --verifier sourcify --verifier-url https://sourcify.roninchain.com/server/"
        ;;
    --log)
        set -- "${@/#--log/}"
        extra_argument+=log@
        ;;
    *) ;;
    esac
done

# Remove the @ character from the end of extra_argument
extra_argument="${extra_argument%%@}"

calldata=$(cast calldata 'run()')
${op_command} forge script ${verify_arg} --legacy ${@} --sig 'run(bytes,string)' ${calldata} "${extra_argument}"
