import xml.etree.ElementTree as ET

def generate_rtl(xml_file):
    # Parse the IP-XACT XML
    tree = ET.parse(xml_file)
    root = tree.getroot()
    ns = {'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}

    registers = []
    # Find all registers in the addressBlock
    for reg in root.findall('.//ipxact:register', ns):
        name = reg.find('ipxact:name', ns).text
        offset = reg.find('ipxact:addressOffset', ns).text.replace("16'h", "16'h")
        access = reg.find('ipxact:access', ns).text
        
        # Get reset value from the first field
        reset_val = "32'h0"
        field = reg.find('.//ipxact:field', ns)
        if field is not None:
            rv = field.find('ipxact:resettableValue', ns)
            if rv is not None:
                reset_val = rv.text.replace("32'h", "32'h")

        registers.append({
            'name': name,
            'offset': offset,
            'access': access,
            'reset': reset_val
        })

    # RTL Generation
    rtl = [
        "// Generated Register Block: apb_register.sv",
        "module apb_register #( ",
        "    parameter APB_AW = 16,",
        "    parameter APB_DW = 32",
        ") (",
        "    input  logic              clk,",
        "    input  logic              rst_n,",
        "    // Register Interface",
        "    input  logic              i_reg_wr_en,",
        "    input  logic              i_reg_rd_en,",
        "    input  logic [APB_AW-1:0] i_reg_addr,",
        "    input  logic [APB_DW-1:0] i_reg_wdata,",
        "    output logic [APB_DW-1:0] o_reg_rdata,",
        "    output logic              o_reg_ready,",
        "    output logic              o_reg_error",
        ");",
        "",
        "    // Internal Register Declarations"
    ]

    for reg in registers:
        rtl.append(f"    logic [31:0] reg_{reg['name'].lower()};")

    rtl.extend([
        "",
        "    // Address Decoding and Error Logic",
        "    logic addr_hit;",
        "    always_comb begin",
        "        addr_hit = 1'b0;",
        "        case (i_reg_addr)"
    ])

    for reg in registers:
        rtl.append(f"            {reg['offset']}: addr_hit = 1'b1;")
    
    rtl.extend([
        "            default: addr_hit = 1'b0;",
        "        endcase",
        "    end",
        "",
        "    assign o_reg_ready = (i_reg_rd_en || i_reg_wr_en);",
        "    assign o_reg_error = (i_reg_rd_en || i_reg_wr_en) && !addr_hit;",
        "",
        "    // Write Logic",
        "    always_ff @(posedge clk or negedge rst_n) begin",
        "        if (!rst_n) begin"
    ])

    # Initial Resets
    for reg in registers:
        rtl.append(f"            reg_{reg['name'].lower()} <= {reg['reset']};")

    rtl.extend([
        "        end else if (i_reg_wr_en && addr_hit) begin",
        "            case (i_reg_addr)"
    ])

    # Logic for different access types
    for reg in registers:
        name = reg['name'].lower()
        acc = reg['access']
        if acc == 'RW':
            rtl.append(f"                {reg['offset']}: reg_{name} <= i_reg_wdata;")
        elif acc == 'W1C':
            rtl.append(f"                {reg['offset']}: reg_{name} <= reg_{name} & ~i_reg_wdata;")
        elif acc == 'W1S':
            rtl.append(f"                {reg['offset']}: reg_{name} <= reg_{name} | i_reg_wdata;")
        elif acc == 'TOW': # Toggle on Write
            rtl.append(f"                {reg['offset']}: reg_{name} <= reg_{name} ^ i_reg_wdata;")
        elif acc == 'WO':
            rtl.append(f"                {reg['offset']}: reg_{name} <= i_reg_wdata;")
        # RO and RC are handled in Read Logic or external hardware
    
    rtl.extend([
        "            endcase",
        "        end",
        "    end",
        "",
        "    // Read Logic",
        "    always_comb begin",
        "        o_reg_rdata = 32'h0;",
       # "        if (i_reg_rd_en && addr_hit) begin",
        "            case (i_reg_addr)"
    ])

    for reg in registers:
        if reg['access'] != 'WO': # WO registers return 0 or undefined on read
            rtl.append(f"                {reg['offset']}: o_reg_rdata = reg_{reg['name'].lower()};")

    rtl.extend([
        "            endcase",
        "        end",
       # "    end",
        "",
        "    // Special Handling: RC (Read Clear) Logic",
        "    always_ff @(posedge clk or negedge rst_n) begin",
        "        if (!rst_n) begin",
        "            // handled in main reset",
        "        end else if (i_reg_rd_en && addr_hit) begin"
    ])

    for reg in registers:
        if reg['access'] == 'RC':
            rtl.append(f"            if (i_reg_addr == {reg['offset']}) reg_{reg['name'].lower()} <= 32'h0;")

    rtl.extend([
        "        end",
        "    end",
        "",
        "endmodule"
    ])

    # Write to file
    with open("apb_register.sv", "w") as f:
        f.write("\n".join(rtl))
    print("Successfully generated apb_register.sv")

if __name__ == "__main__":
    # Ensure your xml file is named 'py_generated_xml' as requested
    # Or change this to 'py_generated_xml.xml' if it has an extension
    generate_rtl("py_generated_xml.xml")