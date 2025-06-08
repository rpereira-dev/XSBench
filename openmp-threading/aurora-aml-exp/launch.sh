#!/bin/bash

echo "$nthreads"

#CMDTIME=
#CMDTIME="command time -v"

export OMP_PROC_BIND=close
export OMP_PLACES="cores"

echo "bin:numactl:nthreads:lookups:mem-max-resident"

for j in {1..5} ; do

    module unload hwloc/main
    module load mpich/opt/develop-git.6037a7a hwloc/2.11.3-mpich-level-zero
    export NUMACTL=0,1

#    for NUMACTL in "0-1" "2-3" ; do
#        for bin in "./XSBench-mpi" ; do
#            for i in 1 2 4 8 12 16 20 24 28 32 36 40 44 48 52 ; do
#                export OMP_NUM_THREADS=$i
#                out=$(mpiexec -n 2 -ppn 2 --cpu-bind=list:0-$[i]:52-$[52+$i] numactl -m $NUMACTL $bin -t $i)
#                time=$(echo "$out" | grep "Runtime" | cut -d ":" -f 2 | xargs | cut -d " " -f 1)
#                lookups=$(echo "$out" | grep "Total Lookups/s" | cut -d ':' -f 2 | xargs | tr -d ',')
#                mem=$(echo "$out" | grep "Maximum resident" | cut -d ":" -f 2 | xargs)
#                echo "$bin:$NUMACTL:$[2*i]:$time:$lookups:$mem"
#            done
#        done
#    done

    module unload mpich/opt/develop-git.6037a7a hwloc/2.11.3-mpich-level-zero
    module load hwloc/main
#
#    for NUMACTL in "0" "2" ; do
#        for bin in "./XSBench-default" ; do
#            for i in 1 2 4 8 16 24 32 40 48 52 56 64 72 80 88 96 104 ; do
#                export OMP_NUM_THREADS=$i
#                out=$($CMDTIME numactl -m $NUMACTL $bin -t $i 2>&1)
#                time=$(echo "$out" | grep "Runtime" | cut -d ":" -f 2 | xargs | cut -d " " -f 1)
#                lookups=$(echo "$out" | grep "Lookups/s" | cut -d ':' -f 2 | xargs | tr -d ',')
#                mem=$(echo "$out" | grep "Maximum resident" | cut -d ":" -f 2 | xargs)
#                echo "$bin:$NUMACTL:$i:$time:$lookups:$mem"
#            done
#        done
#    done

    #for NUMACTL in "0,1" ; do
    for NUMACTL in "2,3" ; do
        for bin in "./XSBench-aml" ; do
            for i in 1 2 4 8 16 24 32 40 48 52 56 64 72 80 88 96 104 ; do
                export OMP_NUM_THREADS=$i
                out=$($CMDTIME numactl -m $NUMACTL $bin -t $i 2>&1)
                time=$(echo "$out" | grep "Runtime" | cut -d ":" -f 2 | xargs | cut -d " " -f 1)
                lookups=$(echo "$out" | grep "Lookups/s" | cut -d ':' -f 2 | xargs | tr -d ',')
                mem=$(echo "$out" | grep "Maximum resident" | cut -d ":" -f 2 | xargs)
                echo "$bin:$NUMACTL:$i:$time:$lookups:$mem"
            done
        done
    done

done
