###################################################################################################
# File Name: generate_xml_to_excel.py
# Purpose: This script parses an IP-XACT XML file and exports the register and 
#          field information into an Excel spreadsheet for documentation.
# Author:Susmitha
# Date: 21/04/2026
# Version: 1.2
###################################################################################################
import xml.etree.ElementTree as ET

import pandas as pd
import os

class IPXactFlow:
    def __init__(self, xml_file):
        self.xml_file = xml_file
        self.ns = {'ip': 'http://www.accellera.org/XMLSchema/IPXACT/1685-2014'}
        self.registers = []

    def parse(self):
        """Parses the XML and extracts register and field data."""
        tree = ET.parse(self.xml_file)
        root = tree.getroot()
        for reg in root.findall('.//ip:register', self.ns):
            reg_name = reg.find('ip:name', self.ns).text
            offset = reg.find('ip:addressOffset', self.ns).text
            access = reg.find('ip:access', self.ns).text
            
            # Extract Fields for Excel documentation
            fields = reg.findall('ip:field', self.ns)
            if not fields:
                # Handle registers without explicit fields
                self.registers.append({
                    'Register': reg_name, 'Offset': offset, 'Access': access,
                    'Field': '-', 'BitOffset': '-', 'BitWidth': 32, 'Reset': '0x0'
                })
            else:
                for field in fields:
                    self.registers.append({
                        'Register': reg_name,
                        'Offset': offset,
                        'Access': access,
                        'Field': field.find('ip:name', self.ns).text,
                        'BitOffset': field.find('ip:bitOffset', self.ns).text,
                        'BitWidth': field.find('ip:bitWidth', self.ns).text,
                        'Reset': field.find('.//ip:value', self.ns).text if field.find('.//ip:value', self.ns) is not None else "0x0"
                    })

    def generate_excel(self, filename="register_map.xlsx"):
        """Converts the parsed data into an Excel spreadsheet."""
        df = pd.DataFrame(self.registers)
        df.to_excel(filename, index=False)
        print(f"Success: Register map exported to {filename}")

if __name__ == "__main__":
    if os.path.exists("ip_name.xml"):
        flow = IPXactFlow("ip_name.xml")
        flow.parse()
        flow.generate_excel()