###################################################################################################

# Filename: excel_to_xml_universal.py
# Purpose : This script converts Excel-based register maps into a structured XML format.
#           It dynamically reads column headers from the Excel file and generates
#           corresponding XML tags without any hardcoded field names.
# Features:
# - Fully dynamic conversion (no fixed column dependency)
# - Supports any number of columns and flexible Excel formats
# - Automatically groups rows into Register and Field hierarchy
# - Uses first column as primary Register identifier
# - Identifies Field-related columns using intelligent heuristics
# - Generates clean, well-formatted (pretty-printed) XML output
# - Supports batch processing of multiple Excel file
# Workflow:
# Excel Register Map → Parse Headers → Group Rows → Generate XML → Save Output
# Version : 0.0
# Author  : Susmitha-
# Date    : 24/04/2026

###################################################################################################

import openpyxl
import xml.etree.ElementTree as ET
from xml.dom import minidom
import os

def excel_to_xml_universal(input_file, output_file):
    """
    Universal Converter:
    1. No hardcoded column names.
    2. Works with any number of columns.
    3. Pure Python (bypasses Pandas DLL blocks).
    """
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found.")
        return

    # Load the workbook and the first sheet
    try:
        wb = openpyxl.load_workbook(input_file, data_only=True)
        sheet = wb.active
    except Exception as e:
        print(f"Could not open {input_file}: {e}")
        return

    # 1. Capture Headers (First Row)
    # These become our XML Tag names automatically
    headers = [str(cell.value).strip().replace(" ", "_") for cell in sheet[1] if cell.value]
    
    # 2. Heuristic for Grouping: 
    # Usually, the first 3-4 columns (Register, Offset, etc.) stay the same for one Register.
    # We will group rows where the first column (the Register Name) is the same.
    data_rows = []
    for row in sheet.iter_rows(min_row=2, values_only=True):
        if any(row): # Skip empty rows
            data_rows.append(dict(zip(headers, row)))

    # Create the XML Root
    root = ET.Element('RegisterMap', {"source": input_file})

    current_reg_name = None
    current_reg_node = None

    # 3. Process Rows dynamically
    reg_key = headers[0] # Use the first column as the primary 'Register' key
    
    for row_data in data_rows:
        reg_id = row_data.get(reg_key)
        
        # If the Register name changes, create a new Register block
        if reg_id != current_reg_name:
            current_reg_name = reg_id
            current_reg_node = ET.SubElement(root, 'Register')
            
            # Add all non-field data to the Register block
            # We assume columns that change (like 'Field' or 'BitWidth') are field-level
            # For a truly universal script, we find the "Field" column index
            field_col_name = next((h for h in headers if 'field' in h.lower()), None)
            field_idx = headers.index(field_col_name) if field_col_name else len(headers) // 2
            
            for i in range(field_idx):
                tag_name = headers[i]
                ET.SubElement(current_reg_node, tag_name).text = str(row_data[tag_name])

        # Add Field block
        field_node = ET.SubElement(current_reg_node, 'Field')
        field_col_name = next((h for h in headers if 'field' in h.lower()), None)
        field_idx = headers.index(field_col_name) if field_col_name else len(headers) // 2
        
        for i in range(field_idx, len(headers)):
            tag_name = headers[i]
            ET.SubElement(field_node, tag_name).text = str(row_data[tag_name])

    # 4. Save with Prettification
    xml_str = ET.tostring(root, encoding='utf-8')
    pretty_xml = minidom.parseString(xml_str).toprettyxml(indent="  ")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(pretty_xml)
    print(f"Successfully converted: {input_file} -> {output_file}")

# =========================================================
# BATCH CONFIGURATION
# Add your file requirements here
# =========================================================
if __name__ == "__main__":
    # Format: ('Input_Excel_Name', 'Output_XML_Name')
    file_queue = [
        ('register_map.xlsx', 'xml1.xml'),
        ('py_xml_reg_map.xlsx', 'xml2.xml'),
        ('complex_ip_map.xlsx', 'xml3.xml'),
    ]

    for excel_in, xml_out in file_queue:
        excel_to_xml_universal(excel_in, xml_out)