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
#Add repositories and install new packages
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
apt-get update
{{- end }}
{{- if hasKey .Values.conf.apt "packages" }}
apt-get update

# Set all debconf selections up front
{{- range .Values.conf.apt.packages }}
{{- $pkg_name := .name }}
{{- range .debconf }}
    debconf-set-selections <<< "{{ $pkg_name }} {{ .question }} {{ .question_type }} {{ .answer }}"
{{- end }}
{{- end }}

# Run dpkg in case of interruption of previous dpkg operation
dpkg --configure -a

# Perform package installs
{{- range .Values.conf.apt.packages }}
{{- $pkg_name := .name }}
if [[ "${CURRENT_PACKAGES[{{ .name | squote }}]+isset}" != "isset"{{- if .version }} || "${CURRENT_PACKAGES[{{ .name | squote }}]}" != {{ .version }}{{- end }} ]]; then
    # Run this in case some package installation was interrupted
    DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold{{- if .repo }} -t {{ .repo }}{{ end }} {{ .name -}} {{- if .version }}={{ .version }}{{ end }}
    INSTALLED_THIS_TIME="$INSTALLED_THIS_TIME {{ .name }}"
fi
REQUESTED_PACKAGES="$REQUESTED_PACKAGES {{ .name }}"
{{- end }}
{{- end }}
{{- end }}

################################################
#Stage 3
#Remove packages not present in conf.apt anymore
################################################

echo $INSTALLED_THIS_TIME | sed 's/ /\n/g' | sed '/^[[:space:]]*$/d' | sort > ${persist_path}/packages.new
echo $REQUESTED_PACKAGES | sed 's/ /\n/g' | sed '/^[[:space:]]*$/d' | sort > ${persist_path}/packages.requested
if [ -f ${persist_path}/packages ]; then
    TO_DELETE=$(comm -23 ${persist_path}/packages ${persist_path}/packages.requested)
    TO_KEEP=$(echo "$TO_DELETE" | comm -23 ${persist_path}/packages -)
    if [ ! -z "$TO_DELETE" ]; then
        dpkg --configure -a
        for pkg in "$TO_DELETE"; do
            apt-get purge -y $pkg
        done
        apt-get autoremove -y
    fi
    if [ ! -z "$TO_KEEP" ]; then
        echo "$TO_KEEP" > ${persist_path}/packages
    else
        rm ${persist_path}/packages
    fi
fi
if [ ! -z "$INSTALLED_THIS_TIME" ]; then
    cat ${persist_path}/packages.new >> ${persist_path}/packages
    sort ${persist_path}/packages -o ${persist_path}/packages
fi

######################################################
#Stage 4
#Remove blacklisted packages in conf.apt.blacklistpkgs
######################################################

{{- if hasKey .Values.conf.apt "blacklistpkgs" }}
dpkg --configure -a
{{- range .Values.conf.apt.blacklistpkgs }}
  {{- $package := . }}
  apt-get remove --autoremove -y {{ $package | squote }}
{{- end }}
apt-get autoremove -y
{{- end }}

log.INFO 'Putting the daemon to sleep.'
EOF

chmod 755 {{ .Values.conf.chroot_mnt_path | quote }}/tmp/apt.sh
chroot {{ .Values.conf.chroot_mnt_path | quote }} /tmp/apt.sh

while [ 1 ]; do
  sleep 300
done

exit 0
