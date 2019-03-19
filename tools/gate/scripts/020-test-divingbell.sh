#!/bin/bash

# TODO: Convert to use new/common gate scripts when available

set -e

NAME=divingbell
: ${LOGS_DIR:=/var/log}
: ${LOGS_SUBDIR:=${LOGS_DIR}/${NAME}/$(date +"%m-%d-%y_%H:%M:%S")}
mkdir -p "${LOGS_SUBDIR}"
LOG_NAME="${LOGS_SUBDIR}/test.log"
TEST_RESULTS="${LOGS_SUBDIR}/results.log"
BASE_VALS="--values=divingbell/values.yaml"
SYSCTL_KEY1=net.ipv4.conf.all.log_martians
SYSCTL_VAL1_DEFAULT=1
SYSCTL_KEY2=net.ipv4.conf.all.secure_redirects
SYSCTL_VAL2_DEFAULT=1
SYSCTL_KEY3=net.ipv4.conf.all.accept_redirects
SYSCTL_VAL3_DEFAULT=0
SYSCTL_KEY4=net/ipv6/conf/all/accept_redirects
SYSCTL_VAL4_DEFAULT=0
MOUNTS_SYSTEMD=/${NAME}
MOUNTS_PATH1=${MOUNTS_SYSTEMD}1
MOUNTS_PATH2=${MOUNTS_SYSTEMD}2
MOUNTS_PATH3=${MOUNTS_SYSTEMD}3
ETHTOOL_KEY2=tx-tcp-segmentation
ETHTOOL_VAL2_DEFAULT=on
ETHTOOL_KEY3=tx-tcp6-segmentation
# Not all NIC hardware has enough ethtool tunables available
ETHTOOL_KEY3_BACKUP=''
ETHTOOL_VAL3_DEFAULT=on
ETHTOOL_KEY4=tx-nocache-copy
ETHTOOL_VAL4_DEFAULT=off
ETHTOOL_KEY5=tx-checksum-ip-generic
ETHTOOL_KEY5_BACKUP=tx-scatter-gather
ETHTOOL_VAL5_DEFAULT=on
USERNAME1=userone
USERNAME1_SUDO=true
USERNAME1_SSHKEY1="ssh-rsa abc123 comment"
USERNAME2=usertwo
USERNAME2_SUDO=false
USERNAME2_SSHKEY1="ssh-rsa xyz456 comment"
USERNAME2_SSHKEY2="ssh-rsa qwe789 comment"
USERNAME2_SSHKEY3="ssh-rsa rfv000 comment"
USERNAME2_CRYPT_PASSWD='$6$AF.NLpphOJjMVTYC$GD6wyUTy9vIgatoMbtTDYcVtEJqh/Mrx3BRetVstMsNodSyn3ZFIZOMRePpRpGbFArnAxgkL1PtQxsZHCgtFn/'
USERNAME3=userthree
USERNAME3_SUDO=true
USERNAME4=userfour
USERNAME4_SUDO=false
APT_PACKAGE1=python-pbr
APT_VERSION1=1.8.0-4ubuntu1
APT_PACKAGE2=mysql-server
APT_PACKAGE3=python-simplejson
APT_VERSION3=3.8.1-1ubuntu2
APT_PACKAGE4=less
APT_PACKAGE5=python-setuptools
APT_PACKAGE6=telnetd
APT_REPOSITORY1="http://us.archive.ubuntu.com/ubuntu/"
APT_DISTRIBUTIONS1="[ xenial ]"
APT_COMPONENTS1="[ main, universe, restricted, multiverse ]"
APT_SUBREPOS1="[ backports, updates ]"
APT_GPGKEYID1="437D05B5"
APT_GPGKEY1="-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

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
Twx6DKLF+3rF5nf1F3Q=
=PBAe
-----END PGP PUBLIC KEY BLOCK-----"
APT_REPOSITORY2="http://security.ubuntu.com/ubuntu/"
APT_DISTRIBUTIONS2="[ xenial ]"
APT_COMPONENTS2="[ main, universe, restricted, multiverse ]"
APT_SUBREPOS2="[ security ]"
APT_GPGKEYID2="C0B21F32"
APT_GPGKEY2="-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

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
DjfegedFClqpn37b
=rDTH
-----END PGP PUBLIC KEY BLOCK-----"
APT_REPOSITORY3="https://download.ceph.com/debian-mimic/"
APT_DISTRIBUTIONS3="[ xenial ]"
APT_COMPONENTS3="[ main ]"
APT_GPGKEYID3="460F3994"
APT_GPGKEY3="-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQINBFX4hgkBEADLqn6O+UFp+ZuwccNldwvh5PzEwKUPlXKPLjQfXlQRig1flpCH
E0HJ5wgGlCtYd3Ol9f9+qU24kDNzfbs5bud58BeE7zFaZ4s0JMOMuVm7p8JhsvkU
C/Lo/7NFh25e4kgJpjvnwua7c2YrA44ggRb1QT19ueOZLK5wCQ1mR+0GdrcHRCLr
7Sdw1d7aLxMT+5nvqfzsmbDullsWOD6RnMdcqhOxZZvpay8OeuK+yb8FVQ4sOIzB
FiNi5cNOFFHg+8dZQoDrK3BpwNxYdGHsYIwU9u6DWWqXybBnB9jd2pve9PlzQUbO
eHEa4Z+jPqxY829f4ldaql7ig8e6BaInTfs2wPnHJ+606g2UH86QUmrVAjVzlLCm
nqoGymoAPGA4ObHu9X3kO8viMBId9FzooVqR8a9En7ZE0Dm9O7puzXR7A1f5sHoz
JdYHnr32I+B8iOixhDUtxIY4GA8biGATNaPd8XR2Ca1hPuZRVuIiGG9HDqUEtXhV
fY5qjTjaThIVKtYgEkWMT+Wet3DPPiWT3ftNOE907e6EWEBCHgsEuuZnAbku1GgD
LBH4/a/yo9bNvGZKRaTUM/1TXhM5XgVKjd07B4cChgKypAVHvef3HKfCG2U/DkyA
LjteHt/V807MtSlQyYaXUTGtDCrQPSlMK5TjmqUnDwy6Qdq8dtWN3DtBWQARAQAB
tCpDZXBoLmNvbSAocmVsZWFzZSBrZXkpIDxzZWN1cml0eUBjZXBoLmNvbT6JAjgE
EwECACIFAlX4hgkCGwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEOhKwsBG
DzmUXdIQAI8YPcZMBWdv489q8CzxlfRIRZ3Gv/G/8CH+EOExcmkVZ89mVHngCdAP
DOYCl8twWXC1lwJuLDBtkUOHXNuR5+Jcl5zFOUyldq1Hv8u03vjnGT7lLJkJoqpG
l9QD8nBqRvBU7EM+CU7kP8+09b+088pULil+8x46PwgXkvOQwfVKSOr740Q4J4nm
/nUOyTNtToYntmt2fAVWDTIuyPpAqA6jcqSOC7Xoz9cYxkVWnYMLBUySXmSS0uxl
3p+wK0lMG0my/gb+alke5PAQjcE5dtXYzCn+8Lj0uSfCk8Gy0ZOK2oiUjaCGYN6D
u72qDRFBnR3jaoFqi03bGBIMnglGuAPyBZiI7LJgzuT9xumjKTJW3kN4YJxMNYu1
FzmIyFZpyvZ7930vB2UpCOiIaRdZiX4Z6ZN2frD3a/vBxBNqiNh/BO+Dex+PDfI4
TqwF8zlcjt4XZ2teQ8nNMR/D8oiYTUW8hwR4laEmDy7ASxe0p5aijmUApWq5UTsF
+s/QbwugccU0iR5orksM5u9MZH4J/mFGKzOltfGXNLYI6D5Mtwrnyi0BsF5eY0u6
vkdivtdqrq2DXY+ftuqLOQ7b+t1RctbcMHGPptlxFuN9ufP5TiTWSpfqDwmHCLsT
k2vFiMwcHdLpQ1IH8ORVRgPPsiBnBOJ/kIiXG2SxPUTjjEGOVgeA
=/Tod
-----END PGP PUBLIC KEY BLOCK-----"
#deb https://download.ceph.com/debian-mimic/ xenial main
EXEC_DIR=/var/${NAME}/exec
# this used in test_overrides to check amount of daemonsets defined
EXPECTED_NUMBER_OF_DAEMONSETS=17
type lshw || apt -y install lshw
type apparmor_parser || apt -y install apparmor
nic_info="$(lshw -class network)"
physical_nic=''
IFS=$'\n'
for line in ${nic_info}; do
  if [[ ${line} = *'physical id:'* ]]; then
    physical_nic=true
  fi
  if [ "${physical_nic}" = 'true' ] && [[ ${line} = *'logical name'* ]]; then
    DEVICE="$(echo "${line}" | cut -d':' -f2 | tr -d '[:space:]')"
    echo "Found device: '${DEVICE}' to use for ethtool testing"
    break
  fi
done
[ -n "${DEVICE}" ] || (echo Could not find physical NIC for tesing; exit 1)
# Not all hardware has the same NIC tunables to use for testing
if [[ $(/sbin/ethtool -k "${DEVICE}" | grep "${ETHTOOL_KEY3}:") =~ .*fixed.* ]]; then
  ETHTOOL_KEY3="${ETHTOOL_KEY3_BACKUP}"
fi
if [[ $(/sbin/ethtool -k "${DEVICE}" | grep "${ETHTOOL_KEY5}:") =~ .*fixed.* ]]; then
  ETHTOOL_KEY5="${ETHTOOL_KEY5_BACKUP}"
fi

exec >& >(while read line; do echo "${line}" | sudo tee -a ${LOG_NAME}; done)

set -x

purge_containers(){
  local chart_status="$(helm list ${NAME})"
  if [ -n "${chart_status}" ]; then
    helm delete --purge ${NAME}
  fi
}

__set_systemd_name(){
  if [ "${2}" = 'mount' ]; then
    SYSTEMD_NAME="$(systemd-escape -p --suffix=mount "${1}")"
  else
    SYSTEMD_NAME="$(systemd-escape -p --suffix=service "${1}")"
  fi
}

_teardown_systemd(){
  __set_systemd_name "${1}" "${2}"
  sudo systemctl stop "${SYSTEMD_NAME}" >& /dev/null || true
  sudo systemctl disable "${SYSTEMD_NAME}" >& /dev/null || true
  sudo rm "/etc/systemd/system/${SYSTEMD_NAME}" >& /dev/null || true
}

clean_persistent_files(){
  sudo rm -r /var/${NAME} >& /dev/null || true
  sudo rm -r /etc/sysctl.d/60-${NAME}-* >& /dev/null || true
  sudo rm -r /etc/security/limits.d/60-${NAME}-* >& /dev/null || true
  sudo rm -r /etc/apparmor.d/${NAME}-* >& /dev/null || true
  _teardown_systemd ${MOUNTS_PATH1} mount
  _teardown_systemd ${MOUNTS_PATH2} mount
  _teardown_systemd ${MOUNTS_PATH3} mount
  sudo systemctl daemon-reload
}

_write_sysctl(){
  sudo /sbin/sysctl -w ${1}=${2}
}

_write_ethtool(){
  local cur_val
  if [ -z "${2}" ]; then
    return
  fi
  cur_val="$(/sbin/ethtool -k ${1} |
             grep "${2}:" | cut -d':' -f2 | cut -d' ' -f2)"
  if [ "${cur_val}" != "${3}" ]; then
    sudo /sbin/ethtool -K ${1} ${2} ${3} || true
  fi
}

_reset_account(){
  if [ -n "$1" ]; then
    sudo deluser $1 >& /dev/null || true
    sudo rm -r /home/$1 >& /dev/null || true
    sudo rm /etc/sudoers.d/*$1* >& /dev/null || true
  fi
}

init_default_state(){
  purge_containers
  clean_persistent_files
  # set sysctl original vals
  _write_sysctl ${SYSCTL_KEY1} ${SYSCTL_VAL1_DEFAULT}
  _write_sysctl ${SYSCTL_KEY2} ${SYSCTL_VAL2_DEFAULT}
  _write_sysctl ${SYSCTL_KEY3} ${SYSCTL_VAL3_DEFAULT}
  _write_sysctl ${SYSCTL_KEY4} ${SYSCTL_VAL4_DEFAULT}
  # set ethtool original vals
  _write_ethtool ${DEVICE} ${ETHTOOL_KEY2} ${ETHTOOL_VAL2_DEFAULT}
  _write_ethtool ${DEVICE} "${ETHTOOL_KEY3}" ${ETHTOOL_VAL3_DEFAULT}
  _write_ethtool ${DEVICE} ${ETHTOOL_KEY4} ${ETHTOOL_VAL4_DEFAULT}
  _write_ethtool ${DEVICE} ${ETHTOOL_KEY5} ${ETHTOOL_VAL5_DEFAULT}
  # Remove any created accounts, SSH keys
  _reset_account ${USERNAME1}
  _reset_account ${USERNAME2}
  _reset_account ${USERNAME3}
  _reset_account ${USERNAME4}
}

install(){
  purge_containers
  helm install --name="${NAME}" --debug "${NAME}" --namespace="${NAME}" "$@"
}

upgrade(){
  helm upgrade --name="${NAME}" --debug "${NAME}" --namespace="${NAME}" "$@"
}

dry_run(){
  helm install --name="${NAME}" --dry-run --debug "${NAME}" --namespace="${NAME}" "$@"
}

get_container_status(){
  local deployment="${1}"
  local log_connect_timeout=60
  local log_connect_sleep_interval=2
  local wait_time=0
  while : ; do
    container="$(kubectl get pods --namespace="${NAME}" | grep ${NAME}-${deployment} | grep -v Terminating | cut -d' ' -f1)"
    kubectl logs "${container}" --namespace="${NAME}" > /dev/null && break || \
      echo "Waiting for container logs..." && \
      wait_time=$((${wait_time} + ${log_connect_sleep_interval})) && \
      sleep ${log_connect_sleep_interval}
    if [ ${wait_time} -ge ${log_connect_timeout} ]; then
      echo "Hit timeout while waiting for container logs to become available."
      exit 1
    fi
  done
  local container_runtime_timeout=210
  local container_runtime_sleep_interval=5
  wait_time=0
  while : ; do
    CLOGS="$(kubectl logs --namespace="${NAME}" "${container}" 2>&1)"
    local status="$(echo "${CLOGS}" | tail -1)"
    if [[ $(echo -e ${status} | tr -d '[:cntrl:]') = *ERROR* ]] ||
       [[ $(echo -e ${status} | tr -d '[:cntrl:]') = *TRACE* ]]; then
      if [ "${2}" = 'expect_failure' ]; then
        echo 'Pod exited as expected'
        break
      else
        echo 'Expected pod to complete successfully, but pod reported errors'
        echo 'pod logs:'
        echo "${CLOGS}"
        exit 1
      fi
    elif [[ $(echo -e ${status} | tr -d '[:cntrl:]') = *'INFO Putting the daemon to sleep.'* ]] ||
    [[ $(echo -e ${status} | tr -d '[:cntrl:]') = *'DEBUG + exit 0'* ]]; then
      if [ "${2}" = 'expect_failure' ]; then
        echo 'Expected pod to die with error, but pod completed successfully'
        echo 'pod logs:'
        echo "${CLOGS}"
        exit 1
      else
        echo 'Pod completed without errors.'
        break
      fi
    else
      wait_time=$((${wait_time} + ${container_runtime_sleep_interval}))
      sleep ${container_runtime_sleep_interval}
    fi
    if [ ${wait_time} -ge ${container_runtime_timeout} ]; then
      echo 'Hit timeout while waiting for container to complete work.'
      break
    fi
  done
}

_test_sysctl_default(){
  test "$(/sbin/sysctl "${1}" | cut -d'=' -f2 | tr -d '[:space:]')" = "${2}"
}

_test_sysctl_value(){
  _test_sysctl_default "${1}" "${2}"
  local key="${1//\//.}"
  test "$(cat /etc/sysctl.d/60-${NAME}-${key}.conf)" = "${key}=${2}"
}

_test_exec_match(){
  expected_result="$1"
  exec_testfile="$2"
  testID="$3"
  if [[ $expected_result != $(cat $exec_testfile) ]]; then
    echo "[FAIL] exec $testID failed. Expected:"
    echo $expected_result
    echo but got:
    echo $(cat $exec_testfile)
    exit 1
  fi
  rm $exec_testfile
}

_test_exec_count(){
  script_location="${1}"
  script_name="${2}"
  script_expected_run_count="${3}"
  script_run_count=$(cat "${script_location}" | wc -l)
  if [[ ${script_run_count} -ne ${script_expected_run_count} ]]; then
    echo "[FAIL] Expected '${script_name}' to run '${script_expected_run_count}' times, but instead it ran '$script_run_count' times"
    exit 1
  fi
}

_test_clog_msg(){
  [[ $CLOGS = *${1}* ]] ||
    (echo "Did not find expected string: '${1}'"
     echo "in container logs:"
     echo "${CLOGS}"
     exit 1)
}

alias install_base="install ${BASE_VALS}"
alias dry_run_base="dry_run ${BASE_VALS}"
shopt -s expand_aliases

test_sysctl(){
  # Test the first set of values
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  local val1=0
  local val2=1
  local val3=0
  local val4=0
  echo "conf:
  sysctl:
    $SYSCTL_KEY1: $val1
    $SYSCTL_KEY2: $val2
    $SYSCTL_KEY3: $val3
    $SYSCTL_KEY4: $val4" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status sysctl
  _test_sysctl_value $SYSCTL_KEY1 $val1
  _test_sysctl_value $SYSCTL_KEY2 $val2
  _test_sysctl_value $SYSCTL_KEY3 $val3
  _test_sysctl_value $SYSCTL_KEY4 $val4
  echo '[SUCCESS] sysctl test1 passed successfully' >> "${TEST_RESULTS}"

  # Test an updated set of values
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set2.yaml
  val1=1
  val2=0
  val3=1
  val4=1
  echo "conf:
  sysctl:
    $SYSCTL_KEY1: $val1
    $SYSCTL_KEY2: $val2
    $SYSCTL_KEY3: $val3
    $SYSCTL_KEY4: $val4" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status sysctl
  _test_sysctl_value $SYSCTL_KEY1 $val1
  _test_sysctl_value $SYSCTL_KEY2 $val2
  _test_sysctl_value $SYSCTL_KEY3 $val3
  _test_sysctl_value $SYSCTL_KEY4 $val4
  echo '[SUCCESS] sysctl test2 passed successfully' >> "${TEST_RESULTS}"

  # Test revert/rollback functionality
  install_base
  get_container_status sysctl
  _test_sysctl_default $SYSCTL_KEY1 $SYSCTL_VAL1_DEFAULT
  _test_sysctl_default $SYSCTL_KEY2 $SYSCTL_VAL2_DEFAULT
  _test_sysctl_default $SYSCTL_KEY3 $SYSCTL_VAL3_DEFAULT
  _test_sysctl_default $SYSCTL_KEY4 $SYSCTL_VAL4_DEFAULT
  echo '[SUCCESS] sysctl test3 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid key
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid1.yaml
  echo "conf:
  sysctl:
    this.is.a.bogus.key: 1" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status sysctl expect_failure
  _test_clog_msg 'sysctl: cannot stat /proc/sys/this/is/a/bogus/key: No such file or directory'
  echo '[SUCCESS] sysctl test4 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid val
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid2.yaml
  echo "conf:
  sysctl:
    $SYSCTL_KEY1: bogus" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  # Sysctl does not report a non-zero exit code for this failure condition per
  # https://bugzilla.redhat.com/show_bug.cgi?id=1264080
  get_container_status sysctl
  _test_clog_msg 'sysctl: setting key "net.ipv4.conf.all.log_martians": Invalid argument'
  echo '[SUCCESS] sysctl test5 passed successfully' >> "${TEST_RESULTS}"
}

_test_limits_value(){
  local limit=${1}
  local domain=${2}
  local type=${3}
  local item=${4}
  local value=${5}
  test "$(cat /etc/security/limits.d/60-${NAME}-${limit}.conf)" = \
    "$domain $type $item $value"
}

test_limits(){
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}.yaml
  echo "conf:
  limits:
    limit1:
      domain: root
      type: hard
      item: core
      value: 0
    limit2:
      domain: '0:'
      type: soft
      item: nofile
      value: 101" > "${overrides_yaml}"
  echo $(cat ${overrides_yaml})
  install_base "--values=${overrides_yaml}"
  get_container_status limits
  _test_limits_value limit1 root hard core 0
  _test_limits_value limit2 '0:' soft nofile 101
  echo "[SUCCESS] test range loop for limits passed successfully" >> "${TEST_RESULTS}"
}

_test_perm_value(){
  local file=${1}
  local owner=${2}
  local group=${3}
  local perm=${4}
  local r_owner="$(stat -c %U ${file})"
  local r_group="$(stat -c %G ${file})"
  local r_perm="$(stat -c %a ${file})"
  [ "${perm}"=="${r_perm}" ] && echo "+" || (echo "File ${file} permissions ${r_perm} but expected ${perm}"; exit 1)
  [ "${owner}"=="${r_owner}" ] && echo "+" || (echo "File ${file} owner ${r_owner} but expected ${owner}"; exit 1)
  [ "${group}"=="${r_group}" ] && echo "+" || (echo "File ${file} group ${r_group} but expected ${group}"; exit 1)
}

_perm_init_one(){
  local file=${1}
  local user=${file##*.}
  useradd ${user} -U
  chmod 777 ${file}
  chown ${user}:${user} ${file}
  echo ${file}
}

_make_p_temp(){
  echo $(mktemp "${TMPDIR:-/tmp}/${0##*/}.XXXXXX")
}

_perm_init(){
  # global vars!
  p_test_file1=$(_perm_init_one $(_make_p_temp))
  p_test_file2=$(_perm_init_one $(_make_p_temp))
}

_perm_teardown_one(){
  local file=${1}
  local user=${file##*.}
  deluser ${user} -q
  rm -f ${file}
}

_perm_teardown(){
  # global vars!
  _perm_teardown_one ${p_test_file1}
  unset p_test_file1
  _perm_teardown_one ${p_test_file2}
  unset p_test_file2
}

test_perm(){
  _perm_init
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}.yaml
  echo "conf:
  perm:
    paths:
    -
      path: ${p_test_file1}
      owner: 'root'
      group: 'shadow'
      permissions: '0640'
    -
      path: ${p_test_file2}
      owner: 'root'
      group: 'shadow'
      permissions: '0640'" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status perm
  _test_perm_value ${p_test_file1} root shadow 640
  _test_perm_value ${p_test_file2} root shadow 640
  echo "[SUCCESS] Positive test for perm passed successfully" >> "${TEST_RESULTS}"
  echo "conf:
  perm:
    paths:
    -
      path: ${p_test_file1}
      owner: 'root'
      group: 'shadow'
      permissions: '0640'" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status perm
  _test_perm_value ${p_test_file1} root shadow 640
  _test_perm_value ${p_test_file2} ${p_test_file2##*.} ${p_test_file2##*.} 777
  echo "[SUCCESS] Backup test for perm passed successfully" >> "${TEST_RESULTS}"
  # Test invalid rerun_interval (too short)
  echo "conf:
  perm:
    rerun_interval: 30
    paths:
    -
      path: ${p_test_file1}
      owner: 'root'
      group: 'shadow'
      permissions: '0640'" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD .rerun_interval. Got' || \
    (echo "[FAIL] perm test invalid rerun_interval value did not receive expected 'BAD .rerun_interval. Got' error" && exit 1)
  echo '[SUCCESS] perm test invalid rerun_interval passed successfully' >> "${TEST_RESULTS}"
  # Test invalid rerun_interval combination
  echo "conf:
  perm:
    rerun_interval: 60
    rerun_policy: once_successfully
    paths:
    -
      path: ${p_test_file1}
      owner: 'root'
      group: 'shadow'
      permissions: '0640'" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD COMBINATION' || \
    (echo "[FAIL] perm invalid rerun_interval combination did not receive expected 'BAD COMBINATION' error" && exit 1)
  echo '[SUCCESS] perm invalid rerun_interval combination passed successfully' >> "${TEST_RESULTS}"
  # test rerun_interval
  echo "conf:
  perm:
    rerun_interval: 60
    paths:
    -
      path: ${p_test_file1}
      owner: 'root'
      group: 'shadow'
      permissions: '0640'" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status perm
  sleep 72
  get_container_status perm
  _test_perm_value ${p_test_file1} root shadow 640
  echo '[SUCCESS] perm rerun_interval passed successfully' >> "${TEST_RESULTS}"
  _perm_teardown
}

_test_if_mounted_positive(){
  mountpoint "${1}" || (echo "Expect ${1} to be mounted, but was not"; exit 1)
  df -h | grep "${1}" | grep "${2}" ||
    (echo "Did not find expected mount size of ${2} in mount table"; exit 1)
  __set_systemd_name "${1}" mount
  systemctl is-enabled "${SYSTEMD_NAME}" ||
    (echo "Expect ${SYSTEMD_NAME} to be flagged to start on boot, but is not"
     exit 1)
}

_test_if_mounted_negative(){
  mountpoint "${1}" &&
    (echo "Expect ${1} not to be mounted, but was"
     exit 1) || true
  __set_systemd_name "${1}" mount
  systemctl is-enabled "${SYSTEMD_NAME}" &&
    (echo "Expect ${SYSTEMD_NAME} not to be flagged to start on boot, but was"
     exit 1) || true
}

test_mounts(){
  # Test the first set of values
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  local mount_size=32M
  echo "conf:
  mounts:
    mnt:
      mnt_tgt: ${MOUNTS_PATH1}
      device: tmpfs
      type: tmpfs
      options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=${mount_size}'
    mnt2:
      mnt_tgt: ${MOUNTS_PATH2}
      device: tmpfs
      type: tmpfs
      options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=${mount_size}'
    mnt3:
      mnt_tgt: ${MOUNTS_PATH3}
      device: tmpfs
      type: tmpfs
      options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=${mount_size}'
      before: ntp.service
      after: dbus.service" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status mounts
  _test_if_mounted_positive ${MOUNTS_PATH1} ${mount_size}
  _test_if_mounted_positive ${MOUNTS_PATH2} ${mount_size}
  _test_if_mounted_positive ${MOUNTS_PATH3} ${mount_size}
  echo '[SUCCESS] mounts test1 passed successfully' >> "${TEST_RESULTS}"

  # Test an updated set of values
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set2.yaml
  mount_size=30M
  echo "conf:
  mounts:
    mnt:
      mnt_tgt: ${MOUNTS_PATH1}
      device: tmpfs
      type: tmpfs
      options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=${mount_size}'
    mnt2:
      mnt_tgt: ${MOUNTS_PATH2}
      device: tmpfs
      type: tmpfs
      options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=${mount_size}'
    mnt3:
      mnt_tgt: ${MOUNTS_PATH3}
      device: tmpfs
      type: tmpfs
      options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=${mount_size}'
      before: ntp.service
      after: dbus.service" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status mounts
  _test_if_mounted_positive ${MOUNTS_PATH1} ${mount_size}
  _test_if_mounted_positive ${MOUNTS_PATH2} ${mount_size}
  _test_if_mounted_positive ${MOUNTS_PATH3} ${mount_size}
  echo '[SUCCESS] mounts test2 passed successfully' >> "${TEST_RESULTS}"

  # Test revert/rollback functionality
  install_base
  get_container_status mounts
  _test_if_mounted_negative ${MOUNTS_PATH1}
  _test_if_mounted_negative ${MOUNTS_PATH2}
  _test_if_mounted_negative ${MOUNTS_PATH3}
  echo '[SUCCESS] mounts test3 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid mount
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid1.yaml
  echo "conf:
  mounts:
    mnt:
      mnt_tgt: '${MOUNTS_PATH1}'
      device: '/dev/bogus'
      type: 'bogus'
      options: 'defaults'" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status mounts expect_failure # systemd has long 3 min timeout
  __set_systemd_name "${MOUNTS_PATH1}" mount
  _test_clog_msg "${SYSTEMD_NAME} failed."
  echo '[SUCCESS] mounts test4 passed successfully' >> "${TEST_RESULTS}"
}

_test_ethtool_value(){
  if [ -z "${1}" ]; then
    return
  fi
  test "$(/sbin/ethtool -k ${DEVICE} |
          grep "${1}:" | cut -d':' -f2 | tr -d '[:space:]')" = "${2}"
}

test_ethtool(){
  # Test the first set of values
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  local val2=on
  local val3=off
  [ -n "${ETHTOOL_KEY3}" ] && local line2_1="${ETHTOOL_KEY3}: $val3"
  local val4=off
  echo "conf:
  ethtool:
    ${DEVICE}:
      $ETHTOOL_KEY2: $val2
      $line2_1
      $ETHTOOL_KEY4: $val4" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool
  _test_ethtool_value $ETHTOOL_KEY2 $val2
  _test_ethtool_value "$ETHTOOL_KEY3" $val3
  _test_ethtool_value $ETHTOOL_KEY4 $val4
  echo '[SUCCESS] ethtool test1 passed successfully' >> "${TEST_RESULTS}"

  # Test an updated set of values
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set2.yaml
  val2=off
  val3=on
  [ -n "${ETHTOOL_KEY3}" ] && local line2_2="${ETHTOOL_KEY3}: $val3"
  val4=on
  echo "conf:
  ethtool:
    ${DEVICE}:
      $ETHTOOL_KEY2: $val2
      $line2_2
      $ETHTOOL_KEY4: $val4" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool
  _test_ethtool_value $ETHTOOL_KEY2 $val2
  _test_ethtool_value "$ETHTOOL_KEY3" $val3
  _test_ethtool_value $ETHTOOL_KEY4 $val4
  echo '[SUCCESS] ethtool test2 passed successfully' >> "${TEST_RESULTS}"

  # Test revert/rollback functionality
  install_base
  get_container_status ethtool
  _test_ethtool_value $ETHTOOL_KEY2 $ETHTOOL_VAL2_DEFAULT
  _test_ethtool_value "$ETHTOOL_KEY3" $ETHTOOL_VAL3_DEFAULT
  _test_ethtool_value $ETHTOOL_KEY4 $ETHTOOL_VAL4_DEFAULT
  echo '[SUCCESS] ethtool test3 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid key
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid1.yaml
  echo "conf:
  ethtool:
    ${DEVICE}:
      this-is-a-bogus-key: $val2" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool expect_failure
  _test_clog_msg "Could not find requested param this-is-a-bogus-key for ${DEVICE}"
  echo '[SUCCESS] ethtool test4 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid val
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid2.yaml
  echo "conf:
  ethtool:
    ${DEVICE}:
      $ETHTOOL_KEY2: bogus" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool expect_failure
  _test_clog_msg "Expected 'on' or 'off', got 'bogus'"
  echo '[SUCCESS] ethtool test5 passed successfully' >> "${TEST_RESULTS}"

  # Test fixed (unchangeable) ethtool param
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid3.yaml
  echo "conf:
  ethtool:
    ${DEVICE}:
      hw-tc-offload: on" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool expect_failure
  _test_clog_msg "does not permit changing the 'hw-tc-offload' setting"
  echo '[SUCCESS] ethtool test6 passed successfully' >> "${TEST_RESULTS}"

  # Test ethtool settings conflict
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid4.yaml
  echo "conf:
  ethtool:
    ${DEVICE}:
      ${ETHTOOL_KEY2}: on
      ${ETHTOOL_KEY5}: off" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool expect_failure
  _test_clog_msg 'There is a conflict between settings chosen for this device.'
  echo '[SUCCESS] ethtool test7 passed successfully' >> "${TEST_RESULTS}"
}

_test_user_enabled(){
  username=$1
  user_enabled=$2

  if [ "${user_enabled}" = "true" ]; then
    # verify the user is there and not set to expire
    getent passwd $username >& /dev/null
    test "$(chage -l ${username} | grep 'Account expires' | cut -d':' -f2 |
            tr -d '[:space:]')" = "never"
  else
    # Verify user is not non-expiring
    getent passwd $username >& /dev/null
    test "$(chage -l ${username} | grep 'Account expires' | cut -d':' -f2 |
            tr -d '[:space:]')" != "never"
  fi
}

_test_user_purged(){
  username=$1

  # Verify user is no longer defined
  getent passwd $username >& /dev/null && \
    echo "Error: User '$username' exists, but was expected it to be purged" && \
    return 1

  if [ -d /home/$username ]; then
    echo "Error: User '$username' home dir exists; expected it to be purged"
    return 1
  fi
}

_test_sudo_enabled(){
  username=$1
  sudo_enable=$2
  sudoers_file=/etc/sudoers.d/*$username*

  if [ "${sudo_enable}" = "true" ]; then
    test -f $sudoers_file
  else
    test ! -f $sudoers_file
  fi
}

_test_ssh_keys(){
  username=$1
  sshkey=$2
  ssh_file=/home/$username/.ssh/authorized_keys

  if [ "$sshkey" = "false" ]; then
    test ! -f "${ssh_file}"
  else
    grep "$sshkey" "${ssh_file}"
  fi
}

_test_user_passwd(){
  username=$1
  crypt_passwd="$2"

  if [ "$crypt_passwd" != "$(getent shadow $username | cut -d':' -f2)" ]; then
    echo "Error: User '$username' passwd did not match expected val '$crypt_passwd'"
    return 1
  fi
}

test_uamlite(){
  # Test the first set of values
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  echo "conf:
  uamlite:
    users:
    - user_name: ${USERNAME1}
      user_sudo: ${USERNAME1_SUDO}
      user_sshkeys:
      - ${USERNAME1_SSHKEY1}
    - user_name: ${USERNAME2}
      user_sudo: ${USERNAME2_SUDO}
      user_crypt_passwd: ${USERNAME2_CRYPT_PASSWD}
      user_sshkeys:
      - ${USERNAME2_SSHKEY1}
      - ${USERNAME2_SSHKEY2}
      - ${USERNAME2_SSHKEY3}
    - user_name: ${USERNAME3}
      user_sudo: ${USERNAME3_SUDO}
    - user_name: ${USERNAME4}" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status uamlite
  _test_user_enabled ${USERNAME1} true
  _test_sudo_enabled ${USERNAME1} ${USERNAME1_SUDO}
  _test_ssh_keys     ${USERNAME1} "${USERNAME1_SSHKEY1}"
  _test_user_passwd  ${USERNAME1} '*'
  _test_user_enabled ${USERNAME2} true
  _test_sudo_enabled ${USERNAME2} ${USERNAME2_SUDO}
  _test_ssh_keys     ${USERNAME2} "${USERNAME2_SSHKEY1}"
  _test_ssh_keys     ${USERNAME2} "${USERNAME2_SSHKEY2}"
  _test_ssh_keys     ${USERNAME2} "${USERNAME2_SSHKEY3}"
  _test_user_passwd  ${USERNAME2} ${USERNAME2_CRYPT_PASSWD}
  _test_user_enabled ${USERNAME3} true
  _test_sudo_enabled ${USERNAME3} ${USERNAME3_SUDO}
  _test_ssh_keys     ${USERNAME3} false
  _test_user_passwd  ${USERNAME3} '*'
  _test_user_enabled ${USERNAME4} true
  _test_sudo_enabled ${USERNAME4} ${USERNAME4_SUDO}
  _test_ssh_keys     ${USERNAME4} false
  _test_user_passwd  ${USERNAME4} '*'
  echo '[SUCCESS] uamlite test1 passed successfully' >> "${TEST_RESULTS}"

  # Test an updated set of values
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set2.yaml
  uname1_sudo=false
  uname2_sudo=true
  uname3_sudo=false
  echo "conf:
  uamlite:
    users:
    - user_name: ${USERNAME1}
      user_sudo: ${uname1_sudo}
    - user_name: ${USERNAME2}
      user_sudo: ${uname2_sudo}
      user_sshkeys:
      - ${USERNAME2_SSHKEY1}
      - ${USERNAME2_SSHKEY2}
    - user_name: ${USERNAME3}
      user_sudo: ${uname3_sudo}
      user_sshkeys:
      - ${USERNAME1_SSHKEY1}
      - ${USERNAME2_SSHKEY3}
    - user_name: ${USERNAME4}" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status uamlite
  _test_user_enabled ${USERNAME1} true
  _test_sudo_enabled ${USERNAME1} ${uname1_sudo}
  _test_ssh_keys     ${USERNAME1} false
  _test_user_passwd  ${USERNAME1} '*'
  _test_user_enabled ${USERNAME2} true
  _test_sudo_enabled ${USERNAME2} ${uname2_sudo}
  _test_ssh_keys     ${USERNAME2} "${USERNAME2_SSHKEY1}"
  _test_ssh_keys     ${USERNAME2} "${USERNAME2_SSHKEY2}"
  _test_user_passwd  ${USERNAME2} '*'
  _test_user_enabled ${USERNAME3} true
  _test_sudo_enabled ${USERNAME3} ${uname3_sudo}
  _test_ssh_keys     ${USERNAME3} "${USERNAME1_SSHKEY1}"
  _test_ssh_keys     ${USERNAME3} "${USERNAME2_SSHKEY3}"
  _test_user_passwd  ${USERNAME3} '*'
  _test_user_enabled ${USERNAME4} true
  _test_sudo_enabled ${USERNAME4} ${USERNAME4_SUDO}
  _test_ssh_keys     ${USERNAME4} false
  _test_user_passwd  ${USERNAME4} '*'
  echo '[SUCCESS] uamlite test2 passed successfully' >> "${TEST_RESULTS}"

  # Test revert/rollback functionality
  install_base
  get_container_status uamlite
  _test_user_enabled ${USERNAME1} false
  _test_sudo_enabled ${USERNAME1} false
  _test_user_enabled ${USERNAME2} false
  _test_sudo_enabled ${USERNAME2} false
  _test_user_enabled ${USERNAME3} false
  _test_sudo_enabled ${USERNAME3} false
  _test_user_enabled ${USERNAME4} false
  _test_sudo_enabled ${USERNAME4} false
  echo '[SUCCESS] uamlite test3 passed successfully' >> "${TEST_RESULTS}"

  # Test purge users flag
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set4.yaml
  echo "conf:
  uamlite:
    purge_expired_users: true" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status uamlite
  _test_user_purged ${USERNAME1}
  _test_user_purged ${USERNAME2}
  _test_user_purged ${USERNAME3}
  _test_user_purged ${USERNAME4}
  echo '[SUCCESS] uamlite test4 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid password
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set5.yaml
  user2_crypt_passwd_invalid='plaintextPassword'
  echo "conf:
  uamlite:
    users:
    - user_name: ${USERNAME2}
      user_crypt_passwd: ${user2_crypt_passwd_invalid}" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD PASSWORD' || \
    (echo "[FAIL] uamlite test5 did not receive expected 'BAD PASSWORD' error" && exit 1)
  echo '[SUCCESS] uamlite test5 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid SSH key
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set6.yaml
  user2_bad_sshkey='AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmT key-comment'
  echo "conf:
  uamlite:
    users:
    - user_name: ${USERNAME2}
      user_sshkeys:
      - ${USERNAME2_SSHKEY1}
      - ${user2_bad_sshkey}
      - ${USERNAME2_SSHKEY3}" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD SSH KEY' || \
    (echo "[FAIL] uamlite test6 did not receive expected 'BAD SSH KEY' error" && exit 1)
  echo '[SUCCESS] uamlite test6 passed successfully' >> "${TEST_RESULTS}"
}

_test_apt_package_version(){
  local pkg_name=$1
  local pkg_ver=$2
  if [ ${pkg_ver} = "none" ]; then
    # Does not include residual-config
    if [[ $(dpkg -l | grep ${pkg_name} | grep -v ^rc) ]]; then
      echo "[FAIL] Package ${pkg_name} should not be installed" >> "${TEST_RESULTS}"
      return 1
    fi
  elif [ ${pkg_ver} = "any" ]; then
    if [[ ! $(dpkg -l | grep ${pkg_name}) ]]; then
      echo "[FAIL] Package ${pkg_name} should be installed" >> "${TEST_RESULTS}"
      return 1
    fi
  else
    if [ $(dpkg -l | awk "/[[:space:]]${pkg_name}[[:space:]]/"'{print $3}') != "${pkg_ver}" ]; then
      echo "[FAIL] Package ${pkg_name} should be of version ${pkg_ver}" >> "${TEST_RESULTS}"
      return 1
    fi
  fi
}

_test_apt_repositories(){
  local repositories=$1
  local remaining_repos
  for repository in $repositories
  do
    if ! grep -qrh "$repository" /etc/apt/sources.list /etc/apt/sources.list.d/*
    then
      echo "[FAIL] The repository (${repository}) was not added."
      #return 1
    fi
  done
  remaining_repos=$(grep -rh "^deb" /etc/apt/sources.list /etc/apt/sources.list.d/* | sort -u | grep -v "${repositories// /\\|}" | awk '{print$2}')
  for repo in $remaining_repos
  do
    echo "[FAIL] Repository ${repo} should not be added."
  done
}

_test_apt_keys(){
  local keys=$1
  for key in $keys
  do
    if ! apt-key list | grep -q "$key"
    then
      echo "[FAIL] The gpg key (${key}) was not installed"
    fi
  done
  remaining_keys=$(apt-key list | grep "^pub" | grep -v "${keys// /\\|}" | awk '{print$2}')
  for rkey in $remaining_keys
  do
    echo "[FAIL] The gpg key (${rkey}) should not be installed"
  done
}

test_apt(){
  # Test the valid set of packages
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  echo "conf:
  apt:
    packages:
    - name: $APT_PACKAGE1
      version: $APT_VERSION1
    - name: $APT_PACKAGE2" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt
  _test_apt_package_version $APT_PACKAGE1 $APT_VERSION1
  _test_apt_package_version $APT_PACKAGE2 any
  echo '[SUCCESS] apt test1 passed successfully' >> "${TEST_RESULTS}"

  # Test removal of one package and install of one new package
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set2.yaml
  echo "conf:
  apt:
    packages:
    - name: $APT_PACKAGE2
      debconf:
      - question: mysql-server/root_password
        question_type: password
        answer: rootpw
      - question: mysql-server/root_password_again
        question_type: password
        answer: rootpw
    - name: $APT_PACKAGE3
      version: $APT_VERSION3" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt
  _test_apt_package_version $APT_PACKAGE1 none
  _test_apt_package_version $APT_PACKAGE2 any
  # Each entry in passwords.dat contains question value in Name and Template
  # field, so grepping root_password should return 4 lines
  if [[ $(grep root_password /var/cache/debconf/passwords.dat | wc -l) != 4 ]]; then
    echo "[FAIL] Package $APT_PACKAGE2 should have debconf values configured" >> "${TEST_RESULTS}"
    return 1
  fi
  _test_apt_package_version $APT_PACKAGE3 $APT_VERSION3
  echo '[SUCCESS] apt test2 passed successfully' >> "${TEST_RESULTS}"

  # Test removal of all installed packages and install of one that already exists
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set3.yaml
  echo "conf:
  apt:
    packages:
    - name: $APT_PACKAGE4" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt
  _test_apt_package_version $APT_PACKAGE2 none
  _test_apt_package_version $APT_PACKAGE3 none
  echo '[SUCCESS] apt test3 passed successfully' >> "${TEST_RESULTS}"

  # Test package not installed by divingbell not removed
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set4.yaml
  echo "conf:
  apt:
    packages:
    - name: $APT_PACKAGE5" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt
  _test_apt_package_version $APT_PACKAGE4 any  # Should still be present
  _test_apt_package_version $APT_PACKAGE5 any
  echo '[SUCCESS] apt test4 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid package name
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-invalid1.yaml
  echo "conf:
  apt:
    packages:
    - name: some-random-name
      version: whatever" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt expect_failure
  _test_clog_msg 'E: Unable to locate package some-random-name'
  echo '[SUCCESS] apt test5 passed successfully' >> "${TEST_RESULTS}"

  # Test blacklistpkgs
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  echo "conf:
  apt:
    packages:
    - name: $APT_PACKAGE6
    blacklistpkgs:
    - $APT_PACKAGE6" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt
  _test_apt_package_version $APT_PACKAGE6 none
  echo '[SUCCESS] apt test6 passed successfully' >> "${TEST_RESULTS}"

  # Test add several repositories with gpg keys
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set5.yaml
  echo "conf:
  apt:
    repositories:
      repository_name1:
        url: $APT_REPOSITORY1
        distributions: $APT_DISTRIBUTIONS1
        components: $APT_COMPONENTS1
        subrepos: $APT_SUBREPOS1
        gpgkey: |-
$(printf '%s' "$APT_GPGKEY1" | awk '{printf "          %s\n", $0}')
      repository_name2:
        url: $APT_REPOSITORY2
        distributions: $APT_DISTRIBUTIONS2
        components: $APT_COMPONENTS2
        subrepos: $APT_SUBREPOS2
        gpgkey: |-
$(printf '%s' "$APT_GPGKEY2" | awk '{printf "          %s\n", $0}')
      repository_name3:
        url: $APT_REPOSITORY3
        distributions: $APT_DISTRIBUTIONS3
        components: $APT_COMPONENTS3
        subrepos: $APT_SUBREPOS3
        gpgkey: |-
$(printf '%s' "$APT_GPGKEY3" | awk '{printf "          %s\n", $0}')" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt
  _test_apt_repositories "$APT_REPOSITORY1 $APT_REPOSITORY2 $APT_REPOSITORY3"
  _test_apt_keys "$APT_GPGKEYID1 $APT_GPGKEYID2 $APT_GPGKEYID3"
  echo '[SUCCESS] apt test7 passed successfully' >> "${TEST_RESULTS}"

  # Test add same gpg key two times
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set6.yaml
  echo "conf:
  apt:
    repositories:
      repository_name1:
        url: $APT_REPOSITORY1
        distributions: $APT_DISTRIBUTIONS1
        components: $APT_COMPONENTS1
        subrepos: $APT_SUBREPOS1
        gpgkey: |-
$(printf '%s' "$APT_GPGKEY1" | awk '{printf "          %s\n", $0}')
      repository_name2:
        url: $APT_REPOSITORY2
        distributions: $APT_DISTRIBUTIONS2
        components: $APT_COMPONENTS2
        subrepos: $APT_SUBREPOS2
        gpgkey: |-
$(printf '%s' "$APT_GPGKEY1" | awk '{printf "          %s\n", $0}')" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apt
  _test_apt_repositories "$APT_REPOSITORY1 $APT_REPOSITORY2"
  _test_apt_keys "$APT_GPGKEYID1"
  echo '[SUCCESS] apt test8 passed successfully' >> "${TEST_RESULTS}"
}

# test exec module
test_exec(){
  # test script execution ordering, args, and env vars
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  echo 'conf:
  exec:
    030-script5.sh:
      blocking_policy: foreground_halt_pod_on_failure
      env:
        env1: env1-val
        env2: env2-val
        env3: env3-val
      args:
      - arg1
      - arg2
      - arg3
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile
        echo args: "$@" >> exec_testfile
        echo env: "$env1 $env2 $env3" >> exec_testfile
    005-script1.sh:
      blocking_policy: foreground
      data: |
        #!/bin/bash
        rm exec_testfile 2> /dev/null || true
        echo script name: ${BASH_SOURCE} >> exec_testfile
    015-script3.sh:
      blocking_policy: foreground_halt_pod_on_failure
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile
    008-script2.sh:
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile
    025-script4.sh:
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status exec
  expected_result='script name: ./005-script1.sh
script name: ./008-script2.sh
script name: ./015-script3.sh
script name: ./025-script4.sh
script name: ./030-script5.sh
args: arg1 arg2 arg3
env: env1-val env2-val env3-val'
  _test_exec_match "$expected_result" "${EXEC_DIR}/exec_testfile" "test1"
  echo '[SUCCESS] exec test1 passed successfully' >> "${TEST_RESULTS}"

  # Test blocking_policy
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set2.yaml
  echo 'conf:
  exec:
    030-script5.sh:
      blocking_policy: foreground_halt_pod_on_failure
      env:
        env1: env1-val
        env2: env2-val
        env3: env3-val
      args:
      - arg1
      - arg2
      - arg3
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile
        echo args: "$@" >> exec_testfile
        echo env: "$env1 $env2 $env3" >> exec_testfile
    005-script1.sh:
      blocking_policy: foreground
      data: |
        #!/bin/bash
        rm exec_testfile 2> /dev/null || true
        echo script name: ${BASH_SOURCE} >> exec_testfile
    015-script3.sh:
      blocking_policy: foreground_halt_pod_on_failure
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile
        false
    008-script2.sh:
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile
    025-script4.sh:
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status exec expect_failure
  expected_result='script name: ./005-script1.sh
script name: ./008-script2.sh
script name: ./015-script3.sh'
  _test_exec_match "$expected_result" "${EXEC_DIR}/exec_testfile" "test2"
  echo '[SUCCESS] exec test2 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid rerun_policy
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set3.yaml
  echo 'conf:
  exec:
    030-script5.sh:
      rerun_policy: foo
      data: |
        #!/bin/bash
        true' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD .rerun_policy. FOR' || \
    (echo "[FAIL] exec test3 did not receive expected 'BAD .rerun_policy. FOR' error" && exit 1)
  echo '[SUCCESS] exec test3 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid blocking_policy
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set4.yaml
  echo 'conf:
  exec:
    030-script5.sh:
      blocking_policy: foo
      data: |
        #!/bin/bash
        true' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD .blocking_policy. FOR' || \
    (echo "[FAIL] exec test4 did not receive expected 'BAD .blocking_policy. FOR' error" && exit 1)
  echo '[SUCCESS] exec test4 passed successfully' >> "${TEST_RESULTS}"

  # Test rerun_policies:
  # 1. Unspecified
  # 2. always
  # 3. once_successfully, when script passes
  # 4. once_successfully, when script fails
  # 5. never

  # first execution
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set5.yaml
  echo 'conf:
  exec:
    001-script1.sh:
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> script1
    002-script2.sh:
      rerun_policy: always
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> script2
    003-script3.sh:
      rerun_policy: once_successfully
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> script3
    004-script4.sh:
      rerun_policy: once_successfully
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> script4
        false
    005-script5.sh:
      rerun_policy: never
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> script5
      env:
        env3: env3-val
        env1: env1-val
        env2: env2-val
      args:
      - arg2
      - arg1
      - arg3
manifests:
  daemonset_ethtool: false
  daemonset_mounts: false
  daemonset_uamlite: false
  daemonset_sysctl: false
  daemonset_limits: false
  daemonset_apt: false
  daemonset_perm: false' > "${overrides_yaml}"

  install_base "--values=${overrides_yaml}"
  get_container_status exec

  # run several times with the same values and evaluate results
  # (ensure no ordering issues cause hashing inconsistencies)
  for i in $(seq 0 11); do
    install_base "--values=${overrides_yaml}"
    get_container_status exec
    _test_exec_count "${EXEC_DIR}/script1" '001-script1.sh' $(($i + 2))
    _test_exec_count "${EXEC_DIR}/script2" '002-script1.sh' $(($i + 2))
    _test_exec_count "${EXEC_DIR}/script3" '003-script1.sh' '1'
    _test_exec_count "${EXEC_DIR}/script4" '004-script1.sh' $(($i + 2))
    _test_exec_count "${EXEC_DIR}/script5" '005-script1.sh' '1'
    echo "[SUCCESS] exec test$(($i + 5)) passed successfully" >> "${TEST_RESULTS}"
  done

  # test timeout
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set17.yaml
  echo 'conf:
  exec:
    011-timeout.sh:
      timeout: 11
      data: |
        #!/bin/bash
        sleep 60' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status exec
  _test_clog_msg 'timeout waiting for'
  echo '[SUCCESS] exec test17 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid timeout
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set18.yaml
  echo 'conf:
  exec:
    011-timeout.sh:
      timeout: infinite
      data: |
        #!/bin/bash
        sleep 60' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD .timeout. FOR' || \
    (echo "[FAIL] exec test18 did not receive expected 'BAD .timeout. FOR' error" && exit 1)
  echo '[SUCCESS] exec test18 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid rerun_interval (too short)
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set19.yaml
  echo 'conf:
  exec:
    012-rerun-interval.sh:
      rerun_interval: 30
      data: |
        #!/bin/bash
        true' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD .rerun_interval. FOR' || \
    (echo "[FAIL] exec test19 did not receive expected 'BAD .rerun_interval. FOR' error" && exit 1)
  echo '[SUCCESS] exec test19 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid retry_interval (too short)
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set20.yaml
  echo 'conf:
  exec:
    012-retry-interval.sh:
      retry_interval: 30
      data: |
        #!/bin/bash
        true' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD .retry_interval. FOR' || \
    (echo "[FAIL] exec test20 did not receive expected 'BAD .retry_interval. FOR' error" && exit 1)
  echo '[SUCCESS] exec test20 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid rerun_interval combination
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set21.yaml
  echo 'conf:
  exec:
    012-rerun-interval.sh:
      rerun_interval: 60
      rerun_policy: once_successfully
      data: |
        #!/bin/bash
        true' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD COMBINATION' || \
    (echo "[FAIL] exec test21 did not receive expected 'BAD COMBINATION' error" && exit 1)
  echo '[SUCCESS] exec test21 passed successfully' >> "${TEST_RESULTS}"

  # Test invalid retry_interval combination
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set22.yaml
  echo 'conf:
  exec:
    012-retry-interval.sh:
      retry_interval: 60
      rerun_policy: never
      data: |
        #!/bin/bash
        true' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}" 2>&1 | grep 'BAD COMBINATION' || \
    (echo "[FAIL] exec test22 did not receive expected 'BAD COMBINATION' error" && exit 1)
  echo '[SUCCESS] exec test22 passed successfully' >> "${TEST_RESULTS}"

  # test rerun_interval
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set23.yaml
  echo 'conf:
  exec:
    012-rerun-interval.sh:
      rerun_interval: 60
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status exec
  sleep 72
  get_container_status exec
  expected_result='script name: ./012-rerun-interval.sh
script name: ./012-rerun-interval.sh'
  _test_exec_match "$expected_result" "${EXEC_DIR}/exec_testfile" "test23"
  echo '[SUCCESS] exec test23 passed successfully' >> "${TEST_RESULTS}"

  # test retry_interval
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set24.yaml
  echo 'conf:
  exec:
    012-retry-interval.sh:
      retry_interval: 60
      data: |
        #!/bin/bash
        echo script name: ${BASH_SOURCE} >> exec_testfile
        false' > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status exec
  sleep 72
  get_container_status exec
  expected_result='script name: ./012-retry-interval.sh
script name: ./012-retry-interval.sh'
  _test_exec_match "$expected_result" "${EXEC_DIR}/exec_testfile" "test24"
  echo '[SUCCESS] exec test24 passed successfully' >> "${TEST_RESULTS}"
}

# test daemonset value overrides for hosts and labels
test_overrides(){
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-dryrun.yaml
  echo "conf:
  sysctl:
    net.ipv4.ip_forward: 1
    net.ipv6.conf.all.forwarding: 1
  overrides:
    divingbell_sysctl:
      labels:
      - label:
          key: compute_type
          values:
          - dpdk
          - sriov
        conf:
          sysctl:
            net.ipv4.ip_forward: 1
      - label:
          key: compute_type
          values:
          - special
        conf:
          sysctl:
            net.ipv4.ip_forward: 1
      - label:
          key: compute_type
          values:
          - special
        conf:
          sysctl:
            net.ipv4.ip_forward: 1
      hosts:
      - name: superhost
        conf:
          sysctl:
            net.ipv4.ip_forward: 0
            net.ipv6.conf.all.forwarding: 0
      - name: helm1
        conf:
          sysctl:
            net.ipv6.conf.all.forwarding: 0
      - name: specialhost
        conf:
          sysctl:
            net.ipv6.conf.all.forwarding: 1
    divingbell_mounts:
      labels:
      - label:
          key: blarg
          values:
          - soup
          - chips
        conf:
          mounts:
            mnt:
              mnt_tgt: /mnt
              device: tmpfs
              type: tmpfs
              options: 'defaults,noatime,nosuid,nodev,noexec,mode=1777,size=32M'
    divingbell_ethtool:
      hosts:
      - name: ethtool-host
        conf:
          ethtool:
            ens3:
              hw-tc-offload: on
    divingbell_bogus:
      labels:
      - label:
          key: bogus
          values:
          - foo
          - bar
        conf:
          bogus:
            other_stuff: XYZ
      - label:
          key: bogus_label
          values:
          - bogus_value
        conf:
          bogus:
            more_stuff: ABC
      hosts:
      - name: superhost2
        conf:
          bogus:
            other_stuff: FOO
            more_stuff: BAR" > "${overrides_yaml}"

  tc_output="$(dry_run_base "--values=${overrides_yaml}")"

  # Compare against expected number of generated daemonsets
  daemonset_count="$(echo "${tc_output}" | grep 'kind: DaemonSet' | wc -l)"
  if [ "${daemonset_count}" != "${EXPECTED_NUMBER_OF_DAEMONSETS}" ]; then
    echo '[FAILURE] overrides test 1 failed' >> "${TEST_RESULTS}"
    echo "Expected ${EXPECTED_NUMBER_OF_DAEMONSETS} daemonsets; got '${daemonset_count}'" >> "${TEST_RESULTS}"
    exit 1
  else
    echo '[SUCCESS] overrides test 1 passed successfully' >> "${TEST_RESULTS}"
  fi

  # TODO: Implement more robust tests that do not depend on match expression
  # ordering.

  # Verify generated affinity for another_label
  echo "${tc_output}" | grep '    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: another_label
                operator: In
                values:
                - "another_value"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "superhost"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "helm1"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "specialhost"' &&
  echo '[SUCCESS] overrides test 2 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 2 failed' && exit 1)

  # Verify generated affinity for compute_type
  echo "${tc_output}" | grep '    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: compute_type
                operator: In
                values:
                - "special"
              - key: another_label
                operator: NotIn
                values:
                - "another_value"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "superhost"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "helm1"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "specialhost"' &&
  echo '[SUCCESS] overrides test 3 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 3 failed' && exit 1)

  # Verify generated affinity for compute_type
  echo "${tc_output}" | grep '    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: compute_type
                operator: In
                values:
                - "dpdk"
                - "sriov"
              - key: compute_type
                operator: NotIn
                values:
                - "special"
              - key: another_label
                operator: NotIn
                values:
                - "another_value"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "superhost"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "helm1"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "specialhost"' &&
  echo '[SUCCESS] overrides test 4 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 4 failed' && exit 1)

  # Verify generated affinity for one of the daemonset hosts
  echo "${tc_output}" | grep '    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: blarg
                operator: In
                values:
                - "soup"
                - "chips"' &&
  echo '[SUCCESS] overrides test 5 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 5 failed' && exit 1)

  # Verify generated affinity for one of the daemonset defaults
  echo "${tc_output}" | grep '    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "superhost"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "helm1"
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - "specialhost"
              - key: compute_type
                operator: NotIn
                values:
                - "dpdk"
                - "sriov"
              - key: compute_type
                operator: NotIn
                values:
                - "special"
              - key: another_label
                operator: NotIn
                values:
                - "another_value"' &&
  echo '[SUCCESS] overrides test 6 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 6 failed' && exit 1)

  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-functional.yaml
  key1_override_val=0
  key2_non_override_val=0
  echo "conf:
  sysctl:
    $SYSCTL_KEY1: 1
    $SYSCTL_KEY2: $key2_non_override_val
  overrides:
    divingbell_sysctl:
      hosts:
      - name: $(hostname -f)
        conf:
          sysctl:
            $SYSCTL_KEY1: $key1_override_val" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status sysctl
  _test_sysctl_default $SYSCTL_KEY1 $key1_override_val
  _test_sysctl_default $SYSCTL_KEY2 $key2_non_override_val
  echo '[SUCCESS] overrides test 7 passed successfully' >> "${TEST_RESULTS}"

}

_test_apparmor_profile_added(){
  local profile_file=$1
  local profile_name=$2
  local defaults_path='/var/divingbell/apparmor'
  local persist_path='/etc/apparmor.d'

  if [ ! -f "${defaults_path}/${profile_file}" ]; then
    return 1
  fi
  if [ ! -L "${persist_path}/${profile_file}" ]; then
    return 1
  fi

  profile_loaded=$(grep $profile_name /sys/kernel/security/apparmor/profiles || : )

  if [ -z "$profile_loaded" ]; then
    return 1
  fi
  return 0
}

_test_apparmor_profile_removed(){
  local profile_file=$1
  local profile_name=$2
  local defaults_path='/var/divingbell/apparmor'
  local persist_path='/etc/apparmor.d'

  if [ -f "${defaults_path}/${profile_file}" ]; then
    return 1
  fi
  if [ -L "${persist_path}/${profile_file}" ]; then
    return 1
  fi

  profile_loaded=$(grep $profile_name /sys/kernel/security/apparmor/profiles || : )

  if [ ! -z "$profile_loaded" ]; then
    return 1
  fi

  reboot_message_present=$(grep $profile_file /var/run/reboot-required.pkgs || : )

  if [ -z "$reboot_message_present" ]; then
    return 1
  fi

  return 0
}

test_apparmor(){
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-apparmor.yaml

  #Test1 - check new profile added and loaded
  echo "conf:
  apparmor:
    profiles:
      divingbell-profile-1: |
        #include <tunables/global>
          /usr/sbin/profile-1 {
            #include <abstractions/apache2-common>
            #include <abstractions/base>
            #include <abstractions/nis>

            capability dac_override,
            capability dac_read_search,
            capability net_bind_service,
            capability setgid,
            capability setuid,

            /data/www/safe/* r,
            deny /data/www/unsafe/* r,
          }" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apparmor
  _test_apparmor_profile_added divingbell-profile-1 profile-1
  echo '[SUCCESS] apparmor test1 passed successfully' >> "${TEST_RESULTS}"

  #Test2 - check new profile added and loaded, profile-1 still exist
  echo "conf:
  apparmor:
    profiles:
      divingbell-profile-1: |
        #include <tunables/global>
          /usr/sbin/profile-1 {
            #include <abstractions/apache2-common>
            #include <abstractions/base>
            #include <abstractions/nis>

            capability dac_override,
            capability dac_read_search,
            capability net_bind_service,
            capability setgid,
            capability setuid,

            /data/www/safe/* r,
            deny /data/www/unsafe/* r,
          }
      divingbell-profile-2: |
        #include <tunables/global>
          /usr/sbin/profile-2 {
            #include <abstractions/apache2-common>
            #include <abstractions/base>
            #include <abstractions/nis>

            capability dac_override,
            capability dac_read_search,
            capability net_bind_service,
            capability setgid,
            capability setuid,

            /data/www/safe/* r,
            deny /data/www/unsafe/* r,
          }" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apparmor
  _test_apparmor_profile_added divingbell-profile-1 profile-1
  _test_apparmor_profile_added divingbell-profile-2 profile-2
  echo '[SUCCESS] apparmor test2 passed successfully' >> "${TEST_RESULTS}"

  #Test3 - check profile-2 removed, profile-1 still exist
  echo "conf:
  apparmor:
    complain_mode: true
    profiles:
      divingbell-profile-1: |
        #include <tunables/global>
          /usr/sbin/profile-1 {
            #include <abstractions/apache2-common>
            #include <abstractions/base>
            #include <abstractions/nis>

            capability dac_override,
            capability dac_read_search,
            capability net_bind_service,
            capability setgid,
            capability setuid,

            /data/www/safe/* r,
            deny /data/www/unsafe/* r,
          }" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apparmor
  _test_apparmor_profile_added divingbell-profile-1 profile-1
  _test_apparmor_profile_removed divingbell-profile-2 profile-2
  echo '[SUCCESS] apparmor test3 passed successfully' >> "${TEST_RESULTS}"

  #Test4 - check for bad profile input
  echo "conf:
  apparmor:
    profiles:
      divingbell-profile-3: |
        #include <tunables/global>
          /usr/sbin/profile-3 {
            bad data
          }" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status apparmor expect_failure
  _test_clog_msg 'AppArmor parser error for /etc/apparmor.d/divingbell-profile-3 in /etc/apparmor.d/divingbell-profile-3 at line 3: syntax error, unexpected TOK_ID, expecting TOK_MODE'
  echo '[SUCCESS] apparmor test4 passed successfully' >> "${TEST_RESULTS}"
}

# initialization
init_default_state

# run tests
if [[ -z $SKIP_BASE_TESTS ]]; then
  install_base
  test_sysctl
  test_limits
  test_perm
  test_mounts
  test_ethtool
  test_uamlite
  test_apt
  test_exec
  test_apparmor
fi
purge_containers
test_overrides

# restore initial state
init_default_state

echo "All tests pass for ${NAME}"
