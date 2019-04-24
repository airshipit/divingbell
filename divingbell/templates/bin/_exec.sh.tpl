#!/bin/bash

{{/*
# Copyright 2017 AT&T Intellectual Property.  All other rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
*/}}

{{- $exec_loop_sleep_interval := 60 }}

set -e

cat <<'UNIQUE_EOF_9c341059-25a0-4725-9489-1789e255e381' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/exec_host_{{ .Chart.Version }}.sh
{{ include "divingbell.shcommon" . }}

exec_path='/var/divingbell/exec'

if [ ! -d "${exec_path}" ]; then
  mkdir -p "${exec_path}"
fi

write_test "${exec_path}"
cd "${exec_path}"

{{- if hasKey .Values.conf "exec" }}
  {{- $sorted_keys := keys $.Values.conf.exec | sortAlpha }}

  {{- range $index, $script := $sorted_keys }}
    {{- $keypath := index $.Values.conf.exec $script }}

    {{/* Need to sort key/values before assessing hash, since helm only preserves order for lists */}}
    {{- $_ := set $.Values "__values_hash" list }}
    {{- range $i, $k := ($keypath | keys | sortAlpha) }}
      {{/* env is the only nested dict, so the same operation needs to be repeated there lacking helm recursion */}}
      {{- if eq $k "env" }}
        {{- range $i2, $k2 := ($keypath.env | keys | sortAlpha) }}
          {{- $_ := set $.Values "__values_hash" (append $.Values.__values_hash (print $.Values.__values_hash ";" ($k | toString) ":" ($k2 | toString) ":" (index $keypath.env $k2 | toString))) }}
        {{- end }}
      {{- else }}
        {{- $_ := set $.Values "__values_hash" (append $.Values.__values_hash (print $.Values.__values_hash ";" ($k | toString) ":" (index $keypath $k | toString))) }}
      {{- end }}
    {{- end }}
    {{- $hash := $.Values.__values_hash | toString | sha256sum }}

    hash={{ $hash | squote }}
    if [ ! -d "${hash}" ]; then
      mkdir -p "${hash}"
    fi

    {{- $_ := set $.Values "__rerun_policy" "always" }}
    {{- if hasKey $keypath "rerun_policy" }}
      {{- if and (not (eq $keypath.rerun_policy "always")) (not (eq $keypath.rerun_policy "never")) (not (eq $keypath.rerun_policy "once_successfully")) }}
        {{- fail (print "BAD 'rerun_policy' FOR '" $script "': Got '" $keypath.rerun_policy "', but expected 'always', 'never', or 'once_successfully'.") }}
      {{- end }}
      {{- $_ := set $.Values "__rerun_policy" $keypath.rerun_policy }}
    {{- end }}

    {{- $_ := set $.Values "__blocking_policy" "foreground" }}
    {{- if hasKey $keypath "blocking_policy" }}
      {{- if and (not (eq $keypath.blocking_policy "foreground")) (not (eq $keypath.blocking_policy "background")) (not (eq $keypath.blocking_policy "foreground_halt_pod_on_failure")) }}
        {{- fail (print "BAD 'blocking_policy' FOR '" $script "': Got '" $keypath.blocking_policy "', but expected 'foreground', 'background', or 'foreground_halt_pod_on_failure'.") }}
      {{- end }}
      {{- if eq $keypath.blocking_policy "background" }}
        {{- fail (print "NOT IMPLEMENTED: 'blocking_policy' FOR '" $script "'") }}
      {{- end }}
      {{- $_ := set $.Values "__blocking_policy" $keypath.blocking_policy }}
    {{- end }}

    {{- $_ := set $.Values "__timeout" 1800 }}
    {{- if hasKey $keypath "timeout" }}
      {{- if eq ($keypath.timeout | toString) "infinite" }}
        {{- fail (print "BAD 'timeout' FOR '" $script "': 'infinite' timeouts not supported.") }}
      {{- end }}
      {{- $_ := set $.Values "__timeout" $keypath.timeout }}
    {{- end }}

    {{- $_ := set $.Values "__rerun_interval" "infinite" }}
    {{- if hasKey $keypath "rerun_interval" }}
      {{- if not (eq ($keypath.rerun_interval | toString) "infinity") }}
        {{- if lt ($keypath.rerun_interval | int) $exec_loop_sleep_interval }}
          {{- fail (print "BAD 'rerun_interval' FOR '" $script "': Got '" $keypath.rerun_interval "', but expected >= '" $exec_loop_sleep_interval "'.") }}
        {{- end }}
        {{- if not (eq $.Values.__rerun_policy "always") }}
          {{- fail (print "BAD COMBINATION: Must use 'rerun_policy' of 'always' when defining a finite 'rerun_interval'. Got 'rerun_policy' of '" $.Values.__rerun_policy "' and 'rerun_interval' of '" $keypath.rerun_interval "' for '" $script "'.") }}
        {{- end }}
      {{- end }}
      {{- $_ := set $.Values "__rerun_interval" $keypath.rerun_interval }}
    {{- end }}

    {{- $_ := set $.Values "__rerun_interval_persist" "true" }}
    {{- if hasKey $keypath "rerun_interval_persist" }}
      {{- fail (print "NOT IMPLEMENTED: 'rerun_interval_persist' FOR '" $script "'") }}
      {{- $_ := set $.Values "__rerun_interval_persist" $keypath.rerun_interval_persist }}
    {{- end }}

    {{- $_ := set $.Values "__rerun_max_count" "infinite" }}
    {{- if hasKey $keypath "rerun_max_count" }}
      {{- fail (print "NOT IMPLEMENTED: 'rerun_max_count' FOR '" $script "'") }}
      {{- $_ := set $.Values "__rerun_max_count" $keypath.rerun_max_count }}
    {{- end }}

    {{- $_ := set $.Values "__retry_interval" (print $.Values.__rerun_interval) }}
    {{- if hasKey $keypath "retry_interval" }}
      {{- if not (eq ($keypath.retry_interval | toString) "infinity") }}
        {{- if lt ($keypath.retry_interval | int) $exec_loop_sleep_interval }}
          {{- fail (print "BAD 'retry_interval' FOR '" $script "': Got '" $keypath.retry_interval "', but expected >= '" $exec_loop_sleep_interval "'.") }}
        {{- end }}
        {{- if and (not (eq $.Values.__rerun_policy "always")) (not (eq $.Values.__rerun_policy "once_successfully")) }}
          {{- fail (print "BAD COMBINATION: Must use 'rerun_policy' of 'always' or 'once_successfully' when defining a finite 'retry_interval'. Got 'rerun_policy' of '" $.Values.__rerun_policy "' and 'retry_interval' of '" $keypath.retry_interval "' for '" $script "'.") }}
        {{- end }}
      {{- end }}
      {{- $_ := set $.Values "__retry_interval" $keypath.retry_interval }}
    {{- end }}

    {{- $_ := set $.Values "__retry_interval_persist" "true" }}
    {{- if hasKey $keypath "retry_interval_persist" }}
      {{- fail (print "NOT IMPLEMENTED: 'retry_interval_persist' FOR '" $script "'") }}
      {{- $_ := set $.Values "__retry_interval_persist" $keypath.retry_interval_persist }}
    {{- end }}

    {{- $_ := set $.Values "__retry_max_count" "infinite" }}
    {{- if hasKey $keypath "retry_max_count" }}
      {{- fail (print "NOT IMPLEMENTED: 'retry_max_count' FOR '" $script "'") }}
      {{- $_ := set $.Values "__retry_max_count" $keypath.retry_max_count }}
    {{- end }}

    cat <<'UNIQUE_EOF_1840dbd4-09e1-4725-87f5-3b6944b80526' > {{ $script }}
{{ $keypath.data }}
UNIQUE_EOF_1840dbd4-09e1-4725-87f5-3b6944b80526
    chmod 700 {{ $script }}
    # check rerun policy
    hash_check=fail
    if  [[ {{ $.Values.__rerun_policy }} = always ]] || \
        [[ ! -f ${hash}/exit_code ]] || \
       ([[ {{ $.Values.__rerun_policy }} = once_successfully ]] && \
        [[ $(cat ${hash}/exit_code) != 0 ]]); then
      hash_check=pass
    fi
    # check rerun/retry interval
    interval_check=fail
    if  [[ ! -f ${hash}/last_run_timestamp ]] || [[ ! -f ${hash}/exit_code ]]; then
      interval_check=pass
    elif [[ $(cat ${hash}/exit_code) = 0 ]]; then
      if [[ {{ $.Values.__rerun_interval }} = infinite ]]; then
        interval_check=pass
      elif [[ $(date +"%s") -ge $(($(cat ${hash}/last_run_timestamp) + {{ $.Values.__rerun_interval }})) ]]; then
        interval_check=pass
      fi
    elif [[ $(cat ${hash}/exit_code) != 0 ]]; then
      if [[ {{ $.Values.__retry_interval }} = infinite ]]; then
        interval_check=pass
      elif [[ $(date +"%s") -ge $(($(cat ${hash}/last_run_timestamp) + {{ $.Values.__retry_interval }})) ]]; then
        interval_check=pass
      fi
    fi
    if [[ $hash_check = pass ]] && [[ $interval_check = pass ]]; then
      if [[ -f ${hash}/exit_code ]]; then
        # remove previous run record, in case this run is interrupted
        rm ${hash}/exit_code
      fi
      # write timestamp at beginning of execution
      echo $(date +"%s") > "${hash}/last_run_timestamp"
      {{- if hasKey $keypath "env" }}
        {{- range $env_key, $env_val := $keypath.env }}
          {{ $env_key }}={{ $env_val | squote }} \
        {{- end }}
      {{- end }}
      ./{{ $script | squote }} \
      {{- if hasKey $keypath "args" }}
        {{- range $arg := $keypath.args }}
          {{ $arg | squote }} \
        {{- end }}
      {{- end }}
      &
      pid=$!
      time_waited=0
      sleep_interval=5
      timeout={{ $.Values.__timeout }}
      while true; do
        if [[ $time_waited -ge $timeout ]]; then
          log.ERROR "Hit '$timeout' second timeout waiting for '{{ $script }}' - terminating."
          # ask nicely first
          kill $pid
          sleep 10
          # force kill if still running
          ps $pid > /dev/null && kill -9 $pid
          break
        fi
        ps $pid > /dev/null || break
        sleep $sleep_interval
        time_waited=$(($time_waited + $sleep_interval))
      done
      wait $pid && echo 0 > "${hash}/exit_code" || echo $? > "${hash}/exit_code"
      {{- if hasKey $keypath "blocking_policy" }}
        {{- if eq $keypath.blocking_policy "foreground_halt_pod_on_failure" }}
          if [[ $(cat "${hash}/exit_code") != '0' ]]; then
            die "Killing pod due to non-zero exit code from '{{ $script }}'."
          fi
        {{- end }}
      {{- end }}
    fi
  {{- end }}
{{- end }}
log.INFO 'Putting the daemon to sleep for {{ $exec_loop_sleep_interval }} seconds.'
UNIQUE_EOF_9c341059-25a0-4725-9489-1789e255e381

chmod 700 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/exec_host_{{ .Chart.Version }}.sh

while true; do
  nsenter -t 1 -m -u -n -i -p /tmp/exec_host_{{ .Chart.Version }}.sh
  sleep {{ $exec_loop_sleep_interval }}
done
