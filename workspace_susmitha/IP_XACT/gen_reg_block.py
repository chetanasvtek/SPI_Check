###################################################################################################
# Filename: gen_reg_block.py
# Purpose: This script parses an XML file to generate a generic register block in SystemVerilog 
#           and a C header file for firmware definitions.
# version: 2.0
# Author: Susmitha
# Date: 22/04/2026
###################################################################################################
import xml.etree.ElementTree as ET
import os

def generate_ip_artifacts(xml_file):
    # IP-XACT Namespace
    ns = {'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}
    
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
    except Exception as e:
        print(f"Error parsing XML: {e}")
        return

    # Extract Basic Information
    comp_name = root.find('ipxact:name', ns).text
    addr_block = root.find('.//ipxact:addressBlock', ns)
    registers = addr_block.findall('ipxact:register', ns)
    base_addr = addr_block.find('ipxact:baseAddress', ns).text
    
    # 1. GENERATE SYSTEMVERILOG RTL
    rtl = []
    rtl.append(f"// Generated Register Block for {comp_name}")
    rtl.append(f"module {comp_name}_regs #(")
    rtl.append("    parameter ADDR_WIDTH = 12,")
    rtl.append("    parameter DATA_WIDTH = 32")
    rtl.append(") (")
    rtl.append("    input  logic                   clk,")
    rtl.append("    input  logic                   rst_n,")
    rtl.append("\n    // --- Bus Interface ---")
    rtl.append("    input  logic [ADDR_WIDTH-1:0]  waddr,")
    rtl.append("    input  logic [DATA_WIDTH-1:0]  wdata,")
    rtl.append("    input  logic                   wen,")
    rtl.append("    input  logic [ADDR_WIDTH-1:0]  raddr,")
    rtl.append("    output logic [DATA_WIDTH-1:0]  rdata,")
    
    rtl.append("\n    // --- Full Register Output Ports ---")
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        if reg.find('ipxact:access', ns).text != 'read-only':
            rtl.append(f"    output logic [31:0]            out_reg_{name},")

    rtl.append("\n    // --- Individual Field Ports ---")
    for reg in registers:
        reg_name = reg.find('ipxact:name', ns).text.lower()
        access = reg.find('ipxact:access', ns).text
        for field in reg.findall('ipxact:field', ns):
            f_name = field.find('ipxact:name', ns).text.lower()
            f_width = int(field.find('ipxact:bitWidth', ns).text)
            if access in ['read-write', 'write-only']:
                rtl.append(f"    output logic [{f_width-1}:0] out_f_{reg_name}_{f_name},")
            elif access == 'read-only':
                rtl.append(f"    input  logic [{f_width-1}:0] in_f_{reg_name}_{f_name},")

    rtl[-1] = rtl[-1].rstrip(',') 
    rtl.append(");")

    # Internal Storage
    rtl.append("\n    // Internal Storage")
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        if reg.find('ipxact:access', ns).text != 'read-only':
            rtl.append(f"    logic [31:0] q_{name};")

    # Write Logic
    rtl.append("\n    // Write Logic")
    rtl.append("    always_ff @(posedge clk or negedge rst_n) begin")
    rtl.append("        if (!rst_n) begin")
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        if reg.find('ipxact:access', ns).text != 'read-only':
            reset_val = reg.find('ipxact:resetValue', ns)
            rv = reset_val.text if reset_val is not None else "32'h0"
            rtl.append(f"            q_{name} <= {rv};")
    rtl.append("        end else if (wen) begin")
    rtl.append("            case (waddr)")
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        offset = reg.find('ipxact:addressOffset', ns).text
        if reg.find('ipxact:access', ns).text != 'read-only':
            rtl.append(f"                {offset} : q_{name} <= wdata;")
    rtl.append("                default : ;")
    rtl.append("            endcase")
    rtl.append("        end")
    rtl.append("    end")

    # Read Logic
    rtl.append("\n    // Read Logic")
    rtl.append("    always_comb begin")
    rtl.append("        case (raddr)")
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        offset = reg.find('ipxact:addressOffset', ns).text
        if reg.find('ipxact:access', ns).text == 'read-only':
            bits = []
            for field in reg.findall('ipxact:field', ns):
                fn, fo, fw = field.find('ipxact:name', ns).text.lower(), field.find('ipxact:bitOffset', ns).text, field.find('ipxact:bitWidth', ns).text
                bits.append(f"({fw}'(in_f_{name}_{fn}) << {fo})")
            rtl.append(f"            {offset} : rdata = {' | '.join(bits)};")
        else:
            rtl.append(f"            {offset} : rdata = q_{name};")
    rtl.append("            default : rdata = 32'h0;")
    rtl.append("        endcase")
    rtl.append("    end")

    # Continuous Assignments
    rtl.append("\n    // Port Mapping")
    for reg in registers:
        name = reg.find('ipxact:name', ns).text.lower()
        if reg.find('ipxact:access', ns).text != 'read-only':
            rtl.append(f"    assign out_reg_{name} = q_{name};")
            for field in reg.findall('ipxact:field', ns):
                fn = field.find('ipxact:name', ns).text.lower()
                fo, fw = int(field.find('ipxact:bitOffset', ns).text), int(field.find('ipxact:bitWidth', ns).text)
                rtl.append(f"    assign out_f_{name}_{fn} = q_{name}[{fo+fw-1}:{fo}];")
    rtl.append("\nendmodule")

    # 2. GENERATE C HEADER
    header = []
    prefix = comp_name.upper()
    header.append(f"/* Automatically generated C header for {comp_name} */")
    header.append(f"#ifndef {prefix}_H\n#define {prefix}_H\n")
    header.append(f"#define {prefix}_BASE_ADDR {base_addr}\n")

    for reg in registers:
        name = reg.find('ipxact:name', ns).text.upper()
        offset = reg.find('ipxact:addressOffset', ns).text
        header.append(f"/* {name} Register */")
        header.append(f"#define {prefix}_{name}_OFFSET {offset}")
        
        for field in reg.findall('ipxact:field', ns):
            f_name = field.find('ipxact:name', ns).text.upper()
            f_off = int(field.find('ipxact:bitOffset', ns).text)
            f_wid = int(field.find('ipxact:bitWidth', ns).text)
            mask = (1 << f_wid) - 1
            header.append(f"#define {name}_{f_name}_POS ({f_off})")
            header.append(f"#define {name}_{f_name}_MASK (0x{mask:x}U << {f_off})")
        header.append("")

    header.append(f"#endif /* {prefix}_H */")

    # Write Files
    with open(f"{comp_name}.sv", "w") as f: f.write("\n".join(rtl))
    with open(f"{comp_name.lower()}.h", "w") as f: f.write("\n".join(header))
    
    print(f"Generated: {comp_name}.sv and {comp_name.lower()}.h")

if __name__ == "__main__":
    generate_ip_artifacts("complex_ip.xml")