###################################################################################################
# File Name: generate_xml_to_excel.py
# Purpose: Parse IP-XACT XML and export register + field info to Excel
# Author: Susmitha
# Version: 2.1 (Uses bitRange from XML only)
###################################################################################################

import xml.etree.ElementTree as ET
import pandas as pd
import os

class IPXactFlow:
    def __init__(self, xml_file):
        self.xml_file = xml_file
        self.ns = {'ip': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}
        self.registers = []

    def get_text(self, parent, tag):
        """Safely get text from XML tag"""
        elem = parent.find(tag, self.ns)
        return elem.text if elem is not None else None

    def parse(self):
        """Parse XML and extract register/field data"""
        tree = ET.parse(self.xml_file)
        root = tree.getroot()

        for reg in root.findall('.//ip:register', self.ns):

            reg_name = self.get_text(reg, 'ip:name')
            offset   = self.get_text(reg, 'ip:addressOffset')
            access   = self.get_text(reg, 'ip:access') or "RW"

            fields = reg.findall('ip:field', self.ns)

            reg_size = self.get_text(reg, 'ip:size')
            
            # If no fields exist
            if not fields:
                self.registers.append({
                    'Register': reg_name,
                    'Offset': offset,
                    'Access': access,
                    'RegWidth': reg_size,
                    'Field': '-',
                    'BitOffset': '-',
                    'BitWidth': '32',
                    'BitRange': '-',   # No range available
                    'Reset': '0x0000_0000'
                })

            else:
                for field in fields:

                    field_name = self.get_text(field, 'ip:name')
                    bit_offset = self.get_text(field, 'ip:bitOffset')
                    bit_width  = self.get_text(field, 'ip:bitWidth')

                    # -------------------------------
                    # Read bitRange ONLY from XML
                    # -------------------------------
                    bit_range = "-"

                   
                    # Find vendorExtensions ignoring namespace
                    ve = field.find('.//{*}vendorExtensions')

                    if ve is not None:
                        br = ve.find('.//{*}bitRange')
                        if br is not None and br.text:
                            bit_range = br.text
                   # -------------------------------
                    # Reset Value (Field or Register)
                    # -------------------------------
                    field_reset = field.find('.//ip:resetValue', self.ns)
                    reg_reset = self.get_text(reg, 'ip:resetValue') or "0x00000000"

                    if field_reset is not None:
                        reset_val = field_reset.text
                    else:
                        reset_val = reg_reset

                    # -------------------------------
                    # Store Data
                    # -------------------------------
                    self.registers.append({
                        'Register': reg_name,
                        'Offset': offset,
                        'Access': access,
                        'RegWidth': reg_size,
                        'Field': field_name,
                        'BitOffset': bit_offset,
                        'BitWidth': bit_width,
                        'BitRange': bit_range,
                        'Reset': reset_val
                    })

    def generate_excel(self, filename="register_map.xlsx"):
        """Generate Excel output"""

        # Handle file lock issue
        if os.path.exists(filename):
            try:
                os.remove(filename)
            except PermissionError:
                print(f"❌ ERROR: Close '{filename}' and try again.")
                return

        df = pd.DataFrame(self.registers)

        columns_order = [
            'Register', 'Offset', 'Access',
            'RegWidth', 'Reset','Field', 'BitOffset', 'BitWidth', 'BitRange'
        ]

        df = df[columns_order]
        df.to_excel(filename, index=False)

        print(f"✅ Success: Register map exported to {filename}")


if __name__ == "__main__":
    xml_file = "complex_ip.xml"

    if os.path.exists(xml_file):
        flow = IPXactFlow(xml_file)
        flow.parse()
        flow.generate_excel()
    else:
        print(f"❌ Error: {xml_file} not found")