{{- define "divingbell.shcommon" -}}
#!/bin/bash

set -o errtrace
set -o pipefail

declare -Ax __log_types=(
{{- if .Values.conf.log_colors }}
  [ERROR]='fd=2, color=\e[01;31m'
  [TRACE]='fd=2, color=\e[01;31m'
  [WARN]='fd=1, color=\e[01;93m'
  [INFO]='fd=1, color=\e[01;37m'
  [DEBUG]='fd=1, color=\e[01;90m'
{{- else }}
  [ERROR]='fd=2,'
  [TRACE]='fd=2,'
  [WARN]='fd=1,'
  [INFO]='fd=1,'
  [DEBUG]='fd=1,'
{{- end }}
)
for __log_type in "${!__log_types[@]}"; do
  alias log.${__log_type}="echo ${__log_type}"
done
shopt -s expand_aliases

__text_formatter(){
  local log_prefix='None'
  local default_log_type='INFO'
  local default_xtrace_type='DEBUG'
  local log_type
  local color_prefix
  local fd
  for log_type in "${!__log_types[@]}"; do
    if [[ ${1} == ${log_type}* ]]; then
      log_prefix=''
      color_prefix="$(echo ${__log_types["${log_type}"]} |
                      cut -d',' -f2 | cut -d'=' -f2)"
      fd="$(echo ${__log_types["${log_type}"]} |
            cut -d',' -f1 | cut -d'=' -f2)"
      break
    fi
  done
  if [ "${log_prefix}" = "None" ]; then
    # xtrace output usually begins with "+" or "'", mark as debug
    if [[ ${1} = '+'* ]] || [[ ${1} = \'* ]]; then
      log_prefix="${default_xtrace_type} "
      log_type="${default_xtrace_type}"
    else
      log_prefix="${default_log_type} "
      log_type="${default_log_type}"
    fi
    color_prefix="$(echo ${__log_types["${log_type}"]} |
                    cut -d',' -f2 | cut -d'=' -f2)"
    fd="$(echo ${__log_types["${log_type}"]} |
          cut -d',' -f1 | cut -d'=' -f2)"
  fi
  local color_suffix=''
  if [ -n "${color_prefix}" ]; then
    color_suffix='\e[0m'
  fi
  timestamp=$(date "+%m-%d-%y %H:%M:%S")
  echo -e "${color_prefix}${timestamp} ${log_prefix}${1}${color_suffix}" >&${fd}
}
# Due to this unresolved issue: http://bit.ly/2xPmOY9 we choose preservation of
# message ordering at the expense of applying appropriate tags to stderr. As a
# result, stderr from subprocesses will still display as INFO level messages.
# However we can still log ERROR messages using the aliased log handlers.
exec >& >(while read line; do
            if [ "${line}" = '__EXIT_MARKER__' ]; then
              break
            else
              __text_formatter "${line}"
            fi
          done)

die(){
  set +x
  # write to stderr any passed error message
  if [[ $@ = *[!\ ]* ]]; then
    log.ERROR "$@"
  fi
  log.TRACE "Backtrace:"
  for ((i=0;i<${#FUNCNAME[@]}-1;i++)); do
    log.TRACE $(caller $i)
  done
  echo __EXIT_MARKER__
  # Exit after pipe closes to ensure all output is flushed first
  while : ; do
    echo "Waiting on exit..." || exit 1
  done
}
export -f die
trap 'die' ERR
set -x

write_test(){
  touch "${1}/__write_test" &&
    rm "${1}/__write_test" ||
    die "Write test to ${1} failed."
}

die_if_null(){
  local var="${1}"
  shift
  [ -n "${var}" ] || die "Null variable exception $@"
}

###############################################################################
{{- end -}}
