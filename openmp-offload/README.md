# Intel
```
icpx -O3 -Wall -fiopenmp -fopenmp-targets=spir64_gen -Xopenmp-target-backend "-device pvc" -I /usr/include/level_zero -lze_loader -fopenmp-offload-mandatory -foffload-lto  Main.c GridInit.c io.c Materials.c Simulation.c XSutils.c 
```

# Nvidia
```
clang++ -O3 -Wall -fopenmp -fopenmp-offload-mandatory -foffload-lto -fopenmp-targets=nvptx64 -Xopenmp-target=nvptx64 --offload-arch=sm_70,sm_80,sm_90  Main.c GridInit.c io.c Materials.c Simulation.c XSutils.c energy.cc -DCUDA_ENERGY=1 -lnvidia-ml
```

# AMD
clang++ -O3 -Wall -fopenmp -fopenmp-offload-mandatory -foffload-lto -fopenmp-targets=amdgcn-amd-amdhsa -Xopenmp-target=amdgcn-amd-amdhsa --offload-arch=gfx90a,gfx942 Main.c GridInit.c io.c Materials.c Simulation.c XSutils.c energy.cc -DROCM_ENERGY=1 -L $(ROCM_PATH)/lib/ -lamdhip64 -L $(ROCM_PATH)/lib/ -lrocm_smi64 -I $(ROCM_PATH)/include

# RUN AS
```
OMP_NUM_THREADS=8 OMP_PROC_BIND=close OMP_PLACES="cores(8)" ./a.out-a100 -m event -s large
```
