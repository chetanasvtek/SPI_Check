File Name,Purpose
ip_name.xml,"Source File: Contains the master definition of all registers, including names, 32-bit widths, and address offsets (0x00, 0x04, 0x08)"
generate_generic_rtl.py,Automation Tool: The Python script that parses the XML and generates the hardware and software deliverables .
register_block.sv,"Hardware Output: Synthesizable SystemVerilog RTL. It uses a generic interface (Address, Data, Enable) to be compatible with APB, AHB, or SPI ."
registers.h,Software Output: C Header file containing #define macros for all register offsets to be used in firmware development .