import xml.etree.ElementTree as ET
import re

def generate_sv_rtl(xml_file):
    tree = ET.parse(xml_file)
    root = tree.getroot()

    registers = []
    for reg_node in root.findall('Register'):
        # Handling the double 'Register' tag in the XML structure
        name = reg_node.find('Register').text
        offset = reg_node.find('Offset').text
        access = reg_node.find('Access').text
        width = int(reg_node.find('RegWidth').text)
        
        fields = []
        for field_node in reg_node.findall('Field'):
            f_name = field_node.find('Field').text
            f_width = int(field_node.find('BitWidth').text)
            f_range = field_node.find('BitRange').text
            f_reset = field_node.find('Reset').text
            fields.append({'name': f_name, 'width': f_width, 'range': f_range, 'reset': f_reset})
        
        registers.append({'name': name, 'offset': offset, 'access': access, 'width': width, 'fields': fields})

    rtl = []
    rtl.append(f"module register_block (")
    rtl.append(f"    input  logic        clk,")
    rtl.append(f"    input  logic        rst_n,")
    rtl.append(f"    input  logic [15:0] addr,")
    rtl.append(f"    input  logic        wen,")
    rtl.append(f"    input  logic [31:0] wdata,")
    rtl.append(f"    output logic [31:0] rdata,")
    rtl.append(f"")
    
    rtl.append(f"    // Register Outputs (Full Width)")
    for reg in registers:
        rtl.append(f"    output logic [{reg['width']-1}:0] out_{reg['name'].lower()},")
    
    rtl.append(f"")
    rtl.append(f"    // Inputs for RO Registers (External Data)")
    for reg in registers:
        if reg['access'] == 'RO':
            rtl.append(f"    input  logic [{reg['width']-1}:0] {reg['name'].lower()}_reg_in,")
    
    rtl[-1] = rtl[-1].rstrip(',') 
    rtl.append(f");")
    rtl.append(f"")

    # Internal Storage logic
    for reg in registers:
        if reg['access'] != 'RO':
            rtl.append(f"    logic [{reg['width']-1}:0] reg_{reg['name'].lower()};")
    
    rtl.append(f"")

    # --- Write Logic (Sequential) ---
    rtl.append(f"    always_ff @(posedge clk or negedge rst_n) begin")
    rtl.append(f"        if (!rst_n) begin")
    for reg in registers:
        if reg['access'] != 'RO':
            # Calculate reset value from bitfields
            reset_val = 0
            for f in reg['fields']:
                res_str = f['reset']
                if "'b" in res_str:
                    val = int(res_str.split("'b")[1], 2)
                    bits = re.findall(r'\d+', f['range'])
                    lsb = int(bits[-1])
                    reset_val |= (val << lsb)
            rtl.append(f"            reg_{reg['name'].lower()} <= {reg['width']}'h{reset_val:X};")
    
    rtl.append(f"        end else if (wen) begin")
    rtl.append(f"            unique case (addr)")
    for reg in registers:
        if reg['access'] in ['RW', 'WO', 'WLC']:
            rtl.append(f"                {reg['offset']}: reg_{reg['name'].lower()} <= wdata[{reg['width']-1}:0];")
    rtl.append(f"                default: ;")
    rtl.append(f"            endcase")
    rtl.append(f"        end")
    rtl.append(f"    end")
    rtl.append(f"")

    # --- Read Logic (Combinational) ---
    rtl.append(f"    always_comb begin")
    rtl.append(f"        unique case (addr)")
    for reg in registers:
        if reg['access'] != 'WO':
            src = f"reg_{reg['name'].lower()}" if reg['access'] != 'RO' else f"{reg['name'].lower()}_reg_in"
            rtl.append(f"            {reg['offset']}: rdata = 32'({src});")
        else:
            rtl.append(f"            {reg['offset']}: rdata = '0; // Write-Only")
    rtl.append(f"            default: rdata = '0;")
    rtl.append(f"        endcase")
    rtl.append(f"    end")
    rtl.append(f"")

    # --- Assignments ---
    rtl.append(f"    // Assignments to top-level ports")
    for reg in registers:
        src = f"reg_{reg['name'].lower()}" if reg['access'] != 'RO' else f"{reg['name'].lower()}_reg_in"
        rtl.append(f"    assign out_{reg['name'].lower()} = {src};")

    rtl.append(f"")
    rtl.append(f"endmodule")

    return "\n".join(rtl)

# Execute
sv_code = generate_sv_rtl('xml2.xml')
with open('register_block.sv', 'w') as f:
    f.write(sv_code)