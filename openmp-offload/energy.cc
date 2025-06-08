# include <stdio.h>
# include <stdint.h>
# include <stdlib.h>
# include <time.h>

uint64_t
power_get_nanotime(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)(ts.tv_sec * 1000000000) + (uint64_t) ts.tv_nsec;
}

# if CUDA_ENERGY
#  include <nvml.h>
static nvmlDevice_t nvdevice;

void
power_init(void)
{
    // Initialize Cuda energy counters
    nvmlReturn_t result;
    unsigned long long energy;

    // Initialize NVML
    result = nvmlInit();
    if (NVML_SUCCESS != result) {
        printf("Failed to initialize NVML: %s\n", nvmlErrorString(result));
        exit(1);
    }

    // Get the handle for the first device
    result = nvmlDeviceGetHandleByIndex(0, &nvdevice);
    if (NVML_SUCCESS != result) {
        printf("Failed to get handle for device 0: %s\n", nvmlErrorString(result));
        nvmlShutdown();
        exit(1);
    }

    // Description
    // Retrieves total energy consumption for this GPU in millijoules (mJ) since the driver was last reloaded
    // For Volta or newer fully supported devices.
    result = nvmlDeviceGetTotalEnergyConsumption(nvdevice, &energy);
    if (NVML_SUCCESS != result) {
        printf("Failed to get total energy consumption: %s\n", nvmlErrorString(result));
        nvmlShutdown();
        exit(1);
    }

    printf("Initialized nvml (CUDA_ENERGY=1) - initial energy is `%llu`\n", energy);
}

void
power_deinit(void)
{
    nvmlShutdown();
}

# endif

# if ROCM_ENERGY
#include "rocm_smi/rocm_smi.h"
static RSMI_POWER_TYPE rsmi_type = RSMI_CURRENT_POWER;
static uint32_t num_devices;
static int rsmi_device = 0;

void
power_init(void)
{
    rsmi_init(0);
    rsmi_num_monitor_devices(&num_devices);
}

void
power_deinit(void)
{
}

# endif

# if ZES_ENERGY
# include <zes_api.h>
static zes_driver_handle_t zes_driver;
static uint32_t zes_driver_count;

# define MAX_DEV_HDL 64
static ze_device_handle_t ze_devices[MAX_DEV_HDL];
static uint32_t ze_devices_count;

# define MAX_PWR_HDL 64
static zes_pwr_handle_t zes_pwr_handle[MAX_DEV_HDL][MAX_PWR_HDL];
static uint32_t zes_pwr_handle_count;

//  Level Zero Sysman API device indexing is different from Level Zero Core API
//  Here is a table (please double check with printf reported, and ZE_AFFINITY_MASK)
//      ZE  ZES
//      0   4
//      1   5
//      2   3
//      3   1
//      4   0
//      5   2

# ifndef ZES_ENERGY_DEVICE_HDL_IDX
#  define ZES_ENERGY_DEVICE_HDL_IDX 4
# endif

# ifndef ZES_ENERGY_PWR_HDL_IDX
#  define ZES_ENERGY_PWR_HDL_IDX 0
# endif

# define ZE_SAFE_CALL(X)                \
    do {                                \
        ze_result_t r = X;              \
        if (r != ZE_RESULT_SUCCESS)     \
            abort();                    \
    } while (0)

void
power_init(void)
{
    zes_init_flags_t flags = ZES_INIT_FLAG_PLACEHOLDER;
    ZE_SAFE_CALL(zesInit(flags));

    zes_driver_count = 1;
    ZE_SAFE_CALL(zesDriverGet(&zes_driver_count, &zes_driver));

    ZE_SAFE_CALL(zeDeviceGet(zes_driver, &ze_devices_count, NULL));
    printf("Looking for %d devices\n", ze_devices_count);
    ZE_SAFE_CALL(zeDeviceGet(zes_driver, &ze_devices_count, ze_devices));

    for (int devIndex = 0 ; devIndex < ze_devices_count ; ++devIndex)
    {
        zes_device_handle_t dev_hdl = (zes_device_handle_t) ze_devices[devIndex];

        ZE_SAFE_CALL(zesDeviceEnumPowerDomains(ze_devices[devIndex], &zes_pwr_handle_count, NULL));
        ZE_SAFE_CALL(zesDeviceEnumPowerDomains(ze_devices[devIndex], &zes_pwr_handle_count, zes_pwr_handle[devIndex]));

        for (int pwrIndex = 0 ; pwrIndex < zes_pwr_handle_count ; ++pwrIndex)
        {
            zes_power_properties_t props {};
            props.stype = ZES_STRUCTURE_TYPE_POWER_PROPERTIES;
            if (zesPowerGetProperties(zes_pwr_handle[devIndex][pwrIndex], &props) == ZE_RESULT_SUCCESS)
            {
                if (props.onSubdevice)
                {
                    printf("[device %d] [pwr handle %d] Sub-device %u power:n\n", devIndex, pwrIndex, props.subdeviceId);
                    printf("[device %d] [pwr handle %d]     Can control: %s\n",   devIndex, pwrIndex, props.canControl ? "yes" : "no");
                }
                else
                {
                    printf("[device %d] [pwr handle %d] Total package power:n\n", devIndex, pwrIndex);
                    printf("[device %d] [pwr handle %d]     Can control: %s\n",   devIndex, pwrIndex, props.canControl ? "yes" : "no");
                }
            }
        }
    }

    printf("Measuring on device %d for power handle %d\n", ZES_ENERGY_DEVICE_HDL_IDX, ZES_ENERGY_PWR_HDL_IDX);
}


void
power_deinit(void)
{
}

# endif /* ZES_ENERGY */

static uint64_t t1, t2;

# if CUDA_ENERGY
static unsigned long long mj1, mj2;
# endif

# if ROCM_ENERGY
static double e1, e2;
# endif

# if ZES_ENERGY
static zes_power_energy_counter_t e1[MAX_DEV_HDL][MAX_PWR_HDL];
static zes_power_energy_counter_t e2[MAX_DEV_HDL][MAX_PWR_HDL];
# endif

void
power_start(void)
{
    # if CUDA_ENERGY
    nvmlDeviceGetTotalEnergyConsumption(nvdevice, &mj1);
    # endif

    # if ROCM_ENERGY
    uint64_t mj;
    float res;
    uint64_t timestamp;
    rsmi_dev_energy_count_get(rsmi_device, &mj, &res, &timestamp);
    e1 = (double) mj * res * 0.000001;
    # endif

    # if ZES_ENERGY
    for (int devIndex = 0 ; devIndex < ze_devices_count ; ++devIndex)
        for (int pwrIndex = 0 ; pwrIndex < zes_pwr_handle_count ; ++pwrIndex)
            ZE_SAFE_CALL(zesPowerGetEnergyCounter(zes_pwr_handle[devIndex][pwrIndex], &e1[devIndex][pwrIndex]));
    # endif

    t1 = power_get_nanotime();
}

double
power_stop(void)
{
    t2 = power_get_nanotime();
    double s = (t2 - t1) / (double) 1e9;

    # if CUDA_ENERGY
    nvmlDeviceGetTotalEnergyConsumption(nvdevice, &mj2);
    double J = (mj2 - mj1) / (double)1e3;
    double P = J / s;
    # endif

    # if ROCM_ENERGY
    uint64_t mj;
    float res;
    uint64_t timestamp;
    rsmi_dev_energy_count_get(rsmi_device, &mj, &res, &timestamp);
    e2 = (double) mj * res * 0.000001;
    double J = (e2 - e1);
    double P = J / s;
    # endif

    # if ZES_ENERGY
    double P = 0.0;
    for (int devIndex = 0 ; devIndex < ze_devices_count ; ++devIndex)
    {
        for (int pwrIndex = 0 ; pwrIndex < zes_pwr_handle_count ; ++pwrIndex)
        {
            ZE_SAFE_CALL(zesPowerGetEnergyCounter(zes_pwr_handle[devIndex][pwrIndex], &e2[devIndex][pwrIndex]));
            double uJ = (double) (e2[devIndex][pwrIndex].energy - e1[devIndex][pwrIndex].energy);
            double J = uJ / (double)1e6;
            char * msg;
            if (devIndex == ZES_ENERGY_DEVICE_HDL_IDX && pwrIndex == ZES_ENERGY_PWR_HDL_IDX)
            {
                P = J / s;
                msg = "* returned in the power measurement";
            }
            else
                msg = "(unused)";

            printf("[device %d][pwr handle %d] used %lf J over %lf s - %s\n", devIndex, pwrIndex, J, s, msg);
        }
    }
    # endif

    return P;
}
