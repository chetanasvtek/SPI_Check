###################################################################################################
# Filename: generate_generic_rtl.py
# Purpose: This script parses an XML file to generate a generic register block in SystemVerilog 
#           and a C header file for firmware definitions.
# version: 1.1
# Author: Susmitha
# Date: 20/04/2026
###################################################################################################
import xml.etree.ElementTree as ET
import os

class GenericRegisterGenerator:
    def __init__(self, xml_file):
        self.xml_file = xml_file
        self.ns = {'ip': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}
        self.registers = []

    def to_sv_hex(self, hex_str):
        clean = hex_str.replace('0x', '').strip()
        return f"32'h{clean}"

    def parse(self):
        """Parses the XML and extracts register metadata [cite: 230-238]."""
        if not os.path.exists(self.xml_file):
            print(f"Error: {self.xml_file} not found.")
            return False
        tree = ET.parse(self.xml_file)
        root = tree.getroot()
        for reg in root.findall('.//ip:register', self.ns):
            self.registers.append({
                'name': reg.find('ip:name', self.ns).text,
                'offset': reg.find('ip:addressOffset', self.ns).text,
                'access': reg.find('ip:access', self.ns).text
            })
        return True

    def generate_rtl(self):
        """Generates a protocol-agnostic register block [cite: 6, 239-246]."""
        with open("register_block.sv", 'w') as f:
            f.write("// Generic Register Block\n")
            f.write("module register_block #(\n  parameter ADDR_W = 32,\n  parameter DATA_W = 32\n)(\n")
            f.write("  input  logic              clk, rst_n,\n")
            f.write("  input  logic [ADDR_W-1:0] addr_i,\n")
            f.write("  input  logic [DATA_W-1:0] wdata_i,\n")
            f.write("  input  logic              we_i,  // Write Enable\n")
            f.write("  input  logic              re_i,  // Read Enable\n")
            f.write("  output logic [DATA_W-1:0] rdata_o\n);\n\n")

            # Internal Storage
            for reg in self.registers:
                if reg['access'] in ['read-write', 'write-only']:
                    f.write(f"  logic [DATA_W-1:0] reg_{reg['name'].lower()};\n")

            # Reset and Write Logic
            f.write("\n  always_ff @(posedge clk or negedge rst_n) begin\n")
            f.write("    if (!rst_n) begin\n")
            for reg in self.registers:
                if reg['access'] in ['read-write', 'write-only']:
                    # FIX: Removed the curly braces around DATA_W so it's treated as Verilog text, not a Python variable
                    f.write(f"      reg_{reg['name'].lower()} <= '0;\n")
            f.write("    end else if (we_i) begin\n")
            f.write("      case (addr_i)\n")
            for reg in self.registers:
                if reg['access'] in ['read-write', 'write-only']:
                    f.write(f"        {self.to_sv_hex(reg['offset'])}: reg_{reg['name'].lower()} <= wdata_i;\n")
            f.write("      endcase\n    end\n  end\n\n")

            # Read Logic
            f.write("  always_comb begin\n")
            f.write("    rdata_o = '0;\n")
            f.write("    if (re_i) begin\n")
            f.write("      case (addr_i)\n")
            for reg in self.registers:
                if reg['access'] == 'read-write':
                    f.write(f"        {self.to_sv_hex(reg['offset'])}: rdata_o = reg_{reg['name'].lower()};\n")
                elif reg['access'] == 'read-only':
                    f.write(f"        {self.to_sv_hex(reg['offset'])}: rdata_o = 32'hFF;\n")
            f.write("        default: rdata_o = '0;\n")
            f.write("      endcase\n    end\n  end\n\nendmodule\n")

    def generate_c_header(self):
        """Generates firmware definitions [cite: 61-68]."""
        with open("registers.h", 'w') as f:
            f.write("#ifndef REGISTERS_H\n#define REGISTERS_H\n\n")
            for reg in self.registers:
                f.write(f"#define {reg['name']}_OFFSET {reg['offset']}\n")
            f.write("\n#endif\n")

if __name__ == "__main__":
    gen = GenericRegisterGenerator("ip_name.xml")
    if gen.parse():
        # FIX: Method name now matches generate_rtl defined above
        gen.generate_rtl()
        gen.generate_c_header()
        print("Success: register_block.sv and registers.h generated.")