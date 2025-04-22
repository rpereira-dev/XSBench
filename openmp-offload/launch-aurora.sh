#!/bin/bash

export OMP_PROC_BIND=close
export OMP_PLACES="cores(8)"
export OMP_NUM_THREADS=8

# FLAT - manually
#echo "FLAT"
#export ZE_FLAT_DEVICE_HIERARCHY=FLAT
#export CPU_BIND_SCHEME="--cpu-bind=list:1-8:9-16:17-24:25-32:33-40:41-48:53-60:61-68:69-76:77-84:85-92:93-100"
#export GPU_BIND_SCHEME="--gpu-bind=list:0.0:0.1:1.0:1.1:2.0:2.1:3.0:3.1:4.0:4.1:5.0:5.1"
#mpiexec -n 12 -ppn 12 ${CPU_BIND_SCHEME} ${GPU_BIND_SCHEME} ./hello_affinity_aurora.out | sort
#mpiexec -n 12 -ppn 12 ${CPU_BIND_SCHEME} ${GPU_BIND_SCHEME} ./xsbench -m event -s large | grep "Total Lookups/s"

# FLAT - with script
# mpiexec -n 12 -ppn 12 ${CPU_BIND_SCHEME} gpu_tile_compact.sh ./hello_affinity_aurora.out | sort
for i in {1..5} ; do
    mpiexec -n 12 -ppn 12 ${CPU_BIND_SCHEME} gpu_tile_compact.sh ./xsbench -m event -s large | grep "Total Lookups/s"
done

# COMPOSITE - manually
# echo "COMPOSITE"
# export ZE_FLAT_DEVICE_HIERARCHY=COMPOSITE
# export CPU_BIND_SCHEME="--cpu-bind=list:1-16:17-32:33-48:53-68:69-84:85-100"
# export GPU_BIND_SCHEME="--gpu-bind=list:0:1:2:3:4:5"
# #mpiexec -n 6 -ppn 6 ${CPU_BIND_SCHEME} ${GPU_BIND_SCHEME} ./hello_affinity_aurora.out | sort
# mpiexec -n 6 -ppn 6 ${CPU_BIND_SCHEME} ${GPU_BIND_SCHEME} ./xsbench -m event -s large | grep "Total Lookups/s"

# COMPOSITE - with script
# mpiexec -n 6 -ppn 6 ${CPU_BIND_SCHEME} gpu_dev_compact.sh ./hello_affinity_aurora.out | sort
for i in {1..5} ; do
    mpiexec -n 6 -ppn 6 ${CPU_BIND_SCHEME} gpu_dev_compact.sh ./xsbench -m event -s large | grep "Total Lookups/s"
done
