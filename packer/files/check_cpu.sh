#!/bin/bash

function usage {
  echo "$(basename $0) usage: "
  echo "    -w warning_level Example: 80"
  echo "    -c critical_level Example: 90"
  echo ""
  exit 1
}

while [[ $# -gt 1 ]]
do
    key="$1"
    case $key in
      -w)
      WARN="$2"
      shift
      ;;
      -c)
      CRIT="$2"
      shift
      ;;
      *)
      usage
      shift
      ;;
  esac
  shift
done

[ ! -z ${WARN} ] && [ ! -z ${CRIT} ] || usage

CPU_USAGE="$(vmstat 1 2|tail -1)"
CPU_USER="$(echo ${CPU_USAGE} | awk '{print $13}')"
CPU_SYSTEM="$(echo ${CPU_USAGE} | awk '{print $14}')"
CPU_IDLE="$(echo ${CPU_USAGE} | awk '{print $15}')"
CPU_IOWAIT="$(echo ${CPU_USAGE} | awk '{print $16}')"
CPU_ST="$(echo ${CPU_USAGE} | awk '{print $17}')"

if [[ ${CPU_USER} -gt ${CRIT} || ${CPU_SYSTEM} -gt ${CRIT} || ${CPU_IOWAIT} -gt ${CRIT} || ${CPU_ST} -gt ${CRIT} ]]
then
  echo "CRITICAL - CPU Usage |CPU_USER=${CPU_USER};;;; CPU_SYSTEM=${CPU_SYSTEM};;;; CPU_IDLE=${CPU_IDLE};;;; CPU_IOWAIT=${CPU_IOWAIT};;;; CPU_ST=${CPU_ST};;;;"
  exit 2
elif [[ ${CPU_USER} -gt ${WARN} || ${CPU_SYSTEM} -gt ${WARN} || ${CPU_IOWAIT} -gt ${WARN} || ${CPU_ST} -gt ${WARN} ]]
then
  echo "WARNING - CPU Usage |CPU_USER=${CPU_USER};;;; CPU_SYSTEM=${CPU_SYSTEM};;;; CPU_IDLE=${CPU_IDLE};;;; CPU_IOWAIT=${CPU_IOWAIT};;;; CPU_ST=${CPU_ST};;;;"
  exit 1
else
  echo "OK - CPU Usage |CPU_USER=${CPU_USER};;;; CPU_SYSTEM=${CPU_SYSTEM};;;; CPU_IDLE=${CPU_IDLE};;;; CPU_IOWAIT=${CPU_IOWAIT};;;; CPU_ST=${CPU_ST};;;;"
  exit 0
fi