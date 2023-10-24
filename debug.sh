# Source (or "dot") the .env file to load environment variables
if [ -f .env ]; then
    source .debug.env
else
    echo "Error: .debug.env file not found."
fi

verify_arg=""
extra_argument=""
op_command=""

for arg in "$@"; do
    case $arg in
    --trezor)
        op_command=""
        extra_argument+=trezor@
        ;;
    --broadcast)
        op_command="op run --env-file="./.env" --"
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

echo Debug Tx...
echo From: ${FROM}
echo To: ${TO}
echo Value: ${VALUE}
echo Calldata:
cast pretty-calldata ${CALLDATA}
calldata=$(cast calldata 'debug(uint256,address,address,uint256,bytes)', ${BLOCK} ${FROM} ${TO} ${VALUE} ${CALLDATA})
${op_command} forge script ${verify_arg} --legacy ${@} script/Debug.s.sol --sig 'run(bytes,string)' ${calldata} "${extra_argument}"
