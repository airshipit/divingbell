#!/bin/bash

# TODO: Convert to use new/common gate scripts when available

set -e

NAME=divingbell
: ${LOGS_DIR:=/var/log}
: ${LOGS_SUBDIR:=${LOGS_DIR}/${NAME}/$(date +"%m-%d-%y_%H:%M:%S")}
mkdir -p "${LOGS_SUBDIR}"
LOG_NAME="${LOGS_SUBDIR}/test.log"
TEST_RESULTS="${LOGS_SUBDIR}/results.log"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${DIR}"
BASE_VALS="--values=${DIR}/../../values.yaml"
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
ETHTOOL_VAL3_DEFAULT=on
ETHTOOL_KEY4=tx-nocache-copy
ETHTOOL_VAL4_DEFAULT=off
ETHTOOL_KEY5=tx-checksum-ip-generic
ETHTOOL_VAL5_DEFAULT=on
nic_info="$(lshw -class network)"
physical_nic=''
IFS=$'\n'
for line in ${nic_info}; do
  if [[ ${line} = *'physical id:'* ]]; then
    physical_nic=true
  fi
  if [ "${physical_nic}" = 'true' ] && [[ ${line} = *'logical name'* ]]; then
    DEVICE="$(echo "${line}" | cut -d':' -f2 | tr -d '[:space:]')"
    echo "Found deivce: '${DEVICE}' to use for ethtool testing"
    break
  fi
done
[ -n "${DEVICE}" ] || (echo Could not find physical NIC for tesing; exit 1)

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
  cur_val="$(/sbin/ethtool -k ${1} |
             grep "${2}:" | cut -d':' -f2 | cut -d' ' -f2)"
  if [ "${cur_val}" != "${3}" ]; then
    sudo /sbin/ethtool -K ${1} ${2} ${3} || true
  fi
}

init_default_state(){
  if [ "${1}" = 'make' ]; then
    (cd ../../../; make)
  fi
  purge_containers
  clean_persistent_files
  # set sysctl original vals
  _write_sysctl ${SYSCTL_KEY1} ${SYSCTL_VAL1_DEFAULT}
  _write_sysctl ${SYSCTL_KEY2} ${SYSCTL_VAL2_DEFAULT}
  _write_sysctl ${SYSCTL_KEY3} ${SYSCTL_VAL3_DEFAULT}
  _write_sysctl ${SYSCTL_KEY4} ${SYSCTL_VAL4_DEFAULT}
  # set ethtool original vals
  _write_ethtool ${DEVICE} ${ETHTOOL_KEY2} ${ETHTOOL_VAL2_DEFAULT}
  _write_ethtool ${DEVICE} ${ETHTOOL_KEY3} ${ETHTOOL_VAL3_DEFAULT}
  _write_ethtool ${DEVICE} ${ETHTOOL_KEY4} ${ETHTOOL_VAL4_DEFAULT}
  _write_ethtool ${DEVICE} ${ETHTOOL_KEY5} ${ETHTOOL_VAL5_DEFAULT}
}

install(){
  purge_containers
  helm install --name="${NAME}" --debug "../../../${NAME}" --namespace="${NAME}" "$@"
}

upgrade(){
  helm upgrade --name="${NAME}" --debug "../../../${NAME}" --namespace="${NAME}" "$@"
}

dry_run(){
  helm install --name="${NAME}" --dry-run --debug "../../../${NAME}" --namespace="${NAME}" "$@"
}

get_container_status(){
  local deployment="${1}"
  container="$(kubectl get pods --namespace="${NAME}" | grep ${NAME}-${deployment} | cut -d' ' -f1)"
  local log_connect_timeout=30
  local log_connect_sleep_interval=2
  local wait_time=0
  while : ; do
    kubectl logs "${container}" --namespace="${NAME}" > /dev/null && break ||
      echo "Waiting for container logs..." &&
      wait_time=$((${wait_time} + ${log_connect_sleep_interval})) &&
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
    if [[ ${status} = *ERROR* ]] || [[ ${status} = *TRACE* ]]; then
      if [ "${2}" = 'expect_failure' ]; then
        echo 'Pod exited as expected'
        break
      else
        echo 'Expected pod to complete successfully, but pod reported errors'
        echo 'pod logs:'
        echo "${CLOGS}"
        exit 1
      fi
    elif [ "${status}" = 'INFO Putting the daemon to sleep.' ]; then
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
  test "$(/sbin/ethtool -k ${DEVICE} |
          grep "${1}:" | cut -d':' -f2 | tr -d '[:space:]')" = "${2}"
}

test_ethtool(){
  # Test the first set of values
  local overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set1.yaml
  local val2=on
  local val3=off
  local val4=off
  echo "conf:
  ethtool:
    ${DEVICE}:
      $ETHTOOL_KEY2: $val2
      $ETHTOOL_KEY3: $val3
      $ETHTOOL_KEY4: $val4" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool
  _test_ethtool_value $ETHTOOL_KEY2 $val2
  _test_ethtool_value $ETHTOOL_KEY3 $val3
  _test_ethtool_value $ETHTOOL_KEY4 $val4
  echo '[SUCCESS] ethtool test1 passed successfully' >> "${TEST_RESULTS}"

  # Test an updated set of values
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-set2.yaml
  val2=off
  val3=on
  val4=on
  echo "conf:
  ethtool:
    ${DEVICE}:
      $ETHTOOL_KEY2: $val2
      $ETHTOOL_KEY3: $val3
      $ETHTOOL_KEY4: $val4" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status ethtool
  _test_ethtool_value $ETHTOOL_KEY2 $val2
  _test_ethtool_value $ETHTOOL_KEY3 $val3
  _test_ethtool_value $ETHTOOL_KEY4 $val4
  echo '[SUCCESS] ethtool test2 passed successfully' >> "${TEST_RESULTS}"

  # Test revert/rollback functionality
  install_base
  get_container_status ethtool
  _test_ethtool_value $ETHTOOL_KEY2 $ETHTOOL_VAL2_DEFAULT
  _test_ethtool_value $ETHTOOL_KEY3 $ETHTOOL_VAL3_DEFAULT
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

# test daemonset value overrides for hosts and labels
test_overrides(){
  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-dryrun.yaml
  echo "conf:
  sysctl:
    net.ipv4.ip_forward: 1
    net.ipv6.conf.all.forwarding: 1
  overrides:
    divingbell-sysctl:
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
          key: another_label
          values:
          - another_value
        conf:
          sysctl:
            net.ipv4.ip_forward: 1
      - label:
          key: test_label
          values:
          - test_value
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
    divingbell-mounts:
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
    divingbell-ethtool:
      hosts:
      - name: ethtool-host
        conf:
          ethtool:
            ens3:
              hw-tc-offload: on
    divingbell-bogus:
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
  if [ "${daemonset_count}" != "11" ]; then
    echo '[FAILURE] overrides test 1 failed' >> "${TEST_RESULTS}"
    echo "Expected 11 daemonsets; got '${daemonset_count}'" >> "${TEST_RESULTS}"
    exit 1
  else
    echo '[SUCCESS] overrides test 1 passed successfully' >> "${TEST_RESULTS}"
  fi

  # TODO: Implement more robust tests that do not depend on match expression
  # ordering.

  # Verify generated affinity for one of the daemonset labels
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
              - key: compute_type
                operator: NotIn
                values:
                - "dpdk"
                - "sriov"
              - key: test_label
                operator: NotIn
                values:
                - "test_value"
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
      hostNetwork: true' &&
  echo '[SUCCESS] overrides test 2 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 2 failed' && exit 1)

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
                - "chips"
      hostNetwork: true' &&
  echo '[SUCCESS] overrides test 3 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 3 failed' && exit 1)

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
              - key: another_label
                operator: NotIn
                values:
                - "another_value"
              - key: test_label
                operator: NotIn
                values:
                - "test_value"
      hostNetwork: true' &&
  echo '[SUCCESS] overrides test 4 passed successfully' >> "${TEST_RESULTS}" ||
  (echo '[FAILURE] overrides test 4 failed' && exit 1)

  overrides_yaml=${LOGS_SUBDIR}/${FUNCNAME}-functional.yaml
  key1_override_val=0
  key2_non_override_val=0
  echo "conf:
  sysctl:
    $SYSCTL_KEY1: 1
    $SYSCTL_KEY2: $key2_non_override_val
  overrides:
    divingbell-sysctl:
      hosts:
      - name: $(hostname -f)
        conf:
          sysctl:
            $SYSCTL_KEY1: $key1_override_val" > "${overrides_yaml}"
  install_base "--values=${overrides_yaml}"
  get_container_status sysctl
  _test_sysctl_default $SYSCTL_KEY1 $key1_override_val
  _test_sysctl_default $SYSCTL_KEY2 $key2_non_override_val
  echo '[SUCCESS] overrides test 5 passed successfully' >> "${TEST_RESULTS}"

}

# initialization
init_default_state make

# run tests
install_base
test_sysctl
test_mounts
test_ethtool
purge_containers
test_overrides

# retore initial state
init_default_state

echo "All tests pass for ${NAME}"

