###################################################################################################
# Filename: generate_general_rtl.py
# Purpose: This script parses an XML file to generate a generic register block in SystemVerilog.
# version: 0.2
# Author: Susmitha
# Date: 05/05/2026
# Execution Command: python generate_general_rtl.py <input_xml> <module_name>
# Example: python generate_general_rtl.py register_map.xml my_register_block
###################################################################################################

import xml.etree.ElementTree as ET
import sys
import re

def generate_rtl(xml_file, module_name):
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
    except Exception as e:
        print(f"Error parsing XML: {e}")
        return

    # Standard IP-XACT Namespace
    ns = {'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}
    registers = root.findall('.//ipxact:register', ns)

    rtl =  f"module {module_name} (\n"
    rtl += f"    input  logic        clk,\n"
    rtl += f"    input  logic        rst_n,\n"
    rtl += f"    // Native Access Interface\n"
    rtl += f"    input  logic [31:0] wr_addr,\n"
    rtl += f"    input  logic [31:0] wr_data,\n"
    rtl += f"    input  logic        wr_en,\n"
    rtl += f"    input  logic [31:0] rd_addr,\n"
    rtl += f"    output logic [31:0] rd_data,\n\n"
    
    rtl += f"    // Exported Register Ports for Hardware Integration\n"
    for i, reg in enumerate(registers):
        name = reg.find('ipxact:name', ns).text.lower()
        comma = "," if i < len(registers) - 1 else ""
        rtl += f"    output logic [31:0] {name}_o{comma}\n"
    rtl += f");\n\n"

    # 1. Internal Register Storage
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        rtl += f"    logic [31:0] {name}_q;\n"
        rtl += f"    assign {name}_o = {name}_q;\n"

    # 2. Sequential Logic: Reset and Access Policies
    rtl += f"\n    always_ff @(posedge clk or negedge rst_n) begin\n"
    rtl += f"        if (!rst_n) begin\n"
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        field = reg.find('.//ipxact:field', ns)
        reset = field.find('ipxact:resettableValue', ns).text if field is not None else "32'h0"
        rtl += f"            {name}_q <= {reset};\n"
    
    rtl += f"        end else begin\n"
    
    # --- WRITE PATH ---
    rtl += f"            if (wr_en) begin\n"
    rtl += f"                case (wr_addr)\n"
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        addr = reg.find('ipxact:addressOffset', ns).text
        access = reg.find('ipxact:access', ns).text
        
        # Format address string (e.g., 16'h0004)
        clean_addr = f"32'h{addr.split('h')[-1].zfill(8)}" if 'h' in addr else f"32'd{addr}"
        
        rtl += f"                    {clean_addr}: begin\n"
        # Access Logic Implementation
        if access in ["RW", "WO"]:
            rtl += f"                        {name}_q <= wr_data;\n"
        elif access == "W1C":
            rtl += f"                        {name}_q <= {name}_q & ~wr_data;\n"
        elif access == "W1S":
            rtl += f"                        {name}_q <= {name}_q | wr_data;\n"
        elif access == "TOW":
            rtl += f"                        {name}_q <= {name}_q ^ wr_data;\n"
        elif access == "W0C":
            rtl += f"                        {name}_q <= {name}_q & wr_data;\n"
        # RO/RESERVED are ignored on write
        rtl += f"                    end\n"
    rtl += f"                    default: ;\n"
    rtl += f"                endcase\n"
    rtl += f"            end\n\n"

    # --- READ CLEAR (RC) LOGIC ---
    # Triggered when a read occurs at the specific address
    rtl += f"            // Read-to-Clear Logic\n"
    rtl += f"            case (rd_addr)\n"
    for reg in registers:
        access = reg.find('ipxact:access', ns).text
        if access == "RC":
            name = reg.find('ipxact:name', ns).text.lower()
            addr = reg.find('ipxact:addressOffset', ns).text
            clean_addr = f"32'h{addr.split('h')[-1].zfill(8)}" if 'h' in addr else f"32'd{addr}"
            rtl += f"                {clean_addr}: {name}_q <= '0;\n"
    rtl += f"                default: ;\n"
    rtl += f"            endcase\n"
    
    rtl += f"        end\n"
    rtl += f"    end\n\n"

    # 3. Combinational Read Path
    rtl += f"    always_comb begin\n"
    rtl += f"        rd_data = 32'h0;\n"
    rtl += f"        case (rd_addr)\n"
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        addr = reg.find('ipxact:addressOffset', ns).text
        access = reg.find('ipxact:access', ns).text
        clean_addr = f"32'h{addr.split('h')[-1].zfill(8)}" if 'h' in addr else f"32'd{addr}"
        
        if access != "WO":
            rtl += f"            {clean_addr}: rd_data = {name}_q;\n"
    rtl += f"            default: rd_data = 32'hDEAD_BEEF;\n"
    rtl += f"        endcase\n"
    rtl += f"    end\n\n"
    
    rtl += "endmodule\n"

    with open(f"{module_name}.sv", "w") as f:
        f.write(rtl)
    print(f"Successfully generated protocol-agnostic RTL: {module_name}.sv")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python script.py <input_xml> <module_name>")
    else:
        generate_rtl(sys.argv[1], sys.argv[2])