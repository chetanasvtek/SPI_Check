# -----------------------------------------------------------------------------
# File Name: register_tool.py
# Purpose: This script provides tools for converting between IP-XACT XML and 
#           Excel formats for register mapping.
# version: 2.1
# Author: Susmitha
# Date: 2026-04-23
# -----------------------------------------------------------------------------

import pandas as pd
import xml.etree.ElementTree as ET
from xml.dom import minidom
import os

# Configuration to match your requested Excel format
REG_COLS = ['Register', 'Offset', 'Access', 'RegWidth', 'Reset']
FIELD_COLS = ['Field', 'BitOffset', 'BitWidth', 'BitRange']
ALL_COLS = REG_COLS + FIELD_COLS

# XML Namespace for IP-XACT
NS = {'ipxact': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}

def xml_to_excel(input_xml, output_excel):
    """Parses IP-XACT XML into the standard Register Map Excel format."""
    tree = ET.parse(input_xml)
    root = tree.getroot()
    rows = []

    # Find all registers using the IP-XACT namespace
    for reg in root.findall('.//ipxact:register', NS):
        # Extract Register data from sub-elements
        reg_name = reg.find('ipxact:name', NS).text if reg.find('ipxact:name', NS) is not None else ""
        reg_offset = reg.find('ipxact:addressOffset', NS).text if reg.find('ipxact:addressOffset', NS) is not None else ""
        reg_access = reg.find('ipxact:access', NS).text if reg.find('ipxact:access', NS) is not None else ""
        reg_width = reg.find('ipxact:size', NS).text if reg.find('ipxact:size', NS) is not None else ""
        reg_reset = reg.find('ipxact:resetValue', NS).text if reg.find('ipxact:resetValue', NS) is not None else "0x0"

        # Find fields within this register
        for field in reg.findall('ipxact:field', NS):
            f_name = field.find('ipxact:name', NS).text if field.find('ipxact:name', NS) is not None else ""
            f_offset = field.find('ipxact:bitOffset', NS).text if field.find('ipxact:bitOffset', NS) is not None else ""
            f_width = field.find('ipxact:bitWidth', NS).text if field.find('ipxact:bitWidth', NS) is not None else ""
            
            # Find bitRange in VendorExtensions
            f_range = ""
            vendor_ext = field.find('.//ipxact:bitRange', NS)
            if vendor_ext is not None:
                f_range = vendor_ext.text

            rows.append({
                'Register': reg_name,
                'Offset': reg_offset,
                'Access': reg_access,
                'RegWidth': reg_width,
                'Reset': reg_reset,
                'Field': f_name,
                'BitOffset': f_offset,
                'BitWidth': f_width,
                'BitRange': f_range
            })

    df = pd.DataFrame(rows)
    df = df[ALL_COLS]
    df.to_excel(output_excel, index=False)
    print(f"Step 1 Success: {input_xml} -> {output_excel}")

def excel_to_xml(input_excel, output_xml):
    """Converts the generated Excel back into the IP-XACT XML format."""
    df = pd.read_excel(input_excel)
    
    # Create Root with Namespace
    root = ET.Element('component', {'xmlns': NS['ipxact']})
    mem_maps = ET.SubElement(root, 'memoryMaps')
    mem_map = ET.SubElement(mem_maps, 'memoryMap')
    addr_block = ET.SubElement(mem_map, 'addressBlock')
    
    # Group by Register
    registers = df.groupby(['Register', 'Offset', 'Access', 'RegWidth', 'Reset'], sort=False)

    for (name, offset, access, width, reset), fields in registers:
        reg_node = ET.SubElement(addr_block, 'register')
        ET.SubElement(reg_node, 'name').text = str(name)
        ET.SubElement(reg_node, 'addressOffset').text = str(offset)
        ET.SubElement(reg_node, 'size').text = str(width)
        ET.SubElement(reg_node, 'access').text = str(access)
        ET.SubElement(reg_node, 'resetValue').text = str(reset)

        for _, row in fields.iterrows():
            f_node = ET.SubElement(reg_node, 'field')
            ET.SubElement(f_node, 'name').text = str(row['Field'])
            ET.SubElement(f_node, 'bitOffset').text = str(row['BitOffset'])
            ET.SubElement(f_node, 'bitWidth').text = str(row['BitWidth'])
            
            # Add VendorExtensions for bitRange
            ve = ET.SubElement(f_node, 'vendorExtensions')
            ET.SubElement(ve, 'bitRange').text = str(row['BitRange'])

    # Prettify and Save
    xml_str = ET.tostring(root, encoding='utf-8')
    pretty_xml = minidom.parseString(xml_str).toprettyxml(indent="  ")
    with open(output_xml, 'w') as f:
        f.write(pretty_xml)
    print(f"Step 2 Success: {input_excel} -> {output_xml}")

if __name__ == "__main__":
    # Task 1: Convert your IP-XACT XML to Excel
    xml_to_excel('complex_ip.xml', 'complex_ip_map.xlsx')
    
    # Task 2: Convert that Excel back to XML (re-generation)
    excel_to_xml('complex_ip_map.xlsx', 'complex_ip_generated.xml')