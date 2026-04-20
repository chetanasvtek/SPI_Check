# -----------------------------------------------------------------------------
# File Name: generate_all.py
# Purpose: This script parses an IP-XACT XML file to generate synthesizable 
#          SystemVerilog RTL for an APB register block and a corresponding 
#          C header file for firmware development.
# version: 1.0
# Author: Susmitha
# Date: 2024-05-22
# -----------------------------------------------------------------------------
import xml.etree.ElementTree as ET


class IPXactFlow:
    def __init__(self, xml_file):
        self.xml_file = xml_file
        self.ns = {'ip': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}
        self.registers = []

    def to_sv_hex(self, hex_str):
        clean = hex_str.replace('0x', '').strip()
        return f"32'h{clean}"

    def parse(self):
        """Parses XML for register names, offsets, and access [cite: 230-238]."""
        tree = ET.parse(self.xml_file)
        root = tree.getroot()
        for reg in root.findall('.//ip:register', self.ns):
            self.registers.append({
                'name': reg.find('ip:name', self.ns).text,
                'offset': reg.find('ip:addressOffset', self.ns).text,
                'access': reg.find('ip:access', self.ns).text
            })

    def generate_rtl(self):
        """Generates synthesizable RTL with specified RO value [cite: 46-60]."""
        with open("apb_registers.sv", 'w') as f:
            f.write("module apb_registers #(\n  parameter APB_AW = 32,\n  parameter APB_DW = 32\n)(\n")
            f.write("  input  logic              PCLK, PRESETn,\n")
            f.write("  input  logic [APB_AW-1:0] PADDR, PWDATA,\n")
            f.write("  input  logic              PSEL, PENABLE, PWRITE,\n")
            f.write("  output logic [APB_DW-1:0] PRDATA,\n")
            f.write("  output logic              PREADY, PSLVERR\n);\n\n")
            f.write("  assign PREADY  = 1'b1;\n  assign PSLVERR = 1'b0;\n\n")

            # Declare internal registers
            for reg in self.registers:
                if reg['access'] in ['read-write', 'write-only']:
                    f.write(f"  logic [APB_DW-1:0] reg_{reg['name'].lower()};\n")

            # Write Logic [cite: 56, 240-245]
            f.write("\n  always_ff @(posedge PCLK or negedge PRESETn) begin\n")
            f.write("    if (!PRESETn) begin\n")
            for reg in self.registers:
                if reg['access'] in ['read-write', 'write-only']:
                    f.write(f"      reg_{reg['name'].lower()} <= 32'h0;\n")
            f.write("    end else if (PSEL && PENABLE && PWRITE) begin\n")
            f.write("      case (PADDR)\n")
            for reg in self.registers:
                if reg['access'] in ['read-write', 'write-only']:
                    f.write(f"        {self.to_sv_hex(reg['offset'])}: reg_{reg['name'].lower()} <= PWDATA;\n")
            f.write("      endcase\n    end\n  end\n\n")

            # Read Logic with hardcoded 0xFF for RO [cite: 57, 242-244]
            f.write("  always_comb begin\n    case (PADDR)\n")
            for reg in self.registers:
                if reg['access'] == 'read-write':
                    f.write(f"      {self.to_sv_hex(reg['offset'])}: PRDATA = reg_{reg['name'].lower()};\n")
                elif reg['access'] == 'read-only':
                    f.write(f"      {self.to_sv_hex(reg['offset'])}: PRDATA = 32'hFF; // Assigned RO Value\n")
                else:
                    f.write(f"      {self.to_sv_hex(reg['offset'])}: PRDATA = 32'h0;\n")
            f.write("      default: PRDATA = 32'h0;\n    endcase\n  end\nendmodule\n")

    def generate_c_header(self):
        """Generates the C header file for firmware usage [cite: 61-68]."""
        with open("registers.h", 'w') as f:
            f.write("#ifndef REGISTERS_H\n#define REGISTERS_H\n\n")
            f.write("/* Register Base Addresses */\n")
            for reg in self.registers:
                f.write(f"#define {reg['name']}_ADDR {reg['offset']}\n")
            f.write("\n#endif\n")

if __name__ == "__main__":
    flow = IPXactFlow("ip_name.xml")
    flow.parse()
    flow.generate_rtl()
    flow.generate_c_header()
    print("Generation complete: apb_registers.sv and registers.h created.")