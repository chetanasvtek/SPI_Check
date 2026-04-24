###################################################################################################

# Filename: mul_sheet_excel_to_xml.py
# Purpose : This script converts multiple sheets from a single Excel register map file into
#           individual XML files based on predefined sheet-to-output mappings.

# Features:
# - Converts multiple Excel sheets into separate XML files
# - Uses user-defined mapping for sheet name → XML filename
# - Dynamically reads headers (no hardcoded column names)
# - Automatically groups data into Register and Field hierarchy
# - Identifies 'Field' column to split Register-level and Field-level data
# - Skips sheets not defined in configuration
# - Generates clean, formatted (pretty-printed) XML output
# - Pure Python implementation using openpyxl (no pandas dependency)
# Workflow:
# Excel (Multi-Sheet) → Identify Sheet → Parse Headers → Group Data →
# Generate XML per Sheet → Save Output Files
# Configuration:
# - SHEET_TO_XML_MAP defines which sheets to process and their output XML names
# Version : 0.1
# Author  : Susmitha
# Date    : 24/04/2026

###################################################################################################

import openpyxl
import xml.etree.ElementTree as ET
from xml.dom import minidom
import os

# =========================================================
# USER HARD-CODED CONFIGURATION
# These names now match your Excel sheets exactly.
# =========================================================
SHEET_TO_XML_MAP = {
    "ADC_Register": "adc_registers_final.xml",
    "DLL_Register": "dll_control_block.xml",
    "IP_Config":    "system_configuration.xml"
}

def convert_sheets_to_custom_xmls(input_excel):
    if not os.path.exists(input_excel):
        print(f"Error: {input_excel} not found.")
        return

    try:
        # Using openpyxl to bypass DLL security blocks
        wb = openpyxl.load_workbook(input_excel, data_only=True)
    except Exception as e:
        print(f"Error opening workbook: {e}")
        return

    print(f"Scanning sheets in {input_excel}...")

    for sheet in wb.worksheets:
        sheet_name = sheet.title
        
        # Exact match check
        if sheet_name in SHEET_TO_XML_MAP:
            output_xml = SHEET_TO_XML_MAP[sheet_name]
            print(f"Match Found! Converting '{sheet_name}' -> '{output_xml}'")
        else:
            print(f"Skipping '{sheet_name}' (Not defined in configuration)")
            continue

        # 1. Capture Headers from the first row
        headers = [str(cell.value).strip() for cell in sheet[1] if cell.value]
        
        # 2. Dynamic Grouping Logic
        # Finds the 'Field' column to handle nesting
        field_col_name = next((h for h in headers if 'field' in h.lower()), None)
        field_idx = headers.index(field_col_name) if field_col_name else len(headers)

        root = ET.Element('RegisterMap', {'source_sheet': sheet_name})
        
        current_reg_name = None
        current_reg_node = None
        reg_key = headers[0] # The first column is the Register ID

        # 3. Process Rows
        for row_cells in sheet.iter_rows(min_row=2, values_only=True):
            if not any(row_cells): continue # Skip empty lines
            
            row_data = dict(zip(headers, row_cells))
            reg_id = str(row_data.get(reg_key, ""))

            # New Register Block starts when the first column value changes
            if reg_id != current_reg_name and reg_id != "":
                current_reg_name = reg_id
                current_reg_node = ET.SubElement(root, 'Register')
                
                # Add Register attributes (columns before 'Field')
                for i in range(field_idx):
                    tag = headers[i].replace(" ", "_")
                    ET.SubElement(current_reg_node, tag).text = str(row_data.get(headers[i], ""))

            # Add Field Block (columns from 'Field' onwards)
            if field_col_name and current_reg_node is not None:
                f_node = ET.SubElement(current_reg_node, 'Field')
                for i in range(field_idx, len(headers)):
                    tag = headers[i].replace(" ", "_")
                    ET.SubElement(f_node, tag).text = str(row_data.get(headers[i], ""))

        # 4. Prettify and Save
        xml_str = ET.tostring(root, encoding='utf-8')
        pretty_xml = minidom.parseString(xml_str).toprettyxml(indent="  ")
        
        with open(output_xml, 'w', encoding='utf-8') as f:
            f.write(pretty_xml)
            
        print(f"  -> Successfully generated: {output_xml}")

if __name__ == "__main__":
    # Ensure this matches your filename on OneDrive
    convert_sheets_to_custom_xmls('register_map_UNV.xlsx')