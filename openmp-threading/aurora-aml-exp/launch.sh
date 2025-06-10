#!/bin/bash

echo "$nthreads"

#CMDTIME=
#CMDTIME="command time -v"

export OMP_PROC_BIND=close
export OMP_PLACES="threads"

echo "bin:numactl:nthreads:time:lookups:mem-max-resident:gridtype:mode"

for MODE in "event" "history" ; do
    for gridtype in "unionized" "nuclide" "hash" ; do
        for j in {1..5} ; do

            module unload hwloc/main
            module load mpich/opt/develop-git.6037a7a hwloc/2.11.3-mpich-level-zero

            # for NUMAMPI in "0:1" "2:3" ; do
            #     for bin in "./XSBench-mpi" ; do
            #         for i in 104 100 96 92 88 84 80 76 72 68 64 60 56 52 48 44 40 36 32 28 24 20 16 12 8 4 2 1 ; do
            #             export OMP_NUM_THREADS=$i
            #             out=$(mpiexec -n 2 -ppn 2 --cpu-bind=list:0-51,104-155:52-103,156-207 --mem-bind=list:$NUMAMPI $bin -t $i -m $MODE -G $gridtype)
            #             time=$(echo "$out" | grep "Runtime" | cut -d ":" -f 2 | xargs | cut -d " " -f 1)
            #             lookups=$(echo "$out" | grep "Total Lookups/s" | cut -d ':' -f 2 | xargs | tr -d ',')
            #             mem=$(echo "$out" | grep "Maximum resident" | cut -d ":" -f 2 | xargs)
            #             NUMACTL=$(echo $NUMAMPI | tr ':' ',')
            #             echo "$bin:$NUMACTL:$[2*i]:$time:$lookups:$mem:$gridtype:$MODE"
            #         done
            #     done
            # done

            module unload mpich/opt/develop-git.6037a7a hwloc/2.11.3-mpich-level-zero
            module load hwloc/main

            # for NUMACTL in "0" "2" ; do
            #     for bin in "./XSBench-default" ; do
            #         for i in 208 200 192 184 176 168 160 152 144 136 128 120 112 104 96 88 80 72 64 56 52 48 40 32 24 16 8 4 2 1 ; do
            #             export OMP_NUM_THREADS=$i
            #             out=$($CMDTIME numactl -m $NUMACTL $bin -t $i -m $MODE -G $gridtype 2>&1 )
            #             time=$(echo "$out" | grep "Runtime" | cut -d ":" -f 2 | xargs | cut -d " " -f 1)
            #             lookups=$(echo "$out" | grep "Lookups/s" | cut -d ':' -f 2 | xargs | tr -d ',')
            #             mem=$(echo "$out" | grep "Maximum resident" | cut -d ":" -f 2 | xargs)
            #             echo "$bin:$NUMACTL:$i:$time:$lookups:$mem:$gridtype:$MODE"
            #         done
            #     done
            # done

            pairs=("0,1 ./XSBench-aml-lat" "2,3 ./XSBench-aml-bw")
            for pair in "${pairs[@]}"; do
                read NUMACTL bin <<< "$pair"
                for i in 208 200 192 184 176 168 160 152 144 136 128 120 112 104 96 88 80 72 64 56 52 48 40 32 24 16 8 4 2 1 ; do
                    export OMP_NUM_THREADS=$i
                    out=$($CMDTIME numactl -m $NUMACTL $bin -t $i -m $MODE -G $gridtype 2>&1)
                    time=$(echo "$out" | grep "Runtime" | cut -d ":" -f 2 | xargs | cut -d " " -f 1)
                    lookups=$(echo "$out" | grep "Lookups/s" | cut -d ':' -f 2 | xargs | tr -d ',')
                    mem=$(echo "$out" | grep "Maximum resident" | cut -d ":" -f 2 | xargs)
                    echo "$bin:$NUMACTL:$i:$time:$lookups:$mem:$gridtype:$MODE"
                done
            done
        done
    done
done
