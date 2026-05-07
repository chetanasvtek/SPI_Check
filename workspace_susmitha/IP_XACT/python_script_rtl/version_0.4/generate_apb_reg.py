import xml.etree.ElementTree as ET

def generate_rtl(xml_file):
    # IP-XACT 2014 Namespace
    ns = {'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}
    
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
    except Exception as e:
        print(f"Error parsing XML: {e}")
        return

    registers = []
    for reg in root.findall('.//ipxact:register', ns):
        name = reg.find('ipxact:name', ns).text
        offset = reg.find('ipxact:addressOffset', ns).text.replace("16'h", "")
        access = reg.find('ipxact:access', ns).text
        
        # Hardcoding reset values based on your template
        reset_map = {
            "GLOBAL_CTRL": "32'h0",
            "COMMAND_WO": "32'h0",
            "STATUS_W1C": "32'h12345678",
            "STICKY_SET_W1S": "32'h0",
            "ERROR_COUNT_RC": "32'h12345678",
            "POLARITY_TOW": "32'hFFFFFFFF",
            "DEV_ID_RO": "32'h12345678"
        }
        
        registers.append({
            'name': name.lower(),
            'offset': f"16'h{offset}",
            'access': access,
            'reset': reset_map.get(name, "32'h0")
        })

    rtl = [
        "// Generated Register Block: apb_register",
        "import apb3_pkg::*;",
        "module apb_register #( ",
        ") (",
        "    input  logic              i_clk,",
        "    input  logic              i_resetn,",
        "    // Register Interface",
        "    input  logic              i_reg_enable,",
        "    input  logic              i_reg_wr_en,",
        "    input  logic              i_reg_rd_en,",
        "    input  logic [APB_AW-1:0] i_reg_addr,",
        "    input  logic [APB_DW-1:0] i_reg_wdata,",
        "",
        "    input  logic [31:0]       dev_id_ro_i,     // RO Register input Signal",
        "    input  logic [31:0]       error_count_rc_i, // RC Register input Signal",
        "",
        "    output logic [APB_DW-1:0] o_reg_rdata,",
        "    output logic              o_reg_ready,",
        "    output logic              o_reg_error,",
        "",
        "    // Exported Register Ports for Hardware Integration",
        "    output logic [31:0]       global_ctrl_o,",
        "    output logic [31:0]       command_wo_o,",
        "    output logic [31:0]       status_w1c_o,",
        "    output logic [31:0]       sticky_set_w1s_o,",
        "    output logic [31:0]       error_count_rc_o,",
        "    output logic [31:0]       polarity_tow_o",
        ");",
        "",
        "    // Internal Register Declarations"
    ]

    for reg in registers:
        rtl.append(f"    logic [31:0] reg_{reg['name']};")

    # Address Decoding Logic
    rtl.extend([
        "",
        "    // Address Decoding and Error Logic",
        "    logic addr_hit;",
        "",
        "    always_comb begin",
        "        addr_hit = 1'b0;",
        "        if (i_reg_wr_en) begin",
        "            case (i_reg_addr)"
    ])
    for reg in registers:
        if reg['access'] != 'RO':
            rtl.append(f"                {reg['offset']}: addr_hit = 1'b1;")
    rtl.extend([
        "            endcase",
        "        end",
        "        else if (i_reg_rd_en) begin",
        "            case (i_reg_addr)"
    ])
    for reg in registers:
        if reg['access'] != 'WO':
            rtl.append(f"                {reg['offset']}: addr_hit = 1'b1;")
    rtl.extend([
        "            endcase",
        "        end",
        "    end",
        "",
        "    // Write Logic",
        "    always_ff @(posedge i_clk or negedge i_resetn) begin",
        "        if (!i_resetn) begin"
    ])

    # Synchronous Reset for writable registers
    for reg in registers:
        if reg['access'] not in ['RO', 'RC']:
            rtl.append(f"            reg_{reg['name']} <= {reg['reset']};")

    rtl.extend([
        "        end ",
        "        else if (i_reg_wr_en && i_reg_enable) begin",
        "            case (i_reg_addr)"
    ])
    for reg in registers:
        name = reg['name']
        if reg['access'] == 'RW' or reg['access'] == 'WO':
            rtl.append(f"                {reg['offset']}: reg_{name} <= i_reg_wdata;")
        elif reg['access'] == 'W1C':
            rtl.append(f"                {reg['offset']}: reg_{name} <= reg_{name} & ~i_reg_wdata;")
        elif reg['access'] == 'W1S':
            rtl.append(f"                {reg['offset']}: reg_{name} <= reg_{name} | i_reg_wdata;")
        elif reg['access'] == 'TOW':
            rtl.append(f"                {reg['offset']}: reg_{name} <= reg_{name} ^ i_reg_wdata;")

    rtl.extend([
        "            endcase",
        "        end",
        "        else if (i_reg_rd_en) begin",
        "            if (i_reg_addr == 16'h0010) reg_error_count_rc <= 32'h0;",
        "        end",
        "    end",
        "",
        "    // Sampling logic for externally driven registers",
        "    always_ff @(posedge i_clk or negedge i_resetn) begin",
        "        if (!i_resetn) begin",
        "            reg_dev_id_ro <= 32'h12345678;",
        "            reg_error_count_rc <= 32'h12345678;",
        "        end else begin",
        "            reg_dev_id_ro <= dev_id_ro_i;",
        "            reg_error_count_rc <= error_count_rc_i;",
        "        end",
        "    end",
        "",
        "    // Read Logic",
        "    always_comb begin",
        "        o_reg_rdata = 32'h0;",
        "        case (i_reg_addr)"
    ])

    for reg in registers:
        if reg['access'] != 'WO':
            rtl.append(f"            {reg['offset']}: o_reg_rdata = reg_{reg['name']};")

    rtl.extend([
        "        endcase",
        "    end",
        "",
        "    assign o_reg_ready = 1'b1; // Always ready for simplicity",
        "    assign o_reg_error = !addr_hit;",
        "",
        "    // Export Register Values to Output Ports",
        "    assign global_ctrl_o     = reg_global_ctrl;",
        "    assign command_wo_o      = reg_command_wo;",
        "    assign status_w1c_o      = reg_status_w1c;",
        "    assign sticky_set_w1s_o  = reg_sticky_set_w1s;",
        "    assign error_count_rc_o  = reg_error_count_rc;",
        "    assign polarity_tow_o    = reg_polarity_tow;",
        "",
        "endmodule"
    ])

    with open("apb_register.sv", "w") as f:
        f.write("\n".join(rtl))
    print("Generated apb_register.sv successfully.")

if __name__ == "__main__":
    generate_rtl("py_generated_xml.xml")