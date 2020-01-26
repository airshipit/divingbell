#!/bin/bash

{{/*
# Copyright 2018 AT&T Intellectual Property.  All other rights reserved.
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

set -e

cat <<'EOF' > {{ .Values.conf.chroot_mnt_path | quote }}/tmp/apt.sh
{{ include "divingbell.shcommon" . }}

persist_path='/var/divingbell/apt'
declare -A CURRENT_PACKAGES
declare INSTALLED_THIS_TIME
declare TO_DELETE
declare TO_KEEP
declare REQUESTED_PACKAGES

if [ ! -d "${persist_path}" ]; then
  mkdir -p "${persist_path}"
fi

write_test "${persist_path}"

load_package_list_with_versions(){
    set +x
    for f in "$@"; do
        IFS="=" read -r name version <<< $f;
        IFS=":" read -r name arch <<< $name;
        CURRENT_PACKAGES["$name"]="$version";
    done
    set -x
}

################################################
#Stage 1
#Collect data
################################################

# First 5 lines are field descriptions
load_package_list_with_versions $(dpkg -l | awk 'NR>5 {print $2"="$3}')

################################################
#Stage 2
#Add repositories and install/upgrade packages
################################################

{{- if hasKey .Values.conf "apt" }}
{{- if hasKey .Values.conf.apt "repositories" }}
echo -n "" > /etc/apt/trusted.gpg.d/divindbell_temp.gpg
echo "#The list of repositories managed by Divingbell" > /etc/apt/sources.list.divingbell
  {{- range .Values.conf.apt.repositories }}
    {{- $url := .url }}
    {{- $components := .components | join " " }}
    {{- $subrepos := .subrepos | default list }}
    {{- range .distributions }}
      {{- $distribution := . }}
echo "{{ printf "deb %s %s %s" $url $distribution $components }}" >>/etc/apt/sources.list.divingbell
      {{- if $subrepos }}
        {{- range $subrepos }}
echo "{{ printf "deb %s %s-%s %s" $url $distribution . $components }}" >>/etc/apt/sources.list.divingbell
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if hasKey . "gpgkey" }}
apt-key --keyring /etc/apt/trusted.gpg.d/divindbell_temp.gpg add - <<"ENDKEY"
{{ .gpgkey }}
ENDKEY
    {{- end }}
  {{- end }}
mv /etc/apt/sources.list.divingbell /etc/apt/sources.list
rm -rf /etc/apt/sources.list.d/*
mv /etc/apt/trusted.gpg.d/divindbell_temp.gpg /etc/apt/trusted.gpg.d/divindbell.gpg
rm -f /etc/apt/trusted.gpg
find /etc/apt/trusted.gpg.d/ -type f ! -name 'divindbell.gpg' -exec rm {{ "{}" }} \;
DEBIAN_FRONTEND=noninteractive apt-get update
{{- end }}
{{- if hasKey .Values.conf.apt "packages" }}
DEBIAN_FRONTEND=noninteractive apt-get update

{{/* Build a unified list of packages */}}
{{- $all_apt_packages := list }}
{{- if kindIs "map" .Values.conf.apt.packages }}
{{- range $k, $v := .Values.conf.apt.packages }}
{{- range $v }}
{{- $all_apt_packages = . | append $all_apt_packages }}
{{- end }}
{{- end }}
{{- else }}
{{- $all_apt_packages = .Values.conf.apt.packages }}
{{- end -}}

# Set all debconf selections up front
{{- range $all_apt_packages }}
{{- $pkg_name := .name }}
{{- range .debconf }}
    debconf-set-selections <<< "{{ $pkg_name }} {{ .question }} {{ .question_type }} {{ .answer }}"
{{- end }}
{{- end }}

# Run dpkg in case of interruption of previous dpkg operation
dpkg --configure -a

# Perform package installs
set +x
{{- if .Values.conf.apt.strict }}
{{- range $all_apt_packages }}
{{- $pkg_name := .name }}
INSTALLED_THIS_TIME="$INSTALLED_THIS_TIME {{$pkg_name}} {{- if .version }}={{ .version }}{{ end }}"
REQUESTED_PACKAGES="$REQUESTED_PACKAGES {{$pkg_name}}"
{{- end }}
{{- else }}
{{- range $all_apt_packages }}
{{- $pkg_name := .name }}
if [[ "${CURRENT_PACKAGES[{{ .name | squote }}]+isset}" != "isset"{{- if .version }} || "${CURRENT_PACKAGES[{{ .name | squote }}]}" != {{ .version }}{{- end }} ]]; then
    INSTALLED_THIS_TIME="$INSTALLED_THIS_TIME {{$pkg_name}} {{- if .version }}={{ .version }}{{ end }}"
fi
REQUESTED_PACKAGES="$REQUESTED_PACKAGES {{$pkg_name}}"
{{- end }}
{{- end }}
set -x
# Run this in case some package installation was interrupted
DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold {{- if .Values.conf.apt.allow_downgrade }} "--allow-downgrades" {{ end }}{{- if .repo }} -t {{ .repo }}{{ end }} $INSTALLED_THIS_TIME
{{- end }}

# Perform package upgrades
{{- if .Values.conf.apt.upgrade }}
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get dist-upgrade \
    -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold

if [[ -f "/var/run/reboot-required" ]]; then
  log.INFO 'System reboot REQUIRED.'
fi
{{- end }}
{{- end }}

################################################
#Stage 3
#Remove packages not present in conf.apt anymore
################################################

{{- if .Values.conf.apt.strict }}
# For strict mode, we do not want to use --autoremove, to avoid
# letting apt remove packages outside divingbell's control
APT_PURGE="apt-get purge -y --allow-remove-essential"
{{- else }}
APT_PURGE="apt-get purge -y --autoremove"
{{- end }}

{{- if hasKey .Values.conf.apt "packages" }}
{{- if .Values.conf.apt.strict }}
# in strict mode we execute this stage even on first run, so
# touch the packages file here to avoid the short-circuit below
touch ${persist_path}/packages
{{- end }}

echo $INSTALLED_THIS_TIME | sed 's/ /\n/g' | sed '/^[[:space:]]*$/d' | sort > ${persist_path}/packages.new
echo $REQUESTED_PACKAGES | sed 's/ /\n/g' | sed '/^[[:space:]]*$/d' | sort > ${persist_path}/packages.requested
if [ -f ${persist_path}/packages ]; then
    # if strict mode, we reload the current package list to ensure we have an accurate list to audit from
    # (e.g., in case a package was requested but not installed for some reason)
    # note that in strict mode, $CURRENT_PACKAGES will duplicate the packages in $INSTALLED_THIS_TIME but in
    # non-strict mode (which has logic to use the "packages" file it writes so it doesn't touch anything it
    # didn't originally install) it doesn't.
    {{- if .Values.conf.apt.strict }}
    load_package_list_with_versions $(dpkg -l | awk 'NR>5 {print $2"="$3}')
    {{- end }}
    set +x
    for package in "${!CURRENT_PACKAGES[@]}"
    do
        CURRENT_PACKAGE_NAMES="$CURRENT_PACKAGE_NAMES $package"
    done
    set -x
    echo $CURRENT_PACKAGE_NAMES | sed 's/ /\n/g' | sed '/^[[:space:]]*$/d' | sort > ${persist_path}/packages.current
    {{- if .Values.conf.apt.strict }}
    TO_DELETE=$(comm -23 ${persist_path}/packages.current ${persist_path}/packages.requested)
    TO_KEEP=$(echo "$TO_DELETE" | comm -23 ${persist_path}/packages.current -)
    {{- else }}
    TO_DELETE=$(comm -23 ${persist_path}/packages ${persist_path}/packages.requested)
    TO_KEEP=$(echo "$TO_DELETE" | comm -23 ${persist_path}/packages -)
    {{- end }}
    if [ ! -z "$TO_DELETE" ]; then
        dpkg --configure -a

        {{- if hasKey .Values.conf.apt "whitelistpkgs" }}
        WHITELIST=({{ include "helm-toolkit.utils.joinListWithSpace" .Values.conf.apt.whitelistpkgs }})
        {{- end }}
        PURGE_LIST=""
        while read -r pkg; do
            {{- if hasKey .Values.conf.apt "whitelistpkgs" }}
            found=false
            for item in "${WHITELIST[@]}"; do
                if [[ "${item}" == "${pkg}" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "${found}" == "false" ]]; then
                PURGE_LIST="$PURGE_LIST $pkg"
            fi
            {{- else }}
            PURGE_LIST="$PURGE_LIST $pkg"
            {{- end }}
        done <<< "$TO_DELETE"
        DEBIAN_FRONTEND=noninteractive $APT_PURGE $PURGE_LIST
    fi
    if [ ! -z "$TO_KEEP" ]; then
        echo "$TO_KEEP" > ${persist_path}/packages
    else
        rm ${persist_path}/packages
    fi
fi
if [ ! -z "$INSTALLED_THIS_TIME" ]; then
{{- if not .Values.conf.apt.strict }}
    cat ${persist_path}/packages.new >> ${persist_path}/packages
{{- end }}
    sort ${persist_path}/packages -o ${persist_path}/packages
fi
{{- end }}

######################################################
#Stage 4
#Remove blacklisted packages in conf.apt.blacklistpkgs
######################################################

{{- if hasKey .Values.conf.apt "blacklistpkgs" }}
dpkg --configure -a
{{- range .Values.conf.apt.blacklistpkgs }}
  {{- $package := . }}
  DEBIAN_FRONTEND=noninteractive $APT_PURGE {{ $package | squote }}
{{- end }}
{{- end }}

log.INFO 'Putting the daemon to sleep.'
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/apt.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/apt.sh

while [ 1 ]; do
  sleep 300
done

exit 0
