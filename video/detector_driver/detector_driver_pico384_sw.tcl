#
# detector_driver_pico384_sw.tcl
#

# Create a new driver
create_driver detector_driver_pico384_driver

# Associate it with some hardware known as "detector_driver_pico384"
set_sw_property hw_class_name detector_driver_pico384

# The version of this driver
set_sw_property version 1.3

# This driver may be incompatible with versions of hardware less
# than specified below. Updates to hardware and device drivers
# rendering the driver incompatible with older versions of
# hardware are noted with this property assignment.
#
# Multiple-Version compatibility was introduced in version 11.0;
# prior versions are therefore excluded.
set_sw_property min_compatible_hw_version 1.3

# Initialize the driver in alt_sys_init()
set_sw_property auto_initialize false

# Location in generated BSP that above sources will be copied into
set_sw_property bsp_subdirectory drivers

#
# Source file listings...
#

# Include files
add_sw_property include_source HAL/inc/detector_driver_regs.h

# This driver supports HAL & UCOSII BSP (OS) types
add_sw_property supported_bsp_type HAL
add_sw_property supported_bsp_type UCOSII

# End of file
