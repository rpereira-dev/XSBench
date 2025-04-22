#!/bin/bash

export OMP_PROC_BIND=close
export OMP_PLACES="cores(8)"
export OMP_NUM_THREADS=8

# FLAT - with script
export CPU_BIND_SCHEME="--cpu-bind=list:1-8:9-16:17-24:25-32:33-40:41-48:53-60:61-68:69-76:77-84:85-92:93-100"
# mpiexec -n 12 -ppn 12 ${CPU_BIND_SCHEME} gpu_tile_compact.sh ./hello_affinity_aurora.out | sort
for i in {1..5} ; do
    mpiexec -n 12 -ppn 12 ${CPU_BIND_SCHEME} gpu_tile_compact.sh ./xsbench -m event -s large | grep "Total Lookups/s"
done

# COMPOSITE - with script
export CPU_BIND_SCHEME="--cpu-bind=list:1-16:17-32:33-48:53-68:69-84:85-100"
# mpiexec -n 6 -ppn 6 ${CPU_BIND_SCHEME} gpu_dev_compact.sh ./hello_affinity_aurora.out | sort
for i in {1..5} ; do
    mpiexec -n 6 -ppn 6 ${CPU_BIND_SCHEME} gpu_dev_compact.sh ./xsbench -m event -s large | grep "Total Lookups/s"
done
